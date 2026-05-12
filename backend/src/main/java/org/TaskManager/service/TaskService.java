package org.TaskManager.service;

import org.TaskManager.dto.TaskRequestDto;
import org.TaskManager.dto.TaskResponseDto;
import org.springframework.stereotype.Service;

@Service
public interface TaskService {
    public TaskResponseDto addTask(TaskRequestDto taskRequestDto);
}
