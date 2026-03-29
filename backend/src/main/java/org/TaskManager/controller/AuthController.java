package org.TaskManager.controller;

import jakarta.validation.Valid;
import org.TaskManager.dto.*;
import org.TaskManager.payload.ApiResponse;
import org.TaskManager.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

@RequestMapping("/api/v1/auth")
@RestController
public class AuthController {



    @Autowired
    private AuthService authService;

    @PostMapping("/signup")
    public ResponseEntity<ApiResponse<Void>> signup(
            @Valid @RequestBody SignupRequestDto signupRequestDto) {

        authService.signup(signupRequestDto);

        ApiResponse<Void> response = new ApiResponse<>(
                true,
                "Registration successful. Please verify your email.",
                HttpStatus.CREATED.value(),
                Instant.now(),
                null
        );

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponseDto>> login(@Valid @RequestBody LoginRequestDto loginDto) {

        LoginResponseDto data = authService.verify(loginDto);

        ApiResponse<LoginResponseDto> response = new ApiResponse<>(
                true,
                "Login successful",
                200,
                Instant.now(),
                data
        );

        return ResponseEntity.ok(response);
    }


    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>>  logout(@Valid @RequestBody LogoutRequestDto logoutDto){

        authService.logout(logoutDto);
        ApiResponse<Void>  response = new ApiResponse<>(
                true,
                "Logged out successfully",
                200,
                Instant.now(),
                null
      );

        return  ResponseEntity.ok(response);
    }


    @GetMapping("/verify-email")
    public ResponseEntity<ApiResponse<String>> verifyEmail(@RequestParam String token) {

        authService.verifyEmail(token);

        ApiResponse<String> response = new ApiResponse<>(
                true,
                "Email verified successfully",
                200,
                Instant.now(),
                null
        );

        return ResponseEntity.ok(response);
    }

    @PostMapping("/resend-verification")
    public ResponseEntity<ApiResponse<String>> resend(@Valid @RequestBody ResendVerificationRequest request) {

        authService.resendVerification(request.getEmail());

        return ResponseEntity.ok(
                new ApiResponse<>(true, "Verification email sent", 200, Instant.now(), null)
        );
    }

}
