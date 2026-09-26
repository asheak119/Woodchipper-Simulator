local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local GameData = require(ReplicatedStorage.Shared.GameData)
local ServerDataModule = require(ServerScriptService.Server.ServerDataModule)

local Events = ReplicatedStorage:WaitForChild("Events")
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

-- Function to handle gathering wood from trees
local function handleTreeHarvest(player, treePart)
    local data = ServerDataModule.GetPlayerData(player)
    if not data then return end

    -- Safety Check: Proximity
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    if (character.HumanoidRootPart.Position - treePart.Position).Magnitude > 20 then return end

    -- Determine Tree Type and Zone
    -- Basic logic: prefix of tree name matches GameData.Trees (e.g. OakTree1 -> OakTree)
    local treeType = "OakTree"
    for tType, tData in pairs(GameData.Trees) do
        if string.find(treePart.Name, tType) then
            treeType = tType
            break
        end
    end

    local treeData = GameData.Trees[treeType]

    -- Check if player unlocked the zone
    local hasUnlocked = false
    for _, zoneId in ipairs(data.UnlockedZones) do
        if zoneId >= treeData.RequiredZone then
            hasUnlocked = true
        end
    end

    if not hasUnlocked then
        -- Could send a client message here "Zone locked!"
        return
    end

    local storageLevel = data.StorageLevel
    local storageData = GameData.Storage[storageLevel]
    local maxCapacity = storageData and storageData.Capacity or 10

    if data.Items < maxCapacity then
        data.Items = math.min(data.Items + treeData.WoodAmount, maxCapacity)
        updateLeaderstats(player, data)
    end
end

-- Function to handle processing wood into cash at the woodchipper
local function handleWoodProcessing(player, chipperPart)
    local data = ServerDataModule.GetPlayerData(player)
    if not data then return end

    -- Safety Check: Proximity
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    if (character.HumanoidRootPart.Position - chipperPart.Position).Magnitude > 15 then return end

    if data.Items > 0 then
        local chipperLevel = data.WoodchipperLevel
        local chipperData = GameData.Woodchippers[chipperLevel]
        local multiplier = chipperData and chipperData.Multiplier or 1

        local coinsGained = data.Items * multiplier
        data.Coins = data.Coins + coinsGained
        data.Items = 0

        updateLeaderstats(player, data)
    end
end

-- Hook up Workspace Interactions
local function setupWorkspaceInteractions()
    local map = Workspace:WaitForChild("Map")

    for _, child in ipairs(map:GetDescendants()) do
        if child:IsA("ClickDetector") and child.Name == "HarvestClick" then
            child.MouseClick:Connect(function(player)
                handleTreeHarvest(player, child.Parent)
            end)
        elseif child:IsA("ProximityPrompt") and child.Name == "ProcessPrompt" then
            child.Triggered:Connect(function(player)
                handleWoodProcessing(player, child.Parent)
            end)
        end
    end
end

task.spawn(setupWorkspaceInteractions)

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
