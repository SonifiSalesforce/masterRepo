

/**
 * @file Where the customization for Call History feed is placed.
 */


/**
 * @description Helper for adding parameter.
 * @class sfQueryParameters
 */
function sfQueryParameters() {
	var queryParameters = [];

	/**
	 * Add a query parameter.
     * @function add
     * @memberof sfQueryParameters
	 * @param {string} name
	 * @param {string} value
	 * @param {bool} skipEmpty
	 * @return {Object} sfQueryParameters
  	 */
	this.add = function(name, value, skipEmpty) {
		if (value || !skipEmpty) {
			var par = name + "=" + encodeURIComponent(value);
			queryParameters.push(par);
		}
		return this;
	}

	/**
	 * Get query string.
     * @function getQueryString
     * @memberof sfQueryParameters
	 * @return {string} query string.
  	 */
	this.getQueryString = function() {
		return queryParameters.join("&");
	}
}

/**
 * @description Demo Wrapup data feed.
 * @function createCallHistoryFeed_demo
 * @param {Object} callDataHelper provides methods for retrieving call property from callData.
 * @param {Object} calllInfo
 * @param {Object} calllData
 * @param {Object} wrapupData
 * @param {Object} userData
 * @param {Object} pageInfo
 * @return {string} should return query string which will be set into saveLog().
 */
function createCallHistoryFeed_demo(callDataHelper, callInfo, callData, wrapupData, userData, pageInfo) {

	try {
		log.debug("createWrapUpSaveLogData_demo: enter");
		var chatConversation = "";
		var mediaType = callDataHelper.getMediaType(callData);
		var txtSubject;

		switch (mediaType) {
		case 'VOIP':
			txtSubject = mediaType + " " + callDataHelper.getDirection(callData);
			break;

		case 'Email':
			break;

		case 'Chat':
			if (userData) {
				chatConversation = "ChatTranscript:" + stringifyChatTranscript(userData);
			}
			txtSubject = mediaType + " " + callDataHelper.getCallerName(callData) + " " + callDataHelper.getCallerMessage(calldata);
			break;
		}

		var txtWrapUp = JSON.stringify(wrapupData);
		var currentDate = new Date();
		var timeStamp = currentDate.toString();
		timeStamp = timeStamp.substring(0, timeStamp.lastIndexOf(':') + 3);
		var dueDate = currentDate.getFullYear() + '-' + (currentDate.getMonth() + 1) + '-' + currentDate.getDate();

		var queryParams = new sfQueryParameters();
		queryParams.add("Subject", txtSubject);
		queryParams.add("Status", "Completed");
		queryParams.add("CallType", callDataHelper.getDirection(callData)); // this will not work because what Salesforce expects is "Inbound", "Internal", or "Outbound".
		queryParams.add("CallObject", callDataHelper.getCallIdHex(callData));
		queryParams.add("Phone", callDataHelper.getCallerANI(callData)); // this will not work because Phone cannot be updated from Task.
		queryParams.add("CallDisposition", txtWrapUp);
		queryParams.add("Description", chatConversation);

		if (pageInfo.objectId.substr(0,3) == '003') {
			queryParams.add("whoId", pageInfo.objectId);
		} else {
			queryParams.add("whatId", pageInfo.objectId);
		}

		var saveParams = queryParams.getQueryString();
		return saveParams;
	}
	catch (e) {
		log.error("createWrapUpSaveLogData_demo: error: " + e.message);
		return "";
	}
}


/**
 * @description Wrapup data feed for NECF.
 * @function createCallHistoryFeed
 * @param {Object} callDataHelper provides methods for retrieving call property from callData.
 * @param {Object} calllInfo
 * @param {Object} calllData
 * @param {Object} wrapupData
 * @param {Object} userData currently we put chat transcript if call is of chat.
 * @param {Object} pageInfo
 * @optional {String} id - id param (send it when you want to UPDATE object with ID specified)
 * @optional {Bool} isInConsole 
 * @return {string} should return query string which will be set into saveLog().
 */
function createCallHistoryFeed(callDataHelper, callInfo, callData, wrapupData, userData, pageInfo, id, isInConsole) {
	
// Status standard -- const "Completed"
// Subject standard -- const"Telephone"
// Phone standard -- CallerANI or DialedTelephoneNumber
// DNIS__c custom -- CallerDNIS (empty for dialer call)
// CallType standard -- "Incoming", "Outgoing", "Preview", or "Predictive"
// ActivityDate standard -- timestamp
// CallStartTime__c custom -- call start time
// CallEndTime__c custom -- call end time
// CallDurationInSeconds custom -- call duration
// CallObject standard(?) -- callId
// CallDisposition standard -- wrapup code
// WrapupComment custom -- wrapup comment
// SEQNO__c custom -- from dialer record

	try {
		log.debug("createWrapUpSaveLogData: enter");

		var dialerRecord = null;

		if (callInfo.direction === "Predictive" || callInfo.direction === "Preview") {
			dialerRecord = callDataHelper.getDialerRecord(callData);
		}

		// utc1 and utc2 both to be timestamp string in ISO format.
		function timeDiffInSeconds(utc1, utc2) {
			try {
				var d1 = Date.parse(utc1);
				var d2 = Date.parse(utc2);
				// wanted to use Math.trunc() but not supported on IE.
				return parseInt((d2 - d1) / 1000, 10);
			}
			catch (e) {
				log.error("timeDiffInSeconds: error: " + e.message);
				return 0;
			}
		}

		// get datetime formatted for Salesforce ("yyyy-MM-dd HH:mm:ss") from ISO format.
		function getDateTime(dt) {
			// simplest one would be dt.replace("T", " ")
			return dt.replace(/(.*)T(.*)[\.].*/, function(match, p1, p2) {
				return [p1, p2].join(" ");
			});
		}

		// get date string for ActivityDate -- "yyyy-MM-dd 00:00:00".
		// date part is in local time, not in UTC/GMT, accorindg to a post https://success.salesforce.com/ideaView?id=08730000000jEaLAAU.
		function getActivityDate(dt) {
			var year = dt.getFullYear(), month = dt.getMonth() + 1, day = dt.getDate();
			return [year, month < 10? "0" + month : month, day < 10? "0" + day : day].join("-") + " 00:00:00";
		}

		function getChatTranscript(chatTranscript) {
			// chatTranscript is array of following object;
			//  "sender": [sender (such as Agent, Caller, Supervisor, and Me.]
			//	"chatLine": [chat text],
			//	"time": time-stamp 

			if (!$.isArray(chatTranscript)) {
				return "";
			}
			var index, line, text = "", maxIndex = chatTranscript.length;
			for (index = 0; index < maxIndex; index++) {
				line = chatTranscript[index];
				text = text + line.sender + ": " + line.chatLine + "\n";
			}
			return text;
		}

		function translateHistoryText(text) {
			if (typeof translator !== "undefined" && translator.callHistoryText) {
				return translator.callHistoryText(text);
			}
			return text;
		}

		function translateFromTo(text) {
			if (typeof translator !== "undefined" && translator.callFromToText) {
				return translator.callFromToText(text);
			}
			return text;
		}

		// helper object building up the query string for saveLog().
		var queryParams = new sfQueryParameters();

		// get current date/time for parameters ActivityDate, CallStartTime__c, and CallEndTime__c.
		var now = new Date();

		// Status
		queryParams.add("Status", translateHistoryText("Completed"));

		// Subject
		if (!isInConsole) {
		    var subject = typeof translator === "undefined" ? callInfo.mediaType : translator.mediaType(callInfo.mediaType);
		    queryParams.add("Subject", subject);
		}

		// Phone__c and DNIS__c
		var phone_c;
		var dnis_c;
		if (dialerRecord || callInfo.direction === "Outgoing") {
			phone_c = translateFromTo(callInfo.to);
			dnis_c = ""; // we do not know what DNIS is used for manual outbound call or dialer call.
		} else {
			phone_c = translateFromTo(callInfo.from);
			dnis_c = translateFromTo(callInfo.to);
		}

		queryParams.add("Phone__c", phone_c);
		queryParams.add("DNIS__c", dnis_c);

		// CallType -- Inbound or Outbound.
		var callType;
		if (callInfo.direction === "Outgoing" || callInfo.direction === "Predictive" || callInfo.direction === "Preview") {
			callType = "Outbound";
		} else {
			callType = "Inbound";
		}
		queryParams.add("CallType", callType);
		
		// CallType__c -- have it translated.
		var callType_c = translator.callDirection(callInfo.direction);
		queryParams.add("CallType__c", callType_c);

		// ActivityDate -- set today mid-night in local time, according to https://success.salesforce.com/ideaView?id=08730000000jEaLAAU.
		queryParams.add("ActivityDate", getActivityDate(now));

		// CallStartTime__c custom
		var callStartTime_c = callData.CtcCallStartTime || now.toISOString();
		queryParams.add("CallStartTime__c", getDateTime(callStartTime_c))
	
		// CallEndTime__c custom -- call end time
		var callEndTime_c = callData.CtcCallEndTime || now.toISOString();
		queryParams.add("CallEndTime__c", getDateTime(callEndTime_c));

		// CallDurationInSeconds custom -- call duration
		var callDurationInSeconds = timeDiffInSeconds(callStartTime_c, callEndTime_c);
		queryParams.add("CallDurationInSeconds", callDurationInSeconds);

		// CallObject standard(?) -- callId in hex.
		var callObject = callInfo.callIdHex;
		queryParams.add("CallObject", callObject);

		// CallDisposition
		var callDisposition = wrapupData.name; // or wrapupData.code
		queryParams.add("CallDisposition", callDisposition);

		// WrapupComment custom -- wrapup comment
		var comment = wrapupData.comment;
		queryParams.add("WrapupComment__c", comment);

		// SEQNO__c custom -- from dialer record
		var seqno_c = "";
		if (dialerRecord) {
			seqno_c = callDataHelper.getDialerDataByName(dialerRecord, "SEQNO");
			queryParams.add("SEQNO__c", seqno_c, true);
		}

		// ChatTranscript__c
		if (userData && userData.length > 0) {
			queryParams.add("ChatTranscript__c", getChatTranscript(userData), true);
		}

		if (pageInfo.objectId.substr(0,3) == '003') {
			queryParams.add("whoId", pageInfo.objectId);
		} else {
			queryParams.add("whatId", pageInfo.objectId);
		}

		if (id){
			queryParams.add("Id", id);
		}

		var saveParams = queryParams.getQueryString();
		return saveParams;
	}
	catch (e) {
		log.error("createCallHistoryFeed: error: " + e.message);
		return "";
	}
}

