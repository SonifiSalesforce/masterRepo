/**
 * @file ccsp.ps.sfconsole.js
 * @description Salesforce Console - CTI wrapper.
 * @copyright Enghouse Interactive, 2016
 */
window.CCSPIntegration = window.CCSPIntegration || {};

CCSPIntegration.sforceCti = CCSPIntegration.sforceCti || {};

CCSPIntegration.sforceCti.console = (function() {

    var settings = {
        directionToCallTypeMapping: {
            Incoming: "inbound",
            Outgoing: "outbound",
            OutDial: "outbound",
            Predictive: "outbound",
            Preview: "outbound",
            OutgoingA2A: "internal",
            IncomingA2A: "internal",
            A: "internal",
            O: "outbound"
        }
    };

    // helper function to get message from thrown.
    function messageInException(e) {
        if (typeof e === 'string') return e;
        return e.description || (e.message + " stack: " + e.stack) || e.message || e.toString();
    }

    function tryCatchWrapper(functionName, context) {
        try {
            context = context || window;
            var args = [].slice.call(arguments).splice(2);
            var namespaces = functionName.split(".");
            var func = namespaces.pop();
            for (var i = 0; i < namespaces.length; i++) {
                context = context[namespaces[i]];
            }
            return context[func].apply(context, args);
        } catch (e) {
            log.error("Error while trying to execute " + fn + " function " + messageInException(e));
        }
    };

    function defaultCallback(response) {
        try {
            if (response && response.success) {
                $.Deferred().reject(response);
            } else {
                $.Deferred().resolve(response);
            }
        } catch (e) {
            $.Deferred().reject(messageInException(e));
        }
    }

    var isInConsole = function() {
        return tryCatchWrapper("sforce.console.isInConsole") || false;
    };

    var fireOnCallBegin = function(callObjectId, callType, callLabel, callback) {
        return tryCatchWrapper("sforce.console.cti.fireOnCallBegin", window, callObjectId, callType, callLabel, callback || defaultCallback);
    };

    var fireOnCallEnd = function(callObjectId, callDuration, callDisposition, callback) {
        return tryCatchWrapper("sforce.console.cti.fireOnCallEnd", window, callObjectId, callDuration, callDisposition, callback || defaultCallback);
    };

    var onCallLogSaved = function(callback) {
        return tryCatchWrapper("sforce.console.cti.onCallLogSaved", window, callback || defaultCallback);
    };

    var setCallAttachedData = function(callObjectId, callData, callType, callback) {
        return tryCatchWrapper("sforce.console.cti.setCallAttachedData", window, callObjectId, callData, callType, callback || defaultCallback);
    };

    var getCallType = function(direction) {
        try {
            if (!direction)
                return '';
            return settings.directionToCallTypeMapping[direction] ? settings.directionToCallTypeMapping[direction] : '';
        } catch (e) {
            messageInException(e);
        }
    };

    return {
        'isInConsole': isInConsole,
        'fireOnCallBegin': fireOnCallBegin,
        'setCallAttachedData': setCallAttachedData,
        'getCallType': getCallType,
        'fireOnCallEnd': fireOnCallEnd,
        'onCallLogSaved': onCallLogSaved
    }
})();

CCSPIntegration.sforceCti.console.wrapper = (function() {
    function fireOnCallBegin(callInfo, callData) {
        try {
            if (!callInfo || !callData) {
                log.error("interactionLog_fireOnCallBegin: error: empty callInfo or callData received.");
                return;
            }

            var callType = CCSPIntegration.sforceCti.console.getCallType(callInfo.direction);
            var callId = callInfo.callId;
            var callLabel = "from: " + callInfo.from || 'unknown';

            CCSPIntegration.sforceCti.console.fireOnCallBegin(callId, callType, callLabel);
        } catch (e) {
            log.error("interactionLog_fireOnCallBegin: error: " + (e.message || e));
        }
    }

    function fireOnCallEnd(callInfo, callData, wrapupData) {
        try {
            if (!callInfo || !callData) {
                log.error("interactionLog_fireOnCallEnd: error: empty callInfo or callData received.");
                return;
            }

            var callObjectId = callInfo.callId;
            var callDisposition = (wrapupData && wrapupData.name) ? wrapupData.name : "unknown";
            var callDuration = 60;

            var callData = JSON.stringify({ "Phone": "4155551212", "DNIS": "8005551212", "SEQNO": "123" });
            sforce.console.cti.setCallAttachedData(callObjectId, callData, 'inbound');

            CCSPIntegration.sforceCti.console.fireOnCallEnd(callObjectId, callDuration, callDisposition);
        } catch (e) {
            log.error("interactionLog_fireOnCallEnd: error: " + (e.message || e));
        }
    }

    function onCallLogSaved(callback) {
        return CCSPIntegration.sforceCti.console.onCallLogSaved(callback);
    }

    function isInConsole() {
        return CCSPIntegration.sforceCti.console.isInConsole();
    }

    return {
        'fireOnCallBegin': fireOnCallBegin,
        'fireOnCallEnd': fireOnCallEnd,
        'isInConsole': isInConsole,
        'onCallLogSaved': onCallLogSaved
    }
})();
