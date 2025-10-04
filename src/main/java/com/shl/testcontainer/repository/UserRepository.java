package com.shl.testcontainer.repository;

import com.shl.testcontainer.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {}
