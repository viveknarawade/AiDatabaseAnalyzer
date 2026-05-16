package org.TaskManager.service;

import jakarta.validation.Valid;
import org.TaskManager.dto.PageResponse;
import org.TaskManager.dto.TaskRequestDto;
import org.TaskManager.dto.TaskResponseDto;
import org.TaskManager.dto.TaskUpdateRequestDto;
import org.apache.coyote.BadRequestException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public interface TaskService {
    public TaskResponseDto createTask(TaskRequestDto taskRequestDto);

    PageResponse<TaskResponseDto> getTask(int page, int size);

    void deleteTaskById(Long taskId) throws BadRequestException;

    void updateTask(Long taskId,TaskUpdateRequestDto taskDto) throws BadRequestException;
}
