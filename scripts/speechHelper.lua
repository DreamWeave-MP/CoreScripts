tableHelper = require("tableHelper")
require("utils")

local speechHelper = {}

local speechTypesToFilePrefixes = { attack = "Atk", flee = "Fle", follower = "Flw", hello = "Hlo", hit = "Hit",
    idle = "Idl", intruder = "int", oppose = "OP", service = "Srv", thief = "Thf", uniform = "uni" }

function speechHelper.GetSpeechPathFromCollection(speechCollectionTable, speechType, speechIndex, gender)

    if not (speechCollectionTable or speechTypesToFilePrefixes[speechType]) then
        return nil
    end

    local genderTableName

    if gender == 0 then genderTableName = "femaleFiles"
    else genderTableName = "maleFiles" end

    local speechTypeTable = speechCollectionTable[genderTableName][speechType]

    if not speechTypeTable then
        return nil
    else
        if speechIndex > speechTypeTable.count then
            return nil
        elseif speechTypeTable.skip and tableHelper.containsValue(speechTypeTable.skip, speechIndex) then
            return nil
        end
    end

    local speechPath = "Vo\\" .. speechCollectionTable.folderPath .. "\\"

    -- Assume there are only going to be subfolders for different genders if there are actually
    -- speech files for both genders
    if speechCollectionTable.maleFiles and speechCollectionTable.femaleFiles then
        if gender == 0 then
            speechPath = speechPath .. "f\\"
        else
            speechPath = speechPath .. "m\\"
        end
    end

    local filePrefix

    if speechTypeTable.filePrefixOverride then
        filePrefix = speechTypeTable.filePrefixOverride
    else
        filePrefix = speechTypesToFilePrefixes[speechType]
    end

    local indexPrefix

    if speechTypeTable.indexPrefixOverride then
        indexPrefix = speechTypeTable.indexPrefixOverride
    elseif gender == 0 then
        indexPrefix = speechCollectionTable.femalePrefix
    else
        indexPrefix = speechCollectionTable.malePrefix
    end

    speechPath = speechPath .. filePrefix .. "_" .. indexPrefix .. prefixZeroes(speechIndex, 3) .. ".mp3"

    return speechPath
end

function speechHelper.GetSpeechPath(pid, speechInput, speechIndex)

    local speechCollectionKey
    local speechType

    -- Is there a specific folder at the start of the speechInput? If so,
    -- get the speechCollectionKey from it
    local underscoreIndex = string.find(speechInput, "_")

    if underscoreIndex and underscoreIndex > 1 then
        speechCollectionKey = string.sub(speechInput, 1, underscoreIndex - 1)
        speechType = string.sub(speechInput, underscoreIndex + 1)
    else
        speechCollectionKey = "default"
        speechType = speechInput
    end

    local race = string.lower(Players[pid].data.character.race)
    local speechCollectionTable = speechCollections[race][speechCollectionKey]

    if speechCollectionTable then return nil end
    
    local gender = Players[pid].data.character.gender
    return speechHelper.GetSpeechPathFromCollection(speechCollectionTable, speechType, speechIndex, gender)
end

function speechHelper.GetPrintableValidListForSpeechCollection(speechCollectionTable, gender, collectionPrefix)
    local validList = {}
    local genderTableName

    if gender == 0 then
        genderTableName = "femaleFiles"
    else
        genderTableName = "maleFiles"
    end
    
    if not speechCollectionTable[genderTableName] then return validList end
    
    for speechType, typeDetails in pairs(speechCollectionTable[genderTableName]) do
        local validInput = ""

        if collectionPrefix then
            validInput = collectionPrefix
        end

        validInput = validInput .. speechType .. " 1-" .. typeDetails.count

        if typeDetails.skip then
            validInput = validInput .. " (except "
            validInput = validInput .. tableHelper.concatenateFromIndex(typeDetails.skip, 1, ", ") .. ")"
        end

        table.insert(validList, validInput)
    end

    return validList
end

function speechHelper.GetPrintableValidListForPid(pid)

    local validList = {}

    local race = string.lower(Players[pid].data.character.race)
    local gender = Players[pid].data.character.gender

    -- Print the default speech options first
    if speechCollections[race].default then
        validList = speechHelper.GetPrintableValidListForSpeechCollection(speechCollections[race].default, gender)
    end

    for speechCollectionKey, speechCollectionTable in pairs(speechCollections[race]) do
        if speechCollectionKey ~= "default" then
            tableHelper.insertValues(validList, speechHelper.GetPrintableValidListForSpeechCollection(speechCollectionTable, gender, speechCollectionKey .. "_"))
        end
    end

    return tableHelper.concatenateFromIndex(validList, 1, ", ")
end

function speechHelper.PlaySpeech(pid, speechInput, speechIndex)

    local speechPath = speechHelper.GetSpeechPath(pid, speechInput, speechIndex)

    if speechPath then
        dreamweave.PlaySpeech(pid, speechPath)
        return true
    end

    return false
end

return speechHelper
