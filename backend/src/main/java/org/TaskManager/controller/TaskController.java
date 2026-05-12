package org.TaskManager.controller;


import jakarta.validation.Valid;
import org.TaskManager.dto.TaskRequestDto;
import org.TaskManager.dto.TaskResponseDto;
import org.TaskManager.payload.ApiResponse;
import org.TaskManager.service.TaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

@RequestMapping("/api/v1/task")
@RestController
public class TaskController {

    @Autowired
    private TaskService taskService;

    @PostMapping("/create")
    public ResponseEntity<ApiResponse<TaskResponseDto>> createTask(@Valid @RequestBody TaskRequestDto taskDto){

        TaskResponseDto data = taskService.createTask(taskDto);
        ApiResponse<TaskResponseDto> response = new ApiResponse<>(
                true,
                "Task created successful",
                200,
                Instant.now(),
                data
        );
        return ResponseEntity.ok(response);
    }

    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<TaskResponseDto>>> getTasks(){

        List<TaskResponseDto> data = taskService.getTask();
        ApiResponse<List<TaskResponseDto>> response = new ApiResponse<>(
                true,
                "Task created successful",
                200,
                Instant.now(),
                data
        );
        return ResponseEntity.ok(response);
    }

}
