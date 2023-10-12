local customEventHooks = {}
local template = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

-- Variables for event registration and re-registration logging
local previousValidatorEvents = {}
local previousHandlerEvents = {}
local previousValidatorFilePath = nil
local previousHandlerFilePath = nil

customEventHooks.validators = {}
customEventHooks.handlers = {}
customEventHooks.scriptID = {
    handlers = {},
    validators = {},
    generatedScriptIDs = {}
}

function customEventHooks.generateScriptID(filePath)
    if not string.match(filePath, "%S") then
        return nil
    end

    local seed = 0
    for i = 1, #filePath do
        local charCode = string.byte(filePath:normalizePath(), i)
        seed = seed + charCode
    end
    math.randomseed(os.time() + tonumber(tostring({}):sub(8), 16))

    local scriptID = template:gsub("x", function() return string.format("%x", math.random(0, 15)) end)
    customEventHooks.scriptID.generatedScriptIDs[filePath] = scriptID
    dreamweave.LogMessage(enumerations.log.VERBOSE, '[customEventHooks]: Generated ScriptID for script: "' .. filePath..'" is ' .. scriptID)
    
    return scriptID
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
    local filePath = debug.getinfo(2, "S").source:sub(2):normalizePath()

    local scriptID = customEventHooks.getScriptID(filePath)
    if not scriptID then
        scriptID = customEventHooks.generateScriptID(filePath)
    end

    -- If we are now registering a new event, check if a previous script's customEventHook registration was caused by a nested include of an already registered script.
    -- If so, we print the functions that were attempted to be re-registered, as well as the script that triggered it.
    -- Although this check does not prevent multiple registrations from happening, it highlights that the event is being included incorrectly.
    if previousValidatorFilePath and previousValidatorFilePath ~= filePath and previousValidatorEvents[previousValidatorFilePath] then 
        local callingScript = previousValidatorEvents[previousValidatorFilePath].callingScript
        local eventsConcatenated = table.concat(previousValidatorEvents[previousValidatorFilePath].events, '", "')
        if #previousValidatorEvents[previousValidatorFilePath].events > 0 then
            eventsConcatenated = '"' .. eventsConcatenated .. '"'
        end
        dreamweave.LogMessage(enumerations.log.WARN, string.format('[customEventHooks][validator]: Events [%s] from previous script "%s" called by "%s"', eventsConcatenated, previousValidatorFilePath, callingScript))
    
        previousValidatorEvents[previousValidatorFilePath] = nil
    end

    dreamweave.LogMessage(enumerations.log.VERBOSE, string.format('[customEventHooks][validator]: Registering event "%s" with ScriptID "%s"',event, scriptID))

    if not customEventHooks.validators[event] then
        customEventHooks.validators[event] = {}
    end

    if not customEventHooks.scriptID[scriptID] then
        dreamweave.LogMessage(enumerations.log.INFO, string.format('[customEventHooks]: Registered ScriptID "%s" for script "%s"', scriptID, filePath))
        customEventHooks.scriptID[scriptID] = {}
    end

    if not customEventHooks.scriptID[scriptID].validators then
        customEventHooks.scriptID[scriptID].validators = {}
    end

    -- Check if the current event already exists in the list of handlers for the current script.
    local eventExists = false
    for _, handlerInfo in ipairs(customEventHooks.scriptID[scriptID].validators) do
        if handlerInfo[1] == event then
            eventExists = true
            break
        end
    end

    -- If the current event already exists in the list of handlers for the current script,
    -- record the event and the calling script for re-registration logging.
    if eventExists then
        -- Note: This debug only works on a nested include.
        local callingScript = debug.getinfo(4, "S").source:sub(2):normalizePath()
        if previousValidatorEvents[filePath] == nil then
            previousValidatorEvents[filePath] = { callingScript = callingScript, events = {} }
        end
        table.insert(previousValidatorEvents[filePath].events, event)
    end

    table.insert(customEventHooks.validators[event], callback)
    table.insert(customEventHooks.scriptID[scriptID].validators, {event, callback})

    previousValidatorFilePath = filePath

    return scriptID
end

function customEventHooks.registerHandler(event, callback)
    -- Retrieve the file path of the current Lua script being executed.
    local filePath = debug.getinfo(2, "S").source:sub(2):normalizePath()

    local scriptID = customEventHooks.getScriptID(filePath)
    if not scriptID then
        scriptID = customEventHooks.generateScriptID(filePath)
    end

    -- If we are now registering a new event, check if a previous script's customEventHook registration was caused by a nested include of an already registered script.
    -- If so, we print the functions that were attempted to be re-registered, as well as the script that triggered it.
    -- Although this check does not prevent multiple registrations from happening, it highlights that the event is being included incorrectly.
    if previousHandlerFilePath and previousHandlerFilePath ~= filePath and previousHandlerEvents[previousHandlerFilePath] then 
        local callingScript = previousHandlerEvents[previousHandlerFilePath].callingScript
        local eventsConcatenated = table.concat(previousHandlerEvents[previousHandlerFilePath].events, '", "')
        if #previousHandlerEvents[previousHandlerFilePath].events > 0 then
            eventsConcatenated = '"' .. eventsConcatenated .. '"'
        end
        dreamweave.LogMessage(enumerations.log.WARN, string.format("[customEventHooks][handler]: Events [%s] from previous script '%s' called by '%s'", eventsConcatenated, previousHandlerFilePath, callingScript))
    
        -- Clear the table for the previousHandlerFilePath
        previousHandlerEvents[previousHandlerFilePath] = nil
    end

    dreamweave.LogMessage(enumerations.log.VERBOSE, string.format('[customEventHooks][handler]: Registering event "%s" with ScriptID "%s"',event, scriptID))

    if not customEventHooks.handlers[event] then
        customEventHooks.handlers[event] = {}
    end

    if not customEventHooks.scriptID[scriptID] then
        dreamweave.LogMessage(enumerations.log.INFO, string.format('[customEventHooks]: Registered ScriptID "%s" for script "%s"', scriptID, filePath))
        customEventHooks.scriptID[scriptID] = {}
    end

    if not customEventHooks.scriptID[scriptID].handlers then
        customEventHooks.scriptID[scriptID].handlers = {}
    end

    -- Check if the current event already exists in the list of handlers for the current script.
    local eventExists = false
    for _, handlerInfo in ipairs(customEventHooks.scriptID[scriptID].handlers) do
        if handlerInfo[1] == event then
            eventExists = true
            break
        end
    end

    -- If the current event already exists in the list of handlers for the current script,
    -- record the event and the calling script for re-registration logging.
    if eventExists then
        -- Note: This debug only works on a nested include.
        local callingScript = debug.getinfo(4, "S").source:sub(2):normalizePath()
        if previousHandlerEvents[filePath] == nil then
            previousHandlerEvents[filePath] = { callingScript = callingScript, events = {} }
        end
        table.insert(previousHandlerEvents[filePath].events, event)
    end

    table.insert(customEventHooks.handlers[event], callback)
    table.insert(customEventHooks.scriptID[scriptID].handlers, {event, callback})

    previousHandlerFilePath = filePath

    return scriptID
end

function customEventHooks.triggerInit(scriptID)
  if not customEventHooks.handlers["OnScriptLoad"] then print("No OnScriptLoad Handlers defined!") return end

  if not customEventHooks.scriptID[scriptID] then print ("Unable to find script to init!") return end

  local registeredScriptHandlers = customEventHooks.scriptID[scriptID].handlers

  for _, callback in ipairs(registeredScriptHandlers) do
    if callback[1] == "OnScriptLoad" then
      eventStatus = customEventHooks.updateEventStatus(eventStatus, callback[2](eventStatus))
    end
  end

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
function customEventHooks.unregisterEventsByType(scriptID, registerType)

  if registerType ~= "validators" and registerType ~= "handlers" then
    dreamweave.LogMessage(enumerations.log.ERROR, "[customEventHooks]: INTERNAL ERROR: Requested an invalid registration type: "
			  .. registerType .. "to clear.\nPlease report this to a developer!")
    return
  end

  dreamweave.LogMessage(enumerations.log.INFO, "[customEventHooks]: Unloading " ..
			registerType .. " using ScriptID: " .. scriptID)

  -- Get the events associated with the script ID
  local scriptIDEvents = customEventHooks.scriptID[scriptID][registerType]

  if not scriptIDEvents then
    dreamweave.LogMessage(enumerations.log.INFO, "[customEventHooks]: No " ..
			  registerType .. " associated with scriptID: " .. scriptID)
    return
  end

  -- If there are no handlers for this scriptID, or the handler isn't a table, bail
  if not scriptIDEvents or type(scriptIDEvents) ~= "table" then return end

  local registrations
  local callback

  for index, eventInfo in ipairs(scriptIDEvents) do
    registrations = customEventHooks[registerType][eventInfo[1]]
    -- Check if the handlers table exists and is not nil
    if registrations then
      table.remove(scriptIDEvents, index)
      callback = eventInfo[2]
      break
    end
  end

  for index, registration in ipairs(registrations) do
    -- Remove the handler if it matches the function being unregistered
    if registration == callback then
      table.remove(registrations, index)
      return
    end
  end
end

function customEventHooks.unregisterAllByScriptID(scriptID)
  dreamweave.LogMessage(enumerations.log.INFO, "[customEventHooks]: Unregistering all events for scriptID: " .. scriptID)
  customEventHooks.unregisterEventsByType(scriptID, "validators")
  customEventHooks.unregisterEventsByType(scriptID, "handlers")
end

function customEventHooks.getScriptID(filePath)
    if not filePath then
        return nil
    end

    local filePath = filePath:normalizePath()

    if customEventHooks.scriptID.generatedScriptIDs[filePath] then
        dreamweave.LogMessage(enumerations.log.VERBOSE, '[customEventHooks][getScriptID]: ScriptID for script: "' .. filePath..'" is ' .. customEventHooks.scriptID.generatedScriptIDs[filePath])
        return customEventHooks.scriptID.generatedScriptIDs[filePath]
     else
        dreamweave.LogMessage(enumerations.log.VERBOSE, '[customEventHooks]: ScriptID not found for script: "' .. filePath..'"')
        return nil
     end
end

return customEventHooks
