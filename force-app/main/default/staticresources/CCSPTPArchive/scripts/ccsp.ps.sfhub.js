
window.CCSPIntegration = window.CCSPIntegration || {};

CCSPIntegration.hub = CCSPIntegration.hub || {};

CCSPIntegration.hub.HubProxyClass = function(url, hubName, qs, eventHandlers, options) {
	var slice_ = Array.prototype.slice,
		self = this,
		url_ = url,
		hubName_ = hubName,
		qs_ = qs,
		selfDisconnect_ = false,
		connection_ = $.hubConnection(url_, {useDefaultPath:false}),
		hubProxy_ = connection_.createHubProxy(hubName_),
		stateEnum_ = $.signalR.connectionState,
		oldState_ = $.signalR.connectionState.disconnected,
		state_ = $.signalR.connectionState.disconnected,
		userDisconnected_ = false,
		connected_ = false,
		connectedFirstTime_ = false,
		reconnectInterval_ = options && options.reconnectInterval? options.reconnectInterval : 3000,
		maxReconnectAttempts_ = options && options.maxReconnectAttempts? options.maxReconnectAttempts : 1000000,
		reconnectAttempts_ = 0,
		i;

	connection_.qs = qs_;

	// set event handlers.
	if (eventHandlers && eventHandlers.length) {
		for (i = 0; i < eventHandlers.length; ++i) {
			hubProxy_.on(eventHandlers[i].eventName, eventHandlers[i].handler);
		}
	} else {
		// Add a dummy event.
		hubProxy_.on('prestartJSClient', function () { });
	}

	// callback handlers
	this.onConnectionStateChange = undefined;
	this.onConnectionError = undefined;
	this.onConnectedFirstTime = undefined;

	function connectionStateChange(state) {
		var stateName;
	
		state_ = state.newState;
		oldState_ = state.oldState;
		log.info("connectionStateChange newState=" + state_ + ", oldState=" + oldState_);
		connected_ = state_ === stateEnum_.connected;
		if (connected_ && !connectedFirstTime_) {
			log.info("is firstTimeConnected.");
			connectedFirstTime_ = true;
			if (self.onConnectedFirstTime) {
				self.onConnectedFirstTime();
			}
		}

		if (self.onConnectionStateChange) {
			switch (state_) {
			case stateEnum_.connecting:
				stateName = "connecting";
				break;
			case stateEnum_.connected:
				stateName = "connected";
				break;
			case stateEnum_.disconnected:
				stateName = "disconnected";
				break;
			case stateEnum_.reconnecting:
				stateName = "reconnecting";
				break;
			default:
				stateName = "unknown";
				break;
			}
			self.onConnectionStateChange(stateName);
		}

		if (state_ === stateEnum_.disconnected && !selfDisconnect_) {
			if (oldState_ === stateEnum_.connected) {
				reconnectAttempts_ = 0;
			}
			if (maxReconnectAttempts_ > 0 && reconnectAttempts_ < maxReconnectAttempts_) {
				reconnectAttempts_++;
				self.Reconnect();
			}
		}
	}

	function connectionError(error) {
		connected_ = false;

		if (self.onConnectionError) {
			self.onConnectionError(error);
		} else {
			log.warn("self.onConnectionError is undefined.");
		}
	}

	connection_.error(connectionError);
	connection_.stateChanged(connectionStateChange);

	function invokeSuccess(methodName) {
		log.debug("method call ["+ methodName + "] succeeded.");
		if (self.onInvokeSuccess) {
			self.onInvokeSuccess(methodName);
		}
	}

	function invokeError(methodName, errorKind, error) {
		log.error("method call ["+ methodName + "] failed. " + errorKind);
		if (self.onInvokeError) {
			self.onInvokeError(methodName, errorKind, error);
		}
	}

	this.Reconnect = function() {
		setTimeout(self.Connect.bind(self), reconnectInterval_);
	}

	this.Connect = function() {
		selfDisconnect_ = false;
		connection_.logging = true;
		var options = {
			jsonp:false,
			transport: "auto",
			withCredentials: true
		};
		connection_.start(options);
	}

	this.Disconnect = function() {
		selfDisconnect_ = true;
		connection_.stop();
	}

	this.Invoke = function() {
		var methodName = arguments[0], args, retval = undefined;
		try {
			if (connection_.state === stateEnum_.connected) {
				args = slice_.call(arguments);
				hubProxy_.invoke.apply(hubProxy_, args)
				.done(function(result) { retval = result; invokeSuccess(methodName); })
				.fail(function(error) {invokeError(methodName, "invoke-error", error); })
			}
			else {
				invokeError(methodName, "no-connection-error", new Error("Not connected to the hub server."));
			}
			return retval;
		}
		catch (e) {
			invokeError(methodName, "error", e);
		}
	}

	this.InvokeThrowError = function() {
		var methodName = arguments[0], args, retval = undefined;
		if (connection_.state === stateEnum_.connected) {
			args = slice_.call(arguments);
			hubProxy_.invoke.apply(hubProxy_, args)
			.done(function(result) { retval = result; invokeSuccess(methodName); })
			.fail(function(error) {invokeError(methodName, "invoke-error", error); throw error;})
		}
		else {
			throw new Error("Not connected to the hub server.");
		}
		return retval;
	}

	this.IsConnected = function() {	return connected_; }
}

CCSPIntegration.hub = CCSPIntegration.hub || {};

CCSPIntegration.sfhub = CCSPIntegration.sfhub || {};
CCSPIntegration.sfhub.hubProxyInstance = null;
CCSPIntegration.sfhub.events = CCSPIntegration.sfhub.events || {};

CCSPIntegration.sfhub.getErrorDescription = function(error, detail) {
	var d;

	if (typeof(error) !== "object") {
		return error;
	}

	if (error.source && error.source === "HubException") {
		d = error.data;
		// thrown from hub.
		// error.data.hubName -- name of the hub (SFHub)
		// error.data.hubMethod -- hub method name from which the error occured.
		// error.data.exceptionName -- name of hub exception.
		// error.data.detailMessage -- detail error message.
		// error.data.detailExceptionName -- exception type name of the error origin.
		// error.data.errorSourceClass -- class name of the error origin.
		// error.data.errorSourceMethod -- method name of the error origin.
		if (detail && d.errorSourceClass && d.errorSourceClass.length > 0) {
			return d.hubMethod + ": " + error.message + " (" + d.errorSourceClass + "." + d.errorSourceMethod + ": " + d.detailExceptionName + " - " + d.detailMessage + ")";
		} else {
			return d.hubMethod + ": " + error.message;
		}
	}
	else {
		return error.message;
	}
}

CCSPIntegration.sfhub.extractDialerRecord = function(callData, useNameMap) {
	var optpar, dialerData, nameMap, i, columnsCount, keyval,
//		keyvalPattern = /([\w]*)~\w~([^|]*)/, // [ColumnName]~N~[Value]|
		keyvalPattern = /([\w]*)~[N|Y]~(.*)/, // [ColumnName]~N~[Value] -- optimized.
		popData = [], columnName;

	function translateColumnName(nameMap, name) {
		var res = nameMap.match(new RegExp(name + "~([^|]*)"));
		return res? res[1] : name;
	}

	try {
		optpar = callData.CallInfo.OptPar;
		if (useNameMap && optpar.ColumnNameMapping) nameMap = optpar.ColumnNameMapping;
		dialerData = optpar.ScreenPopInfo.split("|");

		// there is a trailing |, do not parse the last index
		columnsCount = dialerData.length - 1;
		for (i = 0; i < columnsCount; i++) {
			keyval = dialerData[i].match(keyvalPattern);
			columnName = nameMap? translateColumnName(nameMap, keyval[1]) : keyval[1];
			popData.push({ name: columnName, value: keyval[2] });
        }
    }
    catch (e) {
		log.error("Error in extractDialerRecord: " + e.message);
    }

	return popData;
}


CCSPIntegration.sfhub.commands = CCSPIntegration.sfhub.commands || {};
CCSPIntegration.sfhub.commands.requestCallData = function(requestId, lineId) {
	if (CCSPIntegration.sfhub.hubProxyInstance) {
		CCSPIntegration.sfhub.hubProxyInstance.Invoke("requestCallData", requestId, lineId);
	}
}

CCSPIntegration.sfhub.commands.requestAgentInfo = function(requestId) {
	if (CCSPIntegration.sfhub.hubProxyInstance) {
		CCSPIntegration.sfhub.hubProxyInstance.Invoke("requestAgentInfo", requestId);
	}
}

CCSPIntegration.sfhub.commands.requestMakeCall = function(requestId, dialType, dialNumber, parametersObject) {
	var parametersObjectStr = "";
	if (CCSPIntegration.sfhub.hubProxyInstance) {
		if (typeof(parametersObject) === "object") {
			parametersObjectStr = JSON.stringify(parametersObject);
		}

		CCSPIntegration.sfhub.hubProxyInstance.Invoke("requestMakeCall", requestId, dialType, dialNumber, parametersObjectStr);
	}
}

CCSPIntegration.sfhub.commands.csaCommand = function() {
	var args = Array.prototype.slice.call(arguments);
	if (CCSPIntegration.sfhub.hubProxyInstance) {
		CCSPIntegration.sfhub.hubProxyInstance.Invoke.apply(CCSPIntegration.hubProxyInstance, args);
	}
}

CCSPIntegration.sfhub.commands.sendUserDataToCrmClient = function(keyType, agentKey, tag, data) {
	if (CCSPIntegration.sfhub.hubProxyInstance) {
		CCSPIntegration.sfhub.hubProxyInstance.Invoke("sendUserDataToCrmClient", keyType, agentKey, tag, data);
	}
}

CCSPIntegration.sfhub.commands.registerCallIdKeyedUserData = function(callId, slaveCallId, tag, data, expirationTimeout) {
	if (!expirationTimeout) {
		expirationTimeout = -1;
	}
	if (CCSPIntegration.sfhub.hubProxyInstance) {
		CCSPIntegration.sfhub.hubProxyInstance.Invoke("registerCallIdKeyedUserData", callId, slaveCallId, tag, data, expirationTimeout);
	}
}

CCSPIntegration.sfhub.commands.getCallIdKeyedUserData = function(callId, slaveCallId, tag) {
	if (CCSPIntegration.sfhub.hubProxyInstance) {
		CCSPIntegration.sfhub.hubProxyInstance.Invoke("getCallIdKeyedUserData", callId, slaveCallId, tag);
	}
}

CCSPIntegration.sfhub.init = function(url, qs, options) {
	var eventHandlers = [], sfhub = CCSPIntegration.sfhub, slice_ = Array.prototype.slice,
		createHandler = function(eventName, argsList) {
			return {
				'eventName': eventName,
				'handler': function () {
					var args = [], n, l = argsList.length,
						rawargs, preEventName = 'pre' + eventName;

					if (sfhub.events[preEventName]) {
						rawargs = slice_.call(arguments);
						try {
							sfhub.events[preEventName].apply(window, rawargs);
						}
						catch (e) {
							log.error("Error in sfhub.events." + preEventName + ": " + e.message);
						}
					}
					if (sfhub.events[eventName]) {
						for (n = 0; n < l; n++) {
							try {
								args.push((argsList[n] && arguments[n].length > 0)? JSON.parse(arguments[n]) : arguments[n]);
							}
							catch (e) {
								log.error("Error in preparing sfhub.events." + eventName + ": " + e.message);
								return;
							}
						}
						try {
							sfhub.events[eventName].apply(window, args);
						}
						catch (e) {
							log.error("Error in sfhub.events." + eventName + ": " + e.message);
						}
					}
				}
			}
		}
		
	eventHandlers.push(createHandler('CCSPAgentConnectionStatus', [0]));
	eventHandlers.push(createHandler('CallData', [0,0,1,1]));
	eventHandlers.push(createHandler('CallStateChange', [0,1]));
	eventHandlers.push(createHandler('AgentStateChange', [0,0]));
	eventHandlers.push(createHandler('RequestedCallDataResponse', [0,0,0,1,1]));
	eventHandlers.push(createHandler('RequestedAgentInfoResponse', [0,0,1]));
	eventHandlers.push(createHandler('RequestedMakeCallResponse', [0,0]));
	eventHandlers.push(createHandler('ErrorReport', [0,0]));
	eventHandlers.push(createHandler('WrapUpData', [0,1,1,1,1]));
	eventHandlers.push(createHandler('UserDataFromCrmClient', [0,0,0])); // (senderAgentId, tag, data) -- data might be beter to treate as JSON?
	eventHandlers.push(createHandler('UserDataByCallId', [0,0,0,0])); // (senderAgentId, callId, tag, data) -- data might be beter to treate as JSON?

	var hubProxy = new CCSPIntegration.hub.HubProxyClass(url, "SFHub", qs, eventHandlers, options);
	hubProxy.onConnectionError = function(error) {
		if (sfhub.onConnectionError) {
			try {
				sfhub.onConnectionError(error);
			}
			catch (e) {
				log.error("Error in sfhub.onConnectionError: " + e.message);
			}
		}
	}

	hubProxy.onConnectionStateChange = function(stateName) {
		if (sfhub.onConnectionStateChange) {
			try {
				sfhub.onConnectionStateChange(stateName);
			}
			catch (e) {
				log.error("Error in sfhub.onConnectionStateChange: " + e.message);
			}
		}
	}

	hubProxy.onConnectedFirstTime = function(state) {
		if (sfhub.onConnectedFirstTime) {
			try {
				sfhub.onConnectedFirstTime();
			}
			catch (e) {
				log.error("Error in sfhub.onConnectedFirstTime: " + e.message);
			}
		}
	}

	hubProxy.onInvokeSuccess = function(methodName) {
		if (sfhub.onCommandSuccess) {
			try {
				sfhub.onCommandSuccess(methodName);
			}
			catch (e) {
				log.error("Error in sfhub.onCommandSuccess: " + e.message);
			}
		}
	}

	hubProxy.onInvokeError = function(methodName, errorKind, error) {
		if (sfhub.onCommandError) {
			try {
				sfhub.onCommandError(methodName, errorKind, error);
			}
			catch (e) {
				log.error("Error in sfhub.onCommandError: " + e.message);
			}
		}
	}

	sfhub.hubProxyInstance = hubProxy;
	hubProxy.Connect();
}


