package org.TaskManager.dto;


import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Getter
@Setter
@Valid
public class TaskRequestDto {


    private Long id;
    private String title;
    private  String description;
    private  String status;
    private String priority;
    private Instant dueDate;

    private Instant createdAt;
    private  Instant updatedAt;
    private  Long userId;


}
