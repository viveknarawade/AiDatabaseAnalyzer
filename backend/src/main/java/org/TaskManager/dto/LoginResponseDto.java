package org.TaskManager.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LoginResponseDto {


    private String accessToken;
    private String refreshToken;
    private UserDto user;

}
