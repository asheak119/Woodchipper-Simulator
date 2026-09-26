
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage.Shared.GameData)

local Events = ReplicatedStorage:WaitForChild("Events")
local PurchaseUpgrade = Events:WaitForChild("PurchaseUpgrade")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Check if UI already exists to prevent duplication on spawn
if PlayerGui:FindFirstChild("MainShopUI") then
    return
end

-- Build Base UI Framework
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MainShopUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- HUD for Stats
local HUDFrame = Instance.new("Frame")
HUDFrame.Size = UDim2.new(0, 200, 0, 100)
HUDFrame.Position = UDim2.new(0.5, -100, 0, 10)
HUDFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
HUDFrame.BackgroundTransparency = 0.5
HUDFrame.Parent = ScreenGui

local UIListLayoutHUD = Instance.new("UIListLayout")
UIListLayoutHUD.Parent = HUDFrame
UIListLayoutHUD.SortOrder = Enum.SortOrder.LayoutOrder

local CashLabel = Instance.new("TextLabel")
CashLabel.Size = UDim2.new(1, 0, 0, 50)
CashLabel.BackgroundTransparency = 1
CashLabel.Text = "Cash: 0"
CashLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
CashLabel.TextSize = 24
CashLabel.LayoutOrder = 1
CashLabel.Parent = HUDFrame

local WoodLabel = Instance.new("TextLabel")
WoodLabel.Size = UDim2.new(1, 0, 0, 50)
WoodLabel.BackgroundTransparency = 1
WoodLabel.Text = "Wood: 0 / 10"
WoodLabel.TextColor3 = Color3.fromRGB(139, 69, 19)
WoodLabel.TextSize = 24
WoodLabel.LayoutOrder = 2
WoodLabel.Parent = HUDFrame

-- Update HUD via Leaderstats
local leaderstats = player:WaitForChild("leaderstats", 10)
if leaderstats then
    local coins = leaderstats:WaitForChild("Coins")
    local items = leaderstats:WaitForChild("Items")

    local function updateHUD()
        CashLabel.Text = "Cash: " .. tostring(coins.Value)
        -- Hardcoded max capacity display here just for visual, actual server logic handles real cap
        -- Or we can fetch it, but let's just show current wood.
        WoodLabel.Text = "Wood: " .. tostring(items.Value)
    end

    coins.Changed:Connect(updateHUD)
    items.Changed:Connect(updateHUD)
    updateHUD()
end

-- Shop Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.Text = "Upgrade Shop"
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)

Title.LayoutOrder = 1

local function createButton(name, layoutOrder, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 50)
    button.Position = UDim2.new(0, 10, 0, 0)
    button.Text = name
    button.TextSize = 18
    button.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.LayoutOrder = layoutOrder

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.Parent = button

    button.Parent = MainFrame

    button.MouseButton1Click:Connect(callback)
    return button
end

createButton("Upgrade Woodchipper", 2, function()
    local success, msg = PurchaseUpgrade:InvokeServer("Woodchipper")
    print(msg)
end)

createButton("Upgrade Storage", 3, function()
    local success, msg = PurchaseUpgrade:InvokeServer("Storage")
    print(msg)
end)

createButton("Unlock Next Zone", 4, function()
    local success, msg = PurchaseUpgrade:InvokeServer("Zone")
    print(msg)
end)

-- Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 0, 20)
ToggleButton.Text = "Shop"
ToggleButton.TextSize = 20
ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Parent = ScreenGui

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)
