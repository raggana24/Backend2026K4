package com.backend.restclient.domain.adapters;

import com.backend.restclient.domain.model.Post;

import java.util.List;
import java.util.Optional;

public interface PostAdapter {

    List<Post> list();

    Optional<Post> findById(Integer id);
}
