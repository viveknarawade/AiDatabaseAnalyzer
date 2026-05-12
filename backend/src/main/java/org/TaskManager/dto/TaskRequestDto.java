package org.TaskManager.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.TaskManager.entity.TaskPriority;
import org.TaskManager.entity.TaskStatus;

import java.time.Instant;

@Getter
@Setter
public class TaskRequestDto {

    @NotBlank(message = "Title is required")
    private String title;

    @NotBlank(message = "Description is required")
    private String description;

    private TaskStatus status;

    @NotNull(message = "Priority is required")
    private TaskPriority priority;

    @NotNull(message = "Due date is required")
    @Future(message = "Due date must be future date")
    private Instant dueDate;

}