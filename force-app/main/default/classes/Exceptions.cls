/**
 * Acts as the container class for all exceptions in events app
 */
@isTest
public with sharing class Exceptions {
    private Exceptions() { /* Cannot instantiate Service/Utility class */ }
    
    /**
     * Mirrors java.lang.UnsupportedOperationException, should be used
     * for similar purposes in events app.
     */
    public class UnsupportedOperationException extends Exception {
    }

    /**
     * Mirrors java.lang.IllegalArgumentException, should be used
     * for similar purposes in events app.
     */
    public class IllegalArgumentException extends Exception {

    }

    /**
     * Mirrors java.lang.IllegalStateException, should be used
     * for similar purposes in events app.
     */
    public class IllegalStateException extends Exception {

    }

    /**
     * General app exception in Events app
     */
    public class AppException extends Exception {

    }

    /**
     * General app exception in Events app which does not contain any debuggable
     * info and therefore should not be logged.  Use it in services where you have
     * already logged the useful info and you need to throw a different exception
     * just to indicate to the caller (controller) that the operation failed.
     */
    public class NoDebugAppException extends Exception {

    }
    
    public class UnsupportedObjectTypeException extends Exception {
        
    }
    
    public class UnknownObjectException extends Exception {
    	
    }
    
    public class UnauthorizedException extends Exception {
        
    }
    
    public class LoggerException extends Exception {
    
    }
}