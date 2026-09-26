local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local GameData = require(ReplicatedStorage.Shared.GameData)
local ServerDataModule = require(ServerScriptService.Server.ServerDataModule)

local Events = ReplicatedStorage:WaitForChild("Events")
local CollectItem = Events:WaitForChild("CollectItem")
local ProcessItem = Events:WaitForChild("ProcessItem")
local PurchaseUpgrade = Events:WaitForChild("PurchaseUpgrade")

local function updateLeaderstats(player, data)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        local items = leaderstats:FindFirstChild("Items")
        if coins then coins.Value = data.Coins end
        if items then items.Value = data.Items end
    end
end

CollectItem.OnServerEvent:Connect(function(player)
    local data = ServerDataModule.GetPlayerData(player)
    if not data then return end

    local storageLevel = data.StorageLevel
    local storageData = GameData.Storage[storageLevel]
    local maxCapacity = storageData and storageData.Capacity or 10

    if data.Items < maxCapacity then
        data.Items = data.Items + 1
        updateLeaderstats(player, data)
    end
end)

ProcessItem.OnServerEvent:Connect(function(player)
    local data = ServerDataModule.GetPlayerData(player)
    if not data then return end

    if data.Items > 0 then
        local chipperLevel = data.WoodchipperLevel
        local chipperData = GameData.Woodchippers[chipperLevel]
        local multiplier = chipperData and chipperData.Multiplier or 1

        local coinsGained = data.Items * multiplier
        data.Coins = data.Coins + coinsGained
        data.Items = 0

        updateLeaderstats(player, data)
    end
end)

PurchaseUpgrade.OnServerInvoke = function(player, upgradeType)
    local data = ServerDataModule.GetPlayerData(player)
    if not data then return false, "No data found" end

    if upgradeType == "Woodchipper" then
        local nextLevel = data.WoodchipperLevel + 1
        local nextChipper = GameData.Woodchippers[nextLevel]

        if not nextChipper then return false, "Max level reached" end
        if data.Coins < nextChipper.Cost then return false, "Not enough coins" end

        data.Coins = data.Coins - nextChipper.Cost
        data.WoodchipperLevel = nextLevel
        updateLeaderstats(player, data)
        return true, "Purchased upgraded woodchipper!"

    elseif upgradeType == "Storage" then
        local nextLevel = data.StorageLevel + 1
        local nextStorage = GameData.Storage[nextLevel]

        if not nextStorage then return false, "Max level reached" end
        if data.Coins < nextStorage.Cost then return false, "Not enough coins" end

        data.Coins = data.Coins - nextStorage.Cost
        data.StorageLevel = nextLevel
        updateLeaderstats(player, data)
        return true, "Purchased expanded storage!"

    elseif upgradeType == "Zone" then
        local nextZoneId = #data.UnlockedZones + 1
        local nextZone = GameData.Zones[nextZoneId]

        if not nextZone then return false, "Max zone reached" end
        if data.Coins < nextZone.Cost then return false, "Not enough coins" end

        data.Coins = data.Coins - nextZone.Cost
        table.insert(data.UnlockedZones, nextZoneId)
        updateLeaderstats(player, data)
        return true, "Unlocked new zone: " .. nextZone.Name
    end

    return false, "Invalid upgrade type"
end
