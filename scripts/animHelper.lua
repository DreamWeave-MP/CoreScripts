tableHelper = require("tableHelper")

--- Unsigned int representing player id
--- @class PlayerID

--- Master table for all animHelper functions
--- @class AnimHelper
--- @field GetAnimation fun(pid: PlayerID, animAlias: string): string
--- @field GetValidList fun(pid: PlayerID): string[]
local animHelper = {}

--- Literal animation names common to all races and genders
--- @class AnimTable
--- @field animNames string[]
local defaultAnimNames = { "hit1", "hit2", "hit3", "hit4", "hit5", "idle2", "idle3", "idle4",
    "idle5", "idle6", "idle7", "idle8", "idle9", "pickprobe" }

--- Animation names common to all races and genders
--- @class AnimAliases
local generalAnimAliases = { act_impatient = "idle6", check_missing_item = "idle9", examine_hand = "idle7",
    look_behind = "idle3", shift_feet = "idle2", scratch_neck = "idle4", touch_chin = "idle8",
    touch_shoulder = "idle5" }

--- Dictionary of female animation aliases mapped to their literal names
--- @class FemaleAnimAliases
local femaleAnimAliases = { adjust_hair = "idle4", touch_hip = "idle5" }

--- Dictionary of beast animation aliases mapped to their literal names
--- @class BeastAnimAliases
local beastAnimAliases = { act_confused = "idle9", look_around = "idle2", touch_hands = "idle6" }

--- Retrieve a real animation name using its alias relative to player race/gender
--- @param pid integer The playerID
--- @param animAlias string Practical name for the animation, used as a table key in the animAlias tables
--- @return string animation Literal animation name or invalid if the anim does not exist for this race/gender
function animHelper.GetAnimation(pid, animAlias)

    -- Is this animation included in the default animation names?
    if tableHelper.containsValue(defaultAnimNames, animAlias) then
        return animAlias
    else
        local race = string.lower(Players[pid].data.character.race)
        local gender = Players[pid].data.character.gender

        local isBeast = false
        local isFemale = false

        if race == "khajiit" or race == "argonian" then
            isBeast = true
        elseif gender == 0 then
            isFemale = true
        end

        if generalAnimAliases[animAlias] ~= nil then
            -- Did we use a general alias for something named differently for beasts?
            if isBeast and tableHelper.containsValue(beastAnimAliases, generalAnimAliases[animAlias]) then
                return "invalid"
            -- Did we use a general alias for something named differently for females?
            elseif isFemale and tableHelper.containsValue(femaleAnimAliases, generalAnimAliases[animAlias]) then
                return "invalid"
            else
                return generalAnimAliases[animAlias]
            end
        elseif isBeast and beastAnimAliases[animAlias] ~= nil then
            return beastAnimAliases[animAlias]
        elseif isFemale and femaleAnimAliases[animAlias] ~= nil then
            return femaleAnimAliases[animAlias]
        end
    end

    return "invalid"
end

--- Get all animations a particular player could play
--- @param pid PlayerID Player whose animation list is requested
--- @return string[] animList All literal animation names valid for this PlayerID
function animHelper.GetValidList(pid)

    local validList = {}

    local race = string.lower(Players[pid].data.character.race)
    local gender = Players[pid].data.character.gender

    local isBeast = false
    local isFemale = false

    if race == "khajiit" or race == "argonian" then
        isBeast = true
    elseif gender == 0 then
        isFemale = true
    end

    for generalAlias, defaultAnim in pairs(generalAnimAliases) do

        if (not isBeast and not isFemale) or
           (isBeast and not tableHelper.containsValue(beastAnimAliases, defaultAnim)) or
           (isFemale and not tableHelper.containsValue(femaleAnimAliases, defaultAnim)) then
            table.insert(validList, generalAlias)
        end
    end

    if isBeast then
        for beastAlias, _ in pairs(beastAnimAliases) do
            table.insert(validList, beastAlias)
        end
    end

    if isFemale then
        for femaleAlias, _ in pairs(femaleAnimAliases) do
            table.insert(validList, femaleAlias)
        end
    end

    return tableHelper.concatenateFromIndex(validList, 1, ", ")
end

--- Given a specific animation alias, play it on the target PlayerID
--- @param pid PlayerID Player to animate
--- @param animAlias string Animation to run, see AnimAliases, FemaleAnimAliases, and BeastAnimAliases classes for aliases
--- @return boolean success Whether the animation played
function animHelper.PlayAnimation(pid, animAlias)

    local defaultAnim = animHelper.GetAnimation(pid, animAlias)

    if defaultAnim ~= "invalid" then
        dreamweave.PlayAnimation(pid, defaultAnim, 0, 1, false)
        return true
    end

    return false
end

return animHelper
