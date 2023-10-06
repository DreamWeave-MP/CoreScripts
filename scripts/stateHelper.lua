StateHelper = class("StateHelper")

function StateHelper:LoadJournal(pid, stateObject)

    if not stateObject.data.journal then
        stateObject.data.journal = {}
    end

    dreamweave.ClearJournalChanges(pid)

    for _, journalItem in pairs(stateObject.data.journal) do
        if journalItem.type == enumerations.journal.ENTRY then

            if not journalItem.actorRefId then
                journalItem.actorRefId = "player"
            end

            if journalItem.timestamp then
                dreamweave.AddJournalEntryWithTimestamp(pid, journalItem.quest, journalItem.index, journalItem.actorRefId,
                    journalItem.timestamp.daysPassed, journalItem.timestamp.month, journalItem.timestamp.day)
            else
                dreamweave.AddJournalEntry(pid, journalItem.quest, journalItem.index, journalItem.actorRefId)
            end
        else
            dreamweave.AddJournalIndex(pid, journalItem.quest, journalItem.index)
        end
    end

    dreamweave.SendJournalChanges(pid)
end

function StateHelper:LoadFactionRanks(pid, stateObject)

    if not stateObject.data.factionRanks then
        stateObject.data.factionRanks = {}
    end

    dreamweave.ClearFactionChanges(pid)
    dreamweave.SetFactionChangesAction(pid, enumerations.faction.RANK)

    for factionId, rank in pairs(stateObject.data.factionRanks) do
        dreamweave.SetFactionId(factionId)
        dreamweave.SetFactionRank(rank)
        dreamweave.AddFaction(pid)
    end

    dreamweave.SendFactionChanges(pid)
end

function StateHelper:LoadFactionExpulsion(pid, stateObject)

    if not stateObject.data.factionExpulsion then
        stateObject.data.factionExpulsion = {}
    end

    dreamweave.ClearFactionChanges(pid)
    dreamweave.SetFactionChangesAction(pid, enumerations.faction.EXPULSION)

    for factionId, state in pairs(stateObject.data.factionExpulsion) do
        dreamweave.SetFactionId(factionId)
        dreamweave.SetFactionExpulsionState(state)
        dreamweave.AddFaction(pid)
    end

    dreamweave.SendFactionChanges(pid)
end

function StateHelper:LoadFactionReputation(pid, stateObject)
    if not stateObject.data.factionReputation then
        stateObject.data.factionReputation = {}
    end

    dreamweave.ClearFactionChanges(pid)
    dreamweave.SetFactionChangesAction(pid, enumerations.faction.REPUTATION)

    for factionId, reputation in pairs(stateObject.data.factionReputation) do
        dreamweave.SetFactionId(factionId)
        dreamweave.SetFactionReputation(reputation)
        dreamweave.AddFaction(pid)
    end

    dreamweave.SendFactionChanges(pid)
end

function StateHelper:LoadTopics(pid, stateObject)

    if not stateObject.data.topics then
        stateObject.data.topics = {}
    end

    dreamweave.ClearTopicChanges(pid)

    for _, topicId in pairs(stateObject.data.topics) do

        dreamweave.AddTopic(pid, topicId)
    end

    dreamweave.SendTopicChanges(pid)
end

function StateHelper:LoadBounty(pid, stateObject)

    if not stateObject.data.fame then
        stateObject.data.fame = { bounty = 0, reputation = 0 }
    elseif not stateObject.data.fame.bounty then
        stateObject.data.fame.bounty = 0
    end

    -- Update old player files to the new format
    if stateObject.data.stats and stateObject.data.stats.bounty then
        stateObject.data.fame.bounty = stateObject.data.stats.bounty
        stateObject.data.stats.bounty = nil
    end

    dreamweave.SetBounty(pid, stateObject.data.fame.bounty)
    dreamweave.SendBounty(pid)
end

function StateHelper:LoadReputation(pid, stateObject)

    if not stateObject.data.fame then
        stateObject.data.fame = { bounty = 0, reputation = 0 }
    elseif not stateObject.data.fame.reputation then
        stateObject.data.fame.reputation = 0
    end

    dreamweave.SetReputation(pid, stateObject.data.fame.reputation)
    dreamweave.SendReputation(pid)
end

function StateHelper:LoadClientScriptVariables(pid, stateObject)

    if not stateObject.data.clientVariables then
        stateObject.data.clientVariables = {}
    end

    if not stateObject.data.clientVariables.globals then
        stateObject.data.clientVariables.globals = {}
    end

    local variableCount = 0

    dreamweave.ClearClientGlobals()

    for variableId, variableTable in pairs(stateObject.data.clientVariables.globals) do
        if type(variableTable) == "table" then

            if variableTable.variableType == enumerations.variableType.SHORT then
                dreamweave.AddClientGlobalInteger(variableId, variableTable.intValue, enumerations.variableType.SHORT)
            elseif variableTable.variableType == enumerations.variableType.LONG then
                dreamweave.AddClientGlobalInteger(variableId, variableTable.intValue, enumerations.variableType.LONG)
            elseif variableTable.variableType == enumerations.variableType.FLOAT then
                dreamweave.AddClientGlobalFloat(variableId, variableTable.floatValue)
            end

            variableCount = variableCount + 1
        end
    end

    if variableCount > 0 then
        dreamweave.SendClientScriptGlobal(pid)
    end
end

function StateHelper:LoadDestinationOverrides(pid, stateObject)

    if not stateObject.data.destinationOverrides then
        stateObject.data.destinationOverrides = {}
    end

    local destinationCount = 0

    dreamweave.ClearDestinationOverrides()

    for oldCellDescription, newCellDescription in pairs(stateObject.data.destinationOverrides) do

        dreamweave.AddDestinationOverride(oldCellDescription, newCellDescription)
        destinationCount = destinationCount + 1
    end

    if destinationCount > 0 then
        dreamweave.SendWorldDestinationOverride(pid)
    end
end

function StateHelper:LoadMap(pid, stateObject)

    if not stateObject.data.mapExplored then
        stateObject.data.mapExplored = {}
    end

    local tileCount = 0
    dreamweave.ClearMapChanges()

    for index, cellDescription in pairs(stateObject.data.mapExplored) do

        local filePath = config.dataPath .. "/map/" .. cellDescription .. ".png"

        if dreamweave.DoesFilePathExist(filePath) then

            local cellX, cellY
            _, _, cellX, cellY = string.find(cellDescription, patterns.exteriorCell)
            cellX = tonumber(cellX)
            cellY = tonumber(cellY)

            if type(cellX) == "number" and type(cellY) == "number" then
                dreamweave.LoadMapTileImageFile(cellX, cellY, filePath)
                tileCount = tileCount + 1
            end
        end
    end

    if tileCount > 0 then
        dreamweave.SendWorldMap(pid)
    end
end

function StateHelper:SaveJournal(stateObject, playerPacket)

    if not stateObject.data.journal then
        stateObject.data.journal = {}
    end

    if not stateObject.data.customVariables then
        stateObject.data.customVariables = {}
    end

    for _, journalItem in ipairs(playerPacket.journal) do
        table.insert(stateObject.data.journal, journalItem)

        if journalItem.quest == "a1_1_findspymaster" and journalItem.index >= 14 then
            stateObject.data.customVariables.deliveredCaiusPackage = true
        end
    end

    stateObject:QuicksaveToDrive()
end

function StateHelper:SaveFactionRanks(pid, stateObject)
    if not stateObject.data.factionRanks then
        stateObject.data.factionRanks = {}
    end

    for i = 0, dreamweave.GetFactionChangesSize(pid) - 1 do

        local factionId = dreamweave.GetFactionId(pid, i)
        stateObject.data.factionRanks[factionId] = dreamweave.GetFactionRank(pid, i)
    end

    stateObject:QuicksaveToDrive()
end

function StateHelper:SaveFactionExpulsion(pid, stateObject)

    if not stateObject.data.factionExpulsion then
        stateObject.data.factionExpulsion = {}
    end

    for i = 0, dreamweave.GetFactionChangesSize(pid) - 1 do

        local factionId = dreamweave.GetFactionId(pid, i)
        stateObject.data.factionExpulsion[factionId] = dreamweave.GetFactionExpulsionState(pid, i)
    end

    stateObject:QuicksaveToDrive()
end

function StateHelper:SaveFactionReputation(pid, stateObject)

    if not stateObject.data.factionReputation then
        stateObject.data.factionReputation = {}
    end

    for i = 0, dreamweave.GetFactionChangesSize(pid) - 1 do
        local factionId = dreamweave.GetFactionId(pid, i)
        stateObject.data.factionReputation[factionId] = dreamweave.GetFactionReputation(pid, i)
    end

    stateObject:QuicksaveToDrive()
end

function StateHelper:SaveTopics(pid, stateObject)

    if not stateObject.data.topics then
        stateObject.data.topics = {}
    end

    for i = 0, dreamweave.GetTopicChangesSize(pid) - 1 do
        local topicId = dreamweave.GetTopicId(pid, i)

        if not tableHelper.containsValue(stateObject.data.topics, topicId) then
            table.insert(stateObject.data.topics, topicId)
        end
    end

    stateObject:QuicksaveToDrive()
end

function StateHelper:SaveBounty(pid, stateObject)

    if not stateObject.data.fame then
        stateObject.data.fame = {}
    end

    stateObject.data.fame.bounty = dreamweave.GetBounty(pid)

    stateObject:QuicksaveToDrive()
end

function StateHelper:SaveReputation(pid, stateObject)

    if not stateObject.data.fame then
        stateObject.data.fame = {}
    end

    stateObject.data.fame.reputation = dreamweave.GetReputation(pid)

    stateObject:QuicksaveToDrive()
end

function StateHelper:SaveClientScriptGlobal(stateObject, variables)

    if not stateObject.data.clientVariables then
        stateObject.data.clientVariables = {}
    end

    if not stateObject.data.clientVariables.globals then
        stateObject.data.clientVariables.globals = {}
    end

    for id, variable in pairs (variables) do
        stateObject.data.clientVariables.globals[id] = variable
    end

    stateObject:QuicksaveToDrive()
end

function StateHelper:SaveMapExploration(pid, stateObject)

    local cell = dreamweave.GetCell(pid)

    if dreamweave.IsInExterior(pid) == true then
        if not tableHelper.containsValue(stateObject.data.mapExplored, cell) then
            table.insert(stateObject.data.mapExplored, cell)
        end
    end
end

return StateHelper
