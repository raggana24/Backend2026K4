package com.backend.restclient.application.responses;

import com.backend.restclient.domain.model.Post;

public record PostResponse(Integer id, String title) {


    public static PostResponse of(Post post){
        return new PostResponse(
                post.getId(),
                post.getTitle()
        );

    }

}

