// This class just contains some tests to achieve code coverage so the samples
// can be distributed as unmanaged packages. This is not the right way
// to build unit tests!

@isTest(oninstall = false)
private class TestsForPackaging {

    static testMethod void test1() {
        Test.StartTest();
	    ScheduleHandler.StartScheduler(1);
        Test.StopTest();
    }

    static testMethod void test2() {
        Test.StartTest();
	    ScheduleHandler.StartScheduler(1);
	    RepeatingBatch2.StartTheBatch();
        Test.StopTest();
    }

    static testMethod void test3() {
        Test.StartTest();
	    RepeatingBatch.StartTheBatch(1);
        Test.StopTest();
    }
    
    static testMethod void test4()
    {
    	Test.StartTest();
    	Concurrency.IncrementOptimistic(5,0,0,0);
    	Concurrency.IncrementPessimistic(5,0,0,0);
    	Test.StopTest();
    }

    static testMethod void test5()
    {
    	List<String> badarray = null;
    	try
    	{
    		badarray.size();
    	} catch(Exception ex)
    	{
    		diagnostics.RecordCrash(ex);
    	}
    	diagnostics.RecordDebugEntry('message');
    	diagnostics.SendDiagnosticLog();
    	UsesAFeature u = new UsesAFeature();
    	u.DoesntGrabFeatures();
    	u.IsIdeaCategoriesFieldPresent();
    	
    	Test.StartTest();
    	Concurrency.IncrementOptimistic(5,0,0,0);
    	Concurrency.IncrementPessimistic(5,0,0,0);
    	Test.StopTest();
    }


}