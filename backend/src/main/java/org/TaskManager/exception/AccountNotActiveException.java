package org.TaskManager.exception;


public class AccountNotActiveException extends RuntimeException{
    public  AccountNotActiveException(String msg){
        super(msg);
    }
}
