packetReader = {}

packetReader.GetPlayerPacketTables = function(pid, packetType)

    local packetTable = {}

    if packetType == "PlayerClass" then
        packetTable.character = {}
        packetTable.character.defaultClassState = dreamweave.IsClassDefault(pid)

        if packetTable.character.defaultClassState == 1 then
            packetTable.character.class = dreamweave.GetDefaultClass(pid)
        else
            packetTable.character.class = "custom"
            packetTable.customClass = {
                name = dreamweave.GetClassName(pid),
                description = dreamweave.GetClassDesc(pid):gsub("\n", "\\n"),
                specialization = dreamweave.GetClassSpecialization(pid)
            }

            local majorAttributes = {}
            local majorSkills = {}
            local minorSkills = {}

            for index = 0, 1, 1 do
                majorAttributes[index + 1] = dreamweave.GetAttributeName(tonumber(dreamweave.GetClassMajorAttribute(pid, index)))
            end

            for index = 0, 4, 1 do
                majorSkills[index + 1] = dreamweave.GetSkillName(tonumber(dreamweave.GetClassMajorSkill(pid, index)))
                minorSkills[index + 1] = dreamweave.GetSkillName(tonumber(dreamweave.GetClassMinorSkill(pid, index)))
            end

            packetTable.customClass.majorAttributes = table.concat(majorAttributes, ", ")
            packetTable.customClass.majorSkills = table.concat(majorSkills, ", ")
            packetTable.customClass.minorSkills = table.concat(minorSkills, ", ")
        end
    elseif packetType == "PlayerStatsDynamic" then
        packetTable.stats = {
            healthBase = dreamweave.GetHealthBase(pid),
            magickaBase = dreamweave.GetMagickaBase(pid),
            fatigueBase = dreamweave.GetFatigueBase(pid),
            healthCurrent = dreamweave.GetHealthCurrent(pid),
            magickaCurrent = dreamweave.GetMagickaCurrent(pid),
            fatigueCurrent = dreamweave.GetFatigueCurrent(pid)
        }
    elseif packetType == "PlayerAttribute" then
        packetTable.attributes = {}

        for attributeIndex = 0, dreamweave.GetAttributeCount() - 1 do
            local attributeName = dreamweave.GetAttributeName(attributeIndex)

            packetTable.attributes[attributeName] = {
                base = dreamweave.GetAttributeBase(pid, attributeIndex),
                damage = dreamweave.GetAttributeDamage(pid, attributeIndex),
                skillIncrease = dreamweave.GetSkillIncrease(pid, attributeIndex),
                modifier = dreamweave.GetAttributeModifier(pid, attributeIndex)
            }
        end
    elseif packetType == "PlayerSkill" then
        packetTable.skills = {}

        for skillIndex = 0, dreamweave.GetSkillCount() - 1 do
            local skillName = dreamweave.GetSkillName(skillIndex)

            packetTable.skills[skillName] = {
                base = dreamweave.GetSkillBase(pid, skillIndex),
                damage = dreamweave.GetSkillDamage(pid, skillIndex),
                progress = dreamweave.GetSkillProgress(pid, skillIndex),
                modifier = dreamweave.GetSkillModifier(pid, skillIndex)
            }
        end
    elseif packetType == "PlayerLevel" then
        packetTable.stats = {
            level = dreamweave.GetLevel(pid),
            levelProgress = dreamweave.GetLevelProgress(pid)
        }
    elseif packetType == "PlayerShapeshift" then
        packetTable.shapeshift = {
            scale = dreamweave.GetScale(pid),
            isWerewolf = dreamweave.IsWerewolf(pid)
        }
    elseif packetType == "PlayerCellChange" then
        packetTable.location = {
            cell = dreamweave.GetCell(pid),
            posX = dreamweave.GetPosX(pid),
            posY = dreamweave.GetPosY(pid),
            posZ = dreamweave.GetPosZ(pid),
            rotX = dreamweave.GetRotX(pid),
            rotZ = dreamweave.GetRotZ(pid)
        }
    elseif packetType == "PlayerEquipment" then
        packetTable.equipment = {}

        for changesIndex = 0, dreamweave.GetEquipmentChangesSize(pid) - 1 do
            local slot = dreamweave.GetEquipmentChangesSlot(pid, changesIndex)

            packetTable.equipment[slot] = {
                refId = dreamweave.GetEquipmentItemRefId(pid, slot),
                count = dreamweave.GetEquipmentItemCount(pid, slot),
                charge = dreamweave.GetEquipmentItemCharge(pid, slot),
                enchantmentCharge = dreamweave.GetEquipmentItemEnchantmentCharge(pid, slot)
            }
        end
    elseif packetType == "PlayerInventory" then
        packetTable.inventory = {}
        packetTable.action = dreamweave.GetInventoryChangesAction(pid)

        for changesIndex = 0, dreamweave.GetInventoryChangesSize(pid) - 1 do
            local item = {
                refId = dreamweave.GetInventoryItemRefId(pid, changesIndex),
                count = dreamweave.GetInventoryItemCount(pid, changesIndex),
                charge = dreamweave.GetInventoryItemCharge(pid, changesIndex),
                enchantmentCharge = dreamweave.GetInventoryItemEnchantmentCharge(pid, changesIndex),
                soul = dreamweave.GetInventoryItemSoul(pid, changesIndex)
            }

            table.insert(packetTable.inventory, item)
        end
    elseif packetType == "PlayerSpellbook" then
        packetTable.spellbook = {}
        packetTable.action = dreamweave.GetSpellbookChangesAction(pid)

        for changesIndex = 0, dreamweave.GetSpellbookChangesSize(pid) - 1 do
            local spellId = dreamweave.GetSpellId(pid, changesIndex)
            table.insert(packetTable.spellbook, spellId)
        end
    elseif packetType == "PlayerSpellsActive" then
        packetTable.spellsActive = {}
        packetTable.action = dreamweave.GetSpellsActiveChangesAction(pid)

        for changesIndex = 0, dreamweave.GetSpellsActiveChangesSize(pid) - 1 do
            local spellId = dreamweave.GetSpellsActiveId(pid, changesIndex)

            if packetTable.spellsActive[spellId] == nil then
                packetTable.spellsActive[spellId] = {}
            end

            local spellInstance = {
                effects = {},
                displayName = dreamweave.GetSpellsActiveDisplayName(pid, changesIndex),
                stackingState = dreamweave.GetSpellsActiveStackingState(pid, changesIndex),
                startTime = os.time(),
                caster = {}
            }

            spellInstance.hasPlayerCaster = dreamweave.DoesSpellsActiveHavePlayerCaster(pid, changesIndex)

            if spellInstance.hasPlayerCaster == true then
                local casterPid = dreamweave.GetSpellsActiveCasterPid(pid, changesIndex)
                spellInstance.caster.pid = casterPid

                if Players[casterPid] ~= nil then
                    spellInstance.caster.playerName = Players[casterPid].accountName
                end
            else
                spellInstance.caster.uniqueIndex = dreamweave.GetSpellsActiveCasterRefNum(pid, changesIndex) ..
                    "-" .. dreamweave.GetSpellsActiveCasterMpNum(pid, changesIndex)
                spellInstance.caster.refId = dreamweave.GetSpellsActiveCasterRefId(pid, changesIndex)
            end

            for effectIndex = 0, dreamweave.GetSpellsActiveEffectCount(pid, changesIndex) - 1 do
                local effect = {
                    id = dreamweave.GetSpellsActiveEffectId(pid, changesIndex, effectIndex),
                    magnitude = dreamweave.GetSpellsActiveEffectMagnitude(pid, changesIndex, effectIndex),
                    duration = dreamweave.GetSpellsActiveEffectDuration(pid, changesIndex, effectIndex),
                    timeLeft = dreamweave.GetSpellsActiveEffectTimeLeft(pid, changesIndex, effectIndex),
                    arg = dreamweave.GetSpellsActiveEffectArg(pid, changesIndex, effectIndex)
                }

                if effect.timeLeft > 0 then
                    table.insert(spellInstance.effects, effect)
                end
            end

            if tableHelper.getCount(spellInstance.effects) > 0 then
                table.insert(packetTable.spellsActive[spellId], spellInstance)
            end
        end
    elseif packetType == "PlayerCooldowns" then
        packetTable.cooldowns = {}

        for changesIndex = 0, dreamweave.GetCooldownChangesSize(pid) - 1 do

            local cooldown = {
                spellId = dreamweave.GetCooldownSpellId(pid, changesIndex),
                startDay = dreamweave.GetCooldownStartDay(pid, changesIndex),
                startHour = dreamweave.GetCooldownStartHour(pid, changesIndex)
            }
            
            table.insert(packetTable.cooldowns, cooldown)
        end
    elseif packetType == "PlayerQuickKeys" then
        packetTable.quickKeys = {}

        for changesIndex = 0, dreamweave.GetQuickKeyChangesSize(pid) - 1 do

            local slot = dreamweave.GetQuickKeySlot(pid, changesIndex)

            packetTable.quickKeys[slot] = {
                keyType = dreamweave.GetQuickKeyType(pid, changesIndex),
                itemId = dreamweave.GetQuickKeyItemId(pid, changesIndex)
            }
        end
    elseif packetType == "PlayerJournal" then
        packetTable.journal = {}

        for changesIndex = 0, dreamweave.GetJournalChangesSize(pid) - 1 do
            local journalItem = {
                type = dreamweave.GetJournalItemType(pid, changesIndex),
                index = dreamweave.GetJournalItemIndex(pid, changesIndex),
                quest = dreamweave.GetJournalItemQuest(pid, changesIndex),
                timestamp = {
                    daysPassed = WorldInstance.data.time.daysPassed,
                    month = WorldInstance.data.time.month,
                    day = WorldInstance.data.time.day
                }
            }

            if journalItem.type == enumerations.journal.ENTRY then
                journalItem.actorRefId = dreamweave.GetJournalItemActorRefId(pid, changesIndex)
            end

            table.insert(packetTable.journal, journalItem)
        end
    end

    return packetTable
end

packetReader.GetActorPacketTables = function(packetType)
    
    local packetTables = { actors = {} }
    local actorListSize = dreamweave.GetActorListSize()

    if actorListSize == 0 then return packetTables end

    for packetIndex = 0, actorListSize - 1 do
        local actor = {}
        local uniqueIndex = dreamweave.GetActorRefNum(packetIndex) .. "-" .. dreamweave.GetActorMpNum(packetIndex)
        actor.uniqueIndex = uniqueIndex

        -- Only non-repetitive actor packets contain refId information
        if tableHelper.containsValue({"ActorList", "ActorDeath"}, packetType) then
            actor.refId = dreamweave.GetActorRefId(packetIndex)
        end

        if packetType == "ActorEquipment" then

            actor.equipment = {}
            local equipmentSize = dreamweave.GetEquipmentSize()

            for itemIndex = 0, equipmentSize - 1 do
                local itemRefId = dreamweave.GetActorEquipmentItemRefId(packetIndex, itemIndex)

                if itemRefId ~= "" then
                    actor.equipment[itemIndex] = {
                        refId = itemRefId,
                        count = dreamweave.GetActorEquipmentItemCount(packetIndex, itemIndex),
                        charge = dreamweave.GetActorEquipmentItemCharge(packetIndex, itemIndex),
                        enchantmentCharge = dreamweave.GetActorEquipmentItemEnchantmentCharge(packetIndex, itemIndex)
                    }
                end
            end
        elseif packetType == "ActorSpellsActive" then

            actor.spellsActive = {}
            local spellsActiveChangesSize = dreamweave.GetActorSpellsActiveChangesSize(packetIndex)

            for spellIndex = 0, spellsActiveChangesSize - 1 do

                local spellId = dreamweave.GetActorSpellsActiveId(packetIndex, spellIndex)

                if actor.spellsActive[spellId] == nil then
                    actor.spellsActive[spellId] = {}
                end

                actor.spellActiveChangesAction = dreamweave.GetActorSpellsActiveChangesAction(packetIndex)

                local spellInstance = {
                    effects = {},
                    displayName = dreamweave.GetActorSpellsActiveDisplayName(packetIndex, spellIndex),
                    stackingState = dreamweave.GetActorSpellsActiveStackingState(packetIndex, spellIndex),
                    startTime = os.time(),
                    caster = {}
                }

                spellInstance.hasPlayerCaster = dreamweave.DoesActorSpellsActiveHavePlayerCaster(packetIndex, spellIndex)

                if spellInstance.hasPlayerCaster == true then
                    spellInstance.caster.pid = dreamweave.GetActorSpellsActiveCasterPid(packetIndex, spellIndex)

                    if Players[spellInstance.caster.pid] ~= nil then
                        spellInstance.caster.playerName = Players[spellInstance.caster.pid].accountName
                    end
                else
                    spellInstance.caster.uniqueIndex = dreamweave.GetActorSpellsActiveCasterRefNum(packetIndex, spellIndex) ..
                        "-" .. dreamweave.GetSpellsActiveCasterMpNum(packetIndex, spellIndex)
                    spellInstance.caster.refId = dreamweave.GetActorSpellsActiveCasterRefId(packetIndex, spellIndex)
                end

                for effectIndex = 0, dreamweave.GetActorSpellsActiveEffectCount(packetIndex, spellIndex) - 1 do
                    local effect = {
                        id = dreamweave.GetActorSpellsActiveEffectId(packetIndex, spellIndex, effectIndex),
                        magnitude = dreamweave.GetActorSpellsActiveEffectMagnitude(packetIndex, spellIndex, effectIndex),
                        duration = dreamweave.GetActorSpellsActiveEffectDuration(packetIndex, spellIndex, effectIndex),
                        timeLeft = dreamweave.GetActorSpellsActiveEffectTimeLeft(packetIndex, spellIndex, effectIndex),
                        arg = dreamweave.GetActorSpellsActiveEffectArg(packetIndex, spellIndex, effectIndex)
                    }

                    if effect.timeLeft > 0 then
                        table.insert(spellInstance.effects, effect)
                    end
                end

                if tableHelper.getCount(spellInstance.effects) > 0 then
                    table.insert(actor.spellsActive[spellId], spellInstance)
                end
            end
        elseif packetType == "ActorDeath" then

            actor.deathState = dreamweave.GetActorDeathState(packetIndex)
            actor.killer = {}

            local doesActorHavePlayerKiller = dreamweave.DoesActorHavePlayerKiller(packetIndex)

            if doesActorHavePlayerKiller then
                actor.killer.pid = dreamweave.GetActorKillerPid(packetIndex)

                if Players[actor.killer.pid] ~= nil then
                    actor.killer.playerName = Players[actor.killer.pid].accountName
                end
            else
                actor.killer.refId = dreamweave.GetActorKillerRefId(packetIndex)
                actor.killer.name = dreamweave.GetActorKillerName(packetIndex)
                actor.killer.uniqueIndex = dreamweave.GetActorKillerRefNum(packetIndex) ..
                    "-" .. dreamweave.GetActorKillerMpNum(packetIndex)
            end
        elseif packetType == "ActorAI" then
            actor.ai = {}

            local action = dreamweave.GetActorAIAction(packetIndex)
            actor.ai.action = action

            if action == enumerations.ai.ACTIVATE or action == enumerations.ai.COMBAT or action == enumerations.ai.ESCORT or action == enumerations.ai.FOLLOW then
                actor.ai.target = {}
                local doesActorAIHavePlayerTarget = dreamweave.DoesActorAIHavePlayerTarget(packetIndex)

                if doesActorAIHavePlayerTarget then
                    actor.ai.target.pid = dreamweave.GetActorAITargetPid(packetIndex)
    
                    if Players[actor.ai.target.pid] ~= nil then
                        actor.ai.target.playerName = Players[actor.ai.target.pid].accountName
                    end
                else
                    actor.ai.target.refId = dreamweave.GetActorAITargetRefId(packetIndex)
                    actor.ai.target.name = dreamweave.GetActorAITargetName(packetIndex)
                    actor.ai.target.uniqueIndex = dreamweave.GetActorAITargetRefNum(packetIndex) ..
                        "-" .. dreamweave.GetActorAITargetMpNum(packetIndex)
                end
            end

            if action == enumerations.ai.TRAVEL or action == enumerations.ai.ESCORT or action == enumerations.ai.FOLLOW then
                actor.ai.destination = {}
                actor.ai.destination.posX = dreamweave.GetActorAICoordinateX(packetIndex)
                actor.ai.destination.posY = dreamweave.GetActorAICoordinateY(packetIndex)
                actor.ai.destination.posZ = dreamweave.GetActorAICoordinateZ(packetIndex)
            end

            if action == enumerations.ai.WANDER then
                actor.ai.distance = dreamweave.GetActorAIDistance(packetIndex)
                actor.ai.repetition = dreamweave.GetActorAIRepetition(packetIndex)
            end

            if action == enumerations.ai.ESCORT or action == enumerations.ai.FOLLOW or action == enumerations.ai.WANDER then
                actor.ai.duration = dreamweave.GetActorAIDuration(packetIndex)
            end
        end

        packetTables.actors[uniqueIndex] = actor
    end

    return packetTables
end

packetReader.GetObjectPacketTables = function(packetType)

    local packetTables = { objects = {}, players = {} }
    local objectListSize = dreamweave.GetObjectListSize()

    if objectListSize == 0 then return packetTables end

    for packetIndex = 0, objectListSize - 1 do
        local object, uniqueIndex, player, pid = nil, nil, nil, nil
        
        if tableHelper.containsValue({"ObjectActivate", "ObjectHit", "ObjectSound", "ConsoleCommand"}, packetType) then

            local isObjectPlayer = dreamweave.IsObjectPlayer(packetIndex)

            if isObjectPlayer then
                pid = dreamweave.GetObjectPid(packetIndex)
                player = Players[pid]
            else
                object = {}
                uniqueIndex = dreamweave.GetObjectRefNum(packetIndex) .. "-" .. dreamweave.GetObjectMpNum(packetIndex)
                object.refId = dreamweave.GetObjectRefId(packetIndex)
                object.uniqueIndex = uniqueIndex
            end

            if packetType == "ObjectSound" then

                local soundId = dreamweave.GetObjectSoundId(packetIndex)

                if isObjectPlayer then
                    if player ~= nil then
                        player.soundId = soundId
                    end
                else
                    object.soundId = soundId
                end

            elseif packetType == "ObjectActivate" then

                local doesObjectHaveActivatingPlayer = dreamweave.DoesObjectHavePlayerActivating(packetIndex)

                if doesObjectHaveActivatingPlayer then
                    local activatingPid = dreamweave.GetObjectActivatingPid(packetIndex)

                    if isObjectPlayer then
                        if player ~= nil then
                            player.activatingPid = activatingPid
                            player.drawState = dreamweave.GetDrawState(activatingPid) -- for backwards compatibility
                        end
                    else
                        object.activatingPid = activatingPid
                    end
                else
                    local activatingRefId = dreamweave.GetObjectActivatingRefId(packetIndex)
                    local activatingUniqueIndex = dreamweave.GetObjectActivatingRefNum(packetIndex) ..
                        "-" .. dreamweave.GetObjectActivatingMpNum(packetIndex)

                    if isObjectPlayer then
                        if player ~= nil then
                            player.activatingRefId = activatingRefId
                            player.activatingUniqueIndex = activatingUniqueIndex
                        end
                    else
                        object.activatingRefId = activatingRefId
                        object.activatingUniqueIndex = activatingUniqueIndex
                    end
                end

            elseif packetType == "ObjectHit" then

                local hit = {
                    success = dreamweave.GetObjectHitSuccess(packetIndex),
                    damage = dreamweave.GetObjectHitDamage(packetIndex),
                    block = dreamweave.GetObjectHitBlock(packetIndex),
                    knockdown = dreamweave.GetObjectHitKnockdown(packetIndex)
                }

                if isObjectPlayer then
                    if player ~= nil then
                        player.hit = hit
                    end
                else
                    object.hit = hit
                end

                local doesObjectHaveHittingPlayer = dreamweave.DoesObjectHavePlayerHitting(packetIndex)

                if doesObjectHaveHittingPlayer then
                    local hittingPid = dreamweave.GetObjectHittingPid(packetIndex)

                    if isObjectPlayer then
                        if player ~= nil then
                            player.hittingPid = hittingPid
                            player.hittingRefId = nil
                            player.hittingUniqueIndex = nil
                        end
                    else
                        object.hittingPid = hittingPid
                    end
                else
                    local hittingRefId = dreamweave.GetObjectHittingRefId(packetIndex)
                    local hittingUniqueIndex = dreamweave.GetObjectHittingRefNum(packetIndex) ..
                        "-" .. dreamweave.GetObjectHittingMpNum(packetIndex)

                    if isObjectPlayer then
                        if player ~= nil then
                            player.hittingPid = nil
                            player.hittingRefId = hittingRefId
                            player.hittingUniqueIndex = hittingUniqueIndex
                        end
                    else
                        object.hittingRefId = hittingRefId
                        object.hittingUniqueIndex = hittingUniqueIndex
                    end
                end
            end
        else
            object = {}
            uniqueIndex = dreamweave.GetObjectRefNum(packetIndex) .. "-" .. dreamweave.GetObjectMpNum(packetIndex)
            object.refId = dreamweave.GetObjectRefId(packetIndex)
            object.uniqueIndex = uniqueIndex

            if tableHelper.containsValue({"ObjectPlace", "ObjectSpawn"}, packetType) then
                
                object.location = {
                    posX = dreamweave.GetObjectPosX(packetIndex), posY = dreamweave.GetObjectPosY(packetIndex),
                    posZ = dreamweave.GetObjectPosZ(packetIndex), rotX = dreamweave.GetObjectRotX(packetIndex),
                    rotY = dreamweave.GetObjectRotY(packetIndex), rotZ = dreamweave.GetObjectRotZ(packetIndex)
                }

                if packetType == "ObjectPlace" then
                    object.count = dreamweave.GetObjectCount(packetIndex)
                    object.charge = dreamweave.GetObjectCharge(packetIndex)
                    object.enchantmentCharge = dreamweave.GetObjectEnchantmentCharge(packetIndex)
                    object.soul = dreamweave.GetObjectSoul(packetIndex)
                    object.goldValue = dreamweave.GetObjectGoldValue(packetIndex)
                    object.hasContainer = dreamweave.DoesObjectHaveContainer(packetIndex)
                    object.droppedByPlayer = dreamweave.IsObjectDroppedByPlayer(packetIndex)
                elseif packetType == "ObjectSpawn" then
                    local summonState = dreamweave.GetObjectSummonState(packetIndex)

                    if summonState == true then
                        object.summon = {}
                        object.summon.effectId = dreamweave.GetObjectSummonEffectId(packetIndex)
                        object.summon.spellId = dreamweave.GetObjectSummonSpellId(packetIndex)
                        object.summon.duration = dreamweave.GetObjectSummonDuration(packetIndex)
                        object.summon.startTime = os.time()
                        object.summon.summoner = {}
                        object.summon.hasPlayerSummoner = dreamweave.DoesObjectHavePlayerSummoner(packetIndex)

                        if object.summon.hasPlayerSummoner == true then
                            object.summon.summoner.pid = dreamweave.GetObjectSummonerPid(packetIndex)

                            if Players[object.summon.summoner.pid] ~= nil then
                                object.summon.summoner.playerName = Players[object.summon.summoner.pid].accountName
                            end
                        else
                            object.summon.summoner.refId = dreamweave.GetObjectSummonerRefId(packetIndex)
                            object.summon.summoner.uniqueIndex = dreamweave.GetObjectSummonerRefNum(packetIndex) ..
                                "-" .. dreamweave.GetObjectSummonerMpNum(packetIndex)
                        end
                    end
                end

            elseif packetType == "ObjectLock" then
                object.lockLevel = dreamweave.GetObjectLockLevel(packetIndex)
            elseif packetType == "ObjectTrap" then
                object.trapSpellId = dreamweave.GetObjectTrapSpellId(packetIndex)
                object.trapAction = dreamweave.GetObjectTrapAction(packetIndex)
            elseif packetType == "ObjectDialogueChoice" then
                object.dialogueChoiceType = dreamweave.GetObjectDialogueChoiceType(packetIndex)

                if object.dialogueChoiceType == enumerations.dialogueChoice.TOPIC then
                    object.dialogueTopic = dreamweave.GetObjectDialogueChoiceTopic(packetIndex)
                end
            elseif packetType == "ObjectMiscellaneous" then
                object.goldPool = dreamweave.GetObjectGoldPool(packetIndex)
                object.lastGoldRestockHour = dreamweave.GetObjectLastGoldRestockHour(packetIndex)
                object.lastGoldRestockDay = dreamweave.GetObjectLastGoldRestockDay(packetIndex)
            elseif packetType == "ObjectScale" then
                object.scale = dreamweave.GetObjectScale(packetIndex)
            elseif packetType == "ObjectState" then
                object.state = dreamweave.GetObjectState(packetIndex)
            elseif packetType == "DoorState" then
                object.doorState = dreamweave.GetObjectDoorState(packetIndex)
            elseif packetType =="ClientScriptLocal" then

                local variables = {}
                local variableCount = dreamweave.GetClientLocalsSize(packetIndex)

                for variableIndex = 0, variableCount - 1 do
                    local internalIndex = dreamweave.GetClientLocalInternalIndex(packetIndex, variableIndex)
                    local variableType = dreamweave.GetClientLocalVariableType(packetIndex, variableIndex)
                    local value

                    if tableHelper.containsValue({enumerations.variableType.SHORT, enumerations.variableType.LONG},
                        variableType) then
                        value = dreamweave.GetClientLocalIntValue(packetIndex, variableIndex)
                    elseif variableType == enumerations.variableType.FLOAT then
                        value = dreamweave.GetClientLocalFloatValue(packetIndex, variableIndex)
                    end

                    if variables[variableType] == nil then
                        variables[variableType] = {}
                    end

                    variables[variableType][internalIndex] = value
                end

                object.variables = variables
            end
        end

        if object ~= nil then
            packetTables.objects[uniqueIndex] = object
        elseif player ~= nil then
            packetTables.players[pid] = player
        end
    end

    return packetTables
end

packetReader.GetWorldMapTileArray = function()

    local mapTileArray = {}
    local mapTileCount = dreamweave.GetMapChangesSize()

    for index = 0, mapTileCount - 1 do
        mapTile = {
            cellX = dreamweave.GetMapTileCellX(index),
            cellY = dreamweave.GetMapTileCellY(index),
        }

        mapTile.filename = mapTile.cellX .. ", " .. mapTile.cellY .. ".png"

        table.insert(mapTileArray, mapTile)
    end

    return mapTileArray
end

packetReader.GetClientScriptGlobalPacketTable = function()

    local variables = {}
    local variableCount = dreamweave.GetClientGlobalsSize()

    for index = 0, variableCount - 1 do
        local id = dreamweave.GetClientGlobalId(index)
        local variable = { variableType = dreamweave.GetClientGlobalVariableType(index) }

        if tableHelper.containsValue({enumerations.variableType.SHORT, enumerations.variableType.LONG},
            variable.variableType) then
            variable.intValue = dreamweave.GetClientGlobalIntValue(index)
        elseif variable.variableType == enumerations.variableType.FLOAT then
            variable.floatValue = dreamweave.GetClientGlobalFloatValue(index)
        end

        variables[id] = variable
    end

    return variables
end

packetReader.GetRecordDynamicArray = function(pid)

    local recordArray = {}
    local recordCount = dreamweave.GetRecordCount(pid)
    local recordNumericalType = dreamweave.GetRecordType(pid)

    for recordIndex = 0, recordCount - 1 do
        local record = {}

        if recordNumericalType ~= enumerations.recordType.ENCHANTMENT then
            record.name = dreamweave.GetRecordName(recordIndex)
        end

        if recordNumericalType == enumerations.recordType.SPELL then
            record.subtype = dreamweave.GetRecordSubtype(recordIndex)
            record.cost = dreamweave.GetRecordCost(recordIndex)
            record.flags = dreamweave.GetRecordFlags(recordIndex)
            record.effects = packetReader.GetRecordPacketEffectArray(recordIndex)

        elseif recordNumericalType == enumerations.recordType.POTION then
            record.weight = math.floor(dreamweave.GetRecordWeight(recordIndex) * 100) / 100
            record.value = dreamweave.GetRecordValue(recordIndex)
            record.autoCalc = dreamweave.GetRecordAutoCalc(recordIndex)
            record.icon = dreamweave.GetRecordIcon(recordIndex)
            record.model = dreamweave.GetRecordModel(recordIndex)
            record.script = dreamweave.GetRecordScript(recordIndex)
            record.effects = packetReader.GetRecordPacketEffectArray(recordIndex)

            -- Temporary data that should be discarded afterwards
            record.quantity = dreamweave.GetRecordQuantity(recordIndex)

        elseif recordNumericalType == enumerations.recordType.ENCHANTMENT then
            record.subtype = dreamweave.GetRecordSubtype(recordIndex)
            record.cost = dreamweave.GetRecordCost(recordIndex)
            record.charge = dreamweave.GetRecordCharge(recordIndex)
            record.flags = dreamweave.GetRecordFlags(recordIndex)
            record.effects = packetReader.GetRecordPacketEffectArray(recordIndex)

            -- Temporary data that should be discarded afterwards
            record.clientsideEnchantmentId = dreamweave.GetRecordId(recordIndex)

        else
            record.baseId = dreamweave.GetRecordBaseId(recordIndex)
            record.enchantmentCharge = dreamweave.GetRecordEnchantmentCharge(recordIndex)

            -- Temporary data that should be discarded afterwards
            if recordNumericalType == enumerations.recordType.WEAPON then
                record.quantity = dreamweave.GetRecordQuantity(recordIndex)
            else
                record.quantity = 1
            end

            -- Enchanted item records always have client-set ids for their enchantments
            -- when received by us, so we need to check for the server-set ids matching
            -- them in the player's unresolved enchantments
            local clientEnchantmentId = dreamweave.GetRecordEnchantmentId(recordIndex)
            record.enchantmentId = Players[pid].unresolvedEnchantments[clientEnchantmentId]

            -- Stop tracking this as an unresolved enchantment, assuming the enchantment
            -- itself wasn't previously denied
            if record.enchantmentId ~= nil and Players[pid] ~= nil then
                Players[pid].unresolvedEnchantments[clientEnchantmentId] = nil
            end
        end

        table.insert(recordArray, record)
    end

    return recordArray
end

packetReader.GetRecordPacketEffectArray = function(recordIndex)

    local effectArray = {}
    local effectCount = dreamweave.GetRecordEffectCount(recordIndex)

    for effectIndex = 0, effectCount - 1 do

        local effect = {
            id = dreamweave.GetRecordEffectId(recordIndex, effectIndex),
            attribute = dreamweave.GetRecordEffectAttribute(recordIndex, effectIndex),
            skill = dreamweave.GetRecordEffectSkill(recordIndex, effectIndex),
            rangeType = dreamweave.GetRecordEffectRangeType(recordIndex, effectIndex),
            area = dreamweave.GetRecordEffectArea(recordIndex, effectIndex),
            duration = dreamweave.GetRecordEffectDuration(recordIndex, effectIndex),
            magnitudeMin = dreamweave.GetRecordEffectMagnitudeMin(recordIndex, effectIndex),
            magnitudeMax = dreamweave.GetRecordEffectMagnitudeMax(recordIndex, effectIndex)
        }

        table.insert(effectArray, effect)
    end

    return effectArray
end

return packetReader
