public class SpringCMTriggerHandler {
    public static List<SObject> acc;

	public static void StartWorkflow(String session, String type, List <SObject> listfromtrigger, String workflow) {
		acc = new List<SObject>();
	    for(SObject a : listfromtrigger) {
	    	// HERE you would test your object(s) for inclusion to workflow
	        acc.add(a);
	    }
	    SpringCMRestHelper.StartWorkflow(acc, type, workflow, session);
	}
}