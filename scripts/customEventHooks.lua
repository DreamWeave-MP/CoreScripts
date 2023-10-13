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

local previousValidatorEvents = {}
local previousHandlerEvents = {}
local previousValidatorFilePath = nil
local previousHandlerFilePath = nil

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

    if ScriptLoader.LoadedScripts[filePath] then
        --
    end

    local eventMap = customEventHooks.validators[event]
    if  not eventMap then
        customEventHooks.validators[event] = {}
        eventMap = customEventHooks.validators[event]
    end

    local validatorMap = eventMap[scriptId]
    if not validatorMap then
        eventMap[scriptId] = {}
        validatorMap = eventMap[scriptId]
    end

    if not customEventHooks.flattenedValidators[event] then
        customEventHooks.flattenedValidators[event] = {}
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

    local handlerMap = eventMap[scriptId]
    if not handlerMap then
        eventMap[scriptId] = {}
        handlerMap = eventMap[scriptId]
    end

    if not customEventHooks.flattenedHandlers[event] then
        customEventHooks.flattenedHandlers[event] = {}
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
