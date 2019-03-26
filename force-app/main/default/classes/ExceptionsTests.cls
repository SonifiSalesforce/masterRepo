@isTest
private class ExceptionsTests {
	static void CustomMethod(Exception e)
	{
		throw e;
	}
	static testMethod void testUnsupportedOperationException() {
		Boolean passTest = false;
		try
		{
			CustomMethod(new Exceptions.UnsupportedOperationException());
		}
		catch (Exceptions.UnsupportedOperationException e)
		{
			passTest = true;
		}
		System.assert(passTest);
	}
	static testMethod void testIllegalArgumentException() {
		Boolean passTest = false;
		try
		{
			CustomMethod(new Exceptions.IllegalArgumentException());
		}
		catch (Exceptions.IllegalArgumentException e)
		{
			passTest = true;
		}
		System.assert(passTest);		
	}
	static testMethod void testIllegalStateException() {
		Boolean passTest = false;
		try
		{
			CustomMethod(new Exceptions.IllegalStateException());
		}
		catch (Exceptions.IllegalStateException e)
		{
			passTest = true;
		}
		System.assert(passTest);
	}
	static testMethod void testAppException() {
		Boolean passTest = false;
		try
		{
			CustomMethod(new Exceptions.AppException());
		}
		catch (Exceptions.AppException e)
		{
			passTest = true;
		}
		System.assert(passTest);
	}	
	static testMethod void testNoDebugAppException() {
		Boolean passTest = false;
		try
		{
			CustomMethod(new Exceptions.NoDebugAppException());
		}
		catch (Exceptions.NoDebugAppException e)
		{
			passTest = true;
		}
		System.assert(passTest);
	}		
}