global class ContractRenewalBatchSchedule implements schedulable
{
    global void execute(SchedulableContext sc)
    {
        ContractRenewalBatchProcess b = new ContractRenewalBatchProcess(); 
      database.executebatch(b);
    }
    /*
        ContractRenewalBatchSchedule b = new ContractRenewalBatchSchedule();
            String sch = '0 0 0 * * ?';
        system.schedule('Midnight Contract Renewal Batch Job', sch, b);
    */
}