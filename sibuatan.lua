-- Load Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SkazaDev/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("My Script GUI", "DarkTheme") -- Tema: DarkTheme / LightTheme

-- Ambil service
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local plr = Players.LocalPlayer

-- Checkpoints & Player teleport Tab
local MainTab = Window:NewTab("Main")

-- Section untuk Koordinat
local CoordSection = MainTab:NewSection("Koordinat Player")
local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

-- Update HRP saat respawn
plr.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- Label koordinat
CoordSection:NewLabel("X: 0  Y: 0  Z: 0")

-- Update label tiap frame
spawn(function()
    while true do
        wait(0.1)
        if hrp then
            CoordSection:UpdateLabel(string.format("X: %.1f  Y: %.1f  Z: %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
        end
    end
end)

-- Copy koordinat button
CoordSection:NewButton("Copy Koordinat", "Copy current coordinates", function()
    if hrp then
        setclipboard(string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
    end
end)

-- Section Checkpoints
local CheckSection = MainTab:NewSection("Checkpoints")
local checkpoints = {
    Vector3.new(-345.5, 457.0, -223.6),
    Vector3.new(-764.6, 996.6, -127.6),
    Vector3.new(-1657.7, 998.4, 259.5)
}

for i,pos in ipairs(checkpoints) do
    CheckSection:NewButton("Teleport Checkpoint "..i, "Teleport ke checkpoint "..i, function()
        if hrp then
            hrp.CFrame = CFrame.new(pos)
        end
    end)
end

-- Section Teleport Player
local PlayerSection = MainTab:NewSection("Teleport Player")
local function refreshPlayers()
    -- Hapus button lama
    for _, child in ipairs(PlayerSection:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= plr then
            PlayerSection:NewButton(target.Name, "Teleport ke "..target.Name, function()
                if hrp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    hrp.CFrame = target.Character.HumanoidRootPart.CFrame
                end
            end)
        end
    end
end
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- Section Rejoin / Restart
local ActionSection = MainTab:NewSection("Actions")

ActionSection:NewButton("Rejoin Server", "Teleport ke server ini lagi", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)

ActionSection:NewButton("Restart Script", "Reload script", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sibuatan.lua"))()
end)