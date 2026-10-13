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