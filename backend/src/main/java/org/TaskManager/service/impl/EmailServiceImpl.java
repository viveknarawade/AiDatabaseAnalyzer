package org.TaskManager.service.impl;

import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.TaskManager.service.EmailService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
@Service
@Slf4j
public class EmailServiceImpl implements EmailService {

    @Autowired
    private JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String sender;

    public void sendVerificationEmail(String toEmail, String token) {

        try {
            String link = "http://localhost:8081/api/v1/auth/verify-email?token=" + token;

            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true);

            helper.setFrom("AI Analyzer <" + sender + ">");
            helper.setTo(toEmail);
            helper.setSubject("Verify Your Account");

            String htmlContent = """
                    <div style="font-family: Arial, sans-serif; padding: 20px;">
                        <h2>Welcome to AI Analyzer 🚀</h2>
                        <p>Please verify your email by clicking the button below:</p>
                        
                        <a href="%s" target="_blank"
                               style="display:inline-block;
                                      padding:10px 20px;
                                      background-color:#4CAF50;
                                      color:white;
                                      text-decoration:none;
                                      border-radius:5px;">
                               Verify Email
                            </a>

                        <p style="margin-top:20px;">
                            If you didn't request this, ignore this email.
                        </p>
                    </div>
                    """.formatted(link);

            helper.setText(htmlContent, true); // true = HTML

            mailSender.send(message);

            log.info("Verification email sent to {}", toEmail);

        } catch (Exception e) {
            log.error("Failed to send email to {} : {}", toEmail, e.getMessage());
            throw new RuntimeException("Email sending failed");
        }
    }
}