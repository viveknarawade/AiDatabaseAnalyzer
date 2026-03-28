package org.DBAnalyzer.exception;

public class TokenExpiredException extends RuntimeException{
    public TokenExpiredException(String msg){
        super(msg);
    }
}
