package org.DBAnalyzer.service;

import org.DBAnalyzer.dto.Emaildto;
import org.springframework.stereotype.Service;


public interface EmailService {

    public void sendVerificationEmail(String toEmail, String token);

}
