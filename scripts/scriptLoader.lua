--ScriptLoader Singleton
---@class ScriptLoader
local ScriptLoader = {
    ScriptData = {
        Handlers = {},
        Validators = {},
        GeneratedScriptIds = {}, ---@type table<string, string> Mapping of filepath to script Id
    },
}
local template = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

---@param filePath string File path to load
---@return string|nil ScriptID
function ScriptLoader.generateScriptId(filePath)
    if not string.match(filePath, "%S") then
        return "" -- should throw, this is bad if we fail this?
    end

    local seed = 0
    for i = 1, #filePath do
        local charCode = string.byte(filePath:normalizePath(), i)
        seed = seed + charCode
    end
    math.randomseed(seed)

    local scriptID = template:gsub("x", function() return string.format("%x", math.random(0, 15)) end)
    ScriptLoader.ScriptData.GeneratedScriptIds[filePath] = scriptID
    dreamweave.LogMessage(enumerations.log.VERBOSE, '[customEventHooks]: Generated ScriptID for script: "' .. filePath..'" is ' .. scriptID)

    return scriptID
end

function ScriptLoader.isScriptLoaded(filePath)
    if package.loaded[filePath] then
        return true
    end
    return false
end

---@param filePath string
---@return boolean isValid If script can be loaded
---@return string|nil errorMessage error message for why script wasn't loaded
function ScriptLoader.canLoadScript(filePath)
    if package.loaded[filePath] then
        return false, "Package already laoded"
    end

    return true, nil
end

---@param filePath string
---@return boolean Result is successful
function ScriptLoader.loadScript(filePath)
    local result = prequire(filePath)
    if result then
        -- TODO: implement
        eventHandler.OnScriptLoad(filePath)
        return true
    else
        return false
    end
end

function ScriptLoader.getScriptId(filePath)
    if not filePath then
        return ""
    end

    local filePath = filePath:normalizePath()

    if ScriptLoader.ScriptData.GeneratedScriptIds[filePath] then
        dreamweave.LogMessage(enumerations.log.VERBOSE, '[ScriptLoader][getScriptID]: ScriptID for script: "' .. filePath..'" is ' .. ScriptLoader.ScriptData.GeneratedScriptIds[filePath])
        return ScriptLoader.ScriptData.GeneratedScriptIds[filePath]
     else
        dreamweave.LogMessage(enumerations.log.VERBOSE, '[ScriptLoader]: ScriptID not found for script: "' .. filePath..'"')
        return ""
     end
end

-- TODO: figure out wtf this was supposed to be doing
function ScriptLoader.unloadScript(filePath)
    -- Local objects that use functions from the script we are reloading
    -- will keep their references to the old versions of those functions if
    -- we do this:
    --
    -- package.loaded[scriptName] = nil
    -- require(scriptName)
    --
    -- To get around that, we load up the script with dofile() instead and
    -- then update the function references in package.loaded[scriptName], which
    -- in turn also changes them in the local objects
    --
    local scriptPath = package.searchpath(filePath, package.path)
    local scriptId = ScriptLoader.getScriptId(filePath) or ScriptLoader.generateScriptId(filePath)

    local result = dofile(scriptPath)

    for key, value in pairs(package.loaded[filePath]) do
        if result[key] == nil then
            package.loaded[filePath][key] = nil
        end
    end

    for key, value in pairs(result) do
        package.loaded[filePath][key] = value
    end

    ScriptLoader.triggerInit(scriptID)
end

function ScriptLoader.triggerInit(scriptID)
    if not ScriptLoader.handlers["OnScriptLoad"] then print("No OnScriptLoad Handlers defined!") return end

    if not ScriptLoader.ScriptData[scriptID] then print ("Unable to find script to init!") return end

    local registeredScriptHandlers = ScriptLoader.ScriptData[scriptID].Handlers

    for _, callback in ipairs(registeredScriptHandlers) do
      if callback[1] == "OnScriptLoad" then
        eventStatus = ScriptLoader.updateEventStatus(eventStatus, callback[2](eventStatus))
      end
    end
end

return ScriptLoader
