require("wrapper")
require("utils")
require("enumerations")
tableHelper = require("tableHelper")
class = require("classy")
jsonInterface = require("jsonInterface")

-- Lua's default io library for input/output can't open Unicode filenames on Windows,
-- which is why on Windows it's replaced by TES3MP's io2 (https://github.com/TES3MP/Lua-io2)
if dreamweave.GetOperatingSystemType() == "Windows" then
    jsonInterface.setLibrary(require("io2"))
else
    jsonInterface.setLibrary(io)
end

require("color")
require("config")
require("time")

vec3 = require("vectors")
customEventHooks = require("customEventHooks")
customCommandHooks = require("customCommandHooks")
logicHandler = require("logicHandler")
eventHandler = require("eventHandler")
guiHelper = require("guiHelper")
animHelper = require("animHelper")
speechHelper = require("speechHelper")
menuHelper = require("menuHelper")
require("defaultCommands")
require("customScripts")

Database = nil
Player = nil
Cell = nil
RecordStore = nil
World = nil

pidsByIpAddress = {}
clientDataFiles = {}
clientVariableScopes = {}
speechCollections = {}

hourCounter = nil
updateTimerId = nil

banList = {}

if (config.databaseType and config.databaseType ~= "json") and doesModuleExist("luasql." .. config.databaseType) then

    Database = require("database")
    Database:LoadDriver(config.databaseType)

    dreamweave.LogMessage(enumerations.log.INFO, "Using " .. Database.driver._VERSION .. " with " .. config.databaseType ..
        " driver")

    Database:Connect(config.databasePath)

    -- Make sure we enable foreign keys
    Database:Execute("PRAGMA foreign_keys = ON;")

    Database:CreatePlayerTables()
    Database:CreateWorldTables()

    Player = require("player.sql")
    Cell = require("cell.sql")
    RecordStore = require("recordstore.sql")
    World = require("world.sql")
else
    Player = require("player.json")
    Cell = require("cell.json")
    RecordStore = require("recordstore.json")
    World = require("world.json")
end

function LoadBanList()
    dreamweave.LogMessage(enumerations.log.INFO, "Reading banlist.json")
    banList = jsonInterface.load("banlist.json")

    if not banList.playerNames then
        banList.playerNames = {}
    elseif not banList.ipAddresses then
        banList.ipAddresses = {}
    end

    if #banList.ipAddresses > 0 then
        local message = "- Banning manually-added IP addresses:\n"

        for index, ipAddress in pairs(banList.ipAddresses) do
            message = message .. ipAddress

            if index < #banList.ipAddresses then
                message = message .. ", "
            end

            dreamweave.BanAddress(ipAddress)
        end

        dreamweave.LogAppend(enumerations.log.WARN, message)
    end

    if #banList.playerNames <= 0 then return end
    
    local message = "- Banning all IP addresses stored for players:\n"

    for index, targetName in pairs(banList.playerNames) do
        message = message .. targetName

        if index < #banList.playerNames then
            message = message .. ", "
        end

        local targetPlayer = logicHandler.GetPlayerByName(targetName)

        if not targetPlayer then return end

        for _, ipAddress in pairs(targetPlayer.data.ipAddresses) do
            dreamweave.BanAddress(ipAddress)
        end
    end

    dreamweave.LogAppend(enumerations.log.WARN, message)
end

function SaveBanList()
    jsonInterface.save("banlist.json", banList)
end

do
    local previousHourFloor = nil
    
    function UpdateTime()

        if not config.passTimeWhenEmpty and tableHelper.getCount(Players) <= 0 then return end
    
        hourCounter = hourCounter + (0.0083 * WorldInstance.frametimeMultiplier)

        local hourFloor = math.floor(hourCounter)

        if not previousHourFloor then
            previousHourFloor = hourFloor
        elseif hourFloor > previousHourFloor then
            if hourFloor >= 24 then
                local eventStatus = customEventHooks.triggerValidators("OnGameDay", {})
                if eventStatus.validDefaultHandler then
                    hourCounter = hourCounter - hourFloor
                    hourFloor = 0

                    dreamweave.LogMessage(enumerations.log.INFO, "The world time day has been incremented")
                    WorldInstance:IncrementDay()
                end
                customEventHooks.triggerHandlers("OnGameDay", eventStatus, {})
            end

            local eventStatus = customEventHooks.triggerValidators("OnGameHour", {})
            if eventStatus.validDefaultHandler then
                dreamweave.LogMessage(enumerations.log.INFO, "The world time hour is now " .. hourFloor)
                WorldInstance.data.time.hour = hourCounter

                WorldInstance:UpdateFrametimeMultiplier()

                if tableHelper.getCount(Players) > 0 then
                    WorldInstance:LoadTime(tableHelper.getAnyValue(Players).pid, true)
                end

                previousHourFloor = hourFloor
            end
            customEventHooks.triggerHandlers("OnGameHour", eventStatus, {})
        end

        dreamweave.RestartTimer(updateTimerId, time.seconds(1))
    end
end

function OnServerInit()

    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnServerInit\"")
    local expectedDreamweaveVersion = "0.1.0"
    local dreamweaveVersion = dreamweave.GetDreamweaveVersion()

    if string.sub(dreamweaveVersion, 1, string.len(expectedDreamweaveVersion)) ~= expectedDreamweaveVersion then
        dreamweave.LogAppend(enumerations.log.ERROR, "- Version mismatch between server and Core scripts!")
        dreamweave.LogAppend(enumerations.log.ERROR, "- The Core scripts require a tes3mp version that starts with " ..
            expectedUpstreamVersion "\n" ..
	"- And a Dreamweave version that starts with " ..
	expectedDreamweaveVersion)
        dreamweave.StopServer(1)
    end

    local eventStatus = customEventHooks.triggerValidators("OnServerInit", {})

    if eventStatus.validDefaultHandler then
        logicHandler.InitializeWorld()

        for _, recordStoreTypes in ipairs(config.recordStoreLoadOrder) do
            for _, storeType in ipairs(recordStoreTypes) do
                logicHandler.LoadRecordStore(storeType)
            end
        end

        hourCounter = WorldInstance.data.time.hour
        WorldInstance:UpdateFrametimeMultiplier()

        updateTimerId = dreamweave.CreateTimer("UpdateTime", time.seconds(1))
        dreamweave.StartTimer(updateTimerId)

        logicHandler.PushPlayerList(Players)

        LoadBanList()

        dreamweave.SetDataFileEnforcementState(config.enforceDataFiles)
        dreamweave.SetScriptErrorIgnoringState(config.ignoreScriptErrors)
    end

    customEventHooks.triggerHandlers("OnServerInit", eventStatus, {})
end

function OnServerPostInit()
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnServerPostInit\"")
    local eventStatus = customEventHooks.triggerValidators("OnServerPostInit", {})
    if not eventStatus.validDefaultHandler then return end

    clientVariableScopes = require("clientVariableScopes")
    speechCollections = require("speechCollections")

    eventHandler.InitializeDefaultValidators()
    eventHandler.InitializeDefaultHandlers()

    dreamweave.SetGameMode(config.gameMode)

    local consoleRuleString = "allowed"
    if not config.allowConsole then
        consoleRuleString = "not " .. consoleRuleString
    end

    local bedRestRuleString = "allowed"
    if not config.allowBedRest then
        bedRestRuleString = "not " .. bedRestRuleString
    end

    local wildRestRuleString = "allowed"
    if not config.allowWildernessRest then
        wildRestRuleString = "not " .. wildRestRuleString
    end

    local waitRuleString = "allowed"
    if not config.allowWait then
        waitRuleString = "not " .. waitRuleString
    end

    dreamweave.SetRuleString("enforceDataFiles", tostring(config.enforceDataFiles))
    dreamweave.SetRuleString("ignoreScriptErrors", tostring(config.ignoreScriptErrors))
    dreamweave.SetRuleValue("difficulty", config.difficulty)
    dreamweave.SetRuleValue("deathPenaltyJailDays", config.deathPenaltyJailDays)
    dreamweave.SetRuleString("console", consoleRuleString)
    dreamweave.SetRuleString("bedResting", bedRestRuleString)
    dreamweave.SetRuleString("wildernessResting", wildRestRuleString)
    dreamweave.SetRuleString("waiting", waitRuleString)
    dreamweave.SetRuleValue("enforcedLogLevel", config.enforcedLogLevel)
    dreamweave.SetRuleValue("physicsFramerate", config.physicsFramerate)
    dreamweave.SetRuleString("shareJournal", tostring(config.shareJournal))
    dreamweave.SetRuleString("shareFactionRanks", tostring(config.shareFactionRanks))
    dreamweave.SetRuleString("shareFactionExpulsion", tostring(config.shareFactionExpulsion))
    dreamweave.SetRuleString("shareFactionReputation", tostring(config.shareFactionReputation))
    dreamweave.SetRuleString("shareTopics", tostring(config.shareTopics))
    dreamweave.SetRuleString("shareBounty", tostring(config.shareBounty))
    dreamweave.SetRuleString("shareReputation", tostring(config.shareReputation))
    dreamweave.SetRuleString("shareMapExploration", tostring(config.shareMapExploration))
    dreamweave.SetRuleString("enablePlacedObjectCollision", tostring(config.enablePlacedObjectCollision))

    local respawnCell

    if config.respawnAtImperialShrine then
        respawnCell = "nearest Imperial shrine"

        if config.respawnAtTribunalTemple then
            respawnCell = respawnCell .. " or Tribunal temple"
        end
    elseif config.respawnAtTribunalTemple then
        respawnCell = "nearest Tribunal temple"
    elseif type(config.defaultRespawn) == "table" then
        respawnCell = config.defaultRespawn.cellDescription
    end

    if respawnCell then
        dreamweave.SetRuleString("respawnCell", respawnCell)
    end

    customEventHooks.triggerHandlers("OnServerPostInit", eventStatus, {})
end

function OnServerExit(errorState)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnServerExit\"")
    dreamweave.LogMessage(enumerations.log.ERROR, "Error state: " .. tostring(errorState))
    customEventHooks.triggerHandlers("OnServerExit", customEventHooks.makeEventStatus(true, true) , {errorState})
end

function OnServerScriptCrash(errorMessage)
    dreamweave.LogMessage(enumerations.log.ERROR, "Server crash from script error!")
    customEventHooks.triggerHandlers("OnServerExit", customEventHooks.makeEventStatus(true, true), {errorMessage})
end

function LoadDataFileList(filename)
    local dataFileList = {}
    dreamweave.LogMessage(enumerations.log.INFO, "Reading " .. filename)

    local jsonDataFileList = jsonInterface.load(filename)

    if not jsonDataFileList then
        dreamweave.LogMessage(enumerations.log.ERROR, "Data file list " .. filename .. " cannot be read!")
        dreamweave.StopServer(2)
        return
    end

    tableHelper.fixNumericalKeys(jsonDataFileList, true)

    for listIndex, pluginEntry in ipairs(jsonDataFileList) do
        for entryIndex, checksumStringArray in pairs(pluginEntry) do
            dataFileList[listIndex] = {}
            dataFileList[listIndex].name = entryIndex
            local checksums = {}
            local debugMessage = ("- %d: \"%s\": ["):format(listIndex, entryIndex)

            for _, checksumString in ipairs(checksumStringArray) do
                debugMessage = debugMessage .. ("%X, "):format(tonumber(checksumString, 16))
                table.insert(checksums, tonumber(checksumString, 16))
            end

            dataFileList[listIndex].checksums = checksums
            table.insert(dataFileList[listIndex], "")
            debugMessage = debugMessage .. "\b\b]"
            dreamweave.LogAppend(enumerations.log.WARN, debugMessage)
        end
    end

    return dataFileList
end

function OnRequestDataFileList()

    local dataFileList = LoadDataFileList("requiredDataFiles.json")

    for _, entry in ipairs(dataFileList) do
        local name = entry.name
        table.insert(clientDataFiles, name)

        if tableHelper.isEmpty(entry.checksums) then
            dreamweave.AddDataFileRequirement(name, "")
        else
            for _, checksum in ipairs(entry.checksums) do
                dreamweave.AddDataFileRequirement(name, checksum)
            end
        end
    end
end

-- Older server builds will call an "OnRequestPluginList" event instead of
-- "OnRequestDataFileList", so keep this around for backwards compatibility
function OnRequestPluginList()
    OnRequestDataFileList()
end

function OnPlayerConnect(pid)

    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerConnect\" for pid " .. pid)

    local playerName = dreamweave.GetName(pid)

    if string.len(playerName) > 35 then
        playerName = string.sub(playerName, 0, 35)
    end

    if not logicHandler.IsNameAllowed(playerName) then
        local message = playerName .. " (" .. pid .. ") " .. "joined and tried to use a disallowed name.\n"
        dreamweave.SendMessage(pid, message, true)
        dreamweave.Kick(pid)
    elseif logicHandler.IsPlayerNameLoggedIn(playerName) then
        local message = playerName .. " (" .. pid .. ") " .. "joined and tried to use an existing player's name.\n"
        dreamweave.SendMessage(pid, message, true)
        dreamweave.Kick(pid)
    else
        dreamweave.LogAppend(enumerations.log.INFO, "- New player is named " .. playerName)
        eventHandler.OnPlayerConnect(pid, playerName)
    end
end

function OnPlayerDisconnect(pid)

    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerDisconnect\" for " .. logicHandler.GetChatName(pid))

    eventHandler.OnPlayerDisconnect(pid)
end

function OnPlayerResurrect(pid)
    customEventHooks.triggerHandlers("OnPlayerResurrect", customEventHooks.makeEventStatus(true, true), {pid})
end

function OnPlayerSendMessage(pid, message)
    eventHandler.OnPlayerSendMessage(pid, message)
end

function OnPlayerDeath(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerDeath\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerDeath(pid)
end

function OnPlayerAttribute(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerAttribute\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerAttribute(pid)
end

function OnPlayerSkill(pid)
    eventHandler.OnPlayerSkill(pid)
end

function OnPlayerLevel(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerLevel\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerLevel(pid)
end

function OnPlayerShapeshift(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerShapeshift\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerShapeshift(pid)
end

function OnPlayerCellChange(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerCellChange\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerCellChange(pid)
end

function OnPlayerEquipment(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerEquipment\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerEquipment(pid)
end

function OnPlayerInventory(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerInventory\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerInventory(pid)
end

function OnPlayerSpellbook(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerSpellbook\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerSpellbook(pid)
end

function OnPlayerSpellsActive(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerSpellsActive\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerSpellsActive(pid)
end

function OnPlayerCooldowns(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerCooldowns\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerCooldowns(pid)
end

function OnPlayerQuickKeys(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerQuickKeys\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerQuickKeys(pid)
end

function OnPlayerJournal(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerJournal\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerJournal(pid)
end

function OnPlayerFaction(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerFaction\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerFaction(pid)
end

function OnPlayerTopic(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerTopic\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerTopic(pid)
end

function OnPlayerBounty(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerBounty\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerBounty(pid)
end

function OnPlayerReputation(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerReputation\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerReputation(pid)
end

function OnPlayerBook(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerBook\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerBook(pid)
end

function OnPlayerItemUse(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerItemUse\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerItemUse(pid)
end

function OnPlayerMiscellaneous(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerMiscellaneous\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerMiscellaneous(pid)
end

function OnPlayerEndCharGen(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnPlayerEndCharGen\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnPlayerEndCharGen(pid)
end

function OnCellLoad(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnCellLoad\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnCellLoad(pid, cellDescription)
end

function OnCellUnload(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnCellUnload\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnCellUnload(pid, cellDescription)
end

function OnCellDeletion(cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnCellDeletion\" for cell " .. cellDescription)
    eventHandler.OnCellDeletion(cellDescription)
end

function OnActorList(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnActorList\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnActorList(pid, cellDescription)
end

function OnActorEquipment(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnActorEquipment\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnActorEquipment(pid, cellDescription)
end

function OnActorAI(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnActorAI\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnActorAI(pid, cellDescription)
end

function OnActorDeath(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnActorDeath\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnActorDeath(pid, cellDescription)
end

function OnActorSpellsActive(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnActorSpellsActive\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnActorSpellsActive(pid, cellDescription)
end

function OnActorCellChange(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnActorCellChange\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnActorCellChange(pid, cellDescription)
end

function OnObjectActivate(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectActivate\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectActivate(pid, cellDescription)
end

function OnObjectHit(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectHit\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectHit(pid, cellDescription)
end

function OnObjectPlace(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectPlace\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectPlace(pid, cellDescription)
end

function OnObjectSpawn(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectSpawn\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectSpawn(pid, cellDescription)
end

function OnObjectDelete(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectDelete\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectDelete(pid, cellDescription)
end

function OnObjectLock(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectLock\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectLock(pid, cellDescription)
end

function OnObjectDialogueChoice(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectDialogueChoice\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectDialogueChoice(pid, cellDescription)
end

function OnObjectMiscellaneous(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectMiscellaneous\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectMiscellaneous(pid, cellDescription)
end

function OnObjectRestock(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectRestock\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectRestock(pid, cellDescription)
end

function OnObjectTrap(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectTrap\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectTrap(pid, cellDescription)
end

function OnObjectScale(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectScale\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectScale(pid, cellDescription)
end

function OnObjectSound(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectSound\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectSound(pid, cellDescription)
end

function OnObjectState(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnObjectState\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnObjectState(pid, cellDescription)
end

function OnDoorState(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnDoorState\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnDoorState(pid, cellDescription)
end

function OnConsoleCommand(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnConsoleCommand\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnConsoleCommand(pid, cellDescription)
end

function OnContainer(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnContainer\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnContainer(pid, cellDescription)
end

function OnVideoPlay(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnVideoPlay\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnVideoPlay(pid)
end

function OnRecordDynamic(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnRecordDynamic\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnRecordDynamic(pid)
end

function OnWorldKillCount(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnWorldKillCount\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnWorldKillCount(pid)
end

function OnWorldMap(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnWorldMap\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnWorldMap(pid)
end

function OnWorldWeather(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnWorldWeather\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnWorldWeather(pid)
end

function OnClientScriptLocal(pid, cellDescription)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnClientScriptLocal\" for " .. logicHandler.GetChatName(pid) ..
        " and cell " .. cellDescription)
    eventHandler.OnClientScriptLocal(pid, cellDescription)
end

function OnClientScriptGlobal(pid)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnClientScriptGlobal\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnClientScriptGlobal(pid)
end

function OnGUIAction(pid, idGui, data)
    dreamweave.LogMessage(enumerations.log.INFO, "Called \"OnGUIAction\" for " .. logicHandler.GetChatName(pid))
    eventHandler.OnGUIAction(pid, idGui, data)
end

function OnMpNumIncrement(currentMpNum)
    eventHandler.OnMpNumIncrement(currentMpNum)
end

-- Timer-based events
function OnLoginTimeExpiration(pid, accountName)
    eventHandler.OnLoginTimeExpiration(pid, accountName)
end

function OnDeathTimeExpiration(pid, accountName)
    eventHandler.OnDeathTimeExpiration(pid, accountName)
end

function OnObjectLoopTimeExpiration(loopIndex)
    eventHandler.OnObjectLoopTimeExpiration(loopIndex)
end
