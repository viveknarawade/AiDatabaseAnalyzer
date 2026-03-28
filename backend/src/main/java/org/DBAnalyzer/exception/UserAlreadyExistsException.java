package org.DBAnalyzer.exception;

public class UserAlreadyExistsException extends RuntimeException{
    public UserAlreadyExistsException(String msg){
        super(msg);
        System.out.println("IN UserAlreadyExistsException  ");
    }
}
