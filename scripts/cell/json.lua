require("config")
fileHelper = require("fileHelper")
tableHelper = require("tableHelper")
local BaseCell = require("cell.base")

local Cell = class("Cell", BaseCell)

function Cell:__init(cellDescription)
    BaseCell.__init(self, cellDescription)

    -- Ensure filename is valid
    self.entryName = fileHelper.fixFilename(cellDescription)

    self.entryFile = dreamweave.GetCaseInsensitiveFilename(config.dataPath .. "/cell/", self.entryName .. ".json")

    if self.entryFile == "invalid" then
        self.hasEntry = false
        self.entryFile = self.entryName .. ".json"
    else
        self.hasEntry = true
    end
end

function Cell:CreateEntry()
    self.hasEntry = jsonInterface.save("cell/" .. self.entryFile, self.data)

    if self.hasEntry then
        dreamweave.LogMessage(enumerations.log.INFO, "Successfully created JSON file for cell " .. self.entryName)
    else
        local message = "Failed to create JSON file for " .. self.entryName
        dreamweave.SendMessage(self.pid, message, true)
    end
end

function Cell:SaveToDrive()
    if self.hasEntry then
        tableHelper.cleanNils(self.data.packets)
        jsonInterface.save("cell/" .. self.entryFile, self.data, config.cellKeyOrder)
    end
end

function Cell:QuicksaveToDrive()
    if self.hasEntry then
        jsonInterface.quicksave("cell/" .. self.entryFile, self.data)
    end
end

function Cell:LoadFromDrive()
    self.data = jsonInterface.load("cell/" .. self.entryFile)

    if self.data == nil then
        dreamweave.LogMessage(enumerations.log.ERROR, "cell/" .. self.entryFile .. " cannot be read!")
        dreamweave.StopServer(2)
    else
        -- JSON doesn't allow numerical keys, but we use them, so convert
        -- all string number keys into numerical keys
        tableHelper.fixNumericalKeys(self.data)
    end
end

-- Deprecated function with confusing name, kept around for backwards compatibility
function Cell:Save()
    self:SaveToDrive()
end

function Cell:Load()
    self:LoadFromDrive()
end

return Cell
