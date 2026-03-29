package org.TaskManager.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Getter
@Setter
public class UserDto {
    private Long id;
    private String email;
    private String fullName;
    private String status;
    private Instant createdAt;
}