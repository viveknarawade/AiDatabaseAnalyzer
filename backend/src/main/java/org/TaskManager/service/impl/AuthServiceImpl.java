package org.TaskManager.service.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.TaskManager.dto.*;
import org.TaskManager.entity.RefreshTokenEntity;
import org.TaskManager.entity.UserEntity;
import org.TaskManager.exception.*;
import org.TaskManager.repository.AuthRepo;
import org.TaskManager.repository.RefreshTokenRepo;
import org.TaskManager.service.AuthService;
import org.TaskManager.service.EmailService;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

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

        UserEntity user = authRepo
                .findByEmail(loginRequestDto.getEmail())
                .orElseThrow(() ->
                        new BadCredentialsException(
                                "Invalid email or password"
                        ));

        if (user.isDeleted()) {
            throw new AccountDeletedException(
                    "Account deleted"
            );
        }

        Authentication authentication =
                authManager.authenticate(
                        new UsernamePasswordAuthenticationToken(
                                loginRequestDto.getEmail(),
                                loginRequestDto.getPassword()
                        )
                );

        if (user.getEmailVerifiedAt() == null) {
            throw new EmailNotVerifiedException(
                    "Email not verified"
            );
        }

        String accessToken =
                jwtService.generateToken(
                        String.valueOf(user.getId())
                );

        String refreshTokenString =
                jwtService.generateRefreshToken(
                        String.valueOf(user.getId())
                );

        saveRefreshTokenToDB(user, refreshTokenString);

        UserDto userDto = mapper.map(user, UserDto.class);

        LoginResponseDto response =
                new LoginResponseDto();

        response.setAccessToken(accessToken);
        response.setRefreshToken(refreshTokenString);
        response.setUser(userDto);

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

    @Override
    public void delete(DeleteRequestDto deleteDto) {

        Authentication authentication =
                SecurityContextHolder.getContext().getAuthentication();

        UserEntity user =
                (UserEntity) authentication.getPrincipal();

        if (user.isDeleted()) {
            throw new AccountDeletedException("Account already deleted");
        }
        boolean isMatch =
                encoder.matches(
                        deleteDto.getPassword(),
                        user.getPasswordHash()
                );

        if (!isMatch) {
            throw new BadCredentialsException("Invalid password");
        }

        List<RefreshTokenEntity> allToken =
                refreshTokenRepo.findByUser(user);

        for (RefreshTokenEntity token : allToken) {
            token.setRevoked(true);
        }

        refreshTokenRepo.saveAll(allToken);

        user.setEmail(
                "deleted_" + user.getId() + "_" + user.getEmail()
        );

        user.setDeleted(true);
        user.setDeletedAt(Instant.now());
        user.setStatus("DELETED");
        user.setUpdatedAt(Instant.now());

        authRepo.save(user);
    }
}


