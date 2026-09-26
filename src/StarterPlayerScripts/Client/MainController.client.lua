-- The core gameplay is now handled via Workspace interactions
-- (ClickDetectors for Trees, ProximityPrompts for Woodchippers).
-- No global input spamming is allowed!

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Reserved for future client-side effects (e.g. tree shaking animations, sound effects)
print("Client MainController loaded. Explore the map to find trees!")
