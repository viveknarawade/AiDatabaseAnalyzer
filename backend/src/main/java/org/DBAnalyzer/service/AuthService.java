package org.DBAnalyzer.service;

import org.DBAnalyzer.dto.*;

public interface AuthService {


    public void signup(SignupRequestDto signupRequestDto);

    public LoginResponseDto verify(LoginRequestDto loginRequestDto);

    public void logout(LogoutRequestDto logoutDto);

    void verifyEmail(String token);

    void resendVerification(String email);
}
