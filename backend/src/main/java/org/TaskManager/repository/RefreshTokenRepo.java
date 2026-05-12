package org.TaskManager.repository;

import org.TaskManager.entity.RefreshTokenEntity;
import org.TaskManager.entity.UserEntity;
import org.apache.catalina.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RefreshTokenRepo extends JpaRepository<RefreshTokenEntity,Long> {
     Optional<RefreshTokenEntity> findByToken(String refreshToken);

    List<RefreshTokenEntity> findByUser(UserEntity user);
}
