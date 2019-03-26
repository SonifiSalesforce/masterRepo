public with sharing class SupportOfficeMemberTriggerLogic {
	
	public static final String MESSAGE_PRIMARY_ENGINEER_IN_USE = 'You cannot remove the Primary Engineer for a Support Office that has dispatched cases.';
	
	/**
	 * Checks for active dispatched cases for the passed support office members.
	 * Returns the support office members who are still the owner for active dispatched cases.  
	 */
	public static void validateMemberRemoval(Map<Id, SupportOfficeMember__c> memberMap) {
		
		// Check for members to update
		if (memberMap == null || memberMap.isEmpty()) { return; }
		
		// Get support office to team members map
		Map<Id, List<SupportOfficeMember__c>> supportTeamMemberMap = getSupportTeamMemberMap(memberMap.values());
		
		// Get support office to cases map
		Map<Id, List<Case>> caseTeamMap = CustomCaseLogic.getCaseTeamMap(new List<Id> (supportTeamMemberMap.keyset()));
		if (caseTeamMap == null || caseTeamMap.isEmpty()) { return; }
		
		// Iterate over support offices for dispatched cases
    	for (Id officeId : caseTeamMap.keyset()) {
    		
			// Get team members for this support office
			List<SupportOfficeMember__c> teamMembers = supportTeamMemberMap.get(officeId);
			
			// Find the Primary Engineer for this support office
			// NOTE If the primary engineer is in the list then it is being removed.
			// If the Case is in the list (above), then it is active and dispatched.
			// The combination of these 2 truths is an error state.
			for (SupportOfficeMember__c member : teamMembers) {
				if (member.Role__c == Definitions.SUPPORTMEMBER_PRIMARY_ENGINEER) {
					member.addError(MESSAGE_PRIMARY_ENGINEER_IN_USE);
					break;
				}
			}
		}
	}
	
	/**
	 * Affects related records with member changes
	 */
	public static void processMemberUpdate(Map<Id, SupportOfficeMember__c> memberMap, Boolean deleteDuplicates) {
		
		// Check for members to update
		if (memberMap == null || memberMap.isEmpty()) { return; }
		
		Savepoint sp = Database.setSavepoint();
		try {
			updateMemberCases(memberMap);
			if (deleteDuplicates) { deleteDuplicateRoles(memberMap); }
		} catch (Exception e) {
			Database.rollback(sp);
			throw e;
		}
	}
	
	/**
	 * Update cases associated with the updated members
	 */
	public static void updateMemberCases(Map<Id, SupportOfficeMember__c> memberMap) {
		
		// Check for members to update
		if (memberMap == null || memberMap.isEmpty()) { return; }
		
		// Build support office to team member map
		Map<Id, List<SupportOfficeMember__c>> supportTeamMemberMap = getSupportTeamMemberMap(memberMap.values());
		
		// Get case team map
		Map<Id, List<Case>> caseTeamMap = CustomCaseLogic.getCaseTeamMap(new List<Id> (supportTeamMemberMap.keyset()));
		if (caseTeamMap == null || caseTeamMap.isEmpty()) { return; }
		
		// Update case support team
		CustomCaseLogic.updateCaseSupportTeam(caseTeamMap, supportTeamMemberMap, true);
	}
	
	/**
	 * Delete member roles that are duplicates of the role that was just updated
	 */
	public static void deleteDuplicateRoles(Map<Id, SupportOfficeMember__c> memberMap) {
		
		if (memberMap == null || memberMap.isEmpty()) { return; }
		
		// Create map of affected support offices
		Map<Id, Map<String, SupportOfficeMember__c>> officeMemberRoleMap = new Map<Id, Map<String, SupportOfficeMember__c>>();
		for (SupportOfficeMember__c member : memberMap.values()) {
			if (officeMemberRoleMap.containsKey(member.SupportOffice__c)) {
				officeMemberRoleMap.get(member.SupportOffice__c).put(member.Role__c, member);
			} else {
				officeMemberRoleMap.put(member.SupportOffice__c, new Map<String, SupportOfficeMember__c>{ member.Role__c => member });
			}
		}
		
		// Get members from represented support offices
		Map<Id, Account> supportOfficeMap = new Map<Id, Account>([
			SELECT Id, (
				SELECT Id, User__c, Contact__c, Role__c, IsContact__c
				FROM SupportOfficeMembers__r
			)
			FROM Account
			WHERE Id IN :officeMemberRoleMap.keyset()
		]);
		
		// Iterate over support offices
		List<SupportOfficeMember__c> membersToDelete = new List<SupportOfficeMember__c>();
		for (Account office : supportOfficeMap.values()) {
			
			// Get members identified at this support office
			Map<String, SupportOfficeMember__c> memberRoleMap = officeMemberRoleMap.get(office.Id);
			
			// Iterate over existing support office members
			for (SupportOfficeMember__c member : office.SupportOfficeMembers__r) {
				
				// Check for matching member and role. 
				// If role is found without matching member it is a duplicate. Add it to the list.
				if (memberRoleMap.containsKey(member.Role__c)) {
					SupportOfficeMember__c newMember = memberRoleMap.get(member.Role__c);
					Id memberId = member.IsContact__c == true ? member.Contact__c : member.User__c;
					Id newMemberId = newMember.IsContact__c == true ? newMember.Contact__c : newMember.User__c;
					
					// Check if the User/Contact Id has changed OR if the ACTUAL SupportOfficeMember__c record Id has changed
					// NOTE This duplicated roles as well as identical duplicated members (occurs when data loading) 
					if (member.Id != newMember.Id || memberId != newMemberId) {
						membersToDelete.add(member);
					}
				}
			}
		}
		
		// Check for members to delete
		if (membersToDelete == null || membersToDelete.isEmpty()) { return; }

		// Delete replaced members
		delete membersToDelete;
	}
	
	/**
	 * Builds and returns a map of support offices to team members
	 */
	public static Map<Id, List<SupportOfficeMember__c>> getSupportTeamMemberMap(List<SupportOfficeMember__c> teamMembers) {
		
		// Build support office to team member map
		Map<Id, List<SupportOfficeMember__c>> supportTeamMemberMap = new Map<Id, List<SupportOfficeMember__c>>();
		for (SupportOfficeMember__c member : teamMembers) {
			if (supportTeamMemberMap.containsKey(member.SupportOffice__c)) {
				supportTeamMemberMap.get(member.SupportOffice__c).add(member);
			} else {
				supportTeamMemberMap.put(member.SupportOffice__c, new List<SupportOfficeMember__c> { member });
			}
		}
		
		return supportTeamMemberMap;
	}
}