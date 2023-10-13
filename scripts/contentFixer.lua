tableHelper = require("tableHelper")

require("utils")

---@class contentFixer
local contentFixer = {}

local deadlyItems = { "keening", "sunder" }
local fixesByCell = {}

-- Delete the chargen boat and associated guards and objects
fixesByCell["-1, -9"] = { disable =  { 268178, 297457, 297459, 297460, 299125 }}
fixesByCell["-2, -9"] = { disable = { 172848, 172850, 172852, 289104, 297461, 397559 }}
fixesByCell["-2, -10"] = { disable = { 297463, 297464, 297465, 297466 }}

-- Delete the census papers and unlock the doors
fixesByCell["Seyda Neen, Census and Excise Office"] = { disable = { 172859 }, unlock = { 119513, 172860 }}

---@param pid integer Player ID
---@param cellDescription string Cell Name
function contentFixer.FixCell(pid, cellDescription)
    if fixesByCell[cellDescription] == nil then return end

    for action, refNumArray in pairs(fixesByCell[cellDescription]) do

        tes3mp.ClearObjectList()
        tes3mp.SetObjectListPid(pid)
        tes3mp.SetObjectListCell(cellDescription)

        for arrayIndex, refNum in ipairs(refNumArray) do
            tes3mp.SetObjectRefNum(refNum)
            tes3mp.SetObjectMpNum(0)
            tes3mp.SetObjectRefId("")
            if action == "disable" then tes3mp.SetObjectState(false) end
            if action == "unlock" then tes3mp.SetObjectLockLevel(0) end
            tes3mp.AddObject()
        end

        if action == "delete" then
            tes3mp.SendObjectDelete()
        elseif action == "disable" then
            tes3mp.SendObjectState()
        elseif action == "unlock" then
            tes3mp.SendObjectLock()
        end
    end
end

-- Unequip items that damage the player when worn
--
-- Note: Items with constant damage effects like Whitewalker and the Mantle of Woe
--       are already unequipped by default in the TES3MP client, so this only needs
--       to account for scripted items that are missed there
--
---@param pid integer Player ID
function contentFixer.UnequipDeadlyItems(pid)

    local itemsFound = 0

    for _, itemRefId in pairs(deadlyItems) do
        if tableHelper.containsKeyValue(Players[pid].data.equipment, "refId", itemRefId, true) then
            local itemSlot = tableHelper.getIndexByNestedKeyValue(Players[pid].data.equipment, "refId", itemRefId, true)
            Players[pid].data.equipment[itemSlot] = nil
            itemsFound = itemsFound + 1
        end
    end

    if itemsFound > 0 then
        Players[pid]:QuicksaveToDrive()
        Players[pid]:LoadEquipment()
    end
end

---@param pid integer PlayerID
function contentFixer.AdjustSharedCorprusState(pid)

    local corprusId = "corprus"

    if WorldInstance.data.customVariables.corprusCured == true then
        if tableHelper.containsValue(Players[pid].data.spellbook, corprusId) == true then
        
            tableHelper.removeValue(Players[pid].data.spellbook, corprusId)
            tableHelper.cleanNils(Players[pid].data.spellbook)

            tes3mp.ClearSpellbookChanges(pid)
            tes3mp.SetSpellbookChangesAction(pid, enumerations.spellbook.REMOVE)
            tes3mp.AddSpell(pid, corprusId)
            tes3mp.SendSpellbookChanges(pid)

            tes3mp.ClearSpellbookChanges(pid)
            tes3mp.SetSpellbookChangesAction(pid, enumerations.spellbook.ADD)
            for _, spellId in ipairs({"common disease immunity", "blight disease immunity","corprus immunity"}) do
                table.insert(Players[pid].data.spellbook, spellId)
                tes3mp.AddSpell(pid, spellId)
            end
            tes3mp.SendSpellbookChanges(pid)
            tes3mp.MessageBox(pid, -1, "You have been cured of corprus.")
        end
    elseif WorldInstance.data.customVariables.corprusGained == true then
        if tableHelper.containsValue(Players[pid].data.spellbook, corprusId) == false then

            table.insert(Players[pid].data.spellbook, corprusId)

            tes3mp.ClearSpellbookChanges(pid)
            tes3mp.SetSpellbookChangesAction(pid, enumerations.spellbook.ADD)
            tes3mp.AddSpell(pid, corprusId)
            tes3mp.SendSpellbookChanges(pid)
            tes3mp.MessageBox(pid, -1, "You have been afflicted with corprus.")
        end
    end
end

---@param journal table
---@return boolean madeAdjustment Has cell lost/gained corprus
function contentFixer.AdjustWorldCorprusVariables(journal)
    for _, journalItem in ipairs(journal) do
        if journalItem.quest == "a2_3_corpruscure" and journalItem.index >= 50 then
            WorldInstance.data.customVariables.corprusCured = true
            return true
        elseif journalItem.quest == "a2_2_6thhouse" and journalItem.index >= 50 then
            WorldInstance.data.customVariables.corprusGained = true
            return true 
        end
    end

    return false
end

---@param eventStatus boolean
---@param pid integer Player ID
---@param playerPacket table
customEventHooks.registerHandler("OnPlayerJournal", function(eventStatus, pid, playerPacket)
    if config.shareJournal == false then return end
    local madeAdjustment = contentFixer.AdjustWorldCorprusVariables(playerPacket.journal)

    if madeAdjustment == false then return end
    for otherPid, otherPlayer in pairs(Players) do
        if otherPid ~= pid then
            contentFixer.AdjustSharedCorprusState(otherPid)
        end
    end
end)


---@param eventStatus string
---@param pid integer Player ID
customEventHooks.registerHandler("OnPlayerFinishLogin", function(eventStatus, pid)
    if config.shareJournal == true then
        contentFixer.AdjustSharedCorprusState(pid)
    end
end)

---@param eventStatus string
customEventHooks.registerHandler("OnWorldReload", function(eventStatus)
    if config.shareJournal == true then
        contentFixer.AdjustWorldCorprusVariables(WorldInstance.data.journal)
    end
end)

return contentFixer
