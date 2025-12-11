package com.benchmark.service;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import com.benchmark.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class DatabaseService {
    private final UserRepository userRepository;

    @Autowired
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
