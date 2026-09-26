local ServerDataModule = {}
local SessionData = {}

function ServerDataModule.GetPlayerData(player)
    return SessionData[player.UserId]
end

function ServerDataModule.SetPlayerData(player, data)
    SessionData[player.UserId] = data
end

function ServerDataModule.RemovePlayerData(player)
    local data = SessionData[player.UserId]
    SessionData[player.UserId] = nil
    return data
end

return ServerDataModule
