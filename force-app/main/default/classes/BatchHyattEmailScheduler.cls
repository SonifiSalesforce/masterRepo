global class BatchHyattEmailScheduler implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
    	BatchHyattEmailSchedule b = New BatchHyattEmailSchedule();
     	String cronstrhour = '0 0 * * * ?';
    	String cronstrhalfpast = '0 30 * * * ?';
    	system.schedule('Batch Hyatt Emails Hour', cronstrhour, b);
    	system.schedule('Batch Hyatt Emails Halfpast', cronstrhalfpast, b);
    	
    }
    
}