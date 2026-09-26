local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Events = ReplicatedStorage:WaitForChild("Events")
local CollectItem = Events:WaitForChild("CollectItem")
local ProcessItem = Events:WaitForChild("ProcessItem")

local player = Players.LocalPlayer

-- Basic simulation loop: auto-collect items if pressing E or clicking
-- Realistically this would be touching objects in the workspace.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        CollectItem:FireServer()
    elseif input.KeyCode == Enum.KeyCode.E then
        -- Process items in woodchipper
        ProcessItem:FireServer()
    end
end)
