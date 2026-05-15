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
public class TaskUpdateRequestDto {

    private String title;
    private String description;
    private TaskStatus status;
    private TaskPriority priority;
    @Future(message = "Due date must be future date")
    private Instant dueDate;
}
