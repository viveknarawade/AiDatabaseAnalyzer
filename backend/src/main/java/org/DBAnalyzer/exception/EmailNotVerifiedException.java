package org.DBAnalyzer.exception;

public class EmailNotVerifiedException extends  RuntimeException{

    public EmailNotVerifiedException(String msg){
        super(msg);
    }
}
