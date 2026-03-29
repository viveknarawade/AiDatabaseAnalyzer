package org.TaskManager.exception;

public class TokenExpiredException extends RuntimeException{
    public TokenExpiredException(String msg){
        super(msg);
    }
}
