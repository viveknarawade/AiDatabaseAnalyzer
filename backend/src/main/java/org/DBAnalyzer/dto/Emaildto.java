package org.DBAnalyzer.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Emaildto {

    @NotBlank(message = "recipient required")
    private String recipient;
    private String msgBody;
    private String subject;

}
