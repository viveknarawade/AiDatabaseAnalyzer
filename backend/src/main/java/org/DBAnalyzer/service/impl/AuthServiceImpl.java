package org.DBAnalyzer.service.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.DBAnalyzer.dto.*;
import org.DBAnalyzer.entity.RefreshTokenEntity;
import org.DBAnalyzer.entity.UserEntity;
import org.DBAnalyzer.exception.*;
import org.DBAnalyzer.repository.AuthRepo;
import org.DBAnalyzer.repository.RefreshTokenRepo;
import org.DBAnalyzer.service.AuthService;
import org.DBAnalyzer.service.EmailService;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthServiceImpl implements AuthService {

    @Autowired
    private JwtService jwtService;

    @Autowired
    AuthenticationManager authManager;

    @Autowired
    private AuthRepo authRepo;

    @Autowired
    private RefreshTokenRepo refreshTokenRepo;

    @Autowired
    private final PasswordEncoder encoder;

    @Autowired
    private ModelMapper mapper;

    @Autowired
    private EmailService emailService;

    @Override

    public void signup(SignupRequestDto signupRequestDto) {
        try {
            String encodedPassword = encoder.encode(signupRequestDto.getPassword());
            UserEntity newUser = mapper.map(signupRequestDto, UserEntity.class);
            newUser.setPasswordHash(encodedPassword);
            newUser.setStatus("PENDING");
            newUser.setEmailVerifiedAt(null);
            newUser.setCreatedAt(Instant.now());
            newUser.setUpdatedAt(Instant.now());
            UserEntity savedUser = authRepo.save(newUser);

            log.info("Before sending email");
            String token = jwtService.generateEmailVerificationToken(savedUser.getEmail());
            emailService.sendVerificationEmail(savedUser.getEmail(), token);
            log.info("After sending email");

        } catch (DataIntegrityViolationException ex) {
            throw new UserAlreadyExistsException("Email already exists");
        }
    }
    public LoginResponseDto verify(LoginRequestDto loginRequestDto) {


        //Authenticate (email + password)
        Authentication authentication = authManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        loginRequestDto.getEmail(),
                        loginRequestDto.getPassword()
                )
        );

        //fetch user from DB
        UserEntity user = authRepo.findByEmail(loginRequestDto.getEmail())
                .orElseThrow(()->new UsernameNotFoundException("User not found"));


        // EMAIL VERIFIED
        if (user.getEmailVerifiedAt() == null) {
            throw new EmailNotVerifiedException("Email not verified");
        }

        String accessToken = jwtService.generateToken(user.getEmail());
        String refreshTokenString = jwtService.generateRefreshToken(user.getEmail());

        saveRefreshTokenToDB(user,refreshTokenString);
        UserDto userDto = mapper.map(user, UserDto.class);

        LoginResponseDto response = new LoginResponseDto();
        response.setAccessToken(accessToken);
        response.setRefreshToken(refreshTokenString);
        response.setUser(userDto);

        log.info("Auth Service : Login successful with user {}", userDto.getFullName());
        return response;
    }

    @Override
    public void verifyEmail(String token) {

        String email = jwtService.extractEmail(token);

        UserEntity user = authRepo.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        if (user.getEmailVerifiedAt() != null) {
            throw new EmailAlreadyVerifiedException("Email already verified");
        }

        user.setEmailVerifiedAt(Instant.now());
        user.setStatus("ACTIVE");

        authRepo.save(user);
    }
    @Override
    public void resendVerification(String email) {

        log.info("in resendVerification varification email :{}",email);

        UserEntity user = authRepo.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        if (user.getEmailVerifiedAt() != null) {
            throw new EmailAlreadyVerifiedException("Already verified");
        }

        String token = jwtService.generateEmailVerificationToken(email);
        emailService.sendVerificationEmail(email, token);
    }

    public void logout(LogoutRequestDto logoutDto) {

            RefreshTokenEntity token = refreshTokenRepo.findByToken(logoutDto.getRefreshToken()).orElseThrow(
                    ()-> new TokenNotFoundException("Invalid Refresh Token")
            );

            if (token.isRevoked()) {
                throw new TokenAlreadyRevokedException("Token already revoked");
            }

            if (token.getExpiresAt().isBefore(Instant.now())) {
                throw new TokenExpiredException("Refresh token expired");
            }

            token.setRevoked(true);
            refreshTokenRepo.save(token);
        }

    public void saveRefreshTokenToDB(UserEntity user,String refreshTokenString){
        RefreshTokenEntity refreshTokenEntity = new RefreshTokenEntity();
        refreshTokenEntity.setUser(user);
        refreshTokenEntity.setToken(refreshTokenString);
        refreshTokenEntity.setExpiresAt(Instant.now().plus(java.time.Duration.ofDays(7)));
        refreshTokenRepo.save(refreshTokenEntity);

    }
}