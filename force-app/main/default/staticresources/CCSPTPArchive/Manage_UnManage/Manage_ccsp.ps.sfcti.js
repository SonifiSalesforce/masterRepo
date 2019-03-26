
/**
 * @file ccsp.ps.sfcti.js
 * @description Salesforce CTI wrapper.
 * @copyright Enghouse Interactive, 2016
 */

window.CCSPIntegration = window.CCSPIntegration || {};

CCSPIntegration.sforceCti = CCSPIntegration.sforceCti || {};

CCSPIntegration.sforceCti.config = (function() {

	log.trace("CCSPIntegration.sforceCti.config");
	var dontUseSessionStorage = false;
	var configLoaded = false;
	var callcenterConfig = null;
	var userConfig = null;
	var configRetrievalTimeout = 10000;

	function checkPropertiesExist(target, name) {
		var i;
		for (i = 2; i < arguments.length; i++) {
			if (typeof target[arguments[i]] === 'undefined') {
				throw new Error('property [' + arguments[i] + '] is not configured in ' + name);
			}
		}
	}

	function saveToStorage0(storage, prefix, o) {
		var p, n;
		if (dontUseSessionStorage) return;
		for (p in o) {
			if (o.hasOwnProperty(p)) {
				n = prefix + p;
				storage.setItem(n, o[p]);
			}
		}
		// add flag to mark that parameter have been saved.
		storage.setItem(prefix + "saved", "saved");
	}

	function saveToStorage(storage, prefix, o) {
		var p, n;
		if (dontUseSessionStorage) return;
		
		storage.setItem(prefix + "item", JSON.stringify(o));
		// add flag to mark that parameter have been saved.
		storage.setItem(prefix + "saved", "saved");
	}

	function getConfiguration(prefix, request, retrieve, restore) {
		var d  = $.Deferred(), config = null;
		var configRetrievalTimer;

		if (window.sessionStorage && !dontUseSessionStorage) {
			config = restore(prefix, window.sessionStorage);
			if (config) {
				d.resolve(config);
				return d.promise();
			}
		}

		// set timeout for the case not runing under Salesforce or the browser is configured to call Salesforce.
		if (configRetrievalTimeout > 0) {
			configRetrievalTimer = window.setTimeout(
				function() {
					d.reject("Timed out in waiting response from Salesforce. Possibly not running under Salesforce environment, or thr browser is not configured to call Salesforce API.");
				},
				configRetrievalTimeout);
		}

		var callback = (function(deferred, retrieve) {
			return function(response) {
				var errorMessage, settings, config;
				if (configRetrievalTimer) {
					window.clearTimeout(configRetrievalTimer);
				}

				if (response.result) {
					try {
						settings = JSON.parse(response.result);
						config = retrieve(prefix, settings, window.sessionStorage);
						deferred.resolve(config);
					}
					catch (e) {
						errorMessage = "Error when parsing response.result. " + e.description? e.description : e;
						deferred.reject(errorMessage);
					}
				}
				else {
					errorMessage = response.error || "Error description not provided.";
					deferred.reject(errorMessage);
				}
				
			};
		})(d, retrieve);

		request(callback);
		return d.promise();
	}

	function getCallCenterConfiguration() {
		var prefix = "callcenter_";
		var request = function(callback) {
			sforce.interaction.cti.getCallCenterSettings(callback);
		}

		function getCustomOptions(settings) {
			var tag = "/customOptions/", tagLength = tag.length;
			var propertyName, optionName;
			var config = {};
		
			for (propertyName in settings) {
				if (propertyName.indexOf(tag) === 0) {
					optionName = propertyName.substring(tagLength);
					if (optionName.length > 0) {
						config[optionName] = settings[propertyName];
					}
				}
			}
			return config;
		}

		var retrieve = function(prefix, settings, storage) {
			var config = null;
			var serverUrlParam = "/ServerInfo/CTCServerName";
			checkPropertiesExist(settings, "CallCenterSettings", serverUrlParam);

			config = {};
			config.ctiServerUrl = settings[serverUrlParam];
			config.customOptions =  getCustomOptions(settings);
			config.searchOptions = config.customOptions.searchOptions || "";
			
			if (storage) {
				saveToStorage(storage, prefix, config);
			}
			return config;
		}

		var restore = function(prefix, storage) {
			if (typeof storage === 'undefined' || storage.getItem(prefix + "saved") !== "saved") {
				return null;
			}

			try {
				var config = JSON.parse(storage.getItem(prefix + "item"));
				// we must have ctiServerUrl at least.
				if (!config.ctiServerUrl) {
					return null;
				}
				return config;
			}
			catch (e) {
				return null;
			}
		}

		return getConfiguration(prefix, request, retrieve, restore);
	}

	function getUserConfiguration() {
		var prefix = "user_", i, t;
		

		var request = function(callback) {
			sforce.interaction.runApex('Enghouse_CCSP.AccountRetrieval', 'getUser', '', callback);
		}

		var retrieve = function(prefix, settings, storage) {
			var config = {};

			// what really need is Extension only, which represents the agent id in CCSP.
			checkPropertiesExist(settings, 'UserSettings', 'Id', 'CallCenterId', 'Extension', 'Email');

			// for user settings get all the properties
			for (i in settings) {
				if (settings.hasOwnProperty(i) && ((t = typeof settings[i]) === 'string' || t === 'number')) {
					config[i] = settings[i];
				}
			}

			if (storage) {
				saveToStorage(storage, prefix, config);
			}
			return config;
		}

		var restore = function(prefix, storage) {
			if (typeof storage === 'undefined' || storage.getItem(prefix + "saved") !== "saved") {
				return config;
			}

			try {
				var config = JSON.parse(storage.getItem(prefix + "item"));
				// what we save are, Phone, Id, CallCenterId, Extension and config.Email
				// we must have Extension at least.
				if (!config.Extension) {
					return null;
				}
				return config;
			}
			catch (e) {
				return null;
			}
		}

		return getConfiguration(prefix, request, retrieve, restore);
	} 

	var load = function(defaultClickToDial) {
		$.when(getCallCenterConfiguration(), getUserConfiguration())
			.done(function(cc, user) {
				configLoaded = true;
				callcenterConfig = cc;
				userConfig = user;
				if (defaultClickToDial) {
					CCSPIntegration.sforceCti.api.enableClickToDial(true)
					.done(function() {
						CCSPIntegration.sforceCti.api.onClickToDial(function(data) {
							if (CCSPIntegration.sforceCti.onClickToDial) {
								CCSPIntegration.sforceCti.onClickToDial(data);
							}
						});
					})
					.fail(function(error) {
						log.error("fail enableClickToDial. " + error);
					});
				}

				log.dumpobj("ccConfig", cc, true);
				log.dumpobj("userConfig", user);
				if (typeof CCSPIntegration.sforceCti.onLoadDone === 'function') {
					try {
						CCSPIntegration.sforceCti.onLoadDone(cc, user);
					}
					catch (e) {
						log.error("Error in CCSPIntegration.sforceCti.onLoadDone: " + e.message);
					}
				}
			 })
			.fail(function(error) {
				configLoaded = false;
				callcenterConfig = null;
				userConfig = null;

				if (typeof CCSPIntegration.sforceCti.onLoadFail === 'function') {
					try {
						CCSPIntegration.sforceCti.onLoadFail(error);
					}
					catch (e) {
						log.error("Error in CCSPIntegration.sforceCti.onLoadFail: " + e.message);
					}
				}
			});
	}

	return {
		'load': load,
		'isLoaded': function() { return configLoaded; },
		'callcenterConfig': function() { return callcenterConfig; },
		'userConfig': function() { return userConfig; }
	}
})();

CCSPIntegration.sforceCti.api = (function() {

// helper function to get message from thrown.
function messageInException(e) {
	if (typeof e === 'string') return e;
	return e.description || e.message || e.toString();
}

function dummyapicall(cb) {
	var response = { result: true };
	cb(response);
}

var isInConsole = function() {
	var d = $.Deferred();
	var callback = function(response) {
		if (response.error) {
			d.reject(response.error);
		} else {
			d.resolve(response.result);
		}
	}

	try {
//		dummyapicall(callback);
		sforce.interaction.isInConsole(callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var getCallcenterSettings = function() {
	var d = $.Deferred();

	var callback = function(response) {
		var settings, normalized;
		try {
			if (response.result) {
				settings = JSON.parse(response.result);
			}
			d.resolve(settings);
		}
		catch (e) {
			d.reject(messageInException(e));
		}
	}

	try {
		sforce.interaction.cti.getCallCenterSettings(callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var setSoftphoneHeight = function(h) {
	var d = $.Deferred();
	var callback = function (response) {
		if (response.error) {
			d.reject(response.error);
		} else {
			d.resolve(response.result);
		}
	};

	try {
		sforce.interaction.cti.setSoftphoneHeight(h, callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var setSoftphoneWidth = function(w) {
	var d = $.Deferred();
	var callback = function (response) {
		if (response.error) {
			d.reject(response.error);
		} else {
			d.resolve(response.result);
		}
	};

	try {
		sforce.interaction.cti.setSoftphoneWidth(w, callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var enableClickToDial = function(enable) {
	var d = $.Deferred(), methodName = enable? "enableClickToDial" : "disableClickToDial";
	var callback = function (response) {
		if (response.error) {
			d.reject(response.error);
		} else {
			d.resolve(response.result);
		}
	};

	try {
		sforce.interaction.cti[methodName](callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var onClickToDial = function(listener) {
	var callback = function (response) {
		var data;
		if (response.error) {
			return;
		}
		data = JSON.parse(response.result);
		listener(data);
	}

	sforce.interaction.cti.onClickToDial(callback);
}

var getDirectoryNumbers = function(isGlobal, callcenterName, resultSetPage, resultSetPageSize) {
	var d = $.Deferred();
	var callback = function (response) {
		var data;
		if (response.error) {
			d.reject(response.error);
		} else {
			try {
				data = JSON.parse(response.result);
				d.resolve(data);
			}
			catch (e) {
				d.reject(messageInException(e));
			}
		}
	}

	try {
		sforce.interaction.cti.getDirectoryNumbers(isGlobal, callcenterName, callback, resultSetPage, resultSetPageSize);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var getSoftphoneLayout = function() {
	var d = $.Deferred();
	var callback = function (response) {
		var data;
		if (response.error) {
			d.reject(response.error);
		} else {
			try {
				data = JSON.parse(response.result);
				d.resolve(data);
			}
			catch (e) {
				d.reject(messageInException(e));
			}
		}
	}

	try {
		sforce.interaction.cti.getSoftphoneLayout(callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var getPageInfo = function() {
	var d = $.Deferred(), data;
	var callback = function (response) {
		try {
			if (response.error) {
				d.reject(response.error);
			} else {
				data = JSON.parse(response.result);
				d.resolve(data);
			}
		}
		catch (e) {
			d.reject(messageInException(e));
		}
	}

	try {
		sforce.interaction.getPageInfo(callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var isVisible = function() {
	var d = $.Deferred();
	var callback = function (response) {
		if (response.error) {
			d.reject(response.error);
		} else {
			d.resolve(response.result);
		}
	}

	try {
		sforce.interaction.isVisible(callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var notifyInitializationComplete = function() {
	// call notifyInitializationComplete when it exists. (it seems has been added in version 29.)
	if (typeof sforce.interaction.notifyInitializationComplete === 'function') {
		sforce.interaction.notifyInitializationComplete();
	}
}

var onFocus = function(listener) {
	var callback = function(response) {
		var data;
		if (response.error) {
			return;
		}
		try {
			data = JSON.parse(response.result);
			listener(data);
		}
		catch (e) {
			log.error("onFocus error: " + messageInException(e));
			// throw e;
		}
	}

	if (listener) {
		sforce.interaction.onFocus(callback);
	}
}

var refreshPage = function() {
	var d = $.Deferred();
	var callback = function (response) {
		if (response.error) {
			d.reject(response.error);
		} else {
			d.resolve(response.result);
		}
	}

	try {
		sforce.interaction.refreshPage(callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var refreshRelatedList = function(listName) {
	var d = $.Deferred();
	var callback = function (response) {
		if (response.error) {
			d.reject(response.error);
		} else {
			d.resolve(response.result);
		}
	}

	try {
		sforce.interaction.refreshRelatedList(listName, callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var runApex = function(apexClass, methodName, methodParams) {
	var d = $.Deferred(), data;
	var callback = function (response) {
		if (!response.result) {
			d.reject(response.error);
		} else {
			try {
				data = JSON.parse(response.result);
				d.resolve(data);
			}
			catch (e) {
				d.reject(messageInException(e));
			}
		}
	}

	try {
		sforce.interaction.runApex(apexClass, methodName, methodParams, callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var saveLog = function(objName, saveParams) {
	var d = $.Deferred();
	var callback = function (response) {
		if (!response.result) {
			d.reject(response.error);
		} else {
// Looks like the description in the SF api doc for saveLog is incorrect. The test revealed resposne.result returns the new item id upon success, and response.id is undefined.
//			d.resolve(response.result, response.id);
			d.resolve(response.result);
		}
	}

	try {
		sforce.interaction.saveLog(objName, saveParams, callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var screenPop = function(url, force) {
	var d = $.Deferred();
	var callback = function (response) {
		if (response.error) {
			d.reject(response.error);
		} else {
			d.resolve(response.result);
		}
	}

	try {
		sforce.interaction.screenPop(url, force, callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var searchAndGetScreenPopUrl = function(searchParams, queryParams, callType) {
	var d = $.Deferred();
	var callback = function (response) {
		var data;
		if (response.error) {
			d.reject(response.error);
		} else {
			try {
				data = JSON.parse(response.result);
				d.resolve(data);
			}
			catch (e) {
				d.reject(messageInException(e));
			}
		}
	}

	try {
		sforce.interaction.searchAndGetScreenPopUrl(searchParams, queryParams, callType, callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var searchAndScreenPop = function(searchParams, queryParams, callType) {
	var d = $.Deferred();
	var callback = function (response) {
		var data;
		if (response.error) {
			d.reject(response.error);
		} else {
			try {
				data = JSON.parse(response.result);
				d.resolve(data);
			}
			catch (e) {
				d.reject(messageInException(e));
			}
		}
	}

	try {
		sforce.interaction.searchAndScreenPop(searchParams, queryParams, callType, callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var refreshObject = function(objectId, refreshFields, refreshRelatedLists, refreshFeed) {
	var d = $.Deferred()
	var callback = function (response) {
		var data;
		if (response.error) {
			d.reject(response.error);
		} else {
			d.resolve(response.result);
		}
	}

	try {
		sforce.interaction.entityFeed.refreshObject(objectId, refreshFields, refreshRelatedLists, refreshFeed, callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var setVisible = function(visible) {
	var d = $.Deferred()
	var callback = function (response) {
		var data;
		if (response.error) {
			d.reject(response.error);
		} else {
			d.resolve(response.result);
		}
	}

	try {
		sforce.interaction.setVisible(visible,callback);
	}
	catch (e) {
		d.reject(messageInException(e));
	}
	return d.promise();
}

var onObjectUpdate = function(listener) {
	var d = $.Deferred()
	var callback = function(response) {
		listener(response.fieldUpdated, response.relatedListsUpdated, response.feedUpdated);
	}

	sforce.interaction.entityFeed.onObjectUpdate(callback);
}

	return {
		'isInConsole': isInConsole,
		'getCallcenterSettings': getCallcenterSettings,
		'setSoftphoneHeight': setSoftphoneHeight,
		'setSoftphoneWidth': setSoftphoneWidth,
		'enableClickToDial': enableClickToDial,
		'onClickToDial': onClickToDial,
		'getDirectoryNumbers': getDirectoryNumbers,
		'getSoftphoneLayout': getSoftphoneLayout,
		'getPageInfo': getPageInfo,
		'isVisible': isVisible,
		'notifyInitializationComplete': notifyInitializationComplete,
		'onFocus': onFocus,
		'refreshPage': refreshPage,
		'refreshRelatedList': refreshRelatedList,
		'runApex': runApex,
		'saveLog': saveLog,
		'screenPop': screenPop,
		'searchAndGetScreenPopUrl': searchAndGetScreenPopUrl,
		'searchAndScreenPop': searchAndScreenPop,
		'refreshObject': refreshObject,
		'setVisible': setVisible, 
		'onObjectUpdate': onObjectUpdate
	}
})();

