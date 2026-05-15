package org.TaskManager.service.impl;

import jakarta.persistence.EntityNotFoundException;
import org.TaskManager.dto.TaskRequestDto;
import org.TaskManager.dto.TaskResponseDto;
import org.TaskManager.dto.TaskUpdateRequestDto;
import org.TaskManager.dto.UserDto;
import org.TaskManager.entity.RefreshTokenEntity;
import org.TaskManager.entity.TaskEntity;
import org.TaskManager.entity.UserEntity;
import org.TaskManager.exception.AccountDeletedException;
import org.TaskManager.exception.AccountNotActiveException;
import org.TaskManager.repository.TaskRepo;
import org.TaskManager.service.TaskService;
import org.apache.coyote.BadRequestException;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.TaskManager.entity.TaskStatus.TODO;

@Service
public class TaskServiceImpl implements TaskService {

    @Autowired
    private TaskRepo taskRepo;
    @Autowired
    private ModelMapper mapper;


    public UserEntity authenticateUser(){
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        UserEntity user   = (UserEntity) authentication.getPrincipal();

        if (user.isDeleted()) {
            throw new AccountDeletedException("Account already deleted");
        }
        if(!user.getStatus().equals("ACTIVE")){
            throw new AccountNotActiveException("Account not active");
        }
        return  user;
    }
    @Override
    public TaskResponseDto createTask(TaskRequestDto taskDto) {
        UserEntity user = authenticateUser();
        TaskEntity newTask= mapper.map(taskDto, TaskEntity.class);
        if(taskDto.getStatus() ==null){
            newTask.setStatus(TODO);
        }
        newTask.setUser(user);
        newTask.setCreatedAt(Instant.now());
        newTask.setUpdatedAt(Instant.now());
        TaskEntity savedTask = taskRepo.save(newTask);
        TaskResponseDto responseDto = mapper.map(savedTask,TaskResponseDto.class);
        return responseDto;
    }

    @Override
    public List<TaskResponseDto> getTask() {

        UserEntity user = authenticateUser();

        List<TaskEntity> taskEntityList =
                taskRepo.findAllByUserUserIdAndIsDeletedFalse(user.getUserId());

        List<TaskResponseDto> responseList =
                taskEntityList.stream()
                        .map(task -> mapper.map(task, TaskResponseDto.class))
                        .toList();

        return responseList;
    }

    @Override
    public void deleteTaskById(Long taskId) throws BadRequestException {

        UserEntity user = authenticateUser();
        TaskEntity task = taskRepo.findById(taskId)
                .orElseThrow(() ->
                        new EntityNotFoundException("Task not found with id: " + taskId)
                );
        if (task.isDeleted()) {
            throw new BadRequestException("Task is already deleted");
        }
        if (!task.getUser().getUserId().equals(user.getUserId())) {
            throw new BadRequestException("You are not allowed to delete this task");
        }
        task.setDeleted(true);
        task.setDeletedAt(Instant.now());
        task.setUpdatedAt(Instant.now());
        taskRepo.save(task);
    }

    @Override
    public void updateTask(Long taskId, TaskUpdateRequestDto taskDto) throws BadRequestException {

        UserEntity user = authenticateUser();

        TaskEntity task = taskRepo.findById(taskId)
                .orElseThrow(() ->
                        new EntityNotFoundException("Task not found with id: " + taskId)
                );

        if (task.isDeleted()) {
            throw new BadRequestException("Task is already deleted");
        }

        if (!task.getUser().getUserId().equals(user.getUserId())) {
            throw new BadRequestException("You are not allowed to update this task");
        }


        if (taskDto.getTitle() != null) {
            task.setTitle(taskDto.getTitle());
        }

        if (taskDto.getDescription() != null) {
            task.setDescription(taskDto.getDescription());
        }

        if (taskDto.getStatus() != null) {
            task.setStatus(taskDto.getStatus());
        }

        if (taskDto.getPriority() != null) {
            task.setPriority(taskDto.getPriority());
        }

        if (taskDto.getDueDate() != null) {
            task.setDueDate(taskDto.getDueDate());
        }

        task.setUpdatedAt(Instant.now());

        taskRepo.save(task);
    }
}
