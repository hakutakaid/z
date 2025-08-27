-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer
local hrp = plr.Character:WaitForChild("HumanoidRootPart")

-- Update HRP saat respawn
plr.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "CompactTeleportGUI"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 200)
Frame.Position = UDim2.new(0.05,0,0.1,0)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundColor3 = Color3.fromRGB(50,50,50)
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Text = "Compact Teleport GUI"
Title.TextScaled = true

-- Koordinat
local CoordLabel = Instance.new("TextLabel", Frame)
CoordLabel.Size = UDim2.new(0,230,0,25)
CoordLabel.Position = UDim2.new(0,10,0,40)
CoordLabel.BackgroundColor3 = Color3.fromRGB(40,40,40)
CoordLabel.TextColor3 = Color3.fromRGB(0,255,0)
CoordLabel.TextScaled = true
CoordLabel.Text = "X: 0  Y: 0  Z: 0"

RunService.RenderStepped:Connect(function()
    if hrp then
        local pos = hrp.Position
        CoordLabel.Text = string.format("X: %.1f Y: %.1f Z: %.1f", pos.X,pos.Y,pos.Z)
    end
end)

local CopyBtn = Instance.new("TextButton", Frame)
CopyBtn.Size = UDim2.new(0,110,0,25)
CopyBtn.Position = UDim2.new(0,10,0,70)
CopyBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
CopyBtn.TextColor3 = Color3.fromRGB(255,255,255)
CopyBtn.TextScaled = true
CopyBtn.Text = "Copy Coord"
CopyBtn.MouseButton1Click:Connect(function()
    if hrp then
        setclipboard(string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
    end
end)

-- Checkpoint dropdown
local checkpoints = {
    {name="Checkpoint 1", pos=Vector3.new(-345.5, 457.0, -223.6)},
    {name="Checkpoint 2", pos=Vector3.new(-764.6, 996.6, -127.6)},
    {name="Checkpoint 3", pos=Vector3.new(-1657.7, 998.4, 259.5)}
}

local CPDropdown = Instance.new("TextButton", Frame)
CPDropdown.Size = UDim2.new(0,230,0,25)
CPDropdown.Position = UDim2.new(0,10,0,100)
CPDropdown.BackgroundColor3 = Color3.fromRGB(80,50,50)
CPDropdown.TextColor3 = Color3.fromRGB(255,255,255)
CPDropdown.TextScaled = true
CPDropdown.Text = "Select Checkpoint"

local CPList = Instance.new("Frame", Frame)
CPList.Size = UDim2.new(0,230,0,#checkpoints*25)
CPList.Position = UDim2.new(0,10,0,125)
CPList.BackgroundColor3 = Color3.fromRGB(50,30,30)
CPList.Visible = false

CPDropdown.MouseButton1Click:Connect(function()
    CPList.Visible = not CPList.Visible
end)

for i, cp in ipairs(checkpoints) do
    local btn = Instance.new("TextButton", CPList)
    btn.Size = UDim2.new(1,0,0,25)
    btn.Position = UDim2.new(0,0,0,(i-1)*25)
    btn.BackgroundColor3 = Color3.fromRGB(70,40,40)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true
    btn.Text = cp.name
    btn.MouseButton1Click:Connect(function()
        if hrp then hrp.CFrame = CFrame.new(cp.pos) end
        CPList.Visible = false
    end)
end

-- Player dropdown
local PlayerDropdown = Instance.new("TextButton", Frame)
PlayerDropdown.Size = UDim2.new(0,230,0,25)
PlayerDropdown.Position = UDim2.new(0,10,0,160)
PlayerDropdown.BackgroundColor3 = Color3.fromRGB(50,50,80)
PlayerDropdown.TextColor3 = Color3.fromRGB(255,255,255)
PlayerDropdown.TextScaled = true
PlayerDropdown.Text = "Select Player"

local PlayerList = Instance.new("Frame", Frame)
PlayerList.Size = UDim2.new(0,230,0,200)
PlayerList.Position = UDim2.new(0,10,0,185)
PlayerList.BackgroundColor3 = Color3.fromRGB(30,30,60)
PlayerList.Visible = false

PlayerDropdown.MouseButton1Click:Connect(function()
    PlayerList.Visible = not PlayerList.Visible
end)

local function refreshPlayers()
    for _, child in ipairs(PlayerList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local yPos = 0
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= plr then
            local btn = Instance.new("TextButton", PlayerList)
            btn.Size = UDim2.new(1,0,0,25)
            btn.Position = UDim2.new(0,0,0,yPos)
            btn.BackgroundColor3 = Color3.fromRGB(60,60,100)
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.TextScaled = true
            btn.Text = target.Name
            btn.MouseButton1Click:Connect(function()
                if hrp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    hrp.CFrame = target.Character.HumanoidRootPart.CFrame
                end
                PlayerList.Visible = false
            end)
            yPos = yPos + 25
        end
    end
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- Rejoin & Restart
local RejoinBtn = Instance.new("TextButton", Frame)
RejoinBtn.Size = UDim2.new(0,110,0,25)
RejoinBtn.Position = UDim2.new(0,10,0,390)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(50,80,50)
RejoinBtn.TextColor3 = Color3.fromRGB(255,255,255)
RejoinBtn.TextScaled = true
RejoinBtn.Text = "Rejoin"
RejoinBtn.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)

local RestartBtn = Instance.new("TextButton", Frame)
RestartBtn.Size = UDim2.new(0,110,0,25)
RestartBtn.Position = UDim2.new(0,130,0,390)
RestartBtn.BackgroundColor3 = Color3.fromRGB(80,50,80)
RestartBtn.TextColor3 = Color3.fromRGB(255,255,255)
RestartBtn.TextScaled = true
RestartBtn.Text = "Restart"
RestartBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    -- Ganti URL sesuai script original
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sibuatan.lua"))()
end)