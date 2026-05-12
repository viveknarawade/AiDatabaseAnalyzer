package org.TaskManager.service.impl;

import org.TaskManager.dto.TaskRequestDto;
import org.TaskManager.dto.TaskResponseDto;
import org.TaskManager.entity.TaskEntity;
import org.TaskManager.entity.UserEntity;
import org.TaskManager.exception.AccountDeletedException;
import org.TaskManager.exception.AccountNotActiveException;
import org.TaskManager.repository.TaskRepo;
import org.TaskManager.service.TaskService;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

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
                taskRepo.findAllByUserUserId(user.getUserId());

        List<TaskResponseDto> responseList =
                taskEntityList.stream()
                        .map(task -> mapper.map(task, TaskResponseDto.class))
                        .toList();

        return responseList;
    }


}
