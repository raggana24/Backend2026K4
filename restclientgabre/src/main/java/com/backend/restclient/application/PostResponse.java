package com.backend.restclient.application;


import com.backend.restclient.domain.adapters.PostAdapter;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor

public class PostResponse {

    PostAdapter postAdapter;

    public List<com.backend.restclient.application.responses.PostResponse> list(){
        return postAdapter.list()          // List<Post>      → los 100 posts del adaptador
                .stream()           // Stream<Post>    → los pongo "en una cinta"
                .map(com.backend.restclient.application.responses.PostResponse::of) // Stream<PostResponse> → convierto cada uno
                .toList();          // List<PostResponse> → los vuelvo a juntar en una lista
    }

}
