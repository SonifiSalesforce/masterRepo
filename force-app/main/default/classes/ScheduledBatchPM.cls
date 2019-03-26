/* Filename: ScheduledBatchPM.cls
 * Purpose: Scheduler for BatchPM
 * Author:  Etherios for Sonifi
 *
 * Copyright 2013 by Author, all rights reserved
 *
 * History
 * -----------------------------------------------------------------------------
 * 2013-09-03 Nicholas G. Koopman Jr. Created
*/

global class ScheduledBatchPM implements Schedulable {
    global void execute(SchedulableContext context) {                    
        BatchPM batchProcess = new BatchPM();
        Database.executeBatch(batchProcess);                    
    }
}