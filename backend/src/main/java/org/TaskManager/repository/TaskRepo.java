package org.TaskManager.repository;

import org.TaskManager.entity.TaskEntity;
import org.TaskManager.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;


@Repository
public interface TaskRepo extends JpaRepository<TaskEntity,Long> {
   List<TaskEntity> findAllByUserUserIdAndIsDeletedFalse(Long userId);
}
