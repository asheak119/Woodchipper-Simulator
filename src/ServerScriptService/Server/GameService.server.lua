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

    -- Safety Check: Proximity. Increased to 30 to account for large tree size.
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    if (character.HumanoidRootPart.Position - treePart.Position).Magnitude > 30 then return end

    -- Check if tree is already harvested (falling)
    if not treePart.Anchored then return end

    -- Determine Tree Type and Zone
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

    if not hasUnlocked then return end

    local storageLevel = data.StorageLevel
    local storageData = GameData.Storage[storageLevel]
    local maxCapacity = storageData and storageData.Capacity or 10

    if data.Items < maxCapacity then
        data.Items = math.min(data.Items + treeData.WoodAmount, maxCapacity)
        updateLeaderstats(player, data)

        -- Make tree fall over
        local originalCFrame = treePart.CFrame
        treePart.Anchored = false

        -- Give it a slight push to make sure it falls
        local pushForce = Instance.new("BodyVelocity")
        pushForce.Velocity = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
        pushForce.MaxForce = Vector3.new(10000, 10000, 10000)
        pushForce.Parent = treePart

        game.Debris:AddItem(pushForce, 0.1)

        -- Respawn tree after 5 seconds
        task.delay(5, function()
            treePart.Anchored = true
            treePart.CFrame = originalCFrame
            treePart.Velocity = Vector3.new(0, 0, 0)
            treePart.RotVelocity = Vector3.new(0, 0, 0)
        end)
    end
end

-- Function to handle processing wood into cash at the woodchipper
local function handleWoodProcessing(player, chipperPart)
    local data = ServerDataModule.GetPlayerData(player)
    if not data then return end

    -- Safety Check: Proximity. Increased to 30.
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    if (character.HumanoidRootPart.Position - chipperPart.Position).Magnitude > 30 then return end

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
