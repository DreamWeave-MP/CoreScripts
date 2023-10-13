--[[
    Example usage:

    customCommandHooks.registerCommand("test", function(pid, cmd)
        dreamweave.SendMessage(pid, "You can execute a normal command!\n", false)
    end)


    customCommandHooks.registerCommand("ranktest", function(pid, cmd)
        dreamweave.SendMessage(pid, "You can execute a rank-checked command!\n", false)
    end)
    customCommandHooks.setRankRequirement("ranktest", 2) -- must be at least rank 2


    customCommandHooks.registerCommand("nametest", function(pid, cmd)
        dreamweave.SendMessage(pid, "You can execute a name-checked command!\n", false)
    end)
    customCommandHooks.setNameRequirement("nametest", {"Admin", "Kneg", "Jiub"}) -- must be one of these names

]]

---@class customCommandHooks
local customCommandHooks = {}

local specialCharacter = "/"

customCommandHooks.commands = {}
customCommandHooks.rankRequirement = {}
customCommandHooks.nameRequirement = {}


---@param cmd string Command Syntax
---@param callback string Command Response
function customCommandHooks.registerCommand(cmd, callback)
    if type(cmd) ~= "string" then return end
    customCommandHooks.commands[cmd] = callback 
end

---@param cmd string Command Syntax
function customCommandHooks.removeCommand(cmd)
    if type(cmd) ~= "string" then return end
    customCommandHooks.commands[cmd] = nil 
    customCommandHooks.rankRequirement[cmd] = nil
    customCommandHooks.nameRequirement[cmd] = nil
end

---@param cmd string Command Syntax
function customCommandHooks.getCallback(cmd)
    if type(cmd) ~= "string" then return end
    return customCommandHooks.commands[cmd]
end

---@param cmd string Command Syntax
---@param rank string Permission Level
function customCommandHooks.setRankRequirement(cmd, rank)
    if customCommandHooks.commands[cmd] == nil or type(cmd) ~= "string" then return end
    customCommandHooks.rankRequirement[cmd] = rank
end

---@param cmd string Command Syntax
function customCommandHooks.removeRankRequirement(cmd)
    customCommandHooks.rankRequirement[cmd] = nil
end

---@param cmd string Command Syntax
---@param names string Name
function customCommandHooks.setNameRequirement(cmd, names)
    if customCommandHooks.commands[cmd] ~= nil and type(cmd) ~= "string" then return end 
    customCommandHooks.nameRequirement[cmd] = names
end

function customCommandHooks.addNameRequirement(cmd, name)
    if customCommandHooks.commands[cmd] == nil and type(cmd) == "string" then return end
    
    if customCommandHooks.nameRequirement[cmd] == nil then
        customCommandHooks.nameRequirement[cmd] = {}
    end
    
    table.insert(customCommandHooks.nameRequirement[cmd], name)
end

---@param cmd string Command Syntax
function customCommandHooks.removeNameRequirement(cmd)
    customCommandHooks.nameRequirement[cmd] = nil
end

function customCommandHooks.validator(eventStatus, pid, message)
    if message:sub(1,1) == specialCharacter then
        local cmd = (message:sub(2, #message)):split(" ")
        local callback = customCommandHooks.getCallback(cmd[1])
        if callback ~= nil then
            if customCommandHooks.nameRequirement[cmd[1]] ~= nil then
                if tableHelper.containsValue(customCommandHooks.nameRequirement[cmd[1]], Players[pid].accountName) then
                    callback(pid, cmd)
                    return customEventHooks.makeEventStatus(false, nil)
                end
            elseif customCommandHooks.rankRequirement[cmd[1]] ~= nil then
                if Players[pid].data.settings.staffRank >= customCommandHooks.rankRequirement[cmd[1]] then
                    callback(pid, cmd)
                    return customEventHooks.makeEventStatus(false, nil)
                end
            else
                callback(pid, cmd)
                return customEventHooks.makeEventStatus(false, nil)
            end
        end
    end
end

customEventHooks.registerValidator("OnPlayerSendMessage", customCommandHooks.validator)

return customCommandHooks
