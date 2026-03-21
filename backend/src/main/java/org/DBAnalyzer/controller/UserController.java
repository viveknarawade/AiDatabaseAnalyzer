package org.DBAnalyzer.controller;

import jakarta.validation.Valid;
import org.DBAnalyzer.dto.SignupRequestDTO;
import org.DBAnalyzer.dto.UserDTO;
import org.DBAnalyzer.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

@RequestMapping("/api/v1/auth")
@Controller
public class UserController {


    @Autowired
    private UserService userService;

    @PostMapping("/signup")
    public ResponseEntity<UserDTO> signup(@Valid @RequestBody  SignupRequestDTO signupRequestDTO){
        userService.registerUser(signupRequestDTO);
    }

}
