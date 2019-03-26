global class InstallGradeBatchSchedule implements schedulable
{
    global void execute(SchedulableContext sc)
    {
        InstallGradeBatchProcess b = new InstallGradeBatchProcess(); 
      	database.executebatch(b);
    }
}