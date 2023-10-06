local customEventHooks = {}
local template = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

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
    for i = 1, #filePath:normalizePath() do
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

    dreamweave.LogMessage(enumerations.log.VERBOSE, string.format('[customEventHooks][validator]: Registering event "%s" with ScriptID "%s"',event, scriptID))

    if not customEventHooks.validators[event] then
        customEventHooks.validators[event] = {}
    end

    if not customEventHooks.scriptID[scriptID] then
        dreamweave.LogMessage(enumerations.log.INFO, string.format('[customEventHooks]: Registered ScriptID "%s" for script "%s"', scriptID, filePath))
        customEventHooks.scriptID[scriptID] = {}
        customEventHooks.scriptID[scriptID].validators = {}
    end

    if not customEventHooks.scriptID[scriptID].validators then
        customEventHooks.scriptID[scriptID].validators = {}
    end

    table.insert(customEventHooks.validators[event], callback)
    table.insert(customEventHooks.scriptID[scriptID].validators, {event, callback})

    return scriptID
end

function customEventHooks.registerHandler(event, callback)
    -- Retrieve the file path of the current Lua script being executed.
    local filePath = debug.getinfo(2, "S").source:sub(2):normalizePath()

    local scriptID = customEventHooks.getScriptID(filePath)
    if not scriptID then
        scriptID = customEventHooks.generateScriptID(filePath)
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
    dreamweave.LogMessage(enumerations.log.INFO, "[customEventHooks]: Unloading Handlers using ScriptID: " .. scriptID)

    -- Get the events associated with the script ID
    local scriptIDEvents = customEventHooks.scriptID[scriptID]
    if not scriptIDEvents then
        dreamweave.LogMessage(enumerations.log.INFO, "[customEventHooks]: No Handler events associated with scriptID: " .. scriptID)
        return
    end

    -- Iterate through each event and remove the handlers associated with it
    for _, eventInfo in ipairs(scriptIDEvents.handlers) do
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
    dreamweave.LogMessage(enumerations.log.INFO, "[customEventHooks]: Unregistering validators by scriptID: " .. scriptID)
    local scriptIDEvents = customEventHooks.scriptID[scriptID]

    -- If there are no events associated with the scriptID, return
    if not scriptIDEvents then
        dreamweave.LogMessage(enumerations.log.INFO, "[customEventHooks]: No validator events associated with scriptID: " .. scriptID)
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
    dreamweave.LogMessage(enumerations.log.INFO, "[customEventHooks]: Unregistering all events for scriptID: " .. scriptID)
    customEventHooks.unregisterValidatorsByScriptID(scriptID)
    customEventHooks.unregisterHandlersByScriptID(scriptID)
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
