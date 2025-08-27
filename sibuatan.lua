-- Load Orion Lib dari RikoTheDemonHunter
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RikoTheDemonHunter/V3/refs/heads/main/Orion%20Lib.lua"))()

-- Buat Window
local Window = Library:CreateWindow{
    Title = "Teleport Hub",
    SubTitle = "by RikoTheDemonHunter",
    TabWidth = 130,
    Size = UDim2.fromOffset(650, 450),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
}

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local plr = Players.LocalPlayer
local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

-- Update HRP saat respawn
plr.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- Tab utama
local MainTab = Window:CreateTab("Main", 4483345998)

-- Sections
local CoordSection = MainTab:CreateSection("Koordinat Player")
local CheckSection = MainTab:CreateSection("Checkpoints")
local PlayerSection = MainTab:CreateSection("Teleport Player")
local ActionSection = MainTab:CreateSection("Actions")

-- Koordinat Player
local CoordLabel = CoordSection:CreateLabel("X: 0  Y: 0  Z: 0")
game:GetService("RunService").Heartbeat:Connect(function()
    if hrp then
        CoordLabel:Set("X: "..math.floor(hrp.Position.X).."  Y: "..math.floor(hrp.Position.Y).."  Z: "..math.floor(hrp.Position.Z))
    end
end)

CoordSection:CreateButton("Copy Koordinat", function()
    if hrp then
        setclipboard(hrp.Position)
    end
end)

-- Checkpoints
local checkpoints = {
    {name = "Checkpoint 1", position = Vector3.new(-345.5, 457.0, -223.6)},
    {name = "Checkpoint 2", position = Vector3.new(-764.6, 996.6, -127.6)},
    {name = "Checkpoint 3", position = Vector3.new(-1657.7, 998.4, 259.5)}
}

for _, checkpoint in ipairs(checkpoints) do
    CheckSection:CreateButton(checkpoint.name, function()
        if hrp then
            hrp.CFrame = CFrame.new(checkpoint.position)
        end
    end)
end

-- Teleport Player
local function refreshPlayers()
    PlayerSection:Clear()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr then
            PlayerSection:CreateButton(player.Name, function()
                if hrp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    hrp.CFrame = player.Character.HumanoidRootPart.CFrame
                end
            end)
        end
    end
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- Actions
ActionSection:CreateButton("Rejoin Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)

ActionSection:CreateButton("Restart Script", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sibuatan.lua"))()
end)

-- Init GUI
Library:Init()