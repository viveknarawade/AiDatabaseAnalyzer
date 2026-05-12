package org.TaskManager.controller;


import jakarta.validation.Valid;
import org.TaskManager.dto.LoginRequestDto;
import org.TaskManager.dto.LoginResponseDto;
import org.TaskManager.dto.TaskRequestDto;
import org.TaskManager.dto.TaskResponseDto;
import org.TaskManager.exception.ApiError;
import org.TaskManager.payload.ApiResponse;
import org.TaskManager.service.AuthService;
import org.TaskManager.service.TaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;

@RequestMapping("/api/v1/task")
@RestController
public class TaskController {

    @Autowired
    private TaskService taskService;

    @PostMapping("/add")
    public ResponseEntity<ApiResponse<TaskResponseDto>> addTask(@Valid @RequestBody TaskRequestDto taskDto){

        TaskResponseDto data = taskService.addTask(taskDto);


        ApiResponse<TaskResponseDto> response = new ApiResponse<>(
                true,
                "Task added successful",
                200,
                Instant.now(),
                data
        );

        return ResponseEntity.ok(response);
    }
}
