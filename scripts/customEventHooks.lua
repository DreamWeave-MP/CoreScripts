local ScriptLoader = require('scriptLoader')

---@class CustomEventHooks
---@field validators table<string, table<string, function[]>> Map of event to source to callbacks
---@field handlers table<string, table<string, function[]>> Map of event to source to callbacks
---@field flattenedValidators table<string, function[]>
---@field flattenedHandlers table<string, function[]>
local customEventHooks = {
    validators = {},
    handlers = {},
    flattenedHandlers = {},
    flattenedValidators = {},
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

    local eventMap = customEventHooks.validators[event]
    if  not eventMap then
        customEventHooks.validators[event] = {}
        eventMap = customEventHooks.validators[event]
    end

    local validatorMap = customEventHooks.validators[event][scriptId]
    if not validatorMap then
        customEventHooks.validators[event][scriptId] = {}
        validatorMap = customEventHooks.validators[event][scriptId]
    end

    table.insert(validatorMap, callback)
    table.insert(customEventHooks.flattenedValidators[event], callback)

    return scriptId
end

function customEventHooks.registerHandler(event, callback)
    local filePath = debug.getinfo(2, "S").source:sub(2):normalizePath()
    local scriptId = ScriptLoader.getScriptId(filePath) or ScriptLoader.generateScriptId(filePath)

    local eventMap = customEventHooks.handlers[event]
    if  not eventMap then
        customEventHooks.handlers[event] = {}
        eventMap = customEventHooks.handlers[event]
    end

    local handlerMap = customEventHooks.handlers[event][scriptId]
    if not handlerMap then
        customEventHooks.handlers[event][scriptId] = {}
        handlerMap = customEventHooks.handlers[event][scriptId]
    end

    table.insert(handlerMap, callback)
    table.insert(customEventHooks.flattenedHandlers[event], callback)

    return scriptId
end

-- TODO: why is this not useing varargs?
function customEventHooks.triggerValidators(event, args)
    local eventStatus = customEventHooks.makeEventStatus(true, true)
    if customEventHooks.validators[event] ~= nil then
        for _, callback in ipairs(customEventHooks.flattenedValidators[event]) do
            eventStatus = customEventHooks.updateEventStatus(eventStatus, callback(eventStatus, unpack(args)))
        end
    end
    return eventStatus
end

-- TODO: why is this not useing varargs?
function customEventHooks.triggerHandlers(event, eventStatus, args)
    if customEventHooks.handlers[event] ~= nil then
        for _, callback in ipairs(customEventHooks.flattenedHandlers[event]) do
            eventStatus = customEventHooks.updateEventStatus(eventStatus, callback(eventStatus, unpack(args)))
        end
    end
end

function customEventHooks.unregisterValidatorsByScriptId(scriptId)
    for _, event in ipairs(customEventHooks.validators) do
        if customEventHooks.validators[event][scriptId] then
            customEventHooks.validators[event][scriptId] = nil

            customEventHooks.flattenedValidators[event] = {}
            for _, scriptId in ipairs(customEventHooks.validators[event]) do
                for _, callback in ipairs(customEventHooks.validators[event][scriptId]) do
                    table.insert(customEventHooks.flattenedValidators[event], callback)
                end
            end
        end
    end
end

function customEventHooks.unregisterHandlersByScriptId(scriptId)
    for _, event in ipairs(customEventHooks.handlers) do
        if customEventHooks.handlers[event][scriptId] then
            customEventHooks.handlers[event][scriptId] = nil

            customEventHooks.flattenedHandlers[event] = {}
            for _, scriptId in ipairs(customEventHooks.handlers[event]) do
                for _, callback in ipairs(customEventHooks.handlers[event][scriptId]) do
                    table.insert(customEventHooks.flattenedHandlers[event], callback)
                end
            end
        end
    end
end

function customEventHooks.unregisterAllByScriptId(scriptId)
  tes3mp.LogMessage(enumerations.log.INFO, "[customEventHooks]: Unregistering all events for scriptID: " .. scriptId)
  customEventHooks.unregisterValidatorsByScriptId(scriptId)
  customEventHooks.unregisterHandlersByScriptId(scriptId)
end

return customEventHooks
