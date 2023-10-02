local customEventHooks = {}

customEventHooks.validators = {}
customEventHooks.handlers = {}
customEventHooks.scriptID = {
	handlers = {},
	validators = {}
}

function customEventHooks.generateScriptID(filePath)
	local seed = 0
	for i = 1, #filePath do
		local charCode = string.byte(filePath, i)
		seed = seed + charCode
	end
	math.randomseed(seed)

    local template = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    return template:gsub("x", function() return string.format("%x", math.random(0, 15)) end)
end


function customEventHooks.makeEventStatus(validDefaultHandler, validCustomHandlers)
	return {
		validDefaultHandler = validDefaultHandler,
		validCustomHandlers = validCustomHandlers
	}
end

function customEventHooks.updateEventStatus(oldStatus, newStatus)
	if newStatus == nil then
		return oldStatus
	end
	local result = {}
	if newStatus.validDefaultHandler ~= nil then
		result.validDefaultHandler = newStatus.validDefaultHandler
	else
		result.validDefaultHandler = oldStatus.validDefaultHandler
	end

	if newStatus.validCustomHandlers ~= nil then
		result.validCustomHandlers = newStatus.validCustomHandlers
	else
		result.validCustomHandlers = oldStatus.validCustomHandlers
	end
	return result
end

function customEventHooks.registerValidator(event, callback)
	-- Retrieve the file path of the current Lua script being executed.
	local filePath = debug.getinfo(2, "S").source:sub(2)

	local scriptID = customEventHooks.generateScriptID(filePath)
	tes3mp.LogMessage(enumerations.log.VERBOSE, string.format('[customEventHooks][validator]: Registering event "%s" with ScriptID "%s"',event, scriptID ))

	if customEventHooks.validators[event] == nil then
		customEventHooks.validators[event] = {}
	end

	if customEventHooks.scriptID[scriptID] == nil then
		tes3mp.LogMessage(enumerations.log.INFO, string.format('[customEventHooks]: Registered ScriptID "%s" for script "%s"', scriptID, filePath))
		customEventHooks.scriptID[scriptID] = {}
	end

	if customEventHooks.scriptID[scriptID].validators == nil then
		customEventHooks.scriptID[scriptID].validators = {}
	end

	table.insert(customEventHooks.validators[event], callback)
	table.insert(customEventHooks.scriptID[scriptID].validators, {event, callback})

	return scriptID
end

function customEventHooks.registerHandler(event, callback)
	-- Retrieve the file path of the current Lua script being executed.
	local filePath = debug.getinfo(2, "S").source:sub(2)

	local scriptID = customEventHooks.generateScriptID(filePath)
	tes3mp.LogMessage(enumerations.log.VERBOSE, string.format('[customEventHooks][handler]: Registering event "%s" with ScriptID "%s"',event, scriptID))

	if customEventHooks.handlers[event] == nil then
		customEventHooks.handlers[event] = {}
	end

	if customEventHooks.scriptID[scriptID] == nil then
		tes3mp.LogMessage(enumerations.log.INFO, string.format('[customEventHooks]: Registered ScriptID "%s" for script "%s"', scriptID, filePath))
		customEventHooks.scriptID[scriptID] = {}
	end

	if customEventHooks.scriptID[scriptID].handlers == nil then
		customEventHooks.scriptID[scriptID].handlers = {}
	end

	table.insert(customEventHooks.handlers[event], callback)
	table.insert(customEventHooks.scriptID[scriptID].handlers, {event, callback})

	return scriptID
end

function customEventHooks.triggerValidators(event, args)
	local eventStatus = customEventHooks.makeEventStatus(true, true)
	if customEventHooks.validators[event] ~= nil then
		for _, callback in ipairs(customEventHooks.validators[event]) do
			eventStatus = customEventHooks.updateEventStatus(eventStatus, callback(eventStatus, unpack(args)))
		end
	end
	return eventStatus
end

function customEventHooks.triggerHandlers(event, eventStatus, args)
	if customEventHooks.handlers[event] ~= nil then
		for _, callback in ipairs(customEventHooks.handlers[event]) do
			eventStatus = customEventHooks.updateEventStatus(eventStatus, callback(eventStatus, unpack(args)))
		end
	end
end

-- Function to unregister event handlers based on a scriptID
function customEventHooks.unregisterHandlersByScriptID(scriptID)
	tes3mp.LogMessage(enumerations.log.INFO, "[customEventHooks]: Unloading Handlers using ScriptID: " .. scriptID)

	-- Get the events associated with the script ID
	local scriptIDEvents = customEventHooks.scriptID[scriptID]
	if scriptIDEvents == nil then
		return
	end

	-- Iterate through each event and remove the handlers associated with it
	for i, eventInfo in ipairs(scriptIDEvents.handlers) do
		local handlers = customEventHooks.handlers[eventInfo[1]]
		for j, handler in ipairs(handlers) do
			-- Remove the handler if it matches the function being unregistered
			if handler == eventInfo[2] then
				table.remove(handlers, j)
				break
			end
		end
	end
end

-- Function to unregister event validators based on a scriptID
function customEventHooks.unregisterValidatorsByScriptID(scriptID)
	tes3mp.LogMessage(enumerations.log.INFO, "[customEventHooks]: Unregistering validators by scriptID: " .. scriptID)
	local scriptIDEvents = customEventHooks.scriptID[scriptID]

	-- If there are no events associated with the scriptID, return
	if scriptIDEvents == nil then
		return
	end

	-- Iterate through the events and their validators
	for i, eventInfo in ipairs(scriptIDEvents.validators) do
		local validators = customEventHooks.validators[eventInfo[1]]
		for j, validator in ipairs(validators) do
			-- Remove the validator if it matches the function being unregistered
			if validator == eventInfo[2] then
				table.remove(validators, j)
				break
			end
		end
	end
end

function customEventHooks.unregisterAllByScriptID(scriptID)
	customEventHooks.unregisterValidatorsByScriptID(scriptID)
	customEventHooks.unregisterHandlersByScriptID(scriptID)
end


function customEventHooks.getscriptID(scriptName)
	local ScriptID = customEventHooks.generateScriptID(scriptName)
	tes3mp.LogMessage(enumerations.log.INFO, "[customEventHooks]: Getting ScriptID for script: " .. scriptName)

	for ScriptID, eventLists in pairs(customEventHooks.scriptID) do
		if ScriptID == ScriptID then
			return ScriptID
		end
	end
	return nil
end
return customEventHooks
