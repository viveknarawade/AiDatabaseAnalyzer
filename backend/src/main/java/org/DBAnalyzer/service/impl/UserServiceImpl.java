package org.DBAnalyzer.service.impl;

import jakarta.validation.Valid;
import org.DBAnalyzer.dto.SignupRequestDTO;
import org.DBAnalyzer.dto.UserDTO;
import org.DBAnalyzer.repository.UserRepo;
import org.DBAnalyzer.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;

public class UserServiceImpl implements UserService {

    @Autowired
    private UserRepo userRepo;

    @Override
    public UserDTO registerUser(SignupRequestDTO  signupRequestDTO) {


    
        userRepo.save(signupRequestDTO.getEmail(),signupRequestDTO.getPassword())
        return null;
    }
}
