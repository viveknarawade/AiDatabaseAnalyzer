package org.DBAnalyzer.repository;

import org.DBAnalyzer.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AuthRepo extends JpaRepository<UserEntity,Long> {


    Optional<UserEntity> findByEmail(String email);
}
