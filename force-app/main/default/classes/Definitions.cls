// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 05/13/2013
// Description:  Provides a single source for managing global definitions 
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public with sharing class Definitions {
	
	public enum 							WEEKDAY								{ SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY }
	
	public static final String				RECORDTYPE_HealthcareLeads			= 'Healthcare Leads';
	public static final String				RECORDTYPE_HospitalityLeads			= 'Hospitality Leads'; 
	public static final String				RECORDTYPE_AccountThirdParty		= 'Third Party';
	public static final String				RECORDTYPE_AccountMOL				= 'MOL';
	public static final String				RECORDTYPE_AccountFlagBrand			= 'Flag/Brand';
	public static final String				RECORDTYPE_ContractRequest			= 'Contract Request';
	public static final String				RECORDTYPE_SupportOffice			= 'Support Office';
	public static final String				RECORDTYPE_Install					= 'Install';
	public static final String				RECORDTYPE_Hospitality_Site			= 'Hospitality Site';
	public static final String				RECORDTYPE_Healthcare_Site			= 'Healthcare Site';
	public static final String				RECORDTYPE_Order					= 'Order';
	public static final String				RECORDTYPE_Case_SupportCase			= 'Support Case';
	public static final String				RECORDTYPE_Case_SupportCaseClosed	= 'Support Case Closed'; 
	public static final String				RECORDTYPE_Task_SupportCase			= 'Support Case Task';
	public static final String				RECORDTYPE_Interactive_Preventative_Maintenance = 'Interactive Preventative Maintenance';
	//jjackson 4/2015 for BUG-00459
	public static final String				RECORDTYPE_Network_Engineering		= 'Network Engineering Case';

	public static final String 				PROFILE_SystemAdmin 				= 'System Administrator';
	public static final String 				PROFILE_HealthcareSales 			= 'Healthcare Sales';
	public static final String 				PROFILE_SalesUser 					= 'Sales User';
	
	public static final String 				VENDOR_TYPE_FTG						= 'FTG';
	public static final String 				VENDOR_TYPE_PPV						= 'PPV';
	public static final String 				VENDOR_TYPE_Broadband				= 'Broadband';
	public static final String 				VENDOR_TYPE_PatientEducation		= 'Patient Education';
	public static final String 				VENDOR_TYPE_PatientEntertainment	= 'Patient Entertainment';
	
	public static final String 				PARTNER_TYPE_Dietary				= 'Dietary Vendor';
	public static final String				PARTNER_TYPE_NurseCall				= 'Nurse Call Vendor';
	public static final String 				PARTNER_TYPE_EMR					= 'EMR Vendor';
	public static final String 				PARTNER_TYPE_HVAC					= 'HVAC';
	public static final String 				PARTNER_TYPE_Consultant				= 'Consultant';
	
	public static final String				OPPTY_STAGE_AssignedToRep			= 'Assigned to Rep';
	public static final String				OPPTY_STAGE_ProposalSent			= 'Proposal Sent';
	public static final String				OPPTY_STAGE_ClosedWon				= 'Closed Won';
	public static final String				OPPTY_STAGE_ClosedLost				= 'Closed Lost';
	
	public static final String				PRICEBOOK_Standard					= 'Standard Price Book';
	public static final String				PRICEBOOK_Hospitality				= 'Hospitality Price Book';
	
	public static final String				SUPPORTMEMBER_PRIMARY_ENGINEER		= 'Primary Engineer';
	
	public static final String				ORDER_STATUS_APPROVED				= 'Install Approved';
	public static final String				ORDER_STATUS_INSTALLED				= 'Install Complete';
	public static final String				ORDER_ITEM_STATUS_NEW				= 'Pending Installation Activate';
	public static final String				ORDER_ITEM_STATUS_COMPLETE			= 'Installed Activated';
	public static final String				ASSET_STATUS_PENDING_INSTALL		= 'Pending Installation Activate';
	public static final String				ASSET_STATUS_PENDING_DEINSTALL		= 'Pending De-Installation';
	public static final String				ASSET_STATUS_INSTALLED				= 'Installed Activated';
	public static final String				ASSET_STATUS_DEINSTALLED			= 'De-Installed';
	
	public static final String				CASE_STATUS_INCOMPLETE				= 'Closed - Incomplete';
	
	public static final String				DOWNLOAD_ATTACHMENT					= '/servlet/servlet.FileDownload/';
	public static final String 				PORTAL_NAME							= 'sonifipartners';
	
	
	//TT - edited June 27 for site survey
	/*public static final Set<String>			SITESURVEY_tv_type 					= new Set<String>{'digital_format__c', 'aspect_ratio__c', 'pro_idiom_compatible_type__c', 'pillow_brand__c', 'input_connector__c', 'type_of_tv_mount__c', 'built_in__c', 'length_coax_from_tv_to_wall__c', 'length_of_coax_mti_from_tv_to_terminal__c'};
	public static final Set<String>			SITESURVEY_tv_location				= new Set<String>{'requested_services_for_this_area__c'};
	public static final Set<String>			SITESURVEY_building 				= new Set<String>{'customer_room_ceiling_composition__c', 'hallway_ceiling_composition__c' };
	public static final Set<String>			SITESURVEY_site_survey 				= new Set<String>{'ftg_type__c', 'cable_signal_type__c', 'type_of_high_speed_internet_provider__c', 'downlead_size__c'};
	public static final Set<String>			SITESURVEY_cable_type 				= new Set<String>{'jacket__c', 'where_used__c', 'shielding__c', 'center_conductor__c', 'type__c'};
	public static final Set<String>			SITESURVEY_room_reading 			= new Set<String>{''};
	public static final Set<String>			SITESURVEY_passive_device 			= new Set<String>{'device__c'};
	public static final Set<String>			SITESURVEY_rack_location			= new Set<String>{'type_of_cooling_system_in_rack_room__c'};*/

    public static final Integer 			DST_OFFSET 							= 60; // in seconds
    
    /**
     * Reads and stores the DST start date from the custom setting 
     */
    public static DateTime DST_START_DATE {
    	get {
    		if (DST_START_DATE == null) {
    			try { DST_START_DATE = AppConfig__c.getValues('Global').DST_Start_Date__c; }
				catch (Exception e) {}
    		}
    		return DST_START_DATE;
    	}
    	private set;
    }
    
    /**
     * Reads and stores the DST end date from the custom setting 
     */
    public static DateTime DST_END_DATE {
    	get {
    		if (DST_END_DATE == null) {
    			try { DST_END_DATE = AppConfig__c.getValues('Global').DST_End_Date__c; }
    			catch (Exception e) {}
    		}
    		return DST_END_DATE;
    	}
    	private set;
    }
    
    /**
     * Uses the dst start and stop dates in the custom setting to determine whether 
     * the dst is currently in progress.
     * NOTE Checks every time to ensure changes during the same context are noticed
     */
    public static Boolean IS_DST {
    	get {
    		DateTime rightNow = DateTime.now();
    		if (DST_START_DATE == null || DST_END_DATE == null
    			|| rightNow < DST_START_DATE || rightNow > DST_END_DATE) {
    				return false;
			}
			return true;
    	}
    }
    
    testMethod static void testDefinitions(){
    	
    	AppConfig__c appConfig = new AppConfig__c();
    	appConfig.Name ='GLobal';
    	appConfig.DST_Start_Date__c = null;
    	appConfig.DST_End_Date__c = null;
    	upsert appConfig;
    	
    	Boolean isDst = Definitions.IS_DST;
    	System.assertEquals(false,isDst);
    	
    	DateTime startDate = Definitions.DST_START_DATE;
    	System.assertEquals(null,startDate);
    	
    	DateTime endDate = Definitions.DST_END_DATE;
    	System.assertEquals(null,endDate);
    }
}