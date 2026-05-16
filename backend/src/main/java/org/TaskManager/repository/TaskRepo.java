package org.TaskManager.repository;

import org.TaskManager.entity.TaskEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TaskRepo extends JpaRepository<TaskEntity, Long> {

   Page<TaskEntity> findAllByUserUserIdAndIsDeletedFalse(
           Long userId,
           Pageable pageable
   );
}