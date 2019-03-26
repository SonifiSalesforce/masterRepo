
(function() {
	var LOG_SWITCH_KEY = "logging.switch",
		LOGTAG_LAST_KEY = "logging.last-tag-number",
		LOGTAG_MAX_KEY = "logging.max-tag-number",
		LOGTAG_LASTERROR_KEY = "logging.last-error",
		LOGTAG_KEY_PREFIX = "logging.log-",
		LOG_SEP = "|||",
		arraySlice = Array.prototype.slice,
		baseErrorMethod, baseWarnMethod, baseInfoMethod, baseDebugMethod;

	var logflag = window.localStorage.getItem(LOG_SWITCH_KEY) === "on";
	// set log level here. OFF, FATAL, ERROR, WARN, INFO, DEBUG, TRACE, or ALL.
	var logLevel = log4javascript.Level.ALL;

	// the global one for the logging facility.
	window.log = log4javascript.getDefaultLogger();

	log.setLevel(logLevel);
	log4javascript.setEnabled(logflag);
	window.sessionStorage.setItem(LOGTAG_MAX_KEY, 10);

	if (log.isEnabledFor(log4javascript.Level.DEBUG)) {
		log.dumpobj = function(name, obj, deep) {
			if (!log.isEnabledFor(log4javascript.Level.DEBUG)) return;
			var i;
			if (!obj) {
				log.debug("dumpobj: " + name + " is null (or undefined, empty, etc...).");
				return;
			}

			if (typeof obj !== "object") {
				log.debug("dumpobj: " + name + " is a " + (typeof obj) + " [" + obj.toString() + "]");
				return;
			}

			log.debug("dumpobj: object " + name);
			for (i in obj) {
				if (obj.hasOwnProperty(i)) {
					switch (typeof obj[i]) {
					case 'function':
						log.debug("dumpobj: [" + i + "] => [function]");
						break;
					case 'string':
					case 'number':
						log.debug("dumpobj: [" + i + "] => [" + obj[i] + "]");
						break;
					case 'object':
						if (obj[i] instanceof Array) {
							log.debug("dumpobj: [" + i + "] => [array]");
						} else {
							log.debug("dumpobj: [" + i + "] => [object]");
						}
						if (deep) {
							log.dumpobj(name + "." + i, obj[i], true);
						}
						break;
					}
				}
			}
		};
	} else {
		log.dumpobj = function() {};
	}

	log.restoreLoggingSetting = function(callback) {
		var logflag = window.localStorage.getItem(LOG_SWITCH_KEY) === "on";
		if (callback) {
			callback(logflag);
		}
		return logflag;
	}

	log.saveLoggingSetting = function(logflag) {
		var value = "off";
		if (logflag === "on" || logflag === "true" || logflag === true) {
			value = "on";
		}
		window.localStorage.setItem(LOG_SWITCH_KEY, value);
		log4javascript.setEnabled(value === "on");
	}

	log.setMaxStorageLogs = function(n) {
		window.localStorage.setItem(LOGTAG_MAX_KEY, n);
	}

	function hhmmss() {
		var t = new Date(),
			pad = function(n) {
				return n < 10? "0" + n : n;
			};
		return pad(t.getHours()) + ":" + pad(t.getMinutes()) + ":" + pad(t.getSeconds());
	}

	function saveLogToStorage(isError, msg) {
		var tag = parseInt(window.sessionStorage.getItem(LOGTAG_LAST_KEY), 10),
			tagmax = parseInt(window.sessionStorage.getItem(LOGTAG_MAX_KEY), 10),
			logmsg = msg? hhmmss() + LOG_SEP + msg : "";

		if (isNaN(tag) || tag < 1) {
			tag = 0;
		}
		if (isNaN(tagmax) || tagmax < 1) {
			tagmax = 10;
			window.sessionStorage.setItem(LOGTAG_MAX_KEY, tagmax);
		}

		if (isError) {
			window.sessionStorage.setItem(LOGTAG_LASTERROR_KEY, logmsg);
		}

		if (++ tag > tagmax) {
			tag = 1;
		}
		window.sessionStorage.setItem(LOGTAG_LAST_KEY, tag);
		window.sessionStorage.setItem(LOGTAG_KEY_PREFIX + tag, logmsg);
		return tag;
	}

	function getLogsFromStorage() {
		var tagmax = parseInt(window.sessionStorage.getItem(LOGTAG_MAX_KEY), 10),
			tag = window.sessionStorage.getItem(LOGTAG_LAST_KEY),
			logs = [], logmsg, count;

		if (isNaN(tagmax) || tagmax < 1) tagmax = 10;
		if (isNaN(tag) || tag < 1) return logs; // no logs saved before.

		count = 0;
		for (count = 0; count < tagmax; count++) {
			var log = window.sessionStorage.getItem(LOGTAG_KEY_PREFIX + tag);
			if (log == null || log.length === 0) {
				break;
			}
			logs.push(log.split(LOG_SEP));
			tag = tag - 1;
			if (tag < 0) {
				tag = tagmax;
			}
		}
		return logs;
	}

	baseErrorMethod = log.error;
	baseWarnMethod = log.warn;
	baseInfoMethod = log.info;
	baseDebugMethod = log.debug;
	
	log.error = function(msg) {
		// This supports first argument only, though the original one supports arbitrary number of arguments.
		saveLogToStorage(true, msg);
		if (log.onError) {
			log.onError(msg);
		}
		baseErrorMethod.apply(this, arguments.length === 1? [msg] : arraySlice.call(arguments));
		console.error(msg);
	}

	log.warn = function(msg) {
		saveLogToStorage(false, msg);
		if (log.onWarn) {
			log.onWarn(msg);
		}
		baseWarnMethod.apply(this, arguments.length === 1? [msg] : arraySlice.call(arguments));
		console.warn(msg);
	}

	log.info = function(msg) {
		baseInfoMethod.apply(this, arguments.length === 1? [msg] : arraySlice.call(arguments));
		console.info(msg);
	}

	log.debug = function(msg) {
		baseDebugMethod.apply(this, arguments.length === 1? [msg] : arraySlice.call(arguments));
		console.log(msg);
	}

	log.getRecentLogs = function() {
		return getLogsFromStorage();
	}

	log.lastError = function() {
		var lastmsg = window.sessionStorage.getItem(LOGTAG_LASTERROR_KEY);
		if (lastmsg && lastmsg.length > 0) {
			return lastmsg.split(LOG_SEP)[1];
		}
		return "";
	}

	log.lastErrorExists = function() {
		return log.lastError().length > 0;
	}

	log.clearError = function() {
		saveLogToStorage(true, "");
	}

	window.onerror = function(msg, url, line) {
		log.error("ERROR: " + msg + " at [" + url + "] Line#: " + line);
		return false;
	}

})();

