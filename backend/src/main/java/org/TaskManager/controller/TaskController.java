package org.TaskManager.controller;


import jakarta.validation.Valid;
import org.TaskManager.dto.PageResponse;
import org.TaskManager.dto.TaskRequestDto;
import org.TaskManager.dto.TaskResponseDto;
import org.TaskManager.dto.TaskUpdateRequestDto;
import org.TaskManager.payload.ApiResponse;
import org.TaskManager.service.TaskService;
import org.apache.coyote.BadRequestException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;

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

    @GetMapping("/page")
    public ResponseEntity<ApiResponse<PageResponse<TaskResponseDto>>> getTasks(
            @RequestParam int page,
            @RequestParam int size
    ) {

        PageResponse<TaskResponseDto> data =
                taskService.getTask(page, size);

        ApiResponse<PageResponse<TaskResponseDto>> response =
                new ApiResponse<>(
                        true,
                        "Task fetch successfully",
                        200,
                        Instant.now(),
                        data
                );

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{taskId}")
    public ResponseEntity<ApiResponse<Object>> deleteTask(@PathVariable Long taskId) throws BadRequestException {
        taskService.deleteTaskById(taskId);
        ApiResponse<Object> response = new ApiResponse<>(
                true,
                "Task deleted successfully",
                200,
                Instant.now(),
                null
        );
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{taskId}")
    public  ResponseEntity<ApiResponse<Object>> updateTask(@Valid @PathVariable Long taskId, @RequestBody TaskUpdateRequestDto taskDto) throws BadRequestException {
        taskService.updateTask(taskId,taskDto);

        ApiResponse<Object> response = new ApiResponse<>(
                true,
                "Task updated successfully",
                200,
                Instant.now(),
                null
        );
        return ResponseEntity.ok(response);
    }

}
