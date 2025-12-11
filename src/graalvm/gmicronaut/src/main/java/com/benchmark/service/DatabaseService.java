package com.benchmark.service;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import com.benchmark.repository.UserRepository;
import io.micronaut.context.annotation.Primary;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.List;
import java.util.Optional;

@Singleton
@Primary
public class DatabaseService {
    private final UserRepository userRepository;

    @Inject
    public DatabaseService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public Optional<User> getUserById(Integer id) {
        return userRepository.findByIdRaw(id);
    }

    public List<UserStats> getUserStats(Integer days) {
        return userRepository.findUserStats(days);
    }
}
