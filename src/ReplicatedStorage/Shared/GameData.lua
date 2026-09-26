local GameData = {}

GameData.Woodchippers = {
    [1] = { Name = "Basic Chipper", Cost = 0, Multiplier = 1 },
    [2] = { Name = "Advanced Chipper", Cost = 100, Multiplier = 2 },
    [3] = { Name = "Industrial Chipper", Cost = 500, Multiplier = 5 },
    [4] = { Name = "Laser Chipper", Cost = 2500, Multiplier = 15 }
}

GameData.Storage = {
    [1] = { Name = "Small Bag", Cost = 0, Capacity = 10 },
    [2] = { Name = "Medium Bag", Cost = 50, Capacity = 25 },
    [3] = { Name = "Large Backpack", Cost = 250, Capacity = 100 },
    [4] = { Name = "Void Pouch", Cost = 1000, Capacity = 500 }
}

GameData.Zones = {
    [1] = { Name = "Forest_Zone1", Cost = 0 },
    [2] = { Name = "Jungle_Zone2", Cost = 1000 },
    [3] = { Name = "Magical_Woods", Cost = 5000 }
}

GameData.Trees = {
    OakTree = { RequiredZone = 1, WoodAmount = 1 },
    PineTree = { RequiredZone = 2, WoodAmount = 3 },
    RedwoodTree = { RequiredZone = 3, WoodAmount = 10 }
}

return GameData
