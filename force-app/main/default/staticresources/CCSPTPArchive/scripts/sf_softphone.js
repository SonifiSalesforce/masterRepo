
/**
 * @file Salesforce softphone application javascript file for CCSP.
 * @copyright Enghouse Interactive 2016
 */


/**
 * configurable options
 */
var softphoneOptions = {
	
	// whether or not a confirm popup should be always displayed before click-to-dial.
	alwaysConfirmBeforeDialing: true,

	// hide transfer button in the dial action modal.
	disableTransferInDialAction: false
};

// variables 

var header$ = {};
var agentState$ = {};
var callInfo$ = {};

var pageSyncButton;
var callDetailPopup;
var callDetailPopupLink;
var dialActionPopup;
var searchResultPopup;
var errorBoxPopup;

var currentCallData;
var currentCallInfo;
var currentLineId = "";

var isAgentInfoRequested = false;

var currentConnectionState;

var savedDialData = null; // used to hold dialData for clickToDial.

/**
 * helper for data retrieval from CallData.
 * @global callDataHelper
 */
var callDataHelper = CCSPIntegration.ccsp.callDataHelper;


var screenPopManager = (function() {
	var SCREEN_POP_SAVED_KEY = "screenpop_saved";

	var lastScreenPopInfo = null;

	function save(callId, popId) {
		if (arguments.length === 0 || !callId) {
			lastScreenPopInfo = null;
			window.sessionStorage.removeItem(SCREEN_POP_SAVED_KEY, "");
			return;
		}
		lastScreenPopInfo = {
			callId: callId,
			popId: popId
		};
		window.sessionStorage.setItem(SCREEN_POP_SAVED_KEY, JSON.stringify(lastScreenPopInfo));
	}

	function restore() {
		lastScreenPopInfo = null;
		var savedInfo = window.sessionStorage.getItem(SCREEN_POP_SAVED_KEY);
		if (savedInfo) {
			try {
				lastScreenPopInfo = JSON.parse(savedInfo);
			}
			catch (e) {
				log.error("screenPopManager.restore: error: " + (e.message || e));
			}
		}
	}

	function screenPop(callId, popId, force) {
		force = !!force;
		
		if (lastScreenPopInfo && lastScreenPopInfo.callId === callId) {
			log.debug("screenPopManager.screenPop: screenPop: callId: " + callId + " already done.");
			return;
		}

		save(callId, popId);
		if (!popId) {
			log.debug("screenPopManager.screenPop: callId: " + callId + " : empty popId.");
			return;
		}

		log.debug("screenPopManager.screenPop: callId: " + callId + " : going to screen pop: " + popId);
		CCSPIntegration.sforceCti.api.screenPop(popId, force)
		.done(function() {
			log.debug("screenPopManager.screenPop: succeeded.");
		}).fail(function(error) {
			log.error("screenPopManager.screenPop: failed: " + error);
			displaySearchError("SfScreenPopError:" + error);
		});
	}

  	function getScreenPopCallId() {
		if (lastScreenPopInfo && lastScreenPopInfo.callId) {
			return lastScreenPopInfo.callId;
		}
		return "";
	}

	function callTerminated(callId) {
		var screenPopCallId = getScreenPopCallId();
		if (!screenPopCallId) {
			log.debug("screenPopManager.callTerminated: no screen pop in progress. passed callId: " + callId);
			return;
		}

		if (screenPopCallId === callId) {
			log.debug("screenPopManager.callTerminated: call associated to the screen pop has terminated. callId: " + callId);
			save();
		} else {
			log.debug("screenPopManager.callTerminated: callId does not match. screenPopCallId: " + screenPopCallId + ", passed callId: " + callId);
		}
	}

	function getPopIdFromPageInfo(pageInfo) {
		if (pageInfo.objectId) {
			log.debug("screenPopManager.getPopIdFromPageInfo: get popId from objectId: " + pageInfo.objectId);
			return "/" + pageInfo.objectId;
		}

		if (pageInfo.url) {
			var lastSlash = pageInfo.url.lastIndexOf("/");
			if (lastSlash >= 0) {
				log.debug("screenPopManager.getPopIdFromPageInfo: get popId from url: " + pageInfo.url);
				return "/" + pageInfo.url.substring(lastSlash + 1);
			}
		}
		log.debug("screenPopManager.getPopIdFromPageInfo: could not get popId.");
		return "/";
	}

	return {
		screenPop: screenPop,
		restore: restore,
		callTerminated: callTerminated,
		getScreenPopCallId: getScreenPopCallId,
		getPopIdFromPageInfo: getPopIdFromPageInfo
	}
})();


var screenPopStorage = (function() {
	var CALL_INFO_KEY = "screenpop_callInfo";
	var CALL_DATA_KEY = "screenpop_callData";
	var CALL_LINEID_KEY = "screenpop_lineId";

	function save(callInfo, callData, lineId) {
		window.sessionStorage.setItem(CALL_INFO_KEY, callInfo);
		window.sessionStorage.setItem(CALL_DATA_KEY, callData);
		window.sessionStorage.setItem(CALL_LINEID_KEY, "" + lineId);
	}

	function saveCallInfo(callInfo) {
		if (callInfo) {
			window.sessionStorage.setItem(CALL_INFO_KEY, JSON.stringify(callInfo))
		}
	}

	function restore() {
		var callInfoJson = window.sessionStorage.getItem(CALL_INFO_KEY);
		var callDataJson = window.sessionStorage.getItem(CALL_DATA_KEY);
		var lineId = window.sessionStorage.getItem(CALL_LINEID_KEY);
		if (callInfoJson && callDataJson) {
			currentCallInfo = JSON.parse(callInfoJson);
			currentCallData = JSON.parse(callDataJson);
			currentLineId = lineId;
			return {
				callInfo: currentCallInfo,
				callData: currentCallData,
				lineId: currentLineId
			}
		}
		return {
			callInfo: null,
			callData: null,
			lineId: ""
		}
	}

	function clear() {
		window.sessionStorage.removeItem(CALL_INFO_KEY);
		window.sessionStorage.removeItem(CALL_DATA_KEY);
		window.sessionStorage.removeItem(CALL_LINEID_KEY);
		currentCallInfo = null;
		currentCallData = null;
		currentLineId = "";
		return {
			callInfo: null,
			callData: null,
			lineId: ""
		}
	}

	return {
		save: save,
		saveCallInfo: saveCallInfo,
		clear: clear,
		restore: restore
	}
})();

var lastCallInfoStorage = (function() {
	var LAST_CALL_INFO_KEY = "screenpop_lastCallInfo";
	var lastCallInfo = null;

	function save(callInfo) {
		if (callInfo) {
			lastCallInfo = callInfo;
			try {
				log.debug("lastCallInfoStorage.save: set callInfo: " + JSON.stringify(callInfo));
				window.sessionStorage.setItem(LAST_CALL_INFO_KEY, JSON.stringify(callInfo));
			}
			catch (e) {
				log.debug("lastCallInfoStorage.save: error: " + e.message);
			}
		} else {
			lastCallInfo = null;
			log.debug("lastCallInfoStorage.save: set callInfo: null");
			window.sessionStorage.removeItem(LAST_CALL_INFO_KEY);
		}
	}

	function restore() {
		var lastCallInfoJson = window.sessionStorage.getItem(LAST_CALL_INFO_KEY);
		if (lastCallInfoJson) {
			try {
				var callInfo = JSON.parse(lastCallInfoJson);
				lastCallInfo = callInfo;
				log.debug("lastCallInfoStorage.restore: callInfo: " + JSON.stringify(callInfo));
				return callInfo;
			}
			catch (e) {
				log.debug("lastCallInfoStorage.restore: error: " + e.message);
			}
		}
		lastCallInfo = null;
		log.debug("lastCallInfoStorage.restore: null");
		return null;
	}

	return {
		save: save,
		restore: restore,
	    getLastCallInfo: function() {
			return lastCallInfo;
		}
	}
})();


function makeCall(dialNumber, dialMode) {
	CCSPIntegration.sfhub.commands.requestMakeCall("100", dialMode, dialNumber, savedDialData);
}

function initDialAction() {
	
	$('[id$=cancelbtn]').on("click", function() {
		dialActionPopup.popup("close");
	});

	$('[id$=dialbtn]').on("click", function() {
		makeCall($("#dialAction-number").text(), "dial");
		dialActionPopup.popup("close");
	});

	$('[id$=xferbtn]').on("click", function() {
		makeCall($("#dialAction-number").text(), "transfer");
		dialActionPopup.popup("close");
	});
}

function actionDial(callInfo, dialNumber, dialData) {
	log.debug("actionDial(callInfo, " + dialNumber + ")");

	// save the dialData to global, so that it will be retrieved in makeCall().
	savedDialData = dialData;

	if (currentConnectionState !== "available" && currentConnectionState !== "released") {
		return;
	}

	if ((callInfo == null || callInfo.mediaType !== "VOIP") && !softphoneOptions.alwaysConfirmBeforeDialing) {
		makeCall(dialNumber, "dial");
		return;
	}

	$("#dialAction-number").text(dialNumber);

	if (softphoneOptions.disableTransferInDialAction) {
		$('[id$=xferbtn]').hide();
	} else {
		if (callInfo != null) {
			$('[id$=xferbtn]').show();
		} else {
			$('[id$=xferbtn]').hide();
		}
	}

	dialActionPopup.popup("open");
}

function displayCallDetail(callInfo, callData) {
	$("#callDetail-callId").text(callDataHelper.getCallIdHex(callData));

	$("#callDetail-to").text(translateCallFromTo(callInfo.to));
	$("#callDetail-from").text(translateCallFromTo(callInfo.from));

	$("#callDetail-queueName").text(callDataHelper.getQueueName(callData));
	$("#callDetail-callerName").text(callDataHelper.getCallerName(callData));
	
	$('[id$=callDetail-closebtn]').on("click", function() {
		callDetailPopup.popup("close");
	});
}

function displayAgentExtension(extension) {
	log.debug("displayAgentExtension - " + extension);
	agentState$.extension.text(extension);
}

function requestAgentInfo(){
	if (!isAgentInfoRequested){
		CCSPIntegration.sfhub.commands.requestAgentInfo("");
		isAgentInfoRequested = true;
	}
}

function displayAgentStatus(state, releaseCode) {
	var image = "";
	if (arguments.length === 0) {
		state = "offline";
	}

	currentConnectionState = state.toLowerCase();
	if (currentConnectionState === "released" && releaseCode.length > 0) {
		agentState$.stateText.text(releaseCode);
	} else {
		if (typeof(translator) === "object") {
			agentState$.stateText.text(translator.agentState(state));
		} else {
			agentState$.stateText.text(state);
		}
	}

	switch (currentConnectionState) {
	case "connecting":
	case "connected":
	case "online":
		break;

	case "reconnecting":
	case "disconnected":
	case "offline":
		isAgentInfoRequested = false;
		break;
	case "available":
		image = Archive_path + "/images/Available.png";
		break;
	case "released":
		image = Archive_path + "/images/Released.png";
		break;
	default:
		break;
	}

	requestAgentInfo();
	if (image.length > 0) {
		agentState$.stateImage.show();
		agentState$.stateImage.attr("src", image);
	} else {
		agentState$.stateImage.hide();
	}
}

/**
 * Make a popup to show message that screen pop was not made.
 * @function displaySearchErrorResult
 */
function displaySearchError(error) {
	log.debug("displaySearchError: " + error);
	try {
		var text;
		var sfPopHelper = CCSPIntegration.ccsp.sfPopHelper;

		if (typeof(translator) === "object" && translator.searchError) {
			text = translator.searchError(error, sfPopHelper);
		}
		else {
			if (typeof(error) === "string") {
				if (error.indexOf("SfScreenPopError:") === 0) {
					// error is returned from sforce.screenPop API call.
					text = "SF ScreenPop error: " + error.subsring("SfScreenPopError:".length);
				} else {
					switch (error) {
					case sfPopHelper.GET_SCREENPOP_REQUIRED_EMPTY:
						text = "One or more required field to search is missing or empty.";
						break;

					case sfPopHelper.GET_SCREENPOP_FAILED:
						text = "Search failed. " + log.lastError();
						break;
	
					case sfPopHelper.GET_SCREENPOP_NO_SEARCH_RESULT:
						text = "No search result.";
						break;

					case sfPopHelper.GET_SCREENPOP_NOMORE_SEARCH_OPTIONS:
						text = "No search result.";
						break;

					default:
						text = error;
						break;
					}
				}
			} else {
				text = "Search Error: " + (error.message || error.toString());
			}
		}

		log.debug("displaySearchError: text: " + text);
		$("#search-result-text").text(text);
		searchResultPopup.popup("open");
	}
	catch (e) {
		log.error("displaySearchError: error: " + (e.message || e));
	}
}

function updateCallDetailLinkVisibility() {
	if (!currentCallData) {
		log.debug("updateCallDetailLinkVisibility - hide");
		callDetailPopupLink.hide();
	} else {
		log.debug("updateCallDetailLinkVisibility - show");
		callDetailPopupLink.show();
	}
}

function updatePageSyncButton(callInfo) {
	if (callInfo.state === "SlaveA2AInCall" && callInfo.transferreeAgentGlobalId) {
		pageSyncButton.show();
	} else {
		pageSyncButton.hide();
	}
}

function clearCallInfo() {
	callInfo$.mediaType.text("");
	callInfo$.direction.text("");
	callInfo$.stateText.text("");
	callInfo$.from.text("");
	callInfo$.to.text("");
	lastCallInfoStorage.save(null);
}

function translateCallFromTo(text) {
	if (text === "tts" || text === "Transfer To System") {
		if (typeof(translator) === "object" && translator.callFromToText) {
			return translator.callFromToText(text);
		}
	}
	return text;
}

function isInConsole() {
    return CCSPIntegration && CCSPIntegration.sforceCti && CCSPIntegration.sforceCti.console && CCSPIntegration.sforceCti.console.wrapper && CCSPIntegration.sforceCti.console.wrapper.isInConsole()
}

function displayCallInfo(callInfo, callData) {
	if (!callInfo || !callInfo.state || callInfo.state === 'Destructed') {
		clearCallInfo();
		return;
	}

	if (typeof(translator) === "object") {
		callInfo$.mediaType.text(translator.mediaType(callInfo.mediaType));
		callInfo$.direction.text(translator.callDirection(callInfo.direction));
		callInfo$.stateText.text(translator.callState(callInfo.state));
	} else {
		callInfo$.mediaType.text(callInfo.mediaType);
		callInfo$.direction.text(callInfo.direction);
		callInfo$.stateText.text(callInfo.state);
	}
	callInfo$.from.text(translateCallFromTo(callInfo.from));
	callInfo$.to.text(translateCallFromTo(callInfo.to));
	lastCallInfoStorage.save(callInfo);
}

function updateErrorIndication(msg) {

	if (!msg) {
		header$.errorIndicatorText.html("");
		if (header$.errorIndicator.is(":visible")) {
			header$.errorIndicator.hide();
			header$.errorIndicator.css("width", "0%");
			header$.companyLogo.css("width", "100%");
		}
	} else {
		header$.errorIndicatorText.html(msg);
		if (!header$.errorIndicator.is(":visible")) {
			header$.errorIndicator.css("width", "10%");
			header$.companyLogo.css("width", "90%");
			header$.errorIndicator.show();
		}
	}
}

//
log.onError = function(msg) {
	updateErrorIndication(msg);
}

log.onWarn = function(msg) {
	updateErrorIndication(msg);
}

function screenPopCallData_VOIP_Incoming(lineId, eventName, callInfo, callData) {
	var callId = callInfo.callId || callDataHelper.getCallId(callData);
	var callIdHex = callInfo.callIdHex || callDataHelper.getCallIdHex(callData);

	// Transfer-To-System case.
	var originalCallId = callDataHelper.getOptionalParameter(callData, "__OriginatingCallID__");
	if (originalCallId && originalCallId != callIdHex) {
		CCSPIntegration.sfhub.commands.getCallIdKeyedUserData(originalCallId, null, "pageInfo");
		return true;
	}

	CCSPIntegration.ccsp.sfPopHelper.getScreenPop("Voice", "Incoming", callData)
	.done(function(popId) {
		screenPopManager.screenPop(callId, popId);
	})
	.fail(function(error) {
		displaySearchError(error);
	});
}

function screenPopCallData_VOIP_PD(lineId, eventName, callInfo, callData) {
	var callId = callInfo.callId || callDataHelper.getCallId(callData);


	CCSPIntegration.ccsp.sfPopHelper.getScreenPop("Voice", "Dialer", callData)
	.done(function(popId) {
		screenPopManager.screenPop(callId, popId);
	})
	.fail(function(error) {
		displaySearchError(error);
	});
}

function screenPopCallData_Chat(lineId, eventName, callInfo, callData) {
	var callId = callInfo.callId || callDataHelper.getCallId(callData);

	CCSPIntegration.ccsp.sfPopHelper.getScreenPop("Chat", "Incoming", callData)
	.done(function(popId) {
		screenPopManager.screenPop(callId, popId);
	})
	.fail(function(error) {
		displaySearchError(error);
	});
}

function screenPopCallData_Email(lineId, eventName, callInfo, callData) {
	var callId = callInfo.callId || callDataHelper.getCallId(callData);

	CCSPIntegration.ccsp.sfPopHelper.getScreenPop("Email", "Incoming", callData)
	.done(function(popId) {
		screenPopManager.screenPop(callId, popId);
	})
	.fail(function(error) {
		displaySearchError(error);
	});
}

function screenPopCallData_Callback(lineId, eventName, callInfo, callData) {
	var callId = callInfo.callId || callDataHelper.getCallId(callData);
	var callIdHex = callInfo.callIdHex || callDataHelper.getCallIdHex(callData);

	CCSPIntegration.ccsp.sfPopHelper.getScreenPop("Voice", "Incoming", callData)
	.done(function(popId) {
		screenPopManager.screenPop(callId, popId);
	})
	.fail(function(error) {
		displaySearchError(error);
	});
}

function screenPopCallData_Voicemail(lineId, eventName, callInfo, callData) {
	var callId = callInfo.callId || callDataHelper.getCallId(callData);
	var callIdHex = callInfo.callIdHex || callDataHelper.getCallIdHex(callData);

	CCSPIntegration.ccsp.sfPopHelper.getScreenPop("Voice", "Incoming", callData)
	.done(function(popId) {
		screenPopManager.screenPop(callId, popId);
	})
	.fail(function(error) {
		displaySearchError(error);
	});
}

function setClick2DialOptions(c2dOptions, dialOptions) {

	function getKeyValue(str) {
		var kv = str.split("=");
		if (kv.length === 2) {
			kv[0] = kv[0].trim().toLowerCase();
			kv[1] = kv[1].trim().toLowerCase();
			return kv;
		}
		return null;
	}

	if (!c2dOptions) {
		return;
	}

	var options = c2dOptions.split(";");
	for (var index = 0; index < options.length; ++ index) {
		var kv = getKeyValue(options[index]);
		if (kv) {
			switch (kv[0]) {
			case "confirmalways":
				dialOptions.alwaysConfirmBeforeDialing = (kv[1] === "yes");
				break;
			case "disabletransfer":
				dialOptions.disableTransferInDialAction = (kv[1] === "yes");
				break;
			default:
				break;
			}
		}
	}
}

function setTraceOption(str) {
	if (str && str.toLowerCase() === "yes") {
		$("#trace-option-section").hide();
		log.saveLoggingSetting("off");
	} else {
		$("#trace-option-section").show();
	}
}

function setTouchPointURL(url){
	$("#touchPointFrame").find('iframe').attr('src', url);
}

function hideTabs(){
	$(".psTabs").hide();
}


// called when salesforce configuration has loaded successfully.
CCSPIntegration.sforceCti.onLoadDone = function(cc, user) {

	if (typeof user.Extension === 'undefined' || parseInt(user.Extension, 10) === NaN) {
		displayAgentExtension("bad user extension");
		return;
	}

	displayAgentStatus("connecting");

	var qs = {
		"AgentUID": user.Extension,
		"UserID": user.Id,
		"CallCenterID": user.CallCenterId
	}

	if (cc.customOptions) {
		setClick2DialOptions(cc.customOptions.click2DialOptions, softphoneOptions);
		setTraceOption(cc.customOptions.hideTrace);
		if (cc.customOptions.touchPointURL && cc.customOptions.touchPointURL !== ''){
			setTouchPointURL(cc.customOptions.touchPointURL);
		}
		else {
			hideTabs();
		}

		if (!isInConsole()) {
		    hideTabs();
		}

		CCSPIntegration.ccsp.sfPopHelper.loadSearchOptions(cc.customOptions);
	} else {
		log.error("customOptions not set.");
	}
	CCSPIntegration.sfhub.init(cc.ctiServerUrl, qs);
}

// called when salesforce configuration has failed.
CCSPIntegration.sforceCti.onLoadFail = function (error) {
	displayAgentExtension("config error");
}

/**
 * Called when click-to-dial is triggered.
 * @callback
 * @param {Object} dialData
 */
CCSPIntegration.sforceCti.onClickToDial = function (dialData) {
	try {
		log.debug("CCSPIntegration.sforceCti.onClickToDial: " + dialData.number);
		actionDial(lastCallInfoStorage.getLastCallInfo(), dialData.number, dialData);
	}
	catch (e) {
		log.error("onClickToDial: error : " + (e.message || e));
	}
}

/**
 * Called when conection error in the hub.
 * @callback
 * @param {string} error
 */
CCSPIntegration.sfhub.onConnectionError = function(error) {
	log.error("onConnectionError: " + error);
}

/**
 * Called when the SignalR hub connection state changed.
 * The reconnection attempt upon the SignalR hub disconnection will be handled internally in the ccsp.ps.sfhub.js library. We do not need to take care of connection recovery in the event handler.
 * @callback
 * @param {string} stateName connection state name ("connected", "disconnected", "reconnecting", ...)
 */
CCSPIntegration.sfhub.onConnectionStateChange = function(stateName) {
	try {
		log.debug("softphone page: onConnectionStateChange: " + stateName);
		displayAgentStatus(stateName);
	}
	catch (e) {
		log.error("onConnectionStateChange: error : " + (e.message || e));
	}
}

/**
 * Called when calling a method on the hub failed.
 * @callback
 * @param {string} methoName Name of the function error occured.
 * @param {string} errorKind Error type. "invokce-error", "no-connecton-error", or "error".
 * @param {string} error Error message.
 */
CCSPIntegration.sfhub.onCommandError = function(methodName, errorKind, error) {
	var message = CCSPIntegration.sfhub.getErrorDescription(error, true);
	log.error("Command error: " + methodName + " error: " + message);
}

// called when error is reported from the hub.
CCSPIntegration.sfhub.events.ErrorReport = function(continuable, error) {
	var message;

	message = CCSPIntegration.sfhub.getErrorDescription(error, true);
	if (continuable) {
		log.warn("Warning reported from hub: " + message);
	} else {
		log.error("Error reported from hub: " + message);
	}
}

// called when the far end (CCSPAgent) is connected to or disconnected from the hub.
CCSPIntegration.sfhub.events.CCSPAgentConnectionStatus = function(isConnected) {
	displayAgentStatus(isConnected? "online" : "offline");
	if (isConnected) {
		CCSPIntegration.sfhub.commands.requestAgentInfo("");
	}
}

// called when calldata for screen pop arrives.
CCSPIntegration.sfhub.events.CallData = function(lineId, eventName, callInfo, callData) {
	// log.debug("CallData: lineId:" + lineId + ", eventName: " + eventName + ", callInfo: " + JSON.stringify(callInfo));
	// log.debug("CallData: callData:" + JSON.stringify(callData));

	var callId = callInfo.callId || callDataHelper.getCallId(callData);

	var mediaType = callInfo.mediaType;
	currentCallInfo = callInfo;
	currentCallData = callData;
	currentLineId = lineId;
	
	updateCallDetailLinkVisibility();
	displayCallInfo(callInfo, callData);

	if (isInConsole())
    CCSPIntegration.sforceCti.console.wrapper.fireOnCallBegin(callInfo, callData);


	// if the screen pop for the same call id already made, do not make screen pop again.
	if (screenPopManager.getScreenPopCallId() === callId) {
		log.info("CallData: screenPop for callId: " + callId + " has already been made.");
		return;
	}

	if (mediaType === "VOIP") {
		if (callInfo.direction === "Incoming") {
			screenPopCallData_VOIP_Incoming(lineId, eventName, callInfo, callData);
		} else if (callInfo.direction === "Predictive" || callInfo.direction === "Preview") {
			screenPopCallData_VOIP_PD(lineId, eventName, callInfo, callData);
		}
	} else if (mediaType === "Email") {
		screenPopCallData_Email(lineId, eventName, callInfo, callData);
	} else if (mediaType === "Chat") {
		screenPopCallData_Chat(lineId, eventName, callInfo, callData);
	} else if (mediaType === "Callback") {
		screenPopCallData_Callback(lineId, eventName, callInfo, callData);
	} else if (mediaType === "Voicemail") {
		screenPopCallData_Voicemail(lineId, eventName, callInfo, callData);
	}
}

// called when agent state changes.
CCSPIntegration.sfhub.events.AgentStateChange = function(state, releaseCode) {
	log.debug("AgentStateChange: state: " + state + ", releaseCode: " + releaseCode);
	displayAgentStatus(state, releaseCode);
}

// called when call state changes.
CCSPIntegration.sfhub.events.CallStateChange = function(lineId, callInfo) {
	log.debug("CallStateChange: " + JSON.stringify(callInfo));
	if (!callInfo.state || callInfo.state === 'Destructed') {
		log.debug("AgentStateChange: call terminated callId: " + callInfo.callId);
		if (currentCallInfo && currentCallInfo.callId === callInfo.callId) {
			screenPopStorage.clear(); // this will clear currentCallInfo, currentCallData and currentLineId. (not so good... to be revised.)
		}
		// ask to clear currently holding screen pop info if current screen pop is associated to the callId.
		screenPopManager.callTerminated(callInfo.callId);
	}
	else {
		// update currentCallInfo when callInfo is for the same call.
		if (currentCallInfo && currentCallInfo.callId === callInfo.callId) {
			currentCallInfo = callInfo;
			screenPopStorage.saveCallInfo(callInfo);
		}
	}

	updatePageSyncButton(callInfo);
	updateCallDetailLinkVisibility();
	displayCallInfo(callInfo);
	
	// if call on hold, save page info into the database.
	if (callInfo.mediaType === "VOIP" && callInfo.state === "OnHold") {
		CCSPIntegration.sforceCti.api.getPageInfo()
		.done(function(data){
			try {
				var pageInfo = JSON.stringify(data);
				// in order to save the page info for any call, use callInfo.callId, not currentCallInfo.callId
				CCSPIntegration.sfhub.commands.registerCallIdKeyedUserData(callInfo.callId,  null, "pageInfo",  pageInfo);
			}
			catch (e) {
				log.error("Failed to registerCallIdKeyedUserData: " + (e.message || e));
			}
		})
		.fail(function(error) {
			log.error("Failed to get pageInfo: " + error);
		});
    }
	// when Transfer from transferring agent,  get page info from DB, if not been made the screen pop by [Page Sync] button click during a2a. 
    else if (callInfo.mediaType === "VOIP" && callInfo.direction === "Incoming" && callInfo.state === "TransferComplete") {
      // if (not the screen pop for the same callId being made) { // we have to implement this check by using sessionStroage.
		CCSPIntegration.sfhub.commands.getCallIdKeyedUserData(callInfo.callId, null, "pageInfo");
    }

}


// notification to the data receiver for SendUserDataToCrmClient
// senderAgentId: agent id of the data sender. (who sent the data by calling SendUserDataToCrmClient).
// tag: user defined tag from the data sender.
// data: user data from the data sender.
CCSPIntegration.sfhub.events.UserDataFromCrmClient = function(senderAgentId, tag, data) {
	log.debug("UserDataFromCrmClient.");
	if (tag === "pageInfo") {
		try {
			if (screenPopManager.getScreenPopCallId() === callId) {
				log.debug("UserDataFromCrmClient: screen pop already being made for callId: " + callId);
				return;
			}

			log.debug("UserDataFromCrmClient: going to screen pop.");
			var pageInfo = JSON.parse(data);
			var callId = pageInfo.callId;
			var popId = screenPopManager.getPopIdFromPageInfo(pageInfo);
			log.debug("UserDataFromCrmClient: callId: " + callId + ", popId: " + popId);
			screenPopManager.screenPop(callId, popId);
		}
		catch (e) {
			log.error("Error in screen pop from pageInfo: " + (e.message || e));
		}
	}
}

// notification of the data retrieval in response to GetCallIdKeyedUserData
// senderAgentId: agent id of the data sender (who saved the data by calling RegisterCallIdKeyedUserData).
// callId: callId associated to the data, in hex (ie, 0x...)
// tag: user defined tag from the data sender.
// data: user data from the data sender.
CCSPIntegration.sfhub.events.UserDataByCallId = function(senderAgentId, callId, tag, data) {
	log.debug("UserDataByCallId. callId: " + callId + ", tag: " + tag);
	if (tag === "pageInfo") {
		try {
			if (screenPopManager.getScreenPopCallId() === callId) {
				log.debug("UserDataByCallId: screen pop already being made for callId: " + callId);
				return;
			}

			log.debug("UserDataByCallId: going to screen pop.");
		    // make a screen pop according to the page info received.
			var pageInfo = JSON.parse(data);
			var popId = screenPopManager.getPopIdFromPageInfo(pageInfo);
			log.debug("UserDataByCallId: callId: " + callId + ", popId: " + popId);
			screenPopManager.screenPop(callId, popId);
		}
		catch (e) {
			log.error("UserDataByCallId: Error in screen pop from pageInfo: " + (e.message || e));
		}
	}
}



/**
 * Called when wrapup complete.
 * @param {integer} lineId line number of the call. VoIP/Email call will be with 1 or 2, where as Chat call will be from 1 to 10.
 * @param {Object} callInfo Brief call info, for callId, direction, mediaType, etc.
 * @param {Object} callData Call object which contains full call data. see includes/CallClass.j (WA) or Ajax/Interface/Call.js (TP) on CCSP..
 * @param {Object} wrapupData contains wrapup data. { code, name, comment }
 * @param {} userData any user defined data (or customer customization dependent data).
 * @return {}
 */
CCSPIntegration.sfhub.events.WrapUpData = function(lineId, callInfo, callData, wrapupData, userData) {
	log.debug("WrapUpData: callId: " + callInfo.callId);

	if (typeof createCallHistoryFeed !== "function") {
		return;
	}

	function createOrUpdateTask(id) {
	    var createSaveLogData = createCallHistoryFeed;

	    CCSPIntegration.sforceCti.api.getPageInfo()
	        .done(function(pageInfo) {
	            log.debug("WrapUpData: getPageInfo: succeeded. going to create savelog data.");

	            var saveParams = createSaveLogData(callDataHelper, callInfo, callData, wrapupData, userData, pageInfo, id, isInConsole());
	            log.debug("WrapUpData : saveParams " + saveParams);

	            CCSPIntegration.sforceCti.api.saveLog('Task', saveParams)
	                .done(function(result) {
	                    log.debug("WrapUpData: saveLog: succeeded. result: " + result);
	                })
	                .fail(function(error) {
	                    log.error("WrapUpData: saveLog: failed. " + error);
	                });
	        })
	        .fail(function(error) {
	            log.debug("WrapUpData: getPageInfo: failed. " + error);
	        });
	}


	if (isInConsole()) {
			var createTask = true;
	    CCSPIntegration.sforceCti.console.wrapper.fireOnCallEnd(callInfo, callData, wrapupData);
	    CCSPIntegration.sforceCti.console.wrapper.onCallLogSaved(function(result) {
	            if (!createTask)
	                return; //As onCallLogSaved called everytime we save log, this makes sure, to update task only in wrapup.
	            if (result && result.id)
	                createOrUpdateTask(result.id);
	            else
	                createOrUpdateTask();
	            createTask = false;	           
	        });
	} else {
	    createOrUpdateTask();
	}

}

// called when requested call data comes.
CCSPIntegration.sfhub.events.RequestedCallDataResponse = function(resultCode, requestId, lineId, callInfo, callData) {
	log.debug("RequestedCallDataResponse: resultCode: " + resultCode + ", lineId: " + lineId + ", callInfo: " + JSON.stringify(callInfo));
	if (resultCode != "200") {
		return;
	}

	log.debug("RequestedCallDataResponse: update currentCallInfo, currentCallData, and currentLineId");
	currentCallInfo = callInfo;
	currentCallData = callData;
	currentLineId = lineId;

	updatePageSyncButton(callInfo);
	updateCallDetailLinkVisibility();
	displayCallInfo(callInfo, callData);
}

/**
 * Called when requested agent info comes.
 * @callback
 * @param {string} resultCode
 * @param {string} requestId
 * @param {Object} agentInfo
 */
CCSPIntegration.sfhub.events.RequestedAgentInfoResponse = function(resultCode, requestId, agentInfo) {

	log.debug("RequestedAgentInfoResponse: resultCode: " + resultCode);

	if (resultCode != "200") {
		log.error("RequestedAgentInfoResponse: resultCode is not 200.");
		return;
	}

	log.debug("RequestedAgentInfoResponse: " + JSON.stringify(agentInfo));
	displayAgentExtension(agentInfo.name);
	displayAgentStatus(agentInfo.state, agentInfo.releaseCode);
	// show the call info saved before unload.
	displayCallInfo(lastCallInfoStorage.restore());

	var sendCallDataRequest = false;
	if (agentInfo.lines.length > 0) {
		var lines = agentInfo.lines, lineId, screenPopCallId = screenPopManager.getScreenPopCallId();
		for (var index = 0; index < lines.length; ++ index) {
			lineId = index + 1;
			if (lineId == currentLineId && lines[index].state && lines[index].state !== "Destructed") {
				sendCallDataRequest = true;
			} else if (screenPopCallId && screenPopCallId === lines[index].callId) {
				sendCallDataRequest = true;
			}
			if (sendCallDataRequest) {
				log.debug("RequestedAgentInfoResponse: requestCallData for line: " + lineId);
				CCSPIntegration.sfhub.commands.requestCallData("", "" + lineId);
			}
		}
	}
	if (!sendCallDataRequest) {
		screenPopStorage.clear();
		updateCallDetailLinkVisibility();
	}
}

// called when returned from the requested make call request.
CCSPIntegration.sfhub.events.RequestedMakeCallResponse = function(resultCode, requestId) {
	if (resultCode != "200") {
		return;
	}
}

// called just before the CCSPAgentConnectionStatus event.
CCSPIntegration.sfhub.events.preCCSPAgentConnectionStatus = function(isConnected) {
}


// called just before the CallData event.
CCSPIntegration.sfhub.events.preCallData = function(lineId, eventName, callInfo, callData) {
	screenPopStorage.save(callInfo, callData, lineId);
}

// called just before the AgentStateChange event.
CCSPIntegration.sfhub.events.preAgentStateChange = function(state, releaseCode) {
}

// called just before the CallStateChange event.
CCSPIntegration.sfhub.events.preCallStateChange = function(lineId, callInfo) {
	log.debug("preCallStateChange:" + callInfo );
}

// called just before the WrapUpData event, arguments are still in string and not JSON.parsed'ed yet.
CCSPIntegration.sfhub.events.preWrapUpData = function(lineId, callInfo, callData, wrapupData, userData) {
}

// called just before the RequestedCallDataResponse event.
CCSPIntegration.sfhub.events.preRequestedCallDataResponse = function(resultCode, requestId, lineId, callInfo, callData) {
	if (resultCode != "200") {
		return;
	}
	log.debug("preRequestedCallDataResponse: lineId: " + lineId);
	screenPopStorage.save(callInfo, callData, lineId);
}

// called just before the RequestedAgentInfoResponse event.
CCSPIntegration.sfhub.events.preRequestedAgentInfoResponse = function(resultCode, requestId, agentInfo) {
	if (resultCode != "200") {
		return;
	}
}

// called just before the RequestedMakeCallResponse event.
CCSPIntegration.sfhub.events.preRequestedMakeCallResponse = function(resultCode, requestId) {
	if (resultCode != "200") {
		return;
	}
}

function sendPageSyncRequest() {
	if (currentCallInfo && currentCallInfo.state === "SlaveA2AInCall" && currentCallInfo.transferreeAgentGlobalId ) {
		var keyType = 1; // agent global Id.
		var agentKey = currentCallInfo.transferreeAgentGlobalId;
		log.debug("sendPageSyncRequest: sendPageInfo to agent. keyType: " + keyType + ", agentKey: " + agentKey);
		CCSPIntegration.sforceCti.api.getPageInfo()
		.done(function(data){
			log.debug("sendPageSyncRequest: getPageInfo succeeded. " + JSON.stringify(data));
			data.callId = currentCallInfo.callId;
			var pageInfo = JSON.stringify(data);
			CCSPIntegration.sfhub.commands.sendUserDataToCrmClient(keyType, agentKey, "pageInfo", pageInfo);
		})
		.fail(function(error) {
			log.error("sendPageSyncRequest: getPageInfo failed. " + (error.message || error));
		});
	}
}


function restoreTraceOption() {
	log.restoreLoggingSetting(function(logflag) {
		log.debug("restorTraceOption - " + logflag);
		if (logflag) {
			$("#radio-trace-on").prop("checked", "checked");
		} else {
			$("#radio-trace-off").prop("checked", "checked");
		}
		$("input[type='radio']").checkboxradio("refresh"); // trigger update.
	});
}

function updateTraceOption() {
	var value = $("input[name='trace-option']:checked").val();
	log.saveLoggingSetting(value);
}

/**
 * Check the requirements of the browser for this app.
 * Right now only check for localStorage and sessionStorage.
 * @return {bool} true when okay. false otherwise.
 **/
function validateBrowser() {
	if (typeof(window.sessionStorage) === "undefined" || typeof(window.localStorage) === "undefined") {
		window.alert("This web browser is not supported");
		return false;
	}
	return true;
}

/**
 * Called from child window, errorLog.html, to get recent logged messages.
 * @return {Array} messages array.
 **/
function getLogs() {
	return log.getRecentLogs();
}

function openLogWindow() {
	var w = 600, h = 200,
		left = (screen.width / 2) - (w / 2), top = (screen.height / 2) - (h / 2),
		url = Archive_path + "/errorLog.html",
		target = 'sfsoftphone_errorLog';
	return window.open(url, target, 'toolbar=no, location=no, directories=no, menubar=no, resizable=yes, scrollbars=no, copyhistory=no, width=' + w + ', height=' + h + ', top=' + top + ', left=' + left);
}

$(function() {
	log.clearError();

	if (!validateBrowser()) {
		return;
	}

	restoreTraceOption();
	$("[name='trace-option']").on("click", function() {
		updateTraceOption();
	});
	$("#trace-option-section").hide();

	log.debug("in ready sf_softphone.js");
	header$.companyLogo = $("#company-logo-div");
	header$.errorIndicator = $("#error-indicator-div");
	header$.errorIndicatorText = $("#error-indicator-popup-text");
	header$.errorIndicatorShowRecentButton = $("#error-indicator-show-recent-btn");
	updateErrorIndication();
	
	agentState$.stateText = $("#agent-stateText");
	agentState$.stateImage = $('[id$=agent-stateImage]');
	agentState$.extension = $("#agent-extension");

	callInfo$.mediaType = $("#callInfo-mediaType");
	callInfo$.direction = $("#callInfo-direction");
	callInfo$.stateText = $("#callInfo-stateText");
	callInfo$.from = $("#callInfo-from");
	callInfo$.to = $("#callInfo-to");


	callDetailPopup = $("#popup-callDetail");
	callDetailPopupLink = $("#link-popup-callDetail");
	dialActionPopup = $("#popup-dial");
	searchResultPopup = $("#popup-search-result");
	errorBoxPopup = $("#error-indicator-popup-tooltip");

	pageSyncButton = $("#link-pagesync");
	pageSyncButton.on("click", function() {
		sendPageSyncRequest();
	});
	pageSyncButton.hide();

	callDetailPopup.popup({
		shadow: false,
		positionTo: "origin"
	});

	dialActionPopup.popup({
		shadow: false,
		positionTo: "window"
	});

	searchResultPopup.popup({
		shadow: false,
		positionTo: "window"
	});
	
	callDetailPopup.on('popupafteropen', function () {
		// position callDetail popup close to left.
		callDetailPopup.popup('reposition', { positionTo: "origin", x: 0 })
		displayCallDetail(currentCallInfo, currentCallData);
	});

	header$.errorIndicatorShowRecentButton.on("click", function () {
		openLogWindow();
	});

	initDialAction();

	screenPopManager.restore();
	screenPopStorage.restore();

	displayAgentStatus("connecting");
	// displayCallInfo(); -- commented out in order to show call info after agent info retrieval.
	updateCallDetailLinkVisibility();
	CCSPIntegration.sforceCti.config.load(true);
});

