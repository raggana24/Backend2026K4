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