        var translator = (function() {

            // mapping agent state to translated.
            // note: agent states are, unlike the others, stored here in small letters.
            var agentStatesMap = {
                connecting: "Connecting...",
                connected: "Connected",
                reconnecting: "Reconnecting...",
                disconnected: "Disconnected",
                online: "Online",
                offline: "Offline",
                available: "Available",
                availableincall: "Available",
                incall: "In Call",
                loggedout: "Logged Out",
                multiple: "Multiple",
                onhold: "On Hold",
                pending: "Pending...",
                preview: "Preview",
                released: "Released",
                releasedincall: "Released",
                releasepending: "Pending Unavailable",
                ringing: "Ringing",
                unavailable: "Released",
                wrapup: "Wrap-up"
            };

            // mapping call state to translated.
            var callStatesMap = {
                INITIALIZED: "Ringing", // not in ringing yet but show it as ringing.
                Ringing: "Ringing",
                PickUpPending: "Pick-up Pending",
                InGreeting: "Playing Greeting",
                Initializing: "Initializing",
                PickUpFromHoldPending: "Pick-up From Hold",
                Preview: "Preview",
                InCall: "Active",
                OnHold: "On Hold",
                OnHoldByDPSAgent: "On Hold",
                WrapUp: "Wrap-Up",
                Destructed: "Call Ended",
                Closed: "Idle",
                CallOutPending: "Dialing...", // not sure CallOutPending or OutPending will come, or none comes at all?
                OutPending: "Dialing...",
                BargeIn: "Barge In",
                Silent: "Silent",
                Whisper: "Whisper",
                Passive: "Passive",
                SlaveA2AInCall: "On Hold",
                TransferComplete: "Active", // "Transferred",
                Conference: "Active" // "Conference"
            };

            // mapping call direction to translated.
            var callDirectionsMap = {
                Incoming: "Incoming",
                IncomingA2A: "From Agent",
                Outgoing: "Outgoing",
                OutgoingA2A: "To Agent",
                Predictive: "Predictive",
                Preview: "Preview",
                TransferredCall: "Transferred"
            };

            // mapping mediaType (CallInfo.Type) to translated.
            var mediaTypesMap = {
                Callback: "Callback",
                Chat: "Chat",
                Email: "Email",
                Voice: "Voice",
                Voicemail: "Voicemail",
                VOIP: "Voice"
            };

            var callHistoryTextMap = {
                Completed: "Completed"
            }

            var callFromToTextMap = {
                tts: "Transfer To System",
                "Transfer To System": "Transfer To System"
            }

            function getTranslation(map, text, lcase) {
                var token = lcase ? text.toLowerCase() : text;
                if (map.hasOwnProperty(token)) {
                    return map[token];
                }
                return text;
            }

            function getSearchError(error, sfPopHelper) {
                var text;
                if (typeof(error) === "string") {
                    if (error.indexOf("SfScreenPopError:") === 0) {
                        // error is returned from sforce.screenPop API call.
                        text = "Failed to screen pop: " + error.subsring("SfScreenPopError:".length);
                    } else {
                        switch (error) {
                            case sfPopHelper.GET_SCREENPOP_REQUIRED_EMPTY:
                                text = "One or more required field for search is missing or empty.";
                                break;

                            case sfPopHelper.GET_SCREENPOP_FAILED:
                                text = "Error in the record search for screen pop. " + log.lastError();
                                break;

                            case sfPopHelper.GET_SCREENPOP_NO_SEARCH_RESULT:
                                text = "No records to screen pop found.";
                                break;

                            case sfPopHelper.GET_SCREENPOP_NOMORE_SEARCH_OPTIONS:
                                text = "No records to screen pop found.";
                                break;

                            default:
                                text = error;
                                break;
                        }
                    }
                } else {
                    text = "Unexpected error in the record search: " + (error.message || error.toString());
                }
                return text;
            }


            return {
                language: "en",
                agentState: function(state) {
                    return getTranslation(agentStatesMap, state, true);
                },
                callState: function(state) {
                    return getTranslation(callStatesMap, state);
                },
                mediaType: function(name) {
                    return getTranslation(mediaTypesMap, name);
                },
                callDirection: function(name) {
                    return getTranslation(callDirectionsMap, name);
                },
                searchError: function(error, sfPopHelper) {
                    return getSearchError(error, sfPopHelper);
                },
                callHistoryText: function(text) {
                    return getTranslation(callHistoryTextMap, text);
                },
                callFromToText: function(text) {
                    return getTranslation(callFromToTextMap, text);
                }
            }
        })();
