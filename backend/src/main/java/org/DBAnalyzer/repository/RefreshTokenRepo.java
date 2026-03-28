package org.DBAnalyzer.repository;

import org.DBAnalyzer.entity.RefreshTokenEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RefreshTokenRepo extends JpaRepository<RefreshTokenEntity,Long> {
     Optional<RefreshTokenEntity> findByToken(String refreshToken);
}
