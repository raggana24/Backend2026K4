# Guía completa – Ejercicio RestClient con Spring Boot

> Apuntes relacionados: **14** (Diseño de APIs), **15** (Spring y Spring Boot), **17** (Elementos transversales) y **18** (RestClient).

---

## Índice

1. [¿Qué hace el ejercicio?](#1-qué-hace-el-ejercicio)
2. [Conceptos que tenés que conocer](#2-conceptos-que-tenés-que-conocer)
3. [La arquitectura: puertos y adaptadores](#3-la-arquitectura-puertos-y-adaptadores)
4. [Estructura del proyecto](#4-estructura-del-proyecto)
5. [Archivo por archivo: código y explicación](#5-archivo-por-archivo-código-y-explicación)
6. [Qué pasa cuando llega una petición](#6-qué-pasa-cuando-llega-una-petición)
7. [Compilar, ejecutar y probar: qué tiene que aparecer en cada paso](#7-compilar-ejecutar-y-probar-qué-tiene-que-aparecer-en-cada-paso)
8. [Errores que tuvimos y cómo se resolvieron](#8-errores-que-tuvimos-y-cómo-se-resolvieron)
9. [Consignas para practicar](#9-consignas-para-practicar)
10. [Preguntas de repaso (con respuestas)](#10-preguntas-de-repaso-con-respuestas)
11. [Próximos pasos](#11-próximos-pasos)

---

## 1. ¿Qué hace el ejercicio?

Es una API REST hecha con Spring Boot que **no tiene base de datos propia**. Cuando alguien le pide posts, ella se los pide a otra API pública que está en internet (**JSONPlaceholder**), los transforma y los devuelve.

```
Navegador / Postman  ──►  NUESTRA API (localhost:8080)  ──►  JSONPlaceholder (internet)
                     ◄──                                ◄──
```

Nuestra aplicación cumple **dos roles al mismo tiempo**:

- **Servidor** para el navegador (recibe peticiones y responde).
- **Cliente** de JSONPlaceholder (le hace peticiones con RestClient).

### Endpoints que expone

| Método | URL | Qué devuelve | Código |
|---|---|---|---|
| GET | `/api/v1/posts` | Lista de 100 posts, solo `id` y `title` | 200 |
| GET | `/api/v1/posts/{id}` | Un post, solo `id` y `title` | 200 |
| GET | `/api/v1/posts/{id}` (id inexistente) | Nada | 404 |
| GET | cualquiera, si JSONPlaceholder falla | `{"error": "..."}` | 502 |

### ¿Qué es JSONPlaceholder?

Una API pública y gratuita, hecha para practicar. Tiene **datos falsos y fijos** (siempre los mismos): 100 posts, 500 comentarios, 10 usuarios, 200 tareas. El texto en latín es relleno, como el *lorem ipsum*.

- `https://jsonplaceholder.typicode.com/posts` → lista de 100 posts
- `https://jsonplaceholder.typicode.com/posts/1` → un post

Cada post trae 4 campos:

```json
{
  "userId": 1,
  "id": 1,
  "title": "sunt aut facere repellat provident...",
  "body": "quia et suscipit..."
}
```

> Si le hacés POST, PUT o DELETE, responde como si funcionara, pero **no guarda nada**.

---

## 2. Conceptos que tenés que conocer

### Spring y Spring Boot

- **Spring** es un framework de Java que **crea y conecta los objetos por vos**.
- **Spring Boot** es Spring "preconfigurado": trae un servidor Tomcat adentro, configuración automática y *starters* (paquetes de dependencias listos para usar).

### Bean

Un **bean** es un objeto que Spring crea y administra. Por defecto crea **uno solo** de cada tipo (*singleton*) y lo reutiliza.

Formas de crear beans:

| Forma | Dónde va | Cuándo se usa |
|---|---|---|
| `@Component` | Arriba de una clase tuya | Clases que escribís vos |
| `@Service` | Igual que `@Component` | Clases con lógica de negocio |
| `@RestController` | Igual que `@Component` | Clases que atienden HTTP |
| `@Bean` | Arriba de un método, dentro de una clase `@Configuration` | Objetos de librerías externas (como `RestClient`), que no podés anotar |

`@Service` y `@RestController` son **variantes de `@Component`**: hacen lo mismo, pero el nombre indica el rol de la clase.

### Inyección de dependencias (DI)

Una clase **declara lo que necesita en su constructor** y Spring se lo pasa. Nadie hace `new`.

```java
public class PostService {
    private final PostAdapter postAdapter;

    public PostService(PostAdapter postAdapter) {  // "necesito un PostAdapter"
        this.postAdapter = postAdapter;            // Spring me lo pasa
    }
}
```

**Ventaja:** podés cambiar la implementación (por ejemplo, de API externa a base de datos) sin tocar la clase que la usa.

### Maven y el `pom.xml`

- El **`pom.xml`** es una **lista** de lo que el proyecto necesita (dependencias) y cómo compilarlo.
- **Maven** lee esa lista y **descarga las librerías** de internet a `C:\Users\<usuario>\.m2\repository`.
- **Spring Initializr** solo genera el esqueleto y el `pom.xml`. **No descarga nada.** Eso lo hace Maven cuando IntelliJ reconoce el proyecto.

Dependencias del proyecto:

| Dependencia | Para qué |
|---|---|
| `spring-boot-starter-webmvc` | Controllers, Tomcat, Jackson y **RestClient** |
| `spring-boot-devtools` | Reinicia la app automáticamente cuando cambiás el código |
| `lombok` | Genera getters, constructores y logger con anotaciones |
| `spring-boot-starter-webmvc-test` | Para tests |

> En Spring Boot 4, `spring-boot-starter-web` pasó a llamarse `spring-boot-starter-webmvc`. Es lo mismo.

### Lombok

Genera código repetitivo **al compilar**. No escribís ese código: lo crea Lombok.

| Anotación | Qué genera |
|---|---|
| `@Getter` | `getX()` para cada atributo |
| `@RequiredArgsConstructor` | Un constructor con todos los atributos `final` |
| `@FieldDefaults(level = PRIVATE, makeFinal = true)` | Hace todos los atributos `private final` |
| `@Slf4j` | Un atributo `log` para escribir mensajes en la consola |

Para ver lo que generó: abrí la clase y mirá el panel **Structure** (Alt + 7).

### Jackson

Librería que convierte **JSON ↔ objetos Java**. Viene incluida en el starter web.

- Al **recibir** JSON de JSONPlaceholder → lo convierte en objetos `Post`.
- Al **responder** → convierte `PostResponse` en JSON.

Empareja **por nombre**: el campo `"title"` del JSON va al atributo `title`. Si los nombres no coinciden, el atributo queda en `null`. Si el JSON trae campos que la clase no tiene, los ignora.

### RestClient

Clase de Spring (desde Spring Boot 3.2) para **hacer peticiones HTTP** desde Java. Viene en la librería `spring-web`, que trae el starter.

```java
restClient.get()          // método HTTP
        .uri("/posts")    // ruta (se suma a la URL base)
        .retrieve()       // ejecutar y traer la respuesta
        .body(Post.class) // convertir el JSON del cuerpo a un objeto
```

Antes se usaba `RestTemplate` (más viejo) y `WebClient` (reactivo). En la materia se usa **RestClient**.

### DTO (Data Transfer Object)

Objeto que define **qué datos salen por la API**. No es lo mismo que el modelo interno.

- `Post` (modelo) → 4 campos: `id`, `userId`, `title`, `body`
- `PostResponse` (DTO) → 2 campos: `id`, `title`

Así controlás qué ve el cliente, y si el modelo interno cambia, tu API no se rompe.

### `Optional`

Una "cajita" que **puede tener un valor o estar vacía**. Se usa cuando algo puede no existir (por ejemplo, buscar un post por id). Evita devolver `null`.

```java
Optional<Post> encontrado = Optional.of(post);
Optional<Post> noEncontrado = Optional.empty();
```

---

## 3. La arquitectura: puertos y adaptadores

El ejercicio usa **arquitectura hexagonal** (también llamada de *puertos y adaptadores*). Divide el código en tres zonas:

| Zona | Qué contiene | Regla |
|---|---|---|
| **domain** | El modelo (`Post`) y los **puertos** (interfaces como `PostAdapter`) | **No depende de ninguna tecnología.** Nada de Spring, HTTP ni base de datos. |
| **application** | Casos de uso (`PostService`), entrada HTTP (`PostController`), DTOs y manejo de errores | Usa el dominio. |
| **infrastructure** | Detalles técnicos: configuración de RestClient y **adaptadores** que implementan los puertos | Depende del dominio, nunca al revés. |

```
                 PostController
                       │
                       ▼
                  PostService
                       │ usa la interfaz
                       ▼
          «interface» PostAdapter          ← PUERTO (domain)
                       ▲
                       │ implementa
           JsonPlaceholderAdapter          ← ADAPTADOR (infrastructure)
                       │
                       ▼
                   RestClient ──► Internet
```

### ¿Por qué así?

`PostService` **solo conoce la interfaz** `PostAdapter`. No sabe si los posts vienen de internet, de una base de datos o de un archivo. Si mañana creás un `BaseDeDatosAdapter implements PostAdapter`, el Service y el Controller **no cambian**.

Es el mismo principio de polimorfismo del apunte 8: **programar contra la interfaz, no contra la implementación**.

### Comparación con el apunte 15

| Apunte 15 | Este ejercicio |
|---|---|
| Controller | `PostController` |
| Service | `PostService` |
| Repository | `PostAdapter` (interfaz) + `JsonPlaceholderAdapter` (implementación) |
| Model | `Post` |
| DTO | `PostResponse` |

---

## 4. Estructura del proyecto

```
src/main/java/com/backend/restclient
├── RestclientApplication.java                  ← main: arranca todo
│
├── domain                                      ← EL NEGOCIO
│   ├── model
│   │   └── Post.java                           ← cómo es un post
│   └── adapters
│       └── PostAdapter.java                    ← interfaz (puerto)
│
├── application                                 ← CASOS DE USO Y ENTRADA HTTP
│   ├── PostService.java                        ← lógica
│   ├── controllers
│   │   └── PostController.java                 ← endpoints
│   ├── responses
│   │   └── PostResponse.java                   ← DTO de salida
│   └── exceptions
│       └── GlobalExceptionHandler.java         ← manejo global de errores
│
└── infrastructure                              ← DETALLES TÉCNICOS
    ├── ClienteConfig.java                      ← crea el RestClient
    └── adapters
        └── JsonPlaceholderAdapter.java         ← implementa el puerto con HTTP

src/main/resources
└── application.properties                      ← configuración (URL de la API)
```

> **Regla de Java:** la línea `package` de arriba de cada archivo **tiene que coincidir con su carpeta**. Si no coincide, no compila.

---

## 5. Archivo por archivo: código y explicación

### 5.1 `application.properties`

📁 `src/main/resources/application.properties`

```properties
spring.application.name=restclient

jsonplaceholder.api-url=https://jsonplaceholder.typicode.com
```

**Para qué sirve:** guarda la configuración fuera del código.

- `spring.application.name` → nombre de la app (aparece en los logs).
- `jsonplaceholder.api-url` → **propiedad inventada por nosotros**. La lee `ClienteConfig` con `@Value`.

**¿Por qué no escribir la URL en el código?** Porque si cambia (por ejemplo, para apuntar a otro microservicio), modificás una línea de configuración y no tocás código.

⚠️ El nombre tiene que coincidir **exactamente** con el del `@Value`: punto antes de `api` y guion medio en `api-url`.

---

### 5.2 `RestclientApplication.java`

📁 `com/backend/restclient/RestclientApplication.java`

```java
package com.backend.restclient;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class RestclientApplication {

    public static void main(String[] args) {
        SpringApplication.run(RestclientApplication.class, args);
    }
}
```

**Para qué sirve:** es el punto de entrada. Lo genera Initializr.

- `@SpringBootApplication` activa la configuración automática y le dice a Spring que **escanee este paquete y todos sus subpaquetes** buscando clases con `@Component`, `@Service`, `@RestController`, `@Configuration`, etc.
- `SpringApplication.run(...)` crea todos los beans, los conecta y levanta Tomcat en el puerto 8080.

> Por eso todas tus clases tienen que estar **dentro** de `com.backend.restclient`. Si una queda afuera, Spring no la encuentra.

---

### 5.3 `Post.java` (modelo)

📁 `domain/model/Post.java`

```java
package com.backend.restclient.domain.model;

import lombok.AccessLevel;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Getter
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
public class Post {
    Integer id;
    Integer userId;
    String title;
    String body;
}
```

**Para qué sirve:** representa un post tal como lo devuelve JSONPlaceholder. Los nombres de los atributos coinciden con las claves del JSON.

**Qué genera Lombok** (no lo escribís vos):

```java
private final Integer id;  // ... y los demás atributos
public Post(Integer id, Integer userId, String title, String body) { ... }
public Integer getId() { ... }  // ... y los demás getters
```

**Por qué inmutable (`final`, sin setters):** son datos que vienen de afuera y solo los leemos. Así nadie los modifica por error.

**Cómo lo llena Jackson:** busca el constructor, lee los nombres de sus parámetros (posible gracias a la opción `-parameters` que activa Spring Boot al compilar) y los empareja con el JSON.

**Alternativa equivalente con `record`:**
```java
public record Post(Integer id, Integer userId, String title, String body) {}
```
Con record, los métodos de acceso se llaman `id()` y `title()` (sin `get`).

---

### 5.4 `PostAdapter.java` (puerto)

📁 `domain/adapters/PostAdapter.java`

```java
package com.backend.restclient.domain.adapters;

import com.backend.restclient.domain.model.Post;

import java.util.List;
import java.util.Optional;

public interface PostAdapter {

    List<Post> list();

    Optional<Post> findById(Integer id);
}
```

**Para qué sirve:** es el **contrato**. Dice *qué* necesita el sistema ("listar posts" y "buscar uno por id"), pero no *cómo*.

- Es una **interfaz**: no tiene implementación ni anotaciones de Spring.
- No importa nada de RestClient ni de HTTP. El dominio no conoce la tecnología.
- `findById` devuelve `Optional` porque el post **puede no existir**.

---

### 5.5 `ClienteConfig.java` (configuración del RestClient)

📁 `infrastructure/ClienteConfig.java`

```java
package com.backend.restclient.infrastructure;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class ClienteConfig {

    @Bean
    public RestClient restClient(@Value("${jsonplaceholder.api-url}") String apiUrl) {
        return RestClient.builder()
                .baseUrl(apiUrl)
                .build();
    }
}
```

**Para qué sirve:** crea **un único `RestClient`** configurado con la URL base, para que cualquier clase lo pueda pedir.

| Parte | Qué hace |
|---|---|
| `@Configuration` | Esta clase fabrica beans. |
| `@Bean` | Lo que devuelve el método pasa a ser un bean. |
| `@Value("${jsonplaceholder.api-url}")` | Lee la propiedad de `application.properties`. |
| `RestClient.builder()` | Empieza a armar el cliente (patrón *Builder*). |
| `.baseUrl(apiUrl)` | Todas las llamadas van a empezar con esta URL. |
| `.build()` | Termina de armarlo. |

**¿Por qué `@Bean` y no `@Component`?** Porque `RestClient` es de Spring, no tuyo: no podés abrir su código y anotarlo.

**¿Por qué `builder()` y no `new`?** Porque `RestClient` es una **interfaz** y las interfaces no se instancian con `new`.

---

### 5.6 `JsonPlaceholderAdapter.java` (adaptador)

📁 `infrastructure/adapters/JsonPlaceholderAdapter.java`

```java
package com.backend.restclient.infrastructure.adapters;

import com.backend.restclient.domain.adapters.PostAdapter;
import com.backend.restclient.domain.model.Post;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.List;
import java.util.Optional;

@Component
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
@Slf4j
public class JsonPlaceholderAdapter implements PostAdapter {

    private static final ParameterizedTypeReference<List<Post>> POSTS_TYPE =
            new ParameterizedTypeReference<>() {};

    RestClient restClient;

    @Override
    public List<Post> list() {
        try {
            var posts = restClient.get()
                    .uri("/posts")
                    .retrieve()
                    .body(POSTS_TYPE);

            return posts;
        } catch (RestClientException e) {
            log.error("Error al consultar JSONPlaceholder", e);
            throw e;
        }
    }

    @Override
    public Optional<Post> findById(Integer id) {
        try {
            var post = restClient.get()
                    .uri("/posts/{id}", id)
                    .retrieve()
                    .body(Post.class);

            return Optional.ofNullable(post);
        } catch (HttpClientErrorException.NotFound e) {
            log.warn("Post {} no encontrado en JSONPlaceholder", id);
            return Optional.empty();
        } catch (RestClientException e) {
            log.error("Error al consultar el post {} en JSONPlaceholder", id, e);
            throw e;
        }
    }
}
```

**Para qué sirve:** es **la implementación concreta** del puerto. Sabe traer los posts por HTTP.

**Puntos clave:**

- `implements PostAdapter` → cumple el contrato del dominio.
- `RestClient restClient` → se inyecta por el constructor que genera Lombok. Spring le pasa el bean de `ClienteConfig`.
- `.uri("/posts/{id}", id)` → RestClient reemplaza `{id}` por el valor.

**¿Qué es `ParameterizedTypeReference`?**
Para un objeto se escribe `.body(Post.class)`. Pero para una lista **no se puede** escribir `List<Post>.class`: Java borra el `<Post>` al compilar (*type erasure*). `ParameterizedTypeReference<List<Post>>` "conserva" el tipo completo para que Jackson sepa que es una lista **de Post**.

**Los dos `catch` en `findById`** (del más específico al más general):

| Excepción | Cuándo pasa | Qué hacemos |
|---|---|---|
| `HttpClientErrorException.NotFound` | JSONPlaceholder respondió 404 (el post no existe) | No es una falla: devolvemos `Optional.empty()` |
| `RestClientException` | Sin internet, error 500, timeout, URL mal | Es una falla: la registramos en el log y la relanzamos |

El orden importa: `NotFound` es subclase de `RestClientException`. Si el general fuera primero, el específico nunca se ejecutaría (y Java no compila).

**Logs:** `log.warn("Post {} no encontrado", id)` → las `{}` se reemplazan por los valores que pasás después.

---

### 5.7 `PostResponse.java` (DTO)

📁 `application/responses/PostResponse.java`

```java
package com.backend.restclient.application.responses;

import com.backend.restclient.domain.model.Post;

public record PostResponse(Integer id, String title) {

    public static PostResponse of(Post post) {
        return new PostResponse(
                post.getId(),
                post.getTitle()
        );
    }
}
```

**Para qué sirve:** define **qué sale por la API**. Solo `id` y `title`. Ocultamos `userId` y `body`.

- **`record`**: forma corta de Java para clases que solo transportan datos (atributos finales + constructor + métodos de acceso).
- **`of(Post post)`**: método de fábrica estático que convierte un `Post` en un `PostResponse`. Deja la conversión en un único lugar.

---

### 5.8 `PostService.java` (lógica)

📁 `application/PostService.java` ← suelto dentro de `application`, **no** dentro de `responses`

```java
package com.backend.restclient.application;

import com.backend.restclient.application.responses.PostResponse;
import com.backend.restclient.domain.adapters.PostAdapter;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
public class PostService {

    PostAdapter postAdapter;

    public List<PostResponse> list() {
        return postAdapter.list()
                .stream()
                .map(PostResponse::of)
                .toList();
    }

    public Optional<PostResponse> findById(Integer id) {
        return postAdapter.findById(id)
                .map(PostResponse::of);
    }
}
```

**Para qué sirve:** contiene la lógica de los casos de uso. Acá: pedir los posts y convertirlos al DTO.

- **`PostAdapter postAdapter`** → pide la **interfaz**. Spring busca quién la implementa (`JsonPlaceholderAdapter`) y se la inyecta.
- **El stream** (apunte 10):

```java
postAdapter.list()         // List<Post>
        .stream()          // Stream<Post>
        .map(PostResponse::of) // Stream<PostResponse>  (convierte cada uno)
        .toList();         // List<PostResponse>
```

- `PostResponse::of` es una **referencia a método**. Equivale a `post -> PostResponse.of(post)`.
- `Optional` también tiene `.map(...)`: si hay valor lo convierte; si está vacío, sigue vacío.

> En un caso real, acá irían las reglas de negocio: validaciones, filtros, ordenamientos, cálculos.

---

### 5.9 `PostController.java` (endpoints)

📁 `application/controllers/PostController.java`

```java
package com.backend.restclient.application.controllers;

import com.backend.restclient.application.PostService;
import com.backend.restclient.application.responses.PostResponse;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/posts")
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
public class PostController {

    PostService postService;

    @GetMapping
    public ResponseEntity<List<PostResponse>> list() {
        var list = postService.list();
        return ResponseEntity.ok(list);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PostResponse> findById(@PathVariable Integer id) {
        return postService.findById(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
```

**Para qué sirve:** recibe las peticiones HTTP, **delega** en el Service y decide el código de respuesta. **No tiene lógica de negocio.**

| Parte | Qué hace |
|---|---|
| `@RestController` | Atiende HTTP y convierte lo que devuelve a JSON. |
| `@RequestMapping("/api/v1/posts")` | Ruta base de todos los métodos. Prefijo `/api`, versión `/v1`, sustantivo en plural (apunte 14). |
| `@GetMapping` | Responde a `GET /api/v1/posts`. |
| `@GetMapping("/{id}")` | Responde a `GET /api/v1/posts/5`. |
| `@PathVariable Integer id` | Toma el número de la URL. |
| `ResponseEntity.ok(x)` | 200 con `x` en el cuerpo. |
| `ResponseEntity.notFound().build()` | 404 sin cuerpo. |

---

### 5.10 `GlobalExceptionHandler.java` (manejo de errores)

📁 `application/exceptions/GlobalExceptionHandler.java`

```java
package com.backend.restclient.application.exceptions;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.client.RestClientException;

import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(RestClientException.class)
    public ResponseEntity<Map<String, String>> handleRestClient(RestClientException e) {
        return ResponseEntity
                .status(HttpStatus.BAD_GATEWAY)
                .body(Map.of("error", "El servicio de posts no está disponible. Intente más tarde."));
    }
}
```

**Para qué sirve:** atrapa en **un solo lugar** las excepciones que se escapan de **cualquier** controller y las convierte en respuestas HTTP prolijas (apunte 17).

- `@RestControllerAdvice` → escucha las excepciones de toda la app.
- `@ExceptionHandler(RestClientException.class)` → este método se ejecuta para ese tipo de excepción.
- Devuelve **502 Bad Gateway**: el error no es nuestro, sino del servicio externo del que dependemos.

**¿Por qué no mostrar el detalle técnico?** Porque exponer errores internos es un riesgo de seguridad. El detalle queda en el log del servidor; al cliente le damos un mensaje claro.

**Ventaja:** el Controller y el Service no tienen un solo `try/catch`. La excepción sube sola hasta acá.

### ¿404 o 502?

| Situación | Responsable | Código |
|---|---|---|
| Piden un post que no existe | El cliente pidió algo inexistente | **404 Not Found** |
| JSONPlaceholder está caído o la URL está mal | El servicio externo | **502 Bad Gateway** |
| Nuestro código falla (bug) | Nosotros | **500 Internal Server Error** |

---

## 6. Qué pasa cuando llega una petición

### Al arrancar la app (una sola vez)

Spring crea los beans **de abajo hacia arriba**, porque cada uno necesita el anterior:

```
1. Lee application.properties
2. ClienteConfig           → crea el bean RestClient (con la URL de la propiedad)
3. JsonPlaceholderAdapter  → necesita un RestClient    → le pasa el del paso 2
4. PostService             → necesita un PostAdapter   → le pasa JsonPlaceholderAdapter
5. PostController          → necesita un PostService   → le pasa el del paso 4
6. Levanta Tomcat en el puerto 8080
```

Si uno falla, **fallan todos los que dependen de él** (efecto dominó) y la app no arranca.

### Cuando entrás a `GET /api/v1/posts`

```
Navegador ── GET /api/v1/posts ──► PostController.list()
                                        │
                                        ▼
                                   PostService.list()
                                        │
                                        ▼
                         PostAdapter.list()  (interfaz → JsonPlaceholderAdapter)
                                        │
            RestClient ── GET https://jsonplaceholder.typicode.com/posts ──► Internet
                                        │
                     JSON ──(Jackson)──► List<Post>  (100 posts, 4 campos)
                                        │
                     PostService: .map(PostResponse::of) → List<PostResponse> (2 campos)
                                        │
                     PostController: ResponseEntity.ok(...) → 200
                                        │
Navegador ◄──────── [ {"id":1,"title":"..."}, {"id":2,"title":"..."}, ... ]
```

---

## 7. Compilar, ejecutar y probar: qué tiene que aparecer en cada paso

Son **tres cosas distintas**, y cada una muestra algo diferente:

| Paso | Qué hace | Qué tiene que aparecer | ¿Muestra datos? |
|---|---|---|---|
| **Compilar** | Revisa que el código no tenga errores y genera los `.class` | `BUILD SUCCESS` | ❌ No |
| **Ejecutar** | Arranca Spring y el servidor Tomcat | `Started RestclientApplication` | ❌ No |
| **Probar** | Le hacés una petición desde el navegador o Postman | El JSON con los posts | ✅ Sí |

### 7.1 Compilar

**Cómo:** `Ctrl + F9` (Build → Build Project), o panel **Maven → Lifecycle → compile**.

**Qué hace:**
1. Lombok genera constructores, getters y logger.
2. Java convierte cada `.java` en `.class`.
3. Los deja en la carpeta `target/classes`.

**✅ Salida correcta (lo importante es la última parte):**

```
[INFO] Copying 1 resource from src\main\resources to target\classes
[INFO] Compiling 10 source files with javac [debug parameters release 21] to target\classes
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by lombok.permit.Permit
...
[INFO] BUILD SUCCESS
```

Cómo leerla:
- `Copying 1 resource` → copió `application.properties`.
- `Compiling N source files` → compiló tus clases. `parameters` es la opción que necesita Jackson.
- Los `WARNING: sun.misc.Unsafe...` son **avisos de Lombok, no errores**. Ignoralos.
- **`BUILD SUCCESS` = el código no tiene errores.** Es lo único que tenés que buscar.

**❌ Salida con error:**

```
[ERROR] /C:/.../PostController.java:[32,34] cannot find symbol
  symbol:   method findById(java.lang.Integer)
[INFO] BUILD FAILURE
```

Te dice **archivo**, **[línea, columna]** y **qué falta**.

> ⚠️ Compilar **no** levanta el servidor. Si solo compilaste, el navegador va a decir `ERR_CONNECTION_REFUSED`.

### 7.2 Ejecutar

**Cómo:** abrí `RestclientApplication` y tocá el **▶ verde** al lado de `main` → **Run**. Antes, frená cualquier ejecución anterior con el **■ rojo**.

**✅ Salida correcta:**

```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
...
 :: Spring Boot ::                (v4.1.1)

... Starting RestclientApplication using Java 21 ...
... Tomcat initialized with port 8080 (http)
... Tomcat started on port 8080 (http) with context path '/'
... Started RestclientApplication in 1.5 seconds
```

**Las dos líneas que importan:** `Tomcat started on port 8080` y `Started RestclientApplication`. La app queda **corriendo** (el ■ rojo sigue activo) esperando peticiones.

**❌ Salida con error:**

```
... APPLICATION FAILED TO START
...
Caused by: ... Could not resolve placeholder 'jsonplaceholder.api-url'
```

**Cómo leer un error de Spring:** buscá el **último `Caused by:`**. Esa es la causa real; todo lo de arriba son consecuencias.

### 7.3 Probar

Con la app corriendo, abrí el navegador:

| URL | Resultado esperado | Código |
|---|---|---|
| `http://localhost:8080/api/v1/posts` | `[{"id":1,"title":"sunt aut..."}, ... ]` (100 posts) | 200 |
| `http://localhost:8080/api/v1/posts/1` | `{"id":1,"title":"sunt aut facere..."}` | 200 |
| `http://localhost:8080/api/v1/posts/999` | *Whitelabel Error Page* o página vacía | 404 |

Para el 404, en la consola de IntelliJ tiene que aparecer:
```
WARN ... Post 999 no encontrado en JSONPlaceholder
```

**Probar el 502:** cambiá en `application.properties` la URL por `https://noexiste.typicode.com`, reiniciá y entrá a `/api/v1/posts`:
```json
{"error":"El servicio de posts no está disponible. Intente más tarde."}
```
La app **arranca igual**: el error recién aparece al llamar al endpoint, porque RestClient no se conecta a nada hasta que hace una petición. **Después volvé a poner la URL correcta.**

**Ver el código HTTP exacto:**
- Navegador: **F12 → pestaña Red (Network)** → recargá → columna *Estado*.
- Postman / Bruno: aparece arriba de la respuesta.
- Chrome: tildá **"Dar formato al texto"** para ver el JSON ordenado.

---

## 8. Errores que tuvimos y cómo se resolvieron

| Síntoma | Causa | Solución |
|---|---|---|
| `main` aparece en una sola línea y faltan números de línea | IntelliJ **pliega** el código (*code folding*). No es un error. | Clic en la flechita `>` o `Ctrl + Shift + +` |
| `pom.xml` con ícono `</>`, carpeta `java` gris, no se puede ejecutar | IntelliJ **no reconoció el proyecto como Maven** | Borrar la carpeta `.idea` y abrir con **File → Open → pom.xml → Open as Project**. O clic derecho en `pom.xml` → **Add as Maven Project** |
| Código en rojo, pero `BUILD SUCCESS` | IntelliJ no indexó las librerías | Panel Maven → **Reload All Maven Projects**. Si no alcanza: **File → Invalidate Caches** |
| Paquete `domian` | Error de tipeo | Clic derecho → **Refactor → Rename** (Shift + F6) → `domain` |
| `ERR_CONNECTION_REFUSED` en el navegador | La app **no está corriendo** (no se ejecutó o se cayó al arrancar) | Ejecutar con ▶ y revisar la consola |
| `Could not resolve placeholder 'jsonplaceholder.api-url'` | Falta la propiedad en `application.properties` o está mal escrita | Agregar `jsonplaceholder.api-url=https://jsonplaceholder.typicode.com` |
| `Cannot resolve method 'findById' in 'PostResponses'` | Se creó una clase de más (`PostResponses`) y el controller la usaba en lugar de `PostService` | Borrar `PostResponses` y usar `PostService` en el controller |
| `PostService` dentro de `responses` | Archivo en la carpeta equivocada; la línea `package` no coincide | Arrastrar a `application` → **Refactor** |
| `Port 8080 was already in use` | Ya hay otra app corriendo en ese puerto | Frenarla con ■ o agregar `server.port=8081` |
| `Cannot construct instance of Post` | Jackson no pudo armar el `Post` con Lombok | Pasar `Post` a `record` y usar `post.id()` y `post.title()` en `PostResponse` |
| `WARNING: sun.misc.Unsafe...` al compilar | Aviso interno de Lombok | Ignorar. No es un error. |

---

## 9. Consignas para practicar

Hacelas en orden. Cada una practica un concepto. Después de cada una: **compilar → ejecutar → probar**.

### Consigna 1 – Mostrar más datos (DTO)

Modificá `PostResponse` para que también devuelva el campo `body`.

- **Archivos a tocar:** solo `PostResponse`.
- **Probar:** `/api/v1/posts/1` tiene que mostrar `id`, `title` y `body`.
- **Concepto:** el DTO decide qué sale por la API. El Service y el Controller no cambian.

### Consigna 2 – Filtrar con query string

Agregá la posibilidad de filtrar por usuario: `GET /api/v1/posts?userId=1` devuelve solo los posts del usuario 1. Sin el parámetro, devuelve todos.

- **Pista:** en el controller usá `@RequestParam(required = false) Integer userId`. En el Service, si `userId` no es `null`, agregá un `.filter(...)` al stream **antes** del `.map(...)`.
- **Ojo:** `PostResponse` no tiene `userId`, así que tenés que filtrar sobre los `Post`, no sobre los `PostResponse`.
- **Probar:** `/api/v1/posts?userId=1` → 10 posts.
- **Concepto:** `@PathVariable` (dato obligatorio que identifica un recurso) vs `@RequestParam` (filtro opcional). La lógica de filtrar va en el **Service**.

### Consigna 3 – Contar posts

Agregá `GET /api/v1/posts/count` que devuelva `{"total": 100}`.

- **Pista:** devolvé un `Map.of("total", cantidad)` o creá un record `CountResponse(long total)`.
- **Ojo:** como existe `/{id}`, Spring tiene que distinguir `/count` de `/5`. Probá si funciona y pensá por qué.
- **Concepto:** reutilizar un método existente (`list()`) desde el Service.

### Consigna 4 – Un recurso nuevo completo: usuarios

Replicá toda la arquitectura para usuarios, consumiendo `https://jsonplaceholder.typicode.com/users`.

Endpoints: `GET /api/v1/users` y `GET /api/v1/users/{id}`, devolviendo solo `id`, `name` y `email`.

Archivos a crear:

| Capa | Archivo |
|---|---|
| domain/model | `User` |
| domain/adapters | `UserAdapter` (interfaz) |
| infrastructure/adapters | `JsonPlaceholderUserAdapter` |
| application/responses | `UserResponse` |
| application | `UserService` |
| application/controllers | `UserController` |

- **Pista:** el JSON de usuarios tiene campos anidados (`address`, `company`). Si no los ponés en `User`, Jackson los ignora.
- **Pregunta:** ¿tenés que crear otro `RestClient` o podés reutilizar el mismo? ¿Por qué?
- **Concepto:** repetir el patrón completo sin mirar. Si lo podés hacer solo, entendiste la arquitectura.

### Consigna 5 – Recurso anidado

Agregá `GET /api/v1/posts/{id}/comments`, que devuelva los comentarios de un post, consumiendo `https://jsonplaceholder.typicode.com/posts/{id}/comments`. Mostrá `id`, `name` y `email` de cada comentario.

- **Concepto:** URIs jerárquicas (apunte 14) y `ParameterizedTypeReference` para listas.

### Consigna 6 – Crear un post (POST)

Agregá `POST /api/v1/posts` que reciba `{"userId": 1, "title": "...", "body": "..."}` y lo envíe a JSONPlaceholder (`POST /posts`). Devolvé **201 Created** con el post que responda JSONPlaceholder (va a tener `id: 101`).

- **Pistas:**
  - Creá un record `CreatePostRequest(Integer userId, String title, String body)`.
  - En el controller: `@PostMapping` + `@RequestBody CreatePostRequest request`.
  - En el adapter: `restClient.post().uri("/posts").body(objeto).retrieve().body(Post.class)`.
  - Respondé con `ResponseEntity.status(HttpStatus.CREATED).body(...)`.
- **Probar:** con **Postman o Bruno**, porque el navegador solo hace GET.
- **Recordá:** JSONPlaceholder no guarda nada. Si después pedís `/posts/101`, no existe.
- **Concepto:** `@RequestBody`, verbo POST, código 201.

### Consigna 7 – Validaciones (apunte 17)

Al `CreatePostRequest` de la consigna 6, agregale validaciones: `title` y `body` obligatorios (`@NotBlank`) y `userId` obligatorio (`@NotNull`). Si no se cumplen, la API tiene que responder **400** con un JSON que diga qué campo falló.

- **Pistas:**
  - Agregá la dependencia `spring-boot-starter-validation` al `pom.xml` y recargá Maven. **Sin ella, las validaciones se ignoran.**
  - En el controller: `@Valid @RequestBody CreatePostRequest request`.
  - En `GlobalExceptionHandler`, agregá un `@ExceptionHandler(MethodArgumentNotValidException.class)` que arme un `Map` campo → mensaje (está en el apunte 17).
- **Probar:** POST con `{"userId": 1, "title": ""}` → 400 con `{"title": "...", "body": "..."}`.

### Consigna 8 – Log de todas las llamadas (interceptor)

Hacé que cada llamada a JSONPlaceholder se registre en la consola con método, URL, código de respuesta y tiempo en milisegundos.

- **Pista:** en `ClienteConfig`, agregá un `.requestInterceptor(...)` al builder (está en el apunte 18, sección "Extensiones").
- **Concepto:** lógica transversal aplicada en un único lugar.

---

## 10. Preguntas de repaso (con respuestas)

Intentá responderlas antes de leer la respuesta.

**1. ¿Qué diferencia hay entre compilar y ejecutar?**
> Compilar revisa el código y genera los `.class` (resultado: `BUILD SUCCESS`). Ejecutar arranca Spring y Tomcat para que la app atienda peticiones (resultado: `Started RestclientApplication`). Compilar no levanta el servidor.

**2. ¿Por qué `PostService` usa `PostAdapter` y no `JsonPlaceholderAdapter`?**
> Para depender de la interfaz y no de la implementación. Así se puede cambiar el origen de los datos (por ejemplo, a una base de datos) sin tocar el Service.

**3. ¿Por qué `ClienteConfig` usa `@Bean` y no `@Component`?**
> Porque `RestClient` no es una clase nuestra: no podemos anotarla. Con `@Bean` escribimos un método que la construye y Spring administra el resultado.

**4. Si borrás la propiedad `jsonplaceholder.api-url`, ¿qué pasa y cuándo?**
> La app no arranca. Spring no puede resolver el `@Value`, falla la creación del bean `restClient` y, en dominó, la de todos los que dependen de él.

**5. Si ponés una URL que no existe (pero la propiedad está), ¿qué pasa y cuándo?**
> La app arranca bien. El error recién aparece al llamar al endpoint, porque RestClient no se conecta hasta que hace una petición. El `GlobalExceptionHandler` responde 502.

**6. Si JSONPlaceholder agrega un campo nuevo (`"likes": 50`) y no lo agregás a `Post`, ¿se rompe?**
> No. Jackson ignora los campos del JSON que la clase no tiene.

**7. ¿Por qué hace falta `ParameterizedTypeReference` para la lista y no para un solo post?**
> Por el *type erasure*: Java borra la información de los genéricos al compilar, así que no existe `List<Post>.class`. Para un solo objeto alcanza con `Post.class`.

**8. ¿Por qué el orden de los `catch` en `findById` importa?**
> Porque `HttpClientErrorException.NotFound` es subclase de `RestClientException`. Si el general va primero, atrapa todo y el específico nunca se ejecuta. Java directamente no compila.

**9. ¿Cuándo corresponde 404 y cuándo 502?**
> 404 cuando el recurso pedido no existe. 502 cuando falla un servicio externo del que dependemos (actuamos como intermediario).

**10. ¿Qué ventaja tiene el `GlobalExceptionHandler` frente a poner `try/catch` en cada controller?**
> Centraliza el manejo de errores en un solo lugar, mantiene limpios el Controller y el Service, y asegura respuestas de error consistentes en toda la API.

**11. ¿Por qué `PostResponse` y no devolver directamente `Post`?**
> Para controlar qué datos salen por la API (ocultar `userId` y `body`) y desacoplar la API del modelo interno. Si el modelo cambia, la API no se rompe.

**12. ¿Qué hace `@SpringBootApplication` además de marcar la clase principal?**
> Activa la configuración automática y escanea el paquete `com.backend.restclient` y sus subpaquetes buscando componentes. Una clase fuera de ese paquete no se detecta.

---

## 11. Próximos pasos

Este ejercicio cubre los apuntes **14, 15, 17 y 18**. Para completar el recorrido faltan:

| Paso | Qué vamos a hacer | Apunte |
|---|---|---|
| **Spring Data** | Crear un segundo proyecto, `ms-posts`, que guarde posts en una base de datos con `JpaRepository`. | 16 |
| **Microservicios** | Hacer que este proyecto consuma `ms-posts` en vez de JSONPlaceholder, **cambiando solo la URL en `application.properties`**. | 18 |
| **API Gateway** | Crear un tercer proyecto con Spring Cloud Gateway como puerta única de entrada a los dos servicios. | 19 |

```
                      ┌──► restclient (8081) ──► ms-posts (8082) ──► Base de datos
Cliente ──► Gateway (8080)
                      └──► ms-posts (8082)
```
