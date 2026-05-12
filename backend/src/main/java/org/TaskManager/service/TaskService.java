package org.TaskManager.service;

import jakarta.validation.Valid;
import org.TaskManager.dto.TaskRequestDto;
import org.TaskManager.dto.TaskResponseDto;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public interface TaskService {
    public TaskResponseDto createTask(TaskRequestDto taskRequestDto);

    List<TaskResponseDto> getTask();
}
