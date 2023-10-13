local commandHandler = {}

function commandHandler.ProcessCommand(pid, cmd)

    if cmd[1] == nil then
        local message = "Please use a command after the / symbol.\n"
        dreamweave.SendMessage(pid, color.Error .. message .. color.Default, false)
        return false
    else
        -- The command itself should always be lowercase
        cmd[1] = string.lower(cmd[1])
    end

    local serverOwner = false
    local admin = false
    local moderator = false

    if Players[pid]:IsServerOwner() then
        serverOwner = true
        admin = true
        moderator = true
    elseif Players[pid]:IsAdmin() then
        admin = true
        moderator = true
    elseif Players[pid]:IsModerator() then
        moderator = true
    end

    if (cmd[1] == "teleport" or cmd[1] == "tp") and moderator then
        if cmd[2] ~= "all" then
            logicHandler.TeleportToPlayer(pid, cmd[2], pid)
        else
            for iteratorPid, player in pairs(Players) do
                if iteratorPid ~= pid then
                    if player:IsLoggedIn() then
                        logicHandler.TeleportToPlayer(pid, iteratorPid, pid)
                    end
                end
            end
        end

    elseif (cmd[1] == "teleportto" or cmd[1] == "tpto") and moderator then
        logicHandler.TeleportToPlayer(pid, pid, cmd[2])

    elseif (cmd[1] == "setauthority" or cmd[1] == "setauth") and moderator and #cmd > 2 then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then
            local cellDescription = tableHelper.concatenateFromIndex(cmd, 3)

            -- Get rid of quotation marks
            cellDescription = string.gsub(cellDescription, '"', '')

            if logicHandler.IsCellLoaded(cellDescription) == true then
                local targetPid = tonumber(cmd[2])
                logicHandler.SetCellAuthority(targetPid, cellDescription)
            else
                dreamweave.SendMessage(pid, "Cell \"" .. cellDescription .. "\" isn't loaded!\n", false)
            end
        end

    elseif cmd[1] == "kick" and moderator then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then
            local targetPid = tonumber(cmd[2])
            local message

            if Players[targetPid]:IsAdmin() then
                message = "You cannot kick an Admin from the server.\n"
                dreamweave.SendMessage(pid, message, false)
            elseif Players[targetPid]:IsModerator() and not admin then
                message = "You cannot kick a fellow Moderator from the server.\n"
                dreamweave.SendMessage(pid, message, false)
            else
                message = logicHandler.GetChatName(targetPid) .. " was kicked from the server by " ..
                    logicHandler.GetChatName(pid) .. ".\n"
                dreamweave.SendMessage(pid, message, true)
                Players[targetPid]:Kick()
            end
        end

    elseif cmd[1] == "addadmin" and serverOwner then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then
            local targetPid = tonumber(cmd[2])
            local targetName = Players[targetPid].name
            local message

            if Players[targetPid]:IsAdmin() then
                message = targetName .. " is already an Admin.\n"
                dreamweave.SendMessage(pid, message, false)
            else
                message = targetName .. " was promoted to Admin!\n"
                dreamweave.SendMessage(pid, message, true)
                Players[targetPid].data.settings.staffRank = 2
                Players[targetPid]:QuicksaveToDrive()
            end
        end

    elseif cmd[1] == "removeadmin" and serverOwner then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then
            local targetPid = tonumber(cmd[2])
            local targetName = Players[targetPid].name
            local message

            if Players[targetPid]:IsServerOwner() then
                message = "Cannot demote " .. targetName .. " because they are a Server Owner.\n"
                dreamweave.SendMessage(pid, message, false)
            elseif Players[targetPid]:IsAdmin() then
                message = targetName .. " was demoted from Admin to Moderator!\n"
                dreamweave.SendMessage(pid, message, true)
                Players[targetPid].data.settings.staffRank = 1
                Players[targetPid]:QuicksaveToDrive()
            else
                message = targetName .. " is not an Admin.\n"
                dreamweave.SendMessage(pid, message, false)
            end
        end

    elseif cmd[1] == "addmoderator" and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then
            local targetPid = tonumber(cmd[2])
            local targetName = Players[targetPid].name
            local message

            if Players[targetPid]:IsAdmin() then
                message = targetName .. " is already an Admin.\n"
                dreamweave.SendMessage(pid, message, false)
            elseif Players[targetPid]:IsModerator() then
                message = targetName .. " is already a Moderator.\n"
                dreamweave.SendMessage(pid, message, false)
            else
                message = targetName .. " was promoted to Moderator!\n"
                dreamweave.SendMessage(pid, message, true)
                Players[targetPid].data.settings.staffRank = 1
                Players[targetPid]:QuicksaveToDrive()
            end
        end

    elseif cmd[1] == "removemoderator" and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then
            local targetPid = tonumber(cmd[2])
            local targetName = Players[targetPid].name
            local message

            if Players[targetPid]:IsAdmin() then
                message = "Cannot demote " .. targetName .. " because they are an Admin.\n"
                dreamweave.SendMessage(pid, message, false)
            elseif Players[targetPid]:IsModerator() then
                message = targetName .. " was demoted from Moderator!\n"
                dreamweave.SendMessage(pid, message, true)
                Players[targetPid].data.settings.staffRank = 0
                Players[targetPid]:QuicksaveToDrive()
            else
                message = targetName .. " is not a Moderator.\n"
                dreamweave.SendMessage(pid, message, false)
            end
        end

    elseif cmd[1] == "setrace" and admin then

        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local newRace = tableHelper.concatenateFromIndex(cmd, 3)

            Players[targetPid].data.character.race = newRace
            dreamweave.SetRace(targetPid, newRace)
            dreamweave.SetResetStats(targetPid, false)
            dreamweave.SendBaseInfo(targetPid)
        end

    elseif cmd[1] == "sethead" and admin then

        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local newHead = tableHelper.concatenateFromIndex(cmd, 3)

            Players[targetPid].data.character.head = newHead
            dreamweave.SetHead(targetPid, newHead)
            dreamweave.SetResetStats(targetPid, false)
            dreamweave.SendBaseInfo(targetPid)
        end

    elseif cmd[1] == "sethair" and admin then

        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local newHair = tableHelper.concatenateFromIndex(cmd, 3)

            Players[targetPid].data.character.hair = newHair
            dreamweave.SetHair(targetPid, newHair)
            dreamweave.SetResetStats(targetPid, false)
            dreamweave.SendBaseInfo(targetPid)
        end

    elseif cmd[1] == "setattr" and moderator then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then
            local targetPid = tonumber(cmd[2])
            local targetName = Players[targetPid].name

            if cmd[3] ~= nil and cmd[4] ~= nil and tonumber(cmd[4]) ~= nil then
                local attrId
                local value = tonumber(cmd[4])

                if tonumber(cmd[3]) ~= nil then
                    attrId = tonumber(cmd[3])
                else
                    attrId = dreamweave.GetAttributeId(cmd[3])
                end

                if attrId ~= -1 and attrId < dreamweave.GetAttributeCount() then
                    dreamweave.SetAttributeBase(targetPid, attrId, value)
                    dreamweave.SendAttributes(targetPid)

                    local message = targetName .. "'s " .. dreamweave.GetAttributeName(attrId) ..
                        " is now " .. value .. "\n"
                    dreamweave.SendMessage(pid, message, true)
                    local attributeName = dreamweave.GetAttributeName(attrId)
                    Players[targetPid].data.attributes[attributeName].base = value
                end
            end
        end

    elseif cmd[1] == "setskill" and moderator then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then
            local targetPid = tonumber(cmd[2])
            local targetName = Players[targetPid].name

            if cmd[3] ~= nil and cmd[4] ~= nil and tonumber(cmd[4]) ~= nil then
                local skillId
                local value = tonumber(cmd[4])

                if tonumber(cmd[3]) ~= nil then
                    skillId = tonumber(cmd[3])
                else
                    skillId = dreamweave.GetSkillId(cmd[3])
                end

                if skillId ~= -1 and skillId < dreamweave.GetSkillCount() then
                    dreamweave.SetSkillBase(targetPid, skillId, value)
                    dreamweave.SendSkills(targetPid)

                    local message = targetName .. "'s " .. dreamweave.GetSkillName(skillId) ..
                        " is now " .. value .. "\n"
                    dreamweave.SendMessage(pid, message, true)
                    local skillName = dreamweave.GetSkillName(skillId)
                    Players[targetPid].data.skills[skillName].base = value
                end
            end
        end

    elseif cmd[1] == "setmomentum" and moderator then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local xValue = tonumber(cmd[3])
            local yValue = tonumber(cmd[4])
            local zValue = tonumber(cmd[5])

            if type(xValue) == "number" and type(yValue) == "number" and
               type(zValue) == "number" then

                dreamweave.SetMomentum(targetPid, xValue, yValue, zValue)
                dreamweave.SendMomentum(targetPid)
            else
                dreamweave.SendMessage(pid, "Not a valid argument. Use /setmomentum <pid> <x> <y> <z>\n", false)
            end
        end

    elseif cmd[1] == "setext" and admin then
        dreamweave.SetExterior(pid, cmd[2], cmd[3])

    elseif cmd[1] == "getpos" and moderator then
        logicHandler.PrintPlayerPosition(pid, cmd[2])

    elseif (cmd[1] == "setdifficulty" or cmd[1] == "setdiff") and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local difficulty = cmd[3]

            if type(tonumber(difficulty)) == "number" then
                difficulty = tonumber(difficulty)
            end

            if difficulty == "default" or type(difficulty) == "number" then
                Players[targetPid]:SetDifficulty(difficulty)
                Players[targetPid]:LoadSettings()
                dreamweave.SendMessage(pid, "Difficulty for " .. Players[targetPid].name .. " is now " ..
                    difficulty .. "\n", true)
            else
                dreamweave.SendMessage(pid, "Not a valid argument. Use /setdifficulty <pid> <value>\n", false)
                return false
            end
        end

    elseif cmd[1] == "setconsole" and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local targetName = ""
            local state = ""

            if cmd[3] == "on" then
                Players[targetPid]:SetConsoleAllowed(true)
                state = " enabled.\n"
            elseif cmd[3] == "off" then
                Players[targetPid]:SetConsoleAllowed(false)
                state = " disabled.\n"
            elseif cmd[3] == "default" then
                Players[targetPid]:SetConsoleAllowed("default")
                state = " reset to default.\n"
            else
                 dreamweave.SendMessage(pid, "Not a valid argument. Use /setconsole <pid> on/off/default\n", false)
                 return false
            end

            Players[targetPid]:LoadSettings()
            dreamweave.SendMessage(pid, "Console for " .. Players[targetPid].name .. state, false)
            if targetPid ~= pid then
                dreamweave.SendMessage(targetPid, "Console" .. state, false)
            end
        end

    elseif cmd[1] == "setbedrest" and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local targetName = ""
            local state = ""

            if cmd[3] == "on" then
                Players[targetPid]:SetBedRestAllowed(true)
                state = " enabled.\n"
            elseif cmd[3] == "off" then
                Players[targetPid]:SetBedRestAllowed(false)
                state = " disabled.\n"
            elseif cmd[3] == "default" then
                Players[targetPid]:SetBedRestAllowed("default")
                state = " reset to default.\n"
            else
                 dreamweave.SendMessage(pid, "Not a valid argument. Use /setbedrest <pid> on/off/default\n", false)
                 return false
            end

            Players[targetPid]:LoadSettings()
            dreamweave.SendMessage(pid, "Bed resting for " .. Players[targetPid].name .. state, false)
            if targetPid ~= pid then
                dreamweave.SendMessage(targetPid, "Bed resting" .. state, false)
            end
        end

    elseif (cmd[1] == "setwildernessrest" or cmd[1] == "setwildrest") and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local targetName = ""
            local state = ""

            if cmd[3] == "on" then
                Players[targetPid]:SetWildernessRestAllowed(true)
                state = " enabled.\n"
            elseif cmd[3] == "off" then
                Players[targetPid]:SetWildernessRestAllowed(false)
                state = " disabled.\n"
            elseif cmd[3] == "default" then
                Players[targetPid]:SetWildernessRestAllowed("default")
                state = " reset to default.\n"
            else
                 dreamweave.SendMessage(pid, "Not a valid argument. Use /setwildrest <pid> on/off/default\n", false)
                 return false
            end

            Players[targetPid]:LoadSettings()
            dreamweave.SendMessage(pid, "Wilderness resting for " .. Players[targetPid].name .. state, false)
            if targetPid ~= pid then
                dreamweave.SendMessage(targetPid, "Wilderness resting" .. state, false)
            end
        end

    elseif cmd[1] == "setwait" and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local targetName = ""
            local state = ""

            if cmd[3] == "on" then
                Players[targetPid]:SetWaitAllowed(true)
                state = " enabled.\n"
            elseif cmd[3] == "off" then
                Players[targetPid]:SetWaitAllowed(false)
                state = " disabled.\n"
            elseif cmd[3] == "default" then
                Players[targetPid]:SetWaitAllowed("default")
                state = " reset to default.\n"
            else
                 dreamweave.SendMessage(pid, "Not a valid argument. Use /setwait <pid> on/off/default\n", false)
                 return false
            end

            Players[targetPid]:LoadSettings()
            dreamweave.SendMessage(pid, "Waiting for " .. Players[targetPid].name .. state, false)
            if targetPid ~= pid then
                dreamweave.SendMessage(targetPid, "Waiting" .. state, false)
            end
        end

    elseif (cmd[1] == "setphysicsfps" or cmd[1] == "setphysicsframerate") and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local physicsFramerate = cmd[3]

            if type(tonumber(physicsFramerate)) == "number" then
                physicsFramerate = tonumber(physicsFramerate)
            end

            if physicsFramerate == "default" or type(physicsFramerate) == "number" then
                Players[targetPid]:SetPhysicsFramerate(physicsFramerate)
                Players[targetPid]:LoadSettings()
                dreamweave.SendMessage(pid, "Physics framerate for " .. Players[targetPid].name
                    .. " is now " .. physicsFramerate .. "\n", true)
            else
                dreamweave.SendMessage(pid, "Not a valid argument. Use /setphysicsfps <pid> <value>\n", false)
                return false
            end
        end

    elseif (cmd[1] == "setloglevel" or cmd[1] == "setenforcedloglevel") and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local logLevel = cmd[3]

            if type(tonumber(logLevel)) == "number" then
                logLevel = tonumber(logLevel)
            end

            if logLevel == "default" or type(logLevel) == "number" then
                Players[targetPid]:SetEnforcedLogLevel(logLevel)
                Players[targetPid]:LoadSettings()
                dreamweave.SendMessage(pid, "Enforced log level for " .. Players[targetPid].name
                    .. " is now " .. logLevel .. "\n", true)
            else
                dreamweave.SendMessage(pid, "Not a valid argument. Use /setloglevel <pid> <value>\n", false)
                return false
            end
        end

    elseif cmd[1] == "setscale" and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local targetName = ""
            local scale = cmd[3]

            if type(tonumber(scale)) == "number" then
                scale = tonumber(scale)
            else
                 dreamweave.SendMessage(pid, "Not a valid argument. Use /setscale <pid> <value>.\n", false)
                 return false
            end

            Players[targetPid]:SetScale(scale)
            Players[targetPid]:LoadShapeshift()
            dreamweave.SendMessage(pid, "Scale for " .. Players[targetPid].name .. " is now " .. scale .. "\n", false)
            if targetPid ~= pid then
                dreamweave.SendMessage(targetPid, "Your scale is now " .. scale .. "\n", false)
            end
        end

    elseif cmd[1] == "setwerewolf" and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local targetName = ""
            local state = ""

            if cmd[3] == "on" then
                Players[targetPid]:SetWerewolfState(true)
                state = " enabled.\n"
            elseif cmd[3] == "off" then
                Players[targetPid]:SetWerewolfState(false)
                state = " disabled.\n"
            else
                 dreamweave.SendMessage(pid, "Not a valid argument. Use /setwerewolf <pid> on/off.\n", false)
                 return false
            end

            Players[targetPid]:LoadShapeshift()
            dreamweave.SendMessage(pid, "Werewolf state for " .. Players[targetPid].name .. state, false)
            if targetPid ~= pid then
                dreamweave.SendMessage(targetPid, "Werewolf state" .. state, false)
            end
        end

    elseif cmd[1] == "disguise" and admin then

        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local creatureRefId = tableHelper.concatenateFromIndex(cmd, 3)

            Players[targetPid].data.shapeshift.creatureRefId = creatureRefId
            dreamweave.SetCreatureRefId(targetPid, creatureRefId)
            dreamweave.SendShapeshift(targetPid)

            if creatureRefId == "" then
                creatureRefId = "nothing"
            end

            dreamweave.SendMessage(pid, Players[targetPid].accountName .. " is now disguised as " ..
                creatureRefId .. "\n", false)
            if targetPid ~= pid then
                dreamweave.SendMessage(targetPid, "You are now disguised as " .. creatureRefId .. "\n", false)
            end
        end

    elseif cmd[1] == "usecreaturename" and admin then

        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local nameState

            if cmd[3] == "on" then
                nameState = true
            elseif cmd[3] == "off" then
                nameState = false
            else
                 dreamweave.SendMessage(pid, "Not a valid argument. Use /usecreaturename <pid> on/off\n", false)
                 return false
            end

            Players[targetPid].data.shapeshift.displayCreatureName = nameState
            dreamweave.SetCreatureNameDisplayState(targetPid, nameState)
            dreamweave.SendShapeshift(targetPid)
        end

    elseif cmd[1] == "sethour" and moderator then

        local inputValue = tonumber(cmd[2])

        if type(inputValue) == "number" then

            if inputValue == 24 then
                inputValue = 0
            end

            if inputValue >= 0 and inputValue < 24 then
                WorldInstance.data.time.hour = inputValue
                WorldInstance:QuicksaveToDrive()
                WorldInstance:LoadTime(pid, true)
                hourCounter = inputValue
            else
                dreamweave.SendMessage(pid, "There aren't that many hours in a day.\n", false)
            end
        end

    elseif cmd[1] == "setday" and moderator then

        local inputValue = tonumber(cmd[2])

        if type(inputValue) == "number" then

            local daysInMonth = WorldInstance.monthLengths[WorldInstance.data.time.month]

            if inputValue <= daysInMonth then
                WorldInstance.data.time.day = inputValue
                WorldInstance:QuicksaveToDrive()
                WorldInstance:LoadTime(pid, true)
            else
                dreamweave.SendMessage(pid, "There are only " .. daysInMonth .. " days in the current month.\n", false)
            end
        end

    elseif cmd[1] == "setmonth" and moderator then

        local inputValue = tonumber(cmd[2])

        if type(inputValue) == "number" then
            WorldInstance.data.time.month = inputValue
            WorldInstance:QuicksaveToDrive()
            WorldInstance:LoadTime(pid, true)
        end

    elseif cmd[1] == "settimescale" and moderator then

        local inputPeriod = string.lower(tostring(cmd[2]))
        local inputValue = tonumber(cmd[3])

        if tableHelper.containsValue({"day", "night", "both"}, inputPeriod) and type(inputValue) == "number" then

            if inputPeriod == "day" or inputPeriod == "both" then
                WorldInstance.data.time.dayTimeScale = inputValue
            end

            if inputPeriod == "night" or inputPeriod == "both" then
                WorldInstance.data.time.nightTimeScale = inputValue
            end

            WorldInstance:QuicksaveToDrive()
            WorldInstance:UpdateFrametimeMultiplier()
            WorldInstance:LoadTime(pid, true)
        else
            dreamweave.SendMessage(pid, "Invalid input! Please use /settimescale day/night/both <value>\n", false)
        end

    elseif cmd[1] == "setcollision" and admin then

        local collisionState

        if cmd[2] ~= nil and cmd[3] == "on" then
            collisionState = true
        elseif cmd[2] ~= nil and cmd[3] == "off" then
            collisionState = false
        else
             dreamweave.SendMessage(pid, "Not a valid argument. Use /setcollision <category> on/off\n", false)
             return false
        end

        local categoryInput = string.upper(cmd[2])
        local categoryValue = enumerations.objectCategories[categoryInput]

        if categoryValue == enumerations.objectCategories.PLAYER then
            dreamweave.SetPlayerCollisionState(collisionState)
        elseif categoryValue == enumerations.objectCategories.ACTOR then
            dreamweave.SetActorCollisionState(collisionState)
        elseif categoryValue == enumerations.objectCategories.PLACED_OBJECT then
            dreamweave.SetPlacedObjectCollisionState(collisionState)

            if cmd[4] == "on" then
                dreamweave.UseActorCollisionForPlacedObjects(true)
            elseif cmd[4] == "off" then
                dreamweave.UseActorCollisionForPlacedObjects(false)
            end
        else
            dreamweave.SendMessage(pid, categoryInput .. " is not a valid object category. Valid choices are " ..
                tableHelper.concatenateTableIndexes(enumerations.objectCategories, ", ") .. "\n", false)
            return false
        end

        dreamweave.SendWorldCollisionOverride(pid, true)
        dreamweave.SendMessage(pid, "Collision for " .. categoryInput .. " is now " .. cmd[3] ..
            " for all newly loaded cells.\n", false)

    elseif cmd[1] == "overridecollision" and admin then

        local collisionState
        local refId = cmd[2]

        if refId ~= nil and cmd[3] == "on" then
            collisionState = true
        elseif refId ~= nil and cmd[3] == "off" then
            collisionState = false
        else
            Players[pid]:Message("Use /overridecollision <refId> on/off\n")
            return false
        end

        local message = "A collision-enabling override "

        if tableHelper.containsValue(config.enforcedCollisionRefIds, refId) then
            if collisionState then
                message = message .. "is already on"
            else
                tableHelper.removeValue(config.enforcedCollisionRefIds, refId)
                message = message .. "is now off"
            end
        else
            if collisionState then
                table.insert(config.enforcedCollisionRefIds, refId)
                message = message .. "is now on"
            else
                message = message .. "is already off"
            end
        end

        logicHandler.SendConfigCollisionOverrides(pid, true)
        Players[pid]:Message(message .. " for " .. refId .. " in newly loaded cells\n")

    elseif cmd[1] == "load" and admin then

        local scriptName = cmd[2]:normalizePath()

        if scriptName == nil then
            Players[pid]:Message(color.LightGray .. "Use /load <scriptName>\n" .. color.Default)
        else
            local wasLoaded = false

            if package.loaded[scriptName] then
                if type(package.loaded[scriptName]) ~= "table" then
                    Players[pid]:Message(color.GoldenRod  .. scriptName .. color.LightGray .. " was already loaded but it is not a valid lua module and thus cannot be properly reloaded.\n" .. color.Default)
                    return
                end

                Players[pid]:Message(color.GoldenRod  .. scriptName .. color.LightGray  .. " was already loaded, so it is being reloaded.\n" .. color.Default)
                wasLoaded = true
            end

            local result

            if wasLoaded then
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
                local scriptPath = package.searchpath(scriptName, package.path)
                local scriptID = customEventHooks.getScriptID(scriptName)
                if not scriptID then
                    scriptID = customEventHooks.generateScriptID(scriptName)
                end

                -- Trigger OnScriptUnload event
                local eventStatus = customEventHooks.triggerValidators("OnScriptUnload", {scriptID})

                if eventStatus.validDefaultHandler then
                    customEventHooks.unregisterAllByScriptID(scriptID)
                end

                customEventHooks.triggerHandlers("OnScriptUnload", eventStatus, {scriptID})

                result = dofile(scriptPath)

                for key, value in pairs(package.loaded[scriptName]) do
                    if result[key] == nil then
                        package.loaded[scriptName][key] = nil
                    end
                end

                for key, value in pairs(result) do
                    package.loaded[scriptName][key] = value
                end

		customEventHooks.triggerInit(scriptID)

            else
                result = prequire(scriptName)
            end

            if result then
                if wasLoaded then
                    Players[pid]:Message(color.GoldenRod  .. scriptName .. color.LightGray .. " was successfully reloaded.\n".. color.Default)
                else
                    Players[pid]:Message(color.GoldenRod  .. scriptName .. color.LightGray .. " was successfully loaded.\n".. color.Default)
                end
            else
                Players[pid]:Message(color.GoldenRod  .. scriptName .. color.LightGray .. " could not be found.\n" .. color.Default)
            end
        end
    elseif cmd[1] == "unload" and admin then
        local scriptName = cmd[2]:normalizePath()
        
        if scriptName == nil then
            Players[pid]:Message(color.LightGray .. "Use /unload <scriptName>\n" .. color.Default)
        else
            local wasLoaded = false
    
            if package.loaded[scriptName] then
                if type(package.loaded[scriptName]) ~= "table" then
                    Players[pid]:Message(color.GoldenRod  .. scriptName .. color.LightGray .. " is already loaded but is not a valid Lua module and cannot be properly unloaded.\n" .. color.Default)
                    return
                end
    
                wasLoaded = true
            end
    
            if wasLoaded then

                local scriptID = customEventHooks.getScriptID(scriptName)
                if not scriptID then
                    scriptID = customEventHooks.generateScriptID(scriptName)
                end

                -- Trigger OnScriptUnload event
                local eventStatus = customEventHooks.triggerValidators("OnScriptUnload", {scriptID})
    
                if eventStatus.validDefaultHandler then
                    customEventHooks.unregisterAllByScriptID(scriptID)
                end
    
                customEventHooks.triggerHandlers("OnScriptUnload", eventStatus, {scriptID})
    
                -- Fully unload the script by setting it to nil
                package.loaded[scriptName] = nil
    
                Players[pid]:Message(color.GoldenRod  .. scriptName .. color.LightGray .. " has been successfully unloaded.\n".. color.Default)
            else
                Players[pid]:Message(color.GoldenRod  .. scriptName .. color.LightGray .. " is not currently loaded.\n" .. color.Default)
            end
        end
    elseif cmd[1] == "unloadid" and admin then
        local scriptID = cmd[2]
        if scriptID == nil then
            Players[pid]:Message(color.LightGray .. "Use /unloadbyid <scriptID>\n" .. color.Default)
        else
            -- Trigger OnScriptUnload event
            local eventStatus = customEventHooks.triggerValidators("OnScriptUnload", {scriptID})

            if eventStatus.validDefaultHandler then
            customEventHooks.unregisterAllByScriptID(scriptID)
            Players[pid]:Message(color.LightGray .. scriptID .. " was unloaded." .. "\n" .. color.Default)
            end
            customEventHooks.triggerHandlers("OnScriptUnload", eventStatus, {scriptID})
        end
        
    elseif cmd[1] == "resetkills" and moderator and config.shareKills == true then

        -- Set all currently recorded kills to 0 for connected players
        for refId, killCount in pairs(WorldInstance.data.kills) do
            WorldInstance.data.kills[refId] = 0
        end

        WorldInstance:QuicksaveToDrive()
        WorldInstance:LoadKills(pid, true)
        dreamweave.SendMessage(pid, "All the kill counts for creatures and NPCs have been reset.\n", true)
        
    elseif cmd[1] == "resetkills" and config.shareKills == false then
	
		if Players[pid].data.kills == nil then
			Players[pid].data.kills = {}
		end
        -- Set all currently recorded kills to 0 for players
        for refId, killCount in pairs(Players[pid].data.kills) do
            Players[pid].data.kills[refId] = 0
        end

        Players[pid]:QuicksaveToDrive()
        Players[pid]:LoadKills(pid, false)
        dreamweave.SendMessage(pid, "All the kill counts for creatures and NPCs have been reset.\n", false)
        
    elseif cmd[1] == "suicide" then
        if config.allowSuicideCommand == true then
            dreamweave.SetHealthCurrent(pid, 0)
            dreamweave.SendStatsDynamic(pid)
        else
            dreamweave.SendMessage(pid, "That command is disabled on this server.\n", false)
        end

    elseif cmd[1] == "fixme" then
        if config.allowFixmeCommand == true then
            local currentTime = os.time()

            if not dreamweave.IsInExterior(pid) then
                local message = "Sorry! You can only use " .. color.Yellow .. "/fixme" ..
                    color.White .. " in exteriors.\n"
                dreamweave.SendMessage(pid, message, false)
            elseif Players[pid].data.timestamps.lastFixMe == nil or
                currentTime >= Players[pid].data.timestamps.lastFixMe + config.fixmeInterval then

                logicHandler.RunConsoleCommandOnPlayer(pid, "fixme")
                Players[pid].data.timestamps.lastFixMe = currentTime
                dreamweave.SendMessage(pid, "You have fixed your position!\n", false)
            else
                local remainingSeconds = Players[pid].data.timestamps.lastFixMe +
                    config.fixmeInterval - currentTime
                local message = "Sorry! You can't use " .. color.Yellow .. "/fixme" ..
                    color.White .. " for another "

                if remainingSeconds > 1 then
                    message = message .. color.Yellow .. remainingSeconds .. color.White .. " seconds"
                else
                    message = message .. " second"
                end

                message = message .. "\n"
                dreamweave.SendMessage(pid, message, false)
            end
        else
            dreamweave.SendMessage(pid, "That command is disabled on this server.\n", false)
        end

    elseif cmd[1] == "storeconsole" and cmd[2] ~= nil and cmd[3] ~= nil and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            Players[targetPid].storedConsoleCommand = tableHelper.concatenateFromIndex(cmd, 3)

            dreamweave.SendMessage(pid, "That console command is now stored for player " .. targetPid .. "\n", false)
        end

    elseif cmd[1] == "runconsole" and cmd[2] ~= nil and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])

            if Players[targetPid].storedConsoleCommand == nil then
                dreamweave.SendMessage(pid, "There is no console command stored for player " .. targetPid ..
                    ". Please run /storeconsole on them first.\n", false)
            else
                local consoleCommand = Players[targetPid].storedConsoleCommand
                logicHandler.RunConsoleCommandOnPlayer(targetPid, consoleCommand)

                local count = tonumber(cmd[3])

                if count ~= nil and count > 1 then

                    count = count - 1
                    local interval = 1

                    if tonumber(cmd[4]) ~= nil and tonumber(cmd[4]) > 1 then
                        interval = tonumber(cmd[4])
                    end

                    local loopIndex = tableHelper.getUnusedNumericalIndex(ObjectLoops)
                    local timerId = dreamweave.CreateTimerEx("OnObjectLoopTimeExpiration", interval, "i", loopIndex)

                    ObjectLoops[loopIndex] = {
                        packetType = "console",
                        timerId = timerId,
                        interval = interval,
                        count = count,
                        targetPid = targetPid,
                        targetName = Players[targetPid].accountName,
                        consoleCommand = consoleCommand
                    }

                    dreamweave.StartTimer(timerId)
                end
            end
        end

    elseif (cmd[1] == "placeat" or cmd[1] == "spawnat") and cmd[2] ~= nil and cmd[3] ~= nil and admin then
        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])
            local refId = tableHelper.concatenateFromIndex(cmd, 3)
            local packetType

            if cmd[1] == "placeat" then
                packetType = "place"
            elseif cmd[1] == "spawnat" then
                packetType = "spawn"
            end

            logicHandler.CreateObjectAtPlayer(targetPid, dataTableBuilder.BuildObjectData(refId), packetType)
        end

    elseif (cmd[1] == "anim" or cmd[1] == "a") and cmd[2] ~= nil then
        local isValid = animHelper.PlayAnimation(pid, cmd[2])

        if not isValid then
            local validList = animHelper.GetValidList(pid)
            dreamweave.SendMessage(pid, "That is not a valid animation. Try one of the following:\n" ..
                validList .. "\n", false)
        end

    elseif cmd[1] == "speech" or cmd[1] == "s" then

        local isValid = false
        local race = string.lower(Players[pid].data.character.race)

        if speechCollections[race] then
            if cmd[2] ~= nil and cmd[3] ~= nil and type(tonumber(cmd[3])) == "number" then
                isValid = speechHelper.PlaySpeech(pid, cmd[2], tonumber(cmd[3]))
            end

            if not isValid then
                local validList = speechHelper.GetPrintableValidListForPid(pid)
                dreamweave.SendMessage(pid, "That is not a valid speech. Try one of the following:\n"
                    .. validList .. "\n", false)
            end
        else
            dreamweave.SendMessage(pid, "There are no speech lines for your race.")
        end

    elseif cmd[1] == "confiscate" and moderator then

        if logicHandler.CheckPlayerValidity(pid, cmd[2]) then

            local targetPid = tonumber(cmd[2])

            if targetPid == pid then
                dreamweave.SendMessage(pid, "You can't confiscate from yourself!\n", false)
            elseif Players[targetPid].data.customVariables.isConfiscationTarget then
                dreamweave.SendMessage(pid, "Someone is already confiscating from that player\n", false)
            else
                Players[pid].confiscationTargetName = Players[targetPid].accountName

                Players[targetPid]:SetConfiscationState(true)

                tableHelper.cleanNils(Players[targetPid].data.inventory)
                guiHelper.ShowInventoryList(config.customMenuIds.confiscate, pid, targetPid)
            end
        end

    elseif cmd[1] == "setai" and cmd[2] ~= nil and cmd[3] ~= nil and admin then

        local actionInput = cmd[3]
        local actionNumericalId

        -- Allow both numerical and string input for actions (i.e. 1 or COMBAT), but
        -- convert the latter into the former
        if type(tonumber(actionInput)) == "number" then
            actionNumericalId = tonumber(actionInput)
        else
            actionNumericalId = enumerations.ai[string.upper(actionInput)]
        end

        if actionNumericalId == nil then

            Players[pid]:Message(actionInput .. " is not a valid AI action. Valid choices are " ..
                tableHelper.concatenateTableIndexes(enumerations.ai, ", ") .. "\n")
        else

            local uniqueIndex = cmd[2]
            local cell = logicHandler.GetCellContainingActor(uniqueIndex)

            if cell == nil then

                Players[pid]:Message("Could not find actor " .. uniqueIndex .. " in any loaded cell\n")
            else

                local actionName = tableHelper.getIndexByValue(enumerations.ai, actionNumericalId)
                local messageAction = enumerations.aiPrintableAction[actionName]
                local message = uniqueIndex .. " is now " .. messageAction

                if actionNumericalId == enumerations.ai.CANCEL then

                    logicHandler.SetAIForActor(cell, uniqueIndex, actionNumericalId)
                    Players[pid]:Message(message .. "\n")

                elseif actionNumericalId == enumerations.ai.TRAVEL then

                    local posX, posY, posZ = tonumber(cmd[4]), tonumber(cmd[5]), tonumber(cmd[6])

                    if type(posX) == "number" and type(posY) == "number" and type(posZ) == "number" then

                        logicHandler.SetAIForActor(cell, uniqueIndex, actionNumericalId, nil, nil, posX, posY, posZ)
                        Players[pid]:Message(message .. " " .. posX .. " " .. posY .. " " .. posZ .. "\n")
                    else
                        Players[pid]:Message("Invalid travel coordinates! " ..
                            "Use /setai <uniqueIndex> travel <x> <y> <z>\n")
                    end

                elseif actionNumericalId == enumerations.ai.WANDER then

                    local distance, duration = tonumber(cmd[4]), tonumber(cmd[5])

                    if type(distance) == "number" and type(duration) == "number" then

                        if cmd[6] == "true" then
                            shouldRepeat = true
                        else
                            shouldRepeat = false
                        end

                        logicHandler.SetAIForActor(cell, uniqueIndex, actionNumericalId, nil, nil, nil, nil, nil,
                            distance, duration, shouldRepeat)
                        Players[pid]:Message(message .. " a distance of " .. distance .. " for a duration of " ..
                            duration .. "\n")
                    else
                        Players[pid]:Message("Invalid wander parameters! " ..
                            "Use /setai <uniqueIndex> wander <distance> <duration> true/false\n")
                    end

                elseif cmd[4] ~= nil then

                    local target = cmd[4]
                    local hasPlayerTarget = false

                    if type(tonumber(target)) == "number" and logicHandler.CheckPlayerValidity(pid, target) then
                        target = tonumber(target)
                        hasPlayerTarget = true
                    end

                    if hasPlayerTarget then
                        logicHandler.SetAIForActor(cell, uniqueIndex, actionNumericalId, target)
                        message = message .. " player " .. Players[target].name
                    else
                        logicHandler.SetAIForActor(cell, uniqueIndex, actionNumericalId, nil, target)
                        message = message .. " object " .. target
                    end

                    Players[pid]:Message(message .. "\n")
                else

                    Players[pid]:Message("Invalid AI action!\n")
                end
            end
        end

    elseif cmd[1] == "storerecord" and cmd[2] ~= nil and cmd[3] ~= nil and admin then
        commandHandler.StoreRecord(pid, cmd)

    elseif cmd[1] == "createrecord" and cmd[2] ~= nil and admin then
        commandHandler.CreateRecord(pid, cmd)

    elseif cmd[1] == "help" then

        -- Check "scripts/menu/help.lua" if you want to change the contents of the help menus
        Players[pid].currentCustomMenu = "help player"
        menuHelper.DisplayMenu(pid, Players[pid].currentCustomMenu)

    elseif cmd[1] == "craft" then

        -- Check "scripts/menu/defaultCrafting.lua" if you want to change the example craft menu
        Players[pid].currentCustomMenu = "default crafting origin"
        menuHelper.DisplayMenu(pid, Players[pid].currentCustomMenu)

    elseif (cmd[1] == "advancedexample" or cmd[1] == "advex") and moderator then

        -- Check "scripts/menu/advancedExample.lua" if you want to change the advanced menu example
        Players[pid].currentCustomMenu = "advanced example origin"
        menuHelper.DisplayMenu(pid, Players[pid].currentCustomMenu)

    else
        local message = "Not a valid command. Type /help for more info.\n"
        dreamweave.SendMessage(pid, color.Error .. message .. color.Default, false)
    end
end

function commandHandler.StoreRecord(pid, cmd)

    if Players[pid].data.customVariables == nil then
        Players[pid].data.customVariables = {}
    end

    if Players[pid].data.customVariables.storedRecords == nil then
        Players[pid].data.customVariables.storedRecords = {}
    end

    local inputType = string.lower(cmd[2])

    if config.validRecordSettings[inputType] == nil then
        Players[pid]:Message("Record type " .. inputType .. " is invalid. Please use one of the following " ..
            "valid types instead: " .. tableHelper.concatenateTableIndexes(config.validRecordSettings, ", ") .. "\n")
        return
    else
        if Players[pid].data.customVariables.storedRecords[inputType] == nil then
            Players[pid].data.customVariables.storedRecords[inputType] = {}
        end
    end

    local storedTable = Players[pid].data.customVariables.storedRecords[inputType]
    local inputSetting = cmd[3]

    if inputSetting == "clear" then
        Players[pid].data.customVariables.storedRecords[inputType] = {}
        Players[pid]:Message("Clearing stored " .. inputType .. " data\n")
    elseif inputSetting == "print" then
        local text = "for a record of type " .. inputType

        if tableHelper.isEmpty(storedTable) then
            text = "You have no values stored " .. text .. "."
        else
            text = "You have the current values stored " .. text .. ":\n\n"

            for index, value in pairs(storedTable) do
                text = text .. index .. ": "

                if type(value) == "table" then
                    text = text .. tableHelper.getSimplePrintableTable(value)
                else
                    text = text .. value
                end

                text = text .. "\n"
            end
        end

        dreamweave.CustomMessageBox(pid, config.customMenuIds.recordPrint, text, "Ok")
    elseif inputSetting ~= nil then

        if inputSetting == "add" then
            local inputAdditionType = cmd[4]
            local inputConcatenation
            local inputValues

            if inputAdditionType == nil or cmd[5] == nil then
                Players[pid]:Message("Please provide the minimum number of arguments required.\n")
                return
            else
                inputConcatenation = tableHelper.concatenateFromIndex(cmd, 5, ",")
                inputValues = tableHelper.getTableFromCommaSplit(inputConcatenation)
            end

            if inputAdditionType == "effect" and (inputType == "spell" or inputType == "potion"
                or inputType == "enchantment" or inputType == "ingredient") then

                if inputType == "ingredient" and type(storedTable.effects) == "table"
                    and tableHelper.getCount(storedTable.effects) == 4 then
                    Players[pid]:Message("You have already reached the cap of 4 effects on an ingredient record.\n")
                else
                    if storedTable.effects == nil then
                        storedTable.effects = {}
                    end

                    local inputEffectId = inputValues[1]

                    if type(tonumber(inputEffectId)) == "number" then

                        local effect = { id = tonumber(inputEffectId), rangeType = tonumber(inputValues[2]),
                            duration = tonumber(inputValues[3]), area = tonumber(inputValues[4]),
                            magnitudeMin = tonumber(inputValues[5]), magnitudeMax = tonumber(inputValues[6]),
                            attribute = tonumber(inputValues[7]), skill = tonumber(inputValues[8]) }
                        table.insert(storedTable.effects, effect)
                        Players[pid]:Message("Added effect " .. inputConcatenation .. "\n")
                    else
                        Players[pid]:Message("Please use a numerical value for the effect ID.\n")
                    end
                end
            elseif inputAdditionType == "part" and (inputType == "armor" or inputType == "clothing") then

                if storedTable.parts == nil then
                    storedTable.parts = {}
                end

                local inputPartType = inputValues[1]

                if type(tonumber(inputPartType)) == "number" then

                    local part = { partType = tonumber(inputPartType), malePart = inputValues[2],
                        femalePart = inputValues[3] }
                    table.insert(storedTable.parts, part)
                    Players[pid]:Message("Added part " .. inputConcatenation .. "\n")
                else
                    Players[pid]:Message("Please use a numerical value for the part type.\n")
                end
            elseif inputAdditionType == "item" and tableHelper.containsValue({"creature", "npc", "container"}, inputType) then

                if storedTable.items == nil then
                    storedTable.items = {}
                end

                local inputItemId = inputValues[1]
                local inputItemCount = tonumber(inputValues[2])

                if type(inputItemCount) ~= "number" then
                    inputItemCount = 1
                end

                local item = { id = inputItemId, count = inputItemCount }
                table.insert(storedTable.items, item)
                Players[pid]:Message("Added item " .. inputItemId .. " with count " .. inputItemCount .. "\n")
            else
                Players[pid]:Message(tostring(inputAdditionType) .. " is not a valid addition type for " ..
                    inputType .. " records.\n")
            end

        elseif tableHelper.containsValue(config.validRecordSettings[inputType], inputSetting) then

            local inputValue = tableHelper.concatenateFromIndex(cmd, 4)

            -- Although numerical values are accepted for gender, allow "male" and "female" input
            -- as well
            if inputSetting == "gender" and type(tonumber(inputValue)) ~= "number" then
                local gender

                if inputValue == "male" then
                    gender = 1
                elseif inputValue == "female" then
                    gender = 0
                end

                if type(gender) == "number" then
                    storedTable.gender = gender
                else
                    Players[pid]:Message("Please use either 0/1 or female/male as the gender input.\n")
                    return
                end
            elseif tableHelper.containsValue(config.numericalRecordSettings, inputSetting) then
                inputValue = tonumber(inputValue)

                if type(inputValue) == "number" then
                    storedTable[inputSetting] = inputValue
                else
                    Players[pid]:Message("Please use a valid numerical value as the input for " ..
                        inputSetting .. "\n")
                    return
                end
            elseif tableHelper.containsValue(config.minMaxRecordSettings, inputSetting) then
                local minValue = tonumber(cmd[4])
                local maxValue = tonumber(cmd[5])

                if type(minValue) == "number" and type(maxValue) == "number"  then
                    storedTable[inputSetting] = { min = minValue, max = maxValue }
                else
                    Players[pid]:Message("Please use two valid numerical values as the input for " ..
                        inputSetting .. "\n")
                    return
                end
            elseif tableHelper.containsValue(config.rgbRecordSettings, inputSetting) then
                local redValue = tonumber(cmd[4])
                local greenValue = tonumber(cmd[5])
                local blueValue = tonumber(cmd[6])
                local densityValue = tonumber (cmd[7])

                if type(redValue) == "number" and type(greenValue) == "number" and type(blueValue) == "number" and
                    redValue > -1 and redValue < 256 and greenValue > -1 and greenValue < 256 and
                    blueValue > -1 and blueValue < 256 then
                    storedTable[inputSetting] = { red = redValue, green = greenValue, blue = blueValue }
                else
                    Players[pid]:Message("Please use three valid numerical values between 0 and 255 as the input for " ..
                        inputSetting .. "\n")
                    return
                end

                if densityValue and type(densityValue) == "number" and densityValue > -1 and densityValue < 256 then
                  storedTable[inputSetting].density = densityValue
                else
                  Players[pid]:Message("Please use three valid numerical values between 0 and 255 as the input for " ..
                                       inputSetting .. "\n")
                  return
                end

            elseif tableHelper.containsValue(config.booleanRecordSettings, inputSetting) then
                if inputValue == "true" or inputValue == "on" or tonumber(inputValue) == 1 then
                    storedTable[inputSetting] = true
                elseif inputValue == "false" or inputValue == "off" or tonumber(inputValue) == 0 then
                    storedTable[inputSetting] = false
                else
                    Players[pid]:Message("Please use a valid boolean as the input for " .. inputSetting .. "\n")
                    return
                end
            else
                storedTable[inputSetting] = inputValue
            end

            -- Remove any stored settings that are mutually exclusive with the one we've added
            if config.mutuallyExclusiveRecordSettings[inputType] ~= nil and
                tableHelper.containsValue(config.mutuallyExclusiveRecordSettings[inputType], inputSetting) then
                for _, excludedSetting in pairs(config.mutuallyExclusiveRecordSettings[inputType]) do
                    if excludedSetting ~= inputSetting then
                        storedTable[excludedSetting] = nil
                    end
                end
            end

            local message = "Storing " .. inputType .. " " .. inputSetting .. " with value " .. inputValue .. "\n"
            Players[pid]:Message(message)
        else
            local validSettingsArray = config.validRecordSettings[inputType]
            Players[pid]:Message(inputSetting .. " is not a valid setting for " .. inputType .. " records. " ..
                "Try one of these:\n" .. tableHelper.concatenateArrayValues(validSettingsArray, 1, ", ") .. "\n")
        end
    end
end

function commandHandler.CreateRecord(pid, cmd)

    if Players[pid].data.customVariables == nil then
        Players[pid].data.customVariables = {}
    end

    if Players[pid].data.customVariables.storedRecords == nil then
        Players[pid].data.customVariables.storedRecords = {}
    end

    if tableHelper.getCount(cmd) > 2 then
        Players[pid]:Message("This command does not take more than 1 argument. Did you mean to use " ..
            "/storerecord instead?\n")
        return
    end

    local inputType = string.lower(cmd[2])

    if config.validRecordSettings[inputType] == nil then
        Players[pid]:Message("Record type " .. inputType .. " is invalid. Please use one of the following " ..
            "valid types instead: " .. tableHelper.concatenateTableIndexes(config.validRecordSettings, ", ") .. "\n")
        return
    else
        if Players[pid].data.customVariables.storedRecords[inputType] == nil then
            Players[pid].data.customVariables.storedRecords[inputType] = {}
        end
    end

    local storedTable = Players[pid].data.customVariables.storedRecords[inputType]

    if storedTable.baseId == nil then
        if inputType == "creature" then
            Players[pid]:Message("As of now, you cannot create creatures from scratch because of how many " ..
                "different settings need to be implemented for them. Please use a baseId for your creature " ..
                "instead.\n")
            return
        end

        local missingSettings = {}

        for _, requiredSetting in pairs(config.requiredRecordSettings[inputType]) do
            if storedTable[requiredSetting] == nil then
                table.insert(missingSettings, requiredSetting)
            end
        end

        if not tableHelper.isEmpty(missingSettings) then
            Players[pid]:Message("You cannot create a record of type " .. inputType .. " because it is missing the " ..
                "following required settings: " .. tableHelper.concatenateArrayValues(missingSettings, 1, ", ") .. "\n")
            return
        end
    else
        if logicHandler.IsGeneratedRecord(storedTable.baseId) then
            local baseRecordType = logicHandler.GetRecordTypeByRecordId(storedTable.baseId)

            if baseRecordType and RecordStores[baseRecordType].data.generatedRecords[storedTable.baseId] then
                local baseGeneratedRecord = RecordStores[baseRecordType].data.generatedRecords[storedTable.baseId]

                storedTable.baseId = nil
                
                for k, v in pairs(baseGeneratedRecord) do
                    storedTable[k] = storedTable[k] or v
                end
            end
        end
    end

    if inputType == "enchantment" and (storedTable.effects == nil or tableHelper.isEmpty(storedTable.effects)) then
        Players[pid]:Message("Records of type " .. inputType .. " require at least 1 effect.\n")
        return
    end

    local id = storedTable.id
    local isGenerated = id == nil or logicHandler.IsGeneratedRecord(id)

    local enchantmentStore
    local hasGeneratedEnchantment = tableHelper.containsValue(config.enchantableRecordTypes, inputType) and
        storedTable.enchantmentId ~= nil and logicHandler.IsGeneratedRecord(storedTable.enchantmentId)

    if hasGeneratedEnchantment then
        -- Ensure the generated enchantment used by this record actually exists
        if isGenerated then
            enchantmentStore = RecordStores["enchantment"]

            if enchantmentStore.data.generatedRecords[storedTable.enchantmentId] == nil then
                Players[pid]:Message("The generated enchantment record (" .. storedTable.enchantmentId ..
                    ") you are trying to use for this " .. inputType .. " record does not exist.\n")
                return
            end
        -- Permanent records should only use other permanent records as enchantments, so
        -- go no further if that is not the case
        else
            Players[pid]:Message("You cannot use a generated enchantment record (" .. storedTable.enchantmentId ..
                ") with a permanent record (" .. id .. ").\n")
            return
        end
    end

    local recordStore = RecordStores[inputType]

    if id == nil then
        id = recordStore:GenerateRecordId()
        isGenerated = true
    end

    -- We don't want to insert a direct reference to the storedTable in our record data,
    -- so create a copy of the storedTable and insert that instead
    local savedTable = tableHelper.deepCopy(storedTable)

    -- The id and the savedTable will form a key-value pair, so there's no need to keep
    -- the id in the savedTable as well
    savedTable.id = nil

    -- Use an autoCalc of 1 by default for entirely new NPCs to avoid spawning them
    -- without any stats
    if inputType == "npc" and savedTable.baseId == nil and savedTable.autoCalc == nil then
        savedTable.autoCalc = 1
        Players[pid]:Message("autoCalc is defaulting to 1 for this record.\n")
    end

    -- Use a skillId of -1 by default for entirely new books to avoid having them
    -- increase a skill
    if inputType == "book" and savedTable.skillId == nil then
        savedTable.skillId = -1
        Players[pid]:Message("skillId is defaulting to -1 for this record.\n")
    end

    local message = "Your record has now been saved as a "

    if isGenerated then
        message = message .. "generated record that will be deleted when no longer used.\n"
        recordStore.data.generatedRecords[id] = savedTable

        -- This record will be sent to everyone on the server below, so track it
        -- as having already been received by players
        for _, player in pairs(Players) do
            if not tableHelper.containsValue(Players[pid].generatedRecordsReceived, id) then
                table.insert(player.generatedRecordsReceived, id)
            end
        end

        -- Is this an enchantable record using an enchantment from a generated record?
        -- If so, add a link to this record for that enchantment record
        if hasGeneratedEnchantment then
            enchantmentStore:AddLinkToRecord(savedTable.enchantmentId, id, inputType)
            enchantmentStore:QuicksaveToDrive()
        end
    else
        message = message .. "permanent record that you'll have to remove manually when you no longer need it.\n"
        recordStore.data.permanentRecords[id] = savedTable
    end

    recordStore:QuicksaveToDrive()

    dreamweave.ClearRecords()
    dreamweave.SetRecordType(enumerations.recordType[string.upper(inputType)])

    if inputType == "activator" then packetBuilder.AddActivatorRecord(id, savedTable)
    elseif inputType == "apparatus" then packetBuilder.AddApparatusRecord(id, savedTable)
    elseif inputType == "armor" then packetBuilder.AddArmorRecord(id, savedTable)
    elseif inputType == "book" then packetBuilder.AddBookRecord(id, savedTable)
    elseif inputType == "bodypart" then packetBuilder.AddBodyPartRecord(id, savedTable)
    elseif inputType == "cell" then packetBuilder.AddCellRecord(id, savedTable)
    elseif inputType == "clothing" then packetBuilder.AddClothingRecord(id, savedTable)
    elseif inputType == "container" then packetBuilder.AddContainerRecord(id, savedTable)
    elseif inputType == "creature" then packetBuilder.AddCreatureRecord(id, savedTable)
    elseif inputType == "door" then packetBuilder.AddDoorRecord(id, savedTable)
    elseif inputType == "enchantment" then packetBuilder.AddEnchantmentRecord(id, savedTable)
    elseif inputType == "gamesetting" then packetBuilder.AddGameSettingRecord(id, savedTable)
    elseif inputType == "ingredient" then packetBuilder.AddIngredientRecord(id, savedTable)
    elseif inputType == "light" then packetBuilder.AddLightRecord(id, savedTable)
    elseif inputType == "lockpick" then packetBuilder.AddLockpickRecord(id, savedTable)
    elseif inputType == "miscellaneous" then packetBuilder.AddMiscellaneousRecord(id, savedTable)
    elseif inputType == "npc" then packetBuilder.AddNpcRecord(id, savedTable)
    elseif inputType == "potion" then packetBuilder.AddPotionRecord(id, savedTable)
    elseif inputType == "probe" then packetBuilder.AddProbeRecord(id, savedTable)
    elseif inputType == "repair" then packetBuilder.AddRepairRecord(id, savedTable)
    elseif inputType == "script" then packetBuilder.AddScriptRecord(id, savedTable)
    elseif inputType == "spell" then packetBuilder.AddSpellRecord(id, savedTable)
    elseif inputType == "static" then packetBuilder.AddStaticRecord(id, savedTable)
    elseif inputType == "weapon" then packetBuilder.AddWeaponRecord(id, savedTable) end

    dreamweave.SendRecordDynamic(pid, true, false)

    if not tableHelper.containsValue(config.unplaceableRecordTypes, inputType) then
        if inputType ~= "enchantment" then
            if inputType == "creature" or inputType == "npc" then
                message = message .. "You can spawn an instance of it using /spawnat "
            else
                message = message .. "You can place an instance of it using /placeat "
            end

            message = message .. "<pid> " .. id .. "\n"
        else
            message = message .. "To use it, create an armor, book, clothing or weapon record with an " ..
                "enchantmentId of " .. id .. "\n"
        end
    end

    Players[pid]:Message(message)
end

return commandHandler
