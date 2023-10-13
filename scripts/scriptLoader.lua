--ScriptLoader Singleton
---@class ScriptLoader
local ScriptLoader = {
    LoadedScripts = {}, ---@type table<string, unknown>
    ScriptData = {
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
    tes3mp.LogMessage(enumerations.log.VERBOSE, '[customEventHooks]: Generated ScriptID for script: "' .. filePath..'" is ' .. scriptID)

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
        ScriptLoader.LoadedScripts[filePath] = {}
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
        tes3mp.LogMessage(enumerations.log.VERBOSE, '[ScriptLoader][getScriptID]: ScriptID for script: "' .. filePath..'" is ' .. ScriptLoader.ScriptData.GeneratedScriptIds[filePath])
        return ScriptLoader.ScriptData.GeneratedScriptIds[filePath]
     else
        tes3mp.LogMessage(enumerations.log.VERBOSE, '[ScriptLoader]: ScriptID not found for script: "' .. filePath..'"')
        return ""
     end
end

function ScriptLoader.unloadScript(filePath)
    for key, _ in pairs(package.loaded[filePath]) do
        package.loaded[filePath][key] = nil
      end

      package.loaded[filePath] = nil
      ScriptLoader.LoadedScripts[filePath] = nil
end

return ScriptLoader
