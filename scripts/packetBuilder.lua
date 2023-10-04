packetBuilder = {}

packetBuilder.AddPlayerInventoryItemChange = function(pid, item)

    -- Use default values when necessary
    if item.charge == nil or item.charge < -1 then item.charge = -1 end
    if item.enchantmentCharge == nil or item.enchantmentCharge < -1 then item.enchantmentCharge = -1 end
    if item.soul == nil then item.soul = "" end

    dreamweave.AddItemChange(pid, item.refId, item.count, item.charge, item.enchantmentCharge, item.soul)
end

packetBuilder.AddPlayerSpellsActive = function(pid, spellsActive, action)

    dreamweave.ClearSpellsActiveChanges(pid)
    dreamweave.SetSpellsActiveChangesAction(pid, action)

    for spellId, spellInstances in pairs(spellsActive) do
        for spellInstanceIndex, spellInstanceValues in pairs(spellInstances) do

            if action == enumerations.spellbook.SET or action == enumerations.spellbook.ADD then
                if spellInstanceValues.caster ~= nil and spellInstanceValues.caster.playerName ~= nil then
                    local casterName = spellInstanceValues.caster.playerName

                    if logicHandler.IsPlayerNameLoggedIn(casterName) then
                        local casterPid = logicHandler.GetPidByName(casterName)
                        dreamweave.SetSpellsActiveCasterPid(casterPid)
                    end
                end

                for effectIndex, effectTable in pairs(spellInstanceValues.effects) do

                    if effectTable.timeLeft > 0 then
                        dreamweave.AddSpellActiveEffect(pid, effectTable.id, effectTable.magnitude,
                            effectTable.duration, effectTable.timeLeft, effectTable.arg)
                    end
                end
            end

            dreamweave.AddSpellActive(pid, spellId, spellInstanceValues.displayName,
                spellInstanceValues.stackingState)
        end
    end
end

packetBuilder.AddObjectDelete = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    if objectData.refId ~= nil then dreamweave.SetObjectRefId(objectData.refId) end
    dreamweave.AddObject()
end

packetBuilder.AddObjectPlace = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    dreamweave.SetObjectRefId(objectData.refId)

    local count = objectData.count
    local charge = objectData.charge
    local enchantmentCharge = objectData.enchantmentCharge
    local soul = objectData.soul
    local goldValue = objectData.goldValue
    local droppedByPlayer = objectData.droppedByPlayer

    -- Use default values when necessary
    if count == nil then count = 1 end
    if charge == nil then charge = -1 end
    if enchantmentCharge == nil then enchantmentCharge = -1 end
    if soul == nil then soul = "" end
    if goldValue == nil then goldValue = 1 end
    if droppedByPlayer == nil then droppedByPlayer = false end

    dreamweave.SetObjectCount(count)
    dreamweave.SetObjectCharge(charge)
    dreamweave.SetObjectEnchantmentCharge(enchantmentCharge)
    dreamweave.SetObjectSoul(soul)
    dreamweave.SetObjectGoldValue(goldValue)
    dreamweave.SetObjectDroppedByPlayerState(droppedByPlayer)

    local location = objectData.location
    dreamweave.SetObjectPosition(location.posX, location.posY, location.posZ)
    dreamweave.SetObjectRotation(location.rotX, location.rotY, location.rotZ)

    dreamweave.AddObject()
end

packetBuilder.AddObjectSpawn = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    dreamweave.SetObjectRefId(objectData.refId)

    if objectData.summon ~= nil then
        dreamweave.SetObjectSummonState(true)
        dreamweave.SetObjectSummonEffectId(objectData.summon.effectId)
        dreamweave.SetObjectSummonSpellId(objectData.summon.spellId)

        local currentTime = os.time()
        local finishTime = objectData.summon.startTime + objectData.summon.duration
        dreamweave.SetObjectSummonDuration(finishTime - currentTime)

        if objectData.summon.summoner.playerName then
            local player = logicHandler.GetPlayerByName(objectData.summon.summoner.playerName)
            dreamweave.SetObjectSummonerPid(player.pid)
        else
            local summonerSplitIndex = objectData.summon.summoner.uniqueIndex:split("-")
            dreamweave.SetObjectSummonerRefNum(summonerSplitIndex[1])
            dreamweave.SetObjectSummonerMpNum(summonerSplitIndex[2])
        end
    end

    local location = objectData.location
    dreamweave.SetObjectPosition(location.posX, location.posY, location.posZ)
    dreamweave.SetObjectRotation(location.rotX, location.rotY, location.rotZ)

    dreamweave.AddObject()
end

packetBuilder.AddObjectLock = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    if objectData.refId ~= nil then dreamweave.SetObjectRefId(objectData.refId) end
    dreamweave.SetObjectLockLevel(objectData.lockLevel)
    dreamweave.AddObject()
end

packetBuilder.AddObjectMiscellaneous = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    if objectData.refId ~= nil then dreamweave.SetObjectRefId(objectData.refId) end
    dreamweave.SetObjectGoldPool(objectData.goldPool)
    dreamweave.SetObjectLastGoldRestockHour(objectData.lastGoldRestockHour)
    dreamweave.SetObjectLastGoldRestockDay(objectData.lastGoldRestockDay)
    dreamweave.AddObject()
end

packetBuilder.AddObjectTrap = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    if objectData.refId ~= nil then dreamweave.SetObjectRefId(objectData.refId) end
    if objectData.trapSpellId ~= nil then dreamweave.SetObjectTrapSpellId(objectData.trapSpellId) end
    
    if objectData.trapAction ~= nil then
        dreamweave.SetObjectTrapAction(objectData.trapAction)
    else
        dreamweave.SetObjectTrapAction(enumerations.trap.SET_TRAP)
    end
    
    dreamweave.AddObject()
end

packetBuilder.AddObjectScale = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    if objectData.refId ~= nil then dreamweave.SetObjectRefId(objectData.refId) end
    dreamweave.SetObjectScale(objectData.scale)
    dreamweave.AddObject()
end

packetBuilder.AddObjectState = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    if objectData.refId ~= nil then dreamweave.SetObjectRefId(objectData.refId) end
    dreamweave.SetObjectState(objectData.state)
    dreamweave.AddObject()
end

packetBuilder.AddDoorState = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    if objectData.refId ~= nil then dreamweave.SetObjectRefId(objectData.refId) end
    dreamweave.SetObjectDoorState(objectData.doorState)
    dreamweave.AddObject()
end

packetBuilder.AddDoorDestination = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    dreamweave.SetObjectRefId(objectData.refId)
    local destination = objectData.doorDestination
    dreamweave.SetObjectDoorTeleportState(destination.teleport)
    dreamweave.SetObjectDoorDestinationCell(destination.cell)
    dreamweave.SetObjectDoorDestinationPosition(destination.posX, destination.posY, destination.posZ)
    dreamweave.SetObjectDoorDestinationRotation(destination.rotX, destination.rotZ)
    dreamweave.AddObject()
end

packetBuilder.AddClientScriptLocal = function(uniqueIndex, objectData)

    local splitIndex = uniqueIndex:split("-")
    dreamweave.SetObjectRefNum(splitIndex[1])
    dreamweave.SetObjectMpNum(splitIndex[2])
    if objectData.refId ~= nil then dreamweave.SetObjectRefId(objectData.refId) end

    local variableCount = 0

    for variableType, variableTable in pairs(objectData.variables) do

        if type(variableTable) == "table" then

            for internalIndex, value in pairs(variableTable) do

                if variableType == enumerations.variableType.SHORT then
                    dreamweave.AddClientLocalInteger(tonumber(internalIndex), value, enumerations.variableType.SHORT)
                elseif variableType == enumerations.variableType.LONG then
                    dreamweave.AddClientLocalInteger(tonumber(internalIndex), value, enumerations.variableType.LONG)
                elseif variableType == enumerations.variableType.FLOAT then
                    dreamweave.AddClientLocalFloat(tonumber(internalIndex), value)
                end

                variableCount = variableCount + 1
            end
        end
    end

    if variableCount > 0 then
        dreamweave.AddObject()
    end
end

packetBuilder.AddAIActor = function(actorUniqueIndex, targetPid, aiData)

    local splitIndex = actorUniqueIndex:split("-")
    dreamweave.SetActorRefNum(splitIndex[1])
    dreamweave.SetActorMpNum(splitIndex[2])

    dreamweave.SetActorAIAction(aiData.action)

    if targetPid ~= nil then
        dreamweave.SetActorAITargetToPlayer(targetPid)
    elseif aiData.targetUniqueIndex ~= nil then
        local targetSplitIndex = aiData.targetUniqueIndex:split("-")

        if targetSplitIndex[2] ~= nil then
            dreamweave.SetActorAITargetToObject(targetSplitIndex[1], targetSplitIndex[2])
        end
    elseif aiData.posX ~= nil and aiData.posY ~= nil and aiData.posZ ~= nil then
        dreamweave.SetActorAICoordinates(aiData.posX, aiData.posY, aiData.posZ)
    elseif aiData.distance ~= nil then
        dreamweave.SetActorAIDistance(aiData.distance)
    elseif aiData.duration ~= nil then
        dreamweave.SetActorAIDuration(aiData.duration)
    end

    dreamweave.SetActorAIRepetition(aiData.shouldRepeat)

    dreamweave.AddActor()
end

packetBuilder.AddActorSpellsActive = function(actorUniqueIndex, spellsActive, action)

    local splitIndex = actorUniqueIndex:split("-")
    dreamweave.SetActorRefNum(splitIndex[1])
    dreamweave.SetActorMpNum(splitIndex[2])
    dreamweave.SetActorSpellsActiveAction(action)

    for spellId, spellInstances in pairs(spellsActive) do
        for spellInstanceIndex, spellInstanceValues in pairs(spellInstances) do

            if action == enumerations.spellbook.SET or action == enumerations.spellbook.ADD then
                for effectIndex, effectTable in pairs(spellInstanceValues.effects) do

                    if effectTable.timeLeft > 0 then
                        dreamweave.AddActorSpellActiveEffect(effectTable.id, effectTable.magnitude,
                            effectTable.duration, effectTable.timeLeft, effectTable.arg)
                    end
                end
            end

            dreamweave.AddActorSpellActive(spellId, spellInstanceValues.displayName,
                spellInstanceValues.stackingState)
        end
    end

    dreamweave.AddActor() 
end

packetBuilder.AddEffectToRecord = function(effect)

    dreamweave.SetRecordEffectId(effect.id)
    if effect.attribute ~= nil then dreamweave.SetRecordEffectAttribute(effect.attribute) end
    if effect.skill ~= nil then dreamweave.SetRecordEffectSkill(effect.skill) end
    if effect.rangeType ~= nil then dreamweave.SetRecordEffectRangeType(effect.rangeType) end
    if effect.area ~= nil then dreamweave.SetRecordEffectArea(effect.area) end
    if effect.duration ~= nil then dreamweave.SetRecordEffectDuration(effect.duration) end
    if effect.magnitudeMin ~= nil then dreamweave.SetRecordEffectMagnitudeMin(effect.magnitudeMin) end
    if effect.magnitudeMax ~= nil then dreamweave.SetRecordEffectMagnitudeMax(effect.magnitudeMax) end

    dreamweave.AddRecordEffect()
end

packetBuilder.AddBodyPartToRecord = function(part)

    dreamweave.SetRecordBodyPartType(part.partType)
    if part.malePart ~= nil then dreamweave.SetRecordBodyPartIdForMale(part.malePart) end
    if part.femalePart ~= nil then dreamweave.SetRecordBodyPartIdForFemale(part.femalePart) end

    dreamweave.AddRecordBodyPart()
end

packetBuilder.AddInventoryItemToRecord = function(item)

    dreamweave.SetRecordInventoryItemId(item.id)
    if item.count ~= nil then dreamweave.SetRecordInventoryItemCount(item.count) end

    dreamweave.AddRecordInventoryItem()
end

packetBuilder.AddRecordByType = function(id, record, storeType)

    if storeType == "activator" then
        packetBuilder.AddActivatorRecord(id, record)
    elseif storeType == "apparatus" then
        packetBuilder.AddApparatusRecord(id, record)
    elseif storeType == "armor" then
        packetBuilder.AddArmorRecord(id, record)
    elseif storeType == "bodypart" then
        packetBuilder.AddBodyPartRecord(id, record)
    elseif storeType == "book" then
        packetBuilder.AddBookRecord(id, record)
    elseif storeType == "cell" then
        packetBuilder.AddCellRecord(id, record)
    elseif storeType == "clothing" then
        packetBuilder.AddClothingRecord(id, record)
    elseif storeType == "container" then
        packetBuilder.AddContainerRecord(id, record)
    elseif storeType == "creature" then
        packetBuilder.AddCreatureRecord(id, record)
    elseif storeType == "door" then
        packetBuilder.AddDoorRecord(id, record)
    elseif storeType == "enchantment" then
        packetBuilder.AddEnchantmentRecord(id, record)
    elseif storeType == "gamesetting" then
        packetBuilder.AddGameSettingRecord(id, record)
    elseif storeType == "ingredient" then
        packetBuilder.AddIngredientRecord(id, record)
    elseif storeType == "light" then
        packetBuilder.AddLightRecord(id, record)
    elseif storeType == "lockpick" then
        packetBuilder.AddLockpickRecord(id, record)
    elseif storeType == "miscellaneous" then
        packetBuilder.AddMiscellaneousRecord(id, record)
    elseif storeType == "npc" then
        packetBuilder.AddNpcRecord(id, record)
    elseif storeType == "potion" then
        packetBuilder.AddPotionRecord(id, record)
    elseif storeType == "probe" then
        packetBuilder.AddProbeRecord(id, record)
    elseif storeType == "repair" then
        packetBuilder.AddRepairRecord(id, record)
    elseif storeType == "script" then
        packetBuilder.AddScriptRecord(id, record)
    elseif storeType == "sound" then
        packetBuilder.AddSoundRecord(id, record)
    elseif storeType == "spell" then
        packetBuilder.AddSpellRecord(id, record)
    elseif storeType == "static" then
        packetBuilder.AddStaticRecord(id, record)
    elseif storeType == "weapon" then
        packetBuilder.AddWeaponRecord(id, record)
    end
end

packetBuilder.AddActivatorRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    dreamweave.AddRecord()
end

packetBuilder.AddApparatusRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.subtype ~= nil then dreamweave.SetRecordSubtype(record.subtype) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.quality ~= nil then dreamweave.SetRecordQuality(record.quality) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    dreamweave.AddRecord()
end

packetBuilder.AddArmorRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.subtype ~= nil then dreamweave.SetRecordSubtype(record.subtype) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.health ~= nil then dreamweave.SetRecordHealth(record.health) end
    if record.armorRating ~= nil then dreamweave.SetRecordArmorRating(record.armorRating) end
    if record.enchantmentId ~= nil then dreamweave.SetRecordEnchantmentId(record.enchantmentId) end
    if record.enchantmentCharge ~= nil then dreamweave.SetRecordEnchantmentCharge(record.enchantmentCharge) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    if type(record.parts) == "table" then
        for _, part in pairs(record.parts) do
            packetBuilder.AddBodyPartToRecord(part)
        end
    end

    dreamweave.AddRecord()
end

packetBuilder.AddBodyPartRecord = function(id, record)
    
    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.subtype ~= nil then dreamweave.SetRecordSubtype(record.subtype) end
    if record.part ~= nil then dreamweave.SetRecordBodyPartType(record.part) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.race ~= nil then dreamweave.SetRecordRace(record.race) end
    if record.vampireState ~= nil then dreamweave.SetRecordVampireState(record.vampireState) end
    if record.flags ~= nil then dreamweave.SetRecordFlags(record.flags) end

    dreamweave.AddRecord()
end

packetBuilder.AddBookRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.text ~= nil then dreamweave.SetRecordText(record.text) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.scrollState ~= nil then dreamweave.SetRecordScrollState(record.scrollState) end
    if record.skillId ~= nil then dreamweave.SetRecordSkillId(record.skillId) end
    if record.enchantmentId ~= nil then dreamweave.SetRecordEnchantmentId(record.enchantmentId) end
    if record.enchantmentCharge ~= nil then dreamweave.SetRecordEnchantmentCharge(record.enchantmentCharge) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    dreamweave.AddRecord()
end

packetBuilder.AddCellRecord = function(id, record)

    dreamweave.SetRecordName(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.hasAmbient ~= nil then dreamweave.SetRecordHasAmbient(record.hasAmbient) end
    if record.ambient ~= nil then
        dreamweave.SetRecordAmbientColor(record.ambient.red, record.ambient.green, record.ambient.blue)
    end
    if record.sunlight ~= nil then
        dreamweave.SetRecordSunlightColor(record.sunlight.red, record.sunlight.green, record.sunlight.blue)
    end
    if record.fog ~= nil then
        dreamweave.SetRecordFog(record.fog.red, record.fog.green, record.fog.blue, record.fog.density)
    end
    if record.hasWater ~= nil then dreamweave.SetRecordHasWater(record.hasWater) end
    if record.waterLevel ~= nil then dreamweave.SetRecordWaterLevel(record.waterLevel) end
    if record.noSleep ~= nil then dreamweave.SetRecordNoSleep(record.noSleep) end
    if record.quasiEx ~= nil then dreamweave.SetRecordQuasiEx(record.quasiEx) end
    if record.region ~= nil then dreamweave.SetRecordRegion(record.region) end

    dreamweave.AddRecord()
end

packetBuilder.AddClothingRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.subtype ~= nil then dreamweave.SetRecordSubtype(record.subtype) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.enchantmentId ~= nil then dreamweave.SetRecordEnchantmentId(record.enchantmentId) end
    if record.enchantmentCharge ~= nil then dreamweave.SetRecordEnchantmentCharge(record.enchantmentCharge) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    if type(record.parts) == "table" then
        for _, part in pairs(record.parts) do
            packetBuilder.AddBodyPartToRecord(part)
        end
    end

    dreamweave.AddRecord()
end

packetBuilder.AddContainerRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.flags ~= nil then dreamweave.SetRecordFlags(record.flags) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    if type(record.items) == "table" then
        for _, item in pairs(record.items) do
            packetBuilder.AddInventoryItemToRecord(item)
        end
    end

    dreamweave.AddRecord()
end

packetBuilder.AddCreatureRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.subtype ~= nil then dreamweave.SetRecordSubtype(record.subtype) end
    if record.scale ~= nil then dreamweave.SetRecordScale(record.scale) end
    if record.bloodType ~= nil then dreamweave.SetRecordBloodType(record.bloodType) end
    if record.level ~= nil then dreamweave.SetRecordLevel(record.level) end
    if record.health ~= nil then dreamweave.SetRecordHealth(record.health) end
    if record.magicka ~= nil then dreamweave.SetRecordMagicka(record.magicka) end
    if record.fatigue ~= nil then dreamweave.SetRecordFatigue(record.fatigue) end
    if record.soulValue ~= nil then dreamweave.SetRecordSoulValue(record.soulValue) end
    if record.damageChop ~= nil then dreamweave.SetRecordDamageChop(record.damageChop.min, record.damageChop.max) end
    if record.damageSlash ~= nil then dreamweave.SetRecordDamageSlash(record.damageSlash.min, record.damageSlash.max) end
    if record.damageThrust ~= nil then dreamweave.SetRecordDamageThrust(record.damageThrust.min, record.damageThrust.max) end
    if record.aiFight ~= nil then dreamweave.SetRecordAIFight(record.aiFight) end
    if record.aiServices ~= nil then dreamweave.SetRecordAIServices(record.aiServices) end
    if record.aiFlee ~= nil then dreamweave.SetRecordAIFlee(record.aiFlee) end
    if record.aiAlarm ~= nil then dreamweave.SetRecordAIAlarm(record.aiAlarm) end
    if record.flags ~= nil then dreamweave.SetRecordFlags(record.flags) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    if type(record.items) == "table" then
        for _, item in pairs(record.items) do
            packetBuilder.AddInventoryItemToRecord(item)
        end
    end

    dreamweave.AddRecord()
end

packetBuilder.AddDoorRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.openSound ~= nil then dreamweave.SetRecordOpenSound(record.openSound) end
    if record.closeSound ~= nil then dreamweave.SetRecordCloseSound(record.closeSound) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    dreamweave.AddRecord()
end

packetBuilder.AddEnchantmentRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.subtype ~= nil then dreamweave.SetRecordSubtype(record.subtype) end
    if record.cost ~= nil then dreamweave.SetRecordCost(record.cost) end
    if record.charge ~= nil then dreamweave.SetRecordCharge(record.charge) end

    if record.flags ~= nil then dreamweave.SetRecordFlags(record.flags)
    -- Keep this for compatibility with older data which used autoCalc
    elseif record.autoCalc ~= nil then dreamweave.SetRecordFlags(record.autoCalc) end

    if type(record.effects) == "table" then
        for _, effect in pairs(record.effects) do
            packetBuilder.AddEffectToRecord(effect)
        end
    end

    dreamweave.AddRecord()
end

packetBuilder.AddGameSettingRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end

    if record.intVar ~= nil then dreamweave.SetRecordIntegerVariable(record.intVar)
    elseif record.floatVar ~= nil then dreamweave.SetRecordFloatVariable(record.floatVar)
    elseif record.stringVar ~= nil then dreamweave.SetRecordStringVariable(tostring(record.stringVar)) end

    dreamweave.AddRecord()
end

packetBuilder.AddIngredientRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    if type(record.effects) == "table" then
        for effectIndex = 1, 4 do
            local effect = record.effects[effectIndex]

            if effect == nil then
                effect = { id = -1 }
            end
            
            packetBuilder.AddEffectToRecord(effect)
        end
    end

    dreamweave.AddRecord()
end

packetBuilder.AddLightRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.sound ~= nil then dreamweave.SetRecordSound(record.sound) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.time ~= nil then dreamweave.SetRecordTime(record.time) end
    if record.radius ~= nil then dreamweave.SetRecordRadius(record.radius) end
    if record.color ~= nil then dreamweave.SetRecordColor(record.color.red, record.color.green, record.color.blue) end
    if record.flags ~= nil then dreamweave.SetRecordFlags(record.flags) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    dreamweave.AddRecord()
end

packetBuilder.AddLockpickRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.quality ~= nil then dreamweave.SetRecordQuality(record.quality) end
    if record.uses ~= nil then dreamweave.SetRecordUses(record.uses) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    dreamweave.AddRecord()
end

packetBuilder.AddMiscellaneousRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.keyState ~= nil then dreamweave.SetRecordKeyState(record.keyState) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    dreamweave.AddRecord()
end

packetBuilder.AddNpcRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.inventoryBaseId ~= nil then dreamweave.SetRecordInventoryBaseId(record.inventoryBaseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.gender ~= nil then dreamweave.SetRecordGender(record.gender) end
    if record.race ~= nil then dreamweave.SetRecordRace(record.race) end
    if record.hair ~= nil then dreamweave.SetRecordHair(record.hair) end
    if record.head ~= nil then dreamweave.SetRecordHead(record.head) end
    if record.class ~= nil then dreamweave.SetRecordClass(record.class) end
    if record.level ~= nil then dreamweave.SetRecordLevel(record.level) end
    if record.health ~= nil then dreamweave.SetRecordHealth(record.health) end
    if record.magicka ~= nil then dreamweave.SetRecordMagicka(record.magicka) end
    if record.fatigue ~= nil then dreamweave.SetRecordFatigue(record.fatigue) end
    if record.aiFight ~= nil then dreamweave.SetRecordAIFight(record.aiFight) end
    if record.aiFlee ~= nil then dreamweave.SetRecordAIFlee(record.aiFlee) end
    if record.aiAlarm ~= nil then dreamweave.SetRecordAIAlarm(record.aiAlarm) end
    if record.aiServices ~= nil then dreamweave.SetRecordAIServices(record.aiServices) end
    if record.autoCalc ~= nil then dreamweave.SetRecordAutoCalc(record.autoCalc) end
    if record.faction ~= nil then dreamweave.SetRecordFaction(record.faction) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    if type(record.items) == "table" then
        for _, item in pairs(record.items) do
            packetBuilder.AddInventoryItemToRecord(item)
        end
    end

    dreamweave.AddRecord()
end

packetBuilder.AddPotionRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.autoCalc ~= nil then dreamweave.SetRecordAutoCalc(record.autoCalc) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    if type(record.effects) == "table" then
        for _, effect in pairs(record.effects) do
            packetBuilder.AddEffectToRecord(effect)
        end
    end

    dreamweave.AddRecord()
end

packetBuilder.AddProbeRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.quality ~= nil then dreamweave.SetRecordQuality(record.quality) end
    if record.uses ~= nil then dreamweave.SetRecordUses(record.uses) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    dreamweave.AddRecord()
end

packetBuilder.AddRepairRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.quality ~= nil then dreamweave.SetRecordQuality(record.quality) end
    if record.uses ~= nil then dreamweave.SetRecordUses(record.uses) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    dreamweave.AddRecord()
end

packetBuilder.AddScriptRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.scriptText ~= nil then dreamweave.SetRecordScriptText(record.scriptText) end

    dreamweave.AddRecord()
end

packetBuilder.AddSoundRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.sound ~= nil then dreamweave.SetRecordSound(record.sound) end
    if record.volume ~= nil then dreamweave.SetRecordVolume(record.volume) end
    if record.minRange ~= nil then dreamweave.SetRecordMinRange(record.minRange) end
    if record.maxRange ~= nil then dreamweave.SetRecordMaxRange(record.maxRange) end

    dreamweave.AddRecord()
end

packetBuilder.AddSpellRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.subtype ~= nil then dreamweave.SetRecordSubtype(record.subtype) end
    if record.cost ~= nil then dreamweave.SetRecordCost(record.cost) end
    if record.flags ~= nil then dreamweave.SetRecordFlags(record.flags) end

    if type(record.effects) == "table" then
        for _, effect in pairs(record.effects) do
            packetBuilder.AddEffectToRecord(effect)
        end
    end

    dreamweave.AddRecord()
end

packetBuilder.AddStaticRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end

    dreamweave.AddRecord()
end

packetBuilder.AddWeaponRecord = function(id, record)

    dreamweave.SetRecordId(id)
    if record.baseId ~= nil then dreamweave.SetRecordBaseId(record.baseId) end
    if record.name ~= nil then dreamweave.SetRecordName(record.name) end
    if record.model ~= nil then dreamweave.SetRecordModel(record.model) end
    if record.icon ~= nil then dreamweave.SetRecordIcon(record.icon) end
    if record.subtype ~= nil then dreamweave.SetRecordSubtype(record.subtype) end
    if record.weight ~= nil then dreamweave.SetRecordWeight(record.weight) end
    if record.value ~= nil then dreamweave.SetRecordValue(record.value) end
    if record.health ~= nil then dreamweave.SetRecordHealth(record.health) end
    if record.speed ~= nil then dreamweave.SetRecordSpeed(record.speed) end
    if record.reach ~= nil then dreamweave.SetRecordReach(record.reach) end
    if record.damageChop ~= nil then dreamweave.SetRecordDamageChop(record.damageChop.min, record.damageChop.max) end
    if record.damageSlash ~= nil then dreamweave.SetRecordDamageSlash(record.damageSlash.min, record.damageSlash.max) end
    if record.damageThrust ~= nil then dreamweave.SetRecordDamageThrust(record.damageThrust.min, record.damageThrust.max) end
    if record.flags ~= nil then dreamweave.SetRecordFlags(record.flags) end
    if record.enchantmentId ~= nil then dreamweave.SetRecordEnchantmentId(record.enchantmentId) end
    if record.enchantmentCharge ~= nil then dreamweave.SetRecordEnchantmentCharge(record.enchantmentCharge) end
    if record.script ~= nil then dreamweave.SetRecordScript(record.script) end

    dreamweave.AddRecord()
end

return packetBuilder
