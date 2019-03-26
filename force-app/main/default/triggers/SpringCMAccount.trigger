trigger SpringCMAccount on Account (after insert) {
	if (Test.isRunningTest()) return;
	String workflow = '';
    SpringCMTriggerHandler.StartWorkflow(UserInfo.getSessionId(), Trigger.new.get(0).getSObjectType().getDescribe().getName(), Trigger.new, workflow);
}