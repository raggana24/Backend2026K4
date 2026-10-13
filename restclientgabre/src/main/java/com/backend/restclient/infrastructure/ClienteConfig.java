package com.backend.restclient.infrastructure;


import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class ClienteConfig {

    @Bean
    public RestClient restClient(@Value("${jsonplaceholder.api-url}") String apiUrl){
        return RestClient.builder()
                .baseUrl(apiUrl)
                .build();
    }

}
