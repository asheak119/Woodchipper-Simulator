local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameData = require(ReplicatedStorage.Shared.GameData)
local ServerDataModule = require(ServerScriptService.Server.ServerDataModule)

local PlayerDataStore = DataStoreService:GetDataStore("WoodchipperSimData_v1")

local function setupLeaderstats(player, data)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = data.Coins
    coins.Parent = leaderstats

    local items = Instance.new("IntValue")
    items.Name = "Items"
    items.Value = data.Items
    items.Parent = leaderstats
end

local function onPlayerAdded(player)
    local success, data = pcall(function()
        return PlayerDataStore:GetAsync(tostring(player.UserId))
    end)

    if not success or not data then
        data = {
            Coins = 0,
            Items = 0,
            WoodchipperLevel = 1,
            StorageLevel = 1,
            UnlockedZones = {1}
        }
    end

    ServerDataModule.SetPlayerData(player, data)
    setupLeaderstats(player, data)
end

local function onPlayerRemoving(player)
    local data = ServerDataModule.RemovePlayerData(player)
    if data then
        local success, err = pcall(function()
            PlayerDataStore:SetAsync(tostring(player.UserId), data)
        end)
        if not success then
            warn("Failed to save data for " .. player.Name .. ": " .. tostring(err))
        end
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in the game when the script runs (Studio edge case)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        onPlayerAdded(player)
    end)
end

-- Save on server shutdown
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerRemoving(player)
    end
end)

-- Expose data via RemoteFunction
local Events = ReplicatedStorage:WaitForChild("Events")
local GetPlayerData = Events:WaitForChild("GetPlayerData")
GetPlayerData.OnServerInvoke = function(player)
    return ServerDataModule.GetPlayerData(player)
end
