

window.CCSPIntegration = window.CCSPIntegration || {};

CCSPIntegration.ccsp = CCSPIntegration.ccsp || {};

CCSPIntegration.ccsp.callDataHelper = CCSPIntegration.ccsp.callDataHelper || {};


// In WebAgent callData.CallInfo and callData.StreamInfo are not sent except (CallInfo.OptPar) in order to reduce the packet size.
// WebAgent is in browser control which is IE7 and the size of the signalr message is limited to up to 1024.
//
// CallId
// CallIdHex
// CallerANI
// CallerMessage
// CallerName
// CallerURL
// Direction
// QueueName 
// MediaType
// OptionalParams|OptPar

(function(target) {
	'use strict';
	/**
	 * @description Get property value by name, from object.
	 * @function getProperty
	 * @private
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} obj
	 * @param {string} name
	 * @return {string|object} property value.
  	 */
	function getProperty(obj, name) {
		if (obj && obj[name]) {
			return obj[name];
		}
		return "";
	}

	/**
  	 * @description Get property value by name, from object array of CCSP ConfigItem.
	 * @function CCSPIntegration.ccsp.callDataHelper.getValueByKey
	 * @private
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Array} objectArray
	 * @param {string} key
	 * @return {string|object} property value.
  	 */
	function getValueByKey(objectArray, key) {
		try {
			// in case there is only 1 object, than we need to treat the objectArray as an object and not array
			if (objectArray.length == undefined) {
				if (objectArray.Id == key)
					return objectArray.Value;
				else if (objectArray[key] != undefined)
					return objectArray[key];
			} else {
				for (var i = 0; i < objectArray.length; i++) {
					if (objectArray[i].Id == key) {
						return objectArray[i].Value;
					}
				}
			}
		}
		catch (e) {
		}
		return null;
	}

	/**
  	 * @description
	 * Get callId in decimal format from callData.
	 * Where to get it from is same both in WebAgent and TP.
	 * @function CCSPIntegration.ccsp.callDataHelper.getCallId
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} callId string in decimal format.
  	 */
	target.getCallId = function(callData) {
		if (!callData) return "";
		return callData.CallId || "";
	};

	/**
	 * Get callId in hex format from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getCallIdHex
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} callId string in hex format.
  	 */
	target.getCallIdHex = function(callData) {
		if (!callData) return "";
		return getProperty(callData, "CallIdHex") || getProperty(callData.CallInfo, "IdHex");
	};

	/**
	 * Get CallerANI from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getCallerANI
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} 
  	 */
	target.getCallerANI = function(callData) {
		if (!callData) return "";
		return getProperty(callData, "CallerANI") || getValueByKey(callData.CallInfo.Caller, "ANI") || "";
	};

	/**
	 * @description
	 * Get CallerDNIS from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getCallerDNIS
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} 
  	 */
	target.getCallerDNIS = function(callData) {
		if (!callData) return "";
		return getProperty(callData, "CallerDNIS") || getValueByKey(callData.CallInfo.Caller, "DNIS") || "";
	};
	
	/**
	 * Get CallerMessage from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getCallerMessage
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} 
  	 */
	target.getCallerMessage = function(callData) {
		if (!callData) return "";
		// WebAgent -- XXX not exist in current Salesforce WebAgent integration. need to put it into Call.toJSON(), if needed.
		return getProperty(callData, "CallerMessage") || getProperty(callData.CallInfo, "Message");
	}

	/**
	 * Get CallerName from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getCallerName
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} 
  	 */
	target.getCallerName = function(callData) {
		if (!callData) return "";
		return getProperty(callData, "CallerName") || getValueByKey(callData.CallInfo.Caller, "Name") || "";
	};

	/**
	 * Get CallerURL from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getCallerURL
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} 
  	 */
	target.getCallerURL = function(callData) {
		if (!callData) return "";
		// WebAgent -- XXX not exist in current Salesforce WebAgent integration. need to put it into Call.toJSON(), if needed.
		return getProperty(callData, "CallerURL") || getValueByKey(callData.CallInfo.Caller, "Url") || "";
	}

	/**
	 * Get call direction (Incoming or Outgoing) from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getDirection
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} 
  	 */
	target.getDirection = function(callData) {
		if (!callData) return "";
		return getProperty(callData, "Direction") || getProperty(callData.CallInfo, "Direction");
	}

	/**
	 * Get QueueName from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getQueueName
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} 
  	 */
	target.getQueueName = function(callData) {
		if (!callData) return "";
		// WebAgent -- XXX not exist in current Salesforce WebAgent integration. need to put it into Call.toJSON(), if needed.
		return getProperty(callData, "QueueName") ||
		  callData.CallInfo.System.QueueName ||
			getValueByKey(callData.CallInfo.System, "CallSetName");
	}

	/**
	 * Get MediaType from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getMediaType
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} 
  	 */
	target.getMediaType = function(callData) {
		if (!callData) return "";
		return getProperty(callData, "MediaType") || getProperty(callData.CallInfo.StreamInfo, "MediaType");
	}

	/**
	 * Get Optional Paramaetere from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getOptionalParameter
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @return {string} 
  	 */
	target.getOptionalParameter = function(callData, name) {
		if (!callData) return "";

		// WebAegnt -- callData.CallInfo.OptPar;
		var optpar = callData.CallInfo.OptPar;
		if (optpar) {
			return getProperty(optpar, name);
		}
		
		// TP -- callData.CallInfo.OptionalParams
		optpar = callData.CallInfo.OptionalParams;
		if (optpar) {
			var ret = getValueByKey(optpar, name);
			if (ret && typeof ret === "string") {
				return ret;
			}
			if (ret && typeof ret !== "string") {
				log.info("getOptionalParameter: " + name + " is not a string.");
				// log.dumpobj("optpar." + name, ret, true);
			} else {
				log.info("getOptionalParameter: " + name + " not found.");
				// log.dumpobj("optpar", optpar, true);
			}
		}
		return "";
	},

	/**
	 * Extract dialer record from the provided screenPopInfo string.
	 * @function CCSPIntegration.ccsp.callDataHelper.extractDialerRecord
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {string} screenPopInfo
	 * @param {string} columnNameMapping optional. 
	 * @param {bool} mappingColumnsOnly optional. If set true, return those columns defined in ColumnNameMapping optpar.
	 * @return {array} data array.
	 **/
	target.extractDialerRecord = function(screenPopInfo, columnNameMapping, mappingColumnsOnly) {
		// These fields are received as standard from the Sytel dialer and are not to be displayed.
		var sytelSystemFields = ";SWITCH_RESULT;AGENT_RESULT|RESULT_TS;RETRY_COUNT;RETRY_USERNAME;RETRY_TS;RETRY_INDEX;RETRY_NUMBER;COMPLETE_TS;";
		var popData = [], pdColumns, columnsCount, keyval, keyvalPattern;

		function translateColumnName(nameMap, name, mappedOnly) {
			var res = nameMap.match(new RegExp(name + "~([^|]*)"));
			if (!res) {
				return mappedOnly? null : name;
			}
			return res[1];
		}

		function addPopData(popData, columnName, columnValue, nameMap, mappedOnly) {
			var searchStr = columnName.toUpperCase();
			if (sytelSystemFields.indexOf(searchStr) === -1) {
				if (nameMap) {
					columnName = translateColumnName(nameMap, columnName, mappedOnly);
					if (!columnName) {
						return false;
					}
				}
				popData.push({ name: columnName, value: columnValue });
				return true;
			}
			return false;
		}

		try {
			// The way in how Sytel passes screenPopInfo has been changed to XML since Sytel 10.6.559.
			if (screenPopInfo.indexOf("<MagicXMLDocument") === 0) {

				// contains an xml part which can be converted into an object.
				var endOfXml = "</MagicXMLDocument>";
				var lastIndex = screenPopInfo.lastIndexOf(endOfXml);
				if (lastIndex === -1) {
					throw new Error("end of MagicXmlDocument not found.");
				}
				lastIndex = lastIndex + endOfXml.length;
				var magicXml = screenPopInfo.slice(0, lastIndex);
				screenPopInfo = screenPopInfo.substring(lastIndex);
				var pdData = $.xml2json(magicXml);

				// Display all values apart from those that are not for display
				if (pdData && pdData.r && pdData.r.c && pdData.r.c.length > 0) {
					pdColumns = pdData.r.c;

					// wanted to use array.forEach for iteration. however, to support IFRAME integration on WebAgent (IE7), use the old way.
					columnsCount = pdColumns.length;
					for (var x = 0; x < columnsCount; ++x) {
						col = pdColumns[x];
						// below [col.d || ""] may not be required, but anyway...
						addPopData(popData, col.n, col.d || "", columnNameMapping); 
					}
				}
			}

			// Do the way we used to do, for the Sytel versions before 10.6.559, and for those data added by CCSP PDS.
			// * CCSP PDS adds DialedTelephoneNumber after XML.
			pdColumns = screenPopInfo.split("|");
			// keyvalPattern = /([\w]*)~\w~([^|]*)/; // [ColumnName]~N~[Value]
			keyvalPattern = /([\w]*)~[N|Y]~(.*)/, // [ColumnName]~N~[Value] -- optimized.

			// there is a trailing |, do not parse the last index
			columnsCount = pdColumns.length - 1;
			for (var i = 0; i < columnsCount; i++) {
				keyval = pdColumns[i].match(keyvalPattern);
				addPopData(popData, keyval[1], keyval[2], columnNameMapping);
			}
		}
		catch (e) {
			log.error("extractDialerRecord: error: " + (e.message || e));
		}
		return popData;
	};
	
	/**
	 * Get dialer record from callData.
	 * @function CCSPIntegration.ccsp.callDataHelper.getDialerRecord
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Object} callData 
	 * @param {bool} useColumnNameMapping optional. If set true, translate column name with ColumnNameMapping optpar.
	 * @param {bool} mappingColumnsOnly optional. If set true, return those columns defined in ColumnNameMapping optpar.
	 * @return {string} dialer data array.
  	 */
	target.getDialerRecord = function(callData, useColumnNameMapping, mappingColumnsOnly) {
		if (!callData) return [];
		var screenPopInfo = target.getOptionalParameter(callData, "ScreenPopInfo");
		var columnNameMapping = useColumnNameMapping? target.getOptionalParameter(callData, "ColumnNameMapping") : null;
		return target.extractDialerRecord(screenPopInfo, columnNameMapping, mappingColumnsOnly);
	};

	/**
	 * Get dialer data by data column name.
	 * @function CCSPIntegration.ccsp.callDataHelper.getDialerDataByName
	 * @memberof CCSPIntegration.ccsp.callDataHelper
	 * @param {Array} dialerRecord 
	 * @param {string} columnName
	 * @return {string}
  	 */
	target.getDialerDataByName = function(dialerRecord, columnName) {
		if (!dialerRecord || dialerRecord.length === 0) return null;
		for (var i = 0; i < dialerRecord.length; ++i) {
			if (dialerRecord[i].name === columnName) {
				return dialerRecord[i].value;
			};
		}
		return null;
	};

})(CCSPIntegration.ccsp.callDataHelper);


/**
 * @global CCSPIntegration.ccsp.sfPopHelper
 * @description Manages the retrieval of screen pop from salesforce.
 */
CCSPIntegration.ccsp.sfPopHelper = CCSPIntegration.ccsp.sfPopHelper || {};

(function(target) {
	'use strict';

	var callDataHelper = CCSPIntegration.ccsp.callDataHelper;

	var SPECIAL_CHARS_REGEXP = /([\:\-\_]+(.))/g;

	/**
	 * Converts snake_case to camelCase. (copied from angular...)
	 * @function camelCase
	 * @private
	 * @param {string} name Name to normalize
	 */
	function camelCase(name) {
		return name.replace(SPECIAL_CHARS_REGEXP, function(_, separator, letter, offset) {
			return offset ? letter.toUpperCase() : letter;
		});
	}
	
	var GET_SCREENPOP_REQUIRED_EMPTY = "one or more parameter values empty";
	var GET_SCREENPOP_FAILED =  "failed";
	var GET_SCREENPOP_NO_SEARCH_RESULT =  "no data";
	var GET_SCREENPOP_NOMORE_SEARCH_OPTIONS =  "no more search entities";

	var CCSP_CALLDATA_PREFIX = "callData-";
	var CCSP_CONST_PREFIX = "const-"; // not a good naming.
	var CCSP_VALUE_REQUIRED = "*";

	/**
	 * Parse the search option string and create one of SearchAction object (CallerIdSearchAction, ObjectIdSearchAction, QuerySearchAction, or ApexSearchAction)
	 * @function parseSearchOption
	 * @param {string} str search option strng
	 * @return {Object}
	 */
	function parseSearchOption(str) {
		var searchType, paramstr, params, action;
		var n = str.indexOf(":");
		if (n >= 0) {
			searchType = str.substring(0, n);
			paramstr = str.substring(n + 1);
		} else {
			searchType = str;
			paramstr = "";
		}

		searchType = searchType.trim().toLowerCase();
		params = paramstr? paramstr.split(";") : [];

		if (searchType === "callerid") {
			action = new CallerIdSearchAction(params);
		} else if (searchType === "callerid*") {
			action = new CallerIdSearchAction(params, true);
		} else if (searchType === "objectid") {
			action = new ObjectIdSearchAction(params);
		} else if (searchType === "query") {
			action = new QuerySearchAction(params);
		} else if (searchType === "query*") {
			action = new QuerySearchAction(params, true);
		} else if (searchType === "apex") {
			action = new ApexSearchAction(params);
		} else {
			log.warn("parseSearchOption unknown searchType: " + searchType);
		}
		if (action && action.isValid()) {
			return action;
		}
		return null;
	}

	/**
	 * @function parseQueryParameters
	 * @private
	 * @param {string} className
	 * @param {Array} params
	 * @param {Number} startIndex
	 * @return {Object}
	 */
	function parseQueryParameters(className, params, startIndex) {
		/**
		 * @function parseQueryParameters#parseParameter
		 * @private
		 * @param {string} param
		 * @return {Object}
		 * @throws {string} error message that happend when parsing the parameter.
		 */
		function parseParameter(param) {
			var par = params[index].split("=");
			if (par.length !== 2) {
				throw "no '=' in the parameter.";
			}
			var queryParameterName = par[0].trim();
			if (!queryParameterName) {
				throw "queryParameterName is empty.";
			}
			var ccspParameterName = par[1].trim();
			var isConst = false, isCallData = false, isRequired = false;

			if (ccspParameterName.indexOf(CCSP_CONST_PREFIX) === 0) {
				isConst = true;
				ccspParameterName = ccspParameterName.substring(CCSP_CONST_PREFIX.length);
			}
			else if (ccspParameterName.indexOf(CCSP_CALLDATA_PREFIX) === 0) {
				isCallData = true;
				ccspParameterName = ccspParameterName.substring(CCSP_CALLDATA_PREFIX.length);
			}

			if (ccspParameterName.slice(-1) === CCSP_VALUE_REQUIRED) {
				isRequired = true;
				ccspParameterName = ccspParameterName.slice(0, -1);
			}

			if (!ccspParameterName) {
				throw "ccspParameterName is empty.";
			}

			return {
				queryParameterName: queryParameterName,
				ccspParameterName: ccspParameterName,
				isConst: isConst,
				isCallData: isCallData,
				isRequired: isRequired
			};
		}

		var ret = [];
		for (var index = startIndex; index < params.length ; ++ index) {
			try {
				ret.push(parseParameter(params[index]));
			}
			catch (e) {
				log.error(className + ": " + (e.message || e) + " at parameter#: " + (index - startIndex));
				return null;
			}
		}
		return ret;
	}

	function getCallDataByName(callData, name) {
		var dataValue;
		switch (name) {
		case "CallerId":
			dataValue = callDataHelper.getCallerId(callData);
			break;

		case "CallerIdHex":
			dataValue = callDataHelper.getCallerIdHex(callData);
			break;

		case "CallerANI":
			dataValue = callDataHelper.getCallerANI(callData);
			break;

		case "CallerDNIS":
			dataValue = callDataHelper.getCallerDNIS(callData);
			break;

		case "Direction":
			dataValue = callDataHelper.getDirection(callData);
			break;

		case "QueueName":
			dataValue = callDataHelper.getQueueName(callData);
			break;

		default:
			log.error("getCallDataByName: Unsupported parameter for CallData. : " + name);
			dataValue = "";
			break;
		}
		return dataValue;
	}

	function getQueryParameters(className, queryParams, callData, dialerRecord) {
		
		function getParameter(qPar, callData, dialerRecord) {
			var queryParamName = qPar.queryParameterName;
			var ccspParamName = qPar.ccspParameterName;
			var queryValue;

			if (qPar.isConst) {
				queryValue = ccspParamName;
			} else if (qPar.isCallData) {
				queryValue = getCallDataByName(callData, ccspParamName);
			} else {
				if (dialerRecord) {
					queryValue = callDataHelper.getDialerDataByName(dialerRecord, ccspParamName);
				} else {
					queryValue = callDataHelper.getOptionalParameter(callData, ccspParamName);
				}
			}

			if (!queryValue && qPar.isRequired) {
				return null;
			}
			return queryParamName + "=" + encodeURIComponent(queryValue);
		}
		
		var ret = [];
		for (var index = 0; index < queryParams.length; ++ index) {
			var qpar = queryParams[index];
			var qstr = getParameter(qpar, callData, dialerRecord);
			if (!qstr) {
				log.info(className + ": Required data is empty. data name: " + qpar.ccspParameterName + ", index : " + index);
				return null;
			}
			ret.push(qstr);
		}
		return ret.join("&");
	}

	function getDialerRecordIfDialerCall(callData, dialerRecord) {
		if (dialerRecord) {
			if (dialerRecord instanceof Array) {
				return dialerRecord;
			}
			return callDataHelper.getDialerRecord(callData);
		}

		return null;
	}

	/**
	 * @class CallerIdSearchAction
     */
	function CallerIdSearchAction(initPar, multi) {
		this.isMultiple;

		if (initPar == null || (initPar instanceof Array)) {
			this.isMultiple = !!multi;
		} else {
			this.isMultiple = initPar.isMultiple;
		}
	}

	CallerIdSearchAction.prototype.toJSON = function() {
		return {
			name: "CallerIdSearchAction",
			isMultiple: this.isMultiple
		}
	};

	CallerIdSearchAction.prototype.isValid = function() {
		log.debug("CallerIdSearchAction.isValid: true");
		return true;
	};

	CallerIdSearchAction.prototype.getScreenPop = function(callData, dialerRecord) {
		var defer = $.Deferred();
		var callerId;
		if (dialerRecord) {
			callerId = callDataHelper.getDialerDataByName(dialerRecord, "DialedTelephoneNumber");
		} else {
			callerId = callDataHelper.getCallerANI(callData);
		}

		if (!callerId) {
			log.info("CallerIdSearchAction.getScreenPop: No callerId.");
			defer.reject(GET_SCREENPOP_REQUIRED_EMPTY);
		} else {
			// get screen pop data.
			log.debug("CallerIdSearchAction: callerId: " + callerId);
			// save this.isMultiple to local so that it can be referred in the defer callback.
			var  isMultiple = this.isMultiple;
			CCSPIntegration.sforceCti.api.searchAndGetScreenPopUrl(callerId, "", "inbound")
			.done(function(data) {
				var popId;
				try {
					log.debug("CallerIdSearchAction: result: " + JSON.stringify(data));
					if (isMultiple) {
						popId = data["screenPopUrl"];
					} else {
						for (var i in data) {
							if (i !== "screenPopUrl") {
								popId = "/" + i;
								break;
							}
						}
					}

					if (popId) {
						defer.resolve(popId);
					} else {
						defer.reject(GET_SCREENPOP_NO_SEARCH_RESULT);
					}
				}
				catch (e) {
					log.error("CallerIdSearchAction.getScreenPop: done: error: " + (e.message || e));
					defer.reject(GET_SCREENPOP_FAILED);
				}
			})
			.fail(function(error) { 
				log.error("CallerIdSearchAction.getScreenPop error: " + error);
				defer.reject(GET_SCREENPOP_FAILED);
			});
		}
		return defer.promise();
	}

	/**
	 * @class ObjectIdSearchAction
	 * @param {Object|Array} initPar If array (of string), is regarded as search option parameters
	 *  If an object, is regarded as the state back up restored from json.
	 * @private
	 * @memberof CCSPIntegration.ccsp.sfPopHelper
     */
	function ObjectIdSearchAction(initPar) {
		this.optparName;
		
		if (initPar instanceof Array) {
			this.optparName = initPar.length > 0? initPar[0].trim() : "";
		} else {
			this.optparName = initPar.optparName;
		}
	}

	ObjectIdSearchAction.prototype.toJSON = function() {
		return {
			name: "ObjectIdSearchAction",
			optparName: this.optparName
		}
	};

	ObjectIdSearchAction.prototype.isValid = function() {
		var valid = !!this.optparName;
		log.debug("ObjectIdSearchAction.isValid: " + valid);
		return valid;
	};

	ObjectIdSearchAction.prototype.getScreenPop = function(callData, dialerRecord) {
		var defer = $.Deferred();
		var objectId, popId;
		if (dialerRecord) {
			objectId = callDataHelper.getDialerDataByName(dialerRecord, this.optparName);
		} else {
			objectId = callDataHelper.getOptionalParameter(callData, this.optparName);
		}
		if (!objectId) {
			log.info("ObjectIdSearchAction.getScreenPop: objectId valus is missing or empty.");
			defer.reject(GET_SCREENPOP_REQUIRED_EMPTY);
		} else {
			log.debug("ObjectIdSearchAction: objectId: " + objectId);
			popId = "/" + objectId;
			defer.resolve(popId);
		}
		return defer.promise();
	};

	/**
	 * @class QuerySearchAction
     */
	function QuerySearchAction(initPar, multi) {
		// search: search={[callData-]|[fixed-]}name; queryN=paramNameN;... ;

		this.searchParam;
		this.queryArgs;
		this.isMultiple;

		if (initPar instanceof Array) {
			var params = initPar;
			this.isMultiple = !!multi;
			if (params && params.length > 0) {
				this.searchParam = (function parseSearchParam(par) {
					var isConst = false, isCallData = false;
					par = par.trim();
					if (par.indexOf(CCSP_CONST_PREFIX) === 0) {
						isConst = true;
						par = par.substring(CCSP_CONST_PREFIX.length);
					} else if (par.indexOf(CCSP_CALLDATA_PREFIX) === 0) {
						isCallData = true;
						par = par.substring(CCSP_CALLDATA_PREFIX.length);
					}
					if (!par) {
						log.error("QuerySearchAction: search parameter name is empty.");
						return null;
					}
					
					return {
						isConst: isConst,
						isCallData: isCallData,
						value: par
					};
				})(params[0]);

				this.queryArgs = parseQueryParameters("QuerySearchAction", params, 1);
			} else {
				log.error("QuerySearchAction: number of parameters provided for this search option is less than 2 and is not enough.");
			}
		}
		else {
			this.searchParam = initPar.searchParam;
			this.queryArgs = initPar.queryArgs;
			this.isMultiple = initPar.isMultiple;
		}
	}

	QuerySearchAction.prototype.toJSON = function() {
		return {
			name: "QuerySearchAction",
			searchParam: this.searchParam,
			queryArgs: this.queryArgs,
			isMultiple: this.isMultiple
		}
	};

	QuerySearchAction.prototype.isValid = function() {
		var valid = this.searchParam && this.queryArgs instanceof Array;
		log.debug("QuerySearchAction.isValid: " + valid);
		return valid;
	};

	QuerySearchAction.prototype.getScreenPop = function(callData, dialerRecord) {
		var defer = $.Deferred();
		var searchParamValue, queryParams;
		var spar = this.searchParam;
		
		if (spar.isConst) {
			searchParamValue = spar.value;
		} else if (spar.isCallData) {
			searchParamValue = getCallDataByName(callData, spar.value);
		} else {
			if (dialerRecord) {
				searchParamValue = callDataHelper.getDialerDataByName(dialerRecord, spar.value);
			} else {
				searchParamValue = callDataHelper.getOptionalParameter(callData, spar.value);
			}
		}

		queryParams = getQueryParameters("QuerySearchAction", this.queryArgs, callData, dialerRecord);

		// queryParams is null if invalid, or an empty array [] if no parameters.
		if (!searchParamValue || queryParams === null) {
			log.debug("QuerySearchAction: " + GET_SCREENPOP_REQUIRED_EMPTY);
			defer.reject(GET_SCREENPOP_REQUIRED_EMPTY);
		} else {
			log.debug("QuerySearchAction: call searchAndGetScreenPopUrl: searchParameter: " + searchParamValue + ", params: " + queryParams);
			// save this.isMultiple so that it can be referred in the defer callback.
			var  isMultiple = this.isMultiple;
			CCSPIntegration.sforceCti.api.searchAndGetScreenPopUrl(searchParamValue, queryParams, "inbound")
			.done(function(data) {
				try {
					log.debug("QuerySearchAction: result: " + JSON.stringify(data));
					var popId;
					if (isMultiple) {
						popId = data["screenPopUrl"];
					} else {
						for (var i in data) {
							if (i !== "screenPopUrl") {
								popId = "/" + i;
								break;
							}
						}
					}

					if (popId) {
						defer.resolve(popId);
					} else {
						defer.reject(GET_SCREENPOP_NO_SEARCH_RESULT);
					}
				}
				catch (e) {
					log.error("QuerySearchAction.getScreenPop: done: error: " + (e.message || e));
					defer.reject(GET_SCREENPOP_FAILED);
				}
			})
			.fail(function(error) { 
				log.error("QuerySearchAction.getScreenPop error: " + error);
				defer.reject(GET_SCREENPOP_FAILED);
			});
		}
		
		return defer.promise();
	};

	/**
	 * @class ApexSearchAction
     */
	function ApexSearchAction(initPar) {
		// params[0] => apex class name.
		// params[1] => method name.
		// params[n] => apex-parameter-name=ccsp-calldata-name
		//  if ccsp-calldata-name is prefixed with "callData-", it suppose to get the parameter value from callData,
		//  otherwise, it suppose to get from Optional Parameter or frm Dialer data.
		//  if ccsp-calldata-name ends with "*", it means a require field of which value to be non empty.

		this.apexClass;
		this.methodName;
		this.methodArgs;

		if (initPar instanceof Array) {
			// must have apex class name, method name, and at least one parameter.
			var params = initPar;
			if (params && params.length > 2) {
				this.apexClass = params[0].trim();
				this.methodName = params[1].trim();
				this.methodArgs = parseQueryParameters("ApexSearchAction", params, 2);
			} else {
				log.error("ApexSearchAction: number of parameters provided for this search option is less than 3 and is not enough.");
			}
		} else {
			this.apexClass = initPar.apexClass;
			this.methodName = initPar.methodName;
			this.methodArgs = initPar.methodArgs;
		}
	}

	ApexSearchAction.prototype.toJSON = function() {
		return {
			name: "ApexSearchAction",
			apexClass: this.apexClass,
			methodName: this.methodName,
			methodArgs: this.methodArgs
		}
	};

	ApexSearchAction.prototype.isValid = function() {
		var valid = this.apexClass && this.methodName && this.methodArgs && this.methodArgs.length > 0;
		log.debug("ApexSearchAction.isValid: " + valid);
		return valid;
	};

	ApexSearchAction.prototype.getScreenPop = function(callData, dialerRecord) {
		var defer = $.Deferred();
		var methodParams = getQueryParameters("ApexSearchAction", this.methodArgs, callData, dialerRecord);
		if (!methodParams) {
			log.debug("ApexSearchAction: " + GET_SCREENPOP_REQUIRED_EMPTY);
			defer.reject(GET_SCREENPOP_REQUIRED_EMPTY);
		} else {
			log.debug("ApexSearchAction: call apex: " + this.apexClass + ", method: " + this.methodName + ", params: " + methodParams);
			CCSPIntegration.sforceCti.api.runApex(this.apexClass, this.methodName, methodParams)
			.done(function(result) {
				try {
					log.debug("ApexSearchAction: result: " + JSON.stringify(result));
					var item, popId;
					if (result.length > 0) {
						for (var index = 0; index < result.length; ++ index) { 
							item = result[index];
							if (item.Id) {
								popId = "/" + item.Id;
								break;
							}
						}
					}

					if (popId) {
						log.debug("ApexSearchAction.getScreenPop: popId: " + popId);
						defer.resolve(popId);
					} else {
						log.info("ApexSearchAction.getScreenPop: no search result. items: " + result.length);
						defer.reject(GET_SCREENPOP_NO_SEARCH_RESULT);
					}
				}
				catch (e) {
					log.error("ApexSearchAction.getScreenPop: done: error: " + (e.message || e));
					defer.reject(GET_SCREENPOP_FAILED);
				}
			})
			.fail(function(error) {
				log.error("ApexSearchAction.getScreenPop fail: " + error);
				defer.reject(GET_SCREENPOP_FAILED);
			});
		}
		return defer.promise();
	};

	/**
	 * @name callTypesAndDirections
	 * @type {Array}
	 * @private 
	 * @constant
	 * @description 
	 *  Holds a set of call type and dierction that are subject to screen pop.
     */
	var callTypesAndDirections = [
		"Voice-Incoming",
		"Voice-Dialer",
		"Email-Incoming",
		"Callback-Incoming",
		"Chat-Incoming",
		"Voicemail-Incoming"
	];

	/**
	 * @name screenPopActionEntries
	 * @type {Object}
	 * @private
	 * @see loadSearchOptions, restoreFromStorage, restoreFromJson
	 * @description 
	 *  Holds entries to search action objects.
     */
	var screenPopActionEntries = {
	};

	//target.getScreenPopActionEntries = function() {
	//	return screenPopActionEntries;
	//}

	function saveToStorage(storage, prefix) {
		try {
			storage.setItem(prefix + "screenPopEntities", JSON.stringify(screenPopActionEntries));
			storage.setItem(prefix + "screenPopEntities_saved", "saved");
			return true;
		}
		catch (e) {
			log.error("sfPopHelper.saveToStorage: error: " + (e.message || e));
		}
		return false;
	}

	function fromJson(jsonstr) {
		var json = JSON.parse(jsonstr);
		var restored = {};
		for (var calldir in json) {
			restored[calldir] = [];
			var actions = json[calldir];
			for (var n = 0; n < actions.length; ++ n) {
				var state = actions[n];
				var action = null;
				switch (state.name) {
				case "CallerIdSearchAction":
					action = new CallerIdSearchAction(state);
					break;

				case "ObjectIdSearchAction":
					action = new ObjectIdSearchAction(state);
					break;

				case "QuerySearchAction":
					action = new QuerySearchAction(state);
					break;

				case "ApexSearchAction":
					action = new ApexSearchAction(state);
					break;

				default:
					break;
				}
				if (!action || !action.isValid()) {
					throw new Error("Failed to restore " + state.name + " for " + calldir);
				}
				restored[calldir].push(action);
			}
		}
		return restored;
	}

	function restoreFromStorage(storage, prefix) {
		try {
			if (storage.getItem(prefix + "screenPopEntities_saved") === "saved") {
				var savedData = storage.getItem(prefix + "screenPopEntities");
				screenPopActionEntries = fromJson(savedData);
				return true;
			}
			log.debug("restoreFromStorage: Not saved into storage.");
		}
		catch (e) {
			log.error("restoreFromStorage: Failed to restore: " + (e.message || e));
		}
		return false;
	}

	// target.restoreFromJson = function(jsonstr) { 
	function restoreFromJson(jsonstr) {
		try {
			screenPopActionEntries = fromJson(jsonstr);
			return true;
		}
		catch (e) {
			log.error("restoreFromJson: Failed to restore: " + e.message || e);
		}
		return false;
	}

	/**
	 * @description
	 * Load search options by call type and direction and set them to screenPopActionEntries.
	 * @function CCSPIntegration.ccsp.sfPopHelper.loadSearchOptions
	 * @param {Object} customOptions
	 * @return {bool} true when load successfull.
  	 */
	target.loadSearchOptions = function(customOptions) {
		log.debug("loadSearchOptions() : enter");
		
		/*** disable loading from cache for now. ***/
		// try get from the sessionStorage cache.
		//if (restoreFromStorage(window.sessionStorage, "searchOptions_")) {
		//	log.debug("loadSearchOptions() : " + JSON.stringify(screenPopActionEntries));
		//	log.debug("loadSearchOptions() : restored from storage.");
		//	return true;
		//}

		try {
			for (var i = 0; i < callTypesAndDirections.length; ++ i) {
				var typeAndDirection = callTypesAndDirections[i];
				var keyBase = camelCase(typeAndDirection);
				var searchOptionsKey = keyBase + "SearchOptions";

				if (customOptions.hasOwnProperty(searchOptionsKey)) {
					var searchOptionsStr = customOptions[searchOptionsKey].trim();
					if (!searchOptionsStr) {
						continue;
					}
					var searchOptions = searchOptionsStr.split(";");

					screenPopActionEntries[typeAndDirection] = [];

					for (var index = 0; index < searchOptions.length; ++ index) {
						var optionName = searchOptions[index].trim();
						var optionKey = keyBase + "SearchOption" + optionName;
						if (customOptions.hasOwnProperty(optionKey)) {
							var searchParams = customOptions[optionKey];
							var searchAction = parseSearchOption(searchParams);
							if (!searchAction) {
								log.warn("Failed to get searchAction by [ " + searchParams + "]");
							}
							screenPopActionEntries[typeAndDirection].push(searchAction);
						} else {
							log.warn("loadSearchOptions: key missing: " + entityKey);
						}
					}
				}
			}

			/*** disable loading from cache for now. ***/
			// saveToStorage(window.sessionStorage, "searchOptions_");
			log.debug("loadSearchOptions() : leave");
			return true;
		}
		catch (e) {
			log.error("loadSearchOptions: error: " + (e.message || e));
			return false;
		}
	}

	/**
	 * @description
	 * Traverse search actions until screen pop url retrieval either succeeded or failed, then call resolve or reject on the defer.
	 * @private 
	 * @function traverseGetScreenPop
	 * @param {Object} defer defer object.
	 * @param {Array} searchActions
	 * @param {number} index point to the current action in searchActions.
	 * @param {Object} callData
	 * @param {Object} dialerRecord
	 * @return {} 
  	 */
	function traverseGetScreenPop(defer, searchActions, index, callData, dialerRecord) {

		try {
			log.debug("traverseGetScreenPop: enter: index: " + index);

			if (index >= searchActions.length) {
				log.debug("traverseGetScreenPop: no more search actions. : " + index);
				defer.reject(GET_SCREENPOP_NOMORE_SEARCH_OPTIONS);
				return;
			}

			var action = searchActions[index];
			if (!action) {
				log.debug("traverseGetScreenPop: no search action at: " + index + ". move to next search action.");
				traverseGetScreenPop(defer, searchActions, index + 1, callData, dialerRecord);
				return;
			}

			log.debug("traverseGetScreenPop: use searchAction of: " + JSON.stringify(action));
			action.getScreenPop(callData, dialerRecord)
			.done(function(popId) {
				log.debug("traverseGetScreenPop: get popId: " + popId);
				defer.resolve(popId);
			})
			.fail(function(errorCode) {
				log.debug("traverseGetScreenPop: " + errorCode + " at: " + index);
				if (errorCode === GET_SCREENPOP_REQUIRED_EMPTY || errorCode === GET_SCREENPOP_NO_SEARCH_RESULT) {
					traverseGetScreenPop(defer, searchActions, index + 1, callData, dialerRecord);
				} else {
					defer.reject(errorCode);
				}
			});
		}
		catch (e) {
			log.error("traverseGetScreenPop: error: " + (e.message || e));
			defer.reject(GET_SCREENPOP_FAILED);
		}
	}

	/**
	 * @description get url to screen pop and return it with promise.
	 * @function CCSPIntegration.ccsp.sfPopHelper.getScreenPop
	 * @param {string} callType
	 * @param {direction} direction
	 * @param {Object} callData
	 * @param {Array|bool} dialerRecord
	 * @return {Object} promise
  	 */
	target.getScreenPop = function(callType, direction, callData, dialerRecord) {

		if (callType === "VOIP") {
			callType = "Voice";
		}

		if (direction === "Predictive" || direction === "Preview") {
			direction = "Dialer";
		} else {
			dialerRecord = null;
		}

		if (direction === "Dialer") {
			if (!dialerRecord) dialerRecord = true;
		}

		dialerRecord = getDialerRecordIfDialerCall(callData, dialerRecord);
		if (direction === "Dialer" && dialerRecord == null) {
			log.error("getScreenPop: direction is dialer but dialer record is not available.");
		}
		
		var key = callType + "-" + direction;
		var searchActions = screenPopActionEntries[key];
		var defer = $.Deferred();

		if (!searchActions || searchActions.length === 0) {
			// if no search options, do the default search by CallerANI.
			log.debug("no search action available for : [" + key + "]. use default search.");
			var action = new CallerIdSearchAction([], true);
			action.getScreenPop(callData, dialerRecord)
			.done(function(popId) {
				defer.resolve(popId);
			})
			.fail(function(errorCode) {
				defer.reject(errorCode);
			});
		} else {
			traverseGetScreenPop(defer, searchActions, 0, callData, dialerRecord);
		}

		return defer.promise();
	};

	target.GET_SCREENPOP_REQUIRED_EMPTY = GET_SCREENPOP_REQUIRED_EMPTY;
	target.GET_SCREENPOP_FAILED = GET_SCREENPOP_FAILED;
	target.GET_SCREENPOP_NO_SEARCH_RESULT = GET_SCREENPOP_NO_SEARCH_RESULT;
	target.GET_SCREENPOP_NOMORE_SEARCH_OPTIONS = GET_SCREENPOP_NOMORE_SEARCH_OPTIONS;
	
})(CCSPIntegration.ccsp.sfPopHelper);

