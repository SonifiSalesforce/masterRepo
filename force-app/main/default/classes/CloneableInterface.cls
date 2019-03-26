// *********************************************************************************************
// Version:      0.0.1
// Author:       Etherios
// Date Created: 06/10/2013
// Description:  Interface class for identifying cloneable object functionalities.
//    
// Copyright 2013 Etherios All rights reserved. Customer confidential. Do not distribute.
// *********************************************************************************************
// *********************************************************************************************

public interface CloneableInterface {

    /* Returns the interface object itself  */
	CloneableInterface getCloneableInterface();
	
    /* Returns the parent SObject */
	SObject getParentObject();

    /* Returns a list of objects that can be parents of the cloned activities. */
	List<SObject> getCloneToItems();
	
	/* Returns a field map for cloning records */
	Map<Schema.SObjectType, Map<Schema.SObjectType, Map<Schema.SObjectField, Schema.SObjectField>>> getItemObjectFieldMap();
	
	/* Id for affecting actions (Not necessarily Owner or Contact objects) */
	Id getWhoId();
}