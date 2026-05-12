package org.TaskManager.service;

import jakarta.validation.Valid;
import org.TaskManager.dto.*;
import org.TaskManager.exception.AccountDeletedException;

public interface AuthService {


    public void signup(SignupRequestDto signupRequestDto);

    public LoginResponseDto verify(LoginRequestDto loginRequestDto);

    public void logout(LogoutRequestDto logoutDto);

    void verifyEmail(String token);

    void resendVerification(String email);

    void delete(@Valid DeleteRequestDto deleteDto) throws AccountDeletedException;
}
