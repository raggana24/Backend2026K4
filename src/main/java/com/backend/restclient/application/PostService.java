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