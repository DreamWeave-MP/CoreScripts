local ScriptLoader = require('scriptLoader')

---@class CustomEventHooks
---@field validators table<string, table<string, function[]>> Map of event to source to callbacks
---@field handlers table<string, table<string, function[]>> Map of event to source to callbacks
local customEventHooks = {
    validators = {},
    handlers = {},
}

--TODO: currently, this is hard coupled to scriptloader. Determine if this is okay

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
    local filePath = debug.getinfo(2, "S").source:sub(2):normalizePath()
    local scriptId = ScriptLoader.getScriptId(filePath) or ScriptLoader.generateScriptId(filePath)

    local validatorMap = customEventHooks.validators[event][scriptId]
    if not validatorMap then
        customEventHooks.validators[event][scriptId] = {}
        validatorMap = customEventHooks.validators[event][scriptId]
    end

    table.insert(validatorMap, callback)

    return scriptId
end

function customEventHooks.registerHandler(event, callback)
    local filePath = debug.getinfo(2, "S").source:sub(2):normalizePath()
    local scriptId = ScriptLoader.getScriptId(filePath) or ScriptLoader.generateScriptId(filePath)

    local handlerMap = customEventHooks.handlers[event][scriptId]
    if not handlerMap then
        customEventHooks.handlers[event][scriptId] = {}
        handlerMap = customEventHooks.handlers[event][scriptId]
    end

    table.insert(handlerMap, callback)

    return scriptId
end

-- TODO: wtf
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

-- TODO: why is this not useing varargs?
function customEventHooks.triggerValidators(event, args)
    local eventStatus = customEventHooks.makeEventStatus(true, true)
    if customEventHooks.validators[event] ~= nil then
        for _, scriptId in ipairs(customEventHooks.validators[event]) do
            for _, callback in ipairs(customEventHooks.validators[event][scriptId]) do
                eventStatus = customEventHooks.updateEventStatus(eventStatus, callback(eventStatus, unpack(args)))
            end
        end
    end
    return eventStatus
end

-- TODO: why is this not useing varargs?
function customEventHooks.triggerHandlers(event, eventStatus, args)
    if customEventHooks.handlers[event] ~= nil then
        for _, scriptId in ipairs(customEventHooks.handlers[event]) do
            for _, callback in ipairs(customEventHooks.handlers[event][scriptId]) do
                eventStatus = customEventHooks.updateEventStatus(eventStatus, callback(eventStatus, unpack(args)))
            end
        end
    end
end

function customEventHooks.unregisterValidatorsByScriptId(scriptId)
    for _, event in ipairs(customEventHooks.validators) do
        if customEventHooks.validators[event][scriptId] then
            customEventHooks.validators[event][scriptId] = nil
        end
    end
end

function customEventHooks.unregisterHandlersByScriptId(scriptId)
    for _, event in ipairs(customEventHooks.handlers) do
        if customEventHooks.handlers[event][scriptId] then
            customEventHooks.handlers[event][scriptId] = nil
        end
    end
end

function customEventHooks.unregisterAllByScriptId(scriptId)
  dreamweave.LogMessage(enumerations.log.INFO, "[customEventHooks]: Unregistering all events for scriptID: " .. scriptId)
  customEventHooks.unregisterValidatorsByScriptId(scriptId)
  customEventHooks.unregisterHandlersByScriptId(scriptId)
end

return customEventHooks
