package org.DBAnalyzer.service;

import org.DBAnalyzer.dto.SignupRequestDTO;
import org.DBAnalyzer.dto.UserDTO;

public interface UserService {


    public UserDTO registerUser(SignupRequestDTO signupRequestDTO);
}
