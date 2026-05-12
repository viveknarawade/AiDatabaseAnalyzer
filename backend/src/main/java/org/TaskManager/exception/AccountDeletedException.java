package org.TaskManager.exception;

public class AccountDeletedException extends RuntimeException{
    public AccountDeletedException(String msg){
        super(msg);
    }
}
