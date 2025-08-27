-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer
local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") or plr.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

plr.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "FinalTeleportGUI"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0,320,0,420)
Frame.Position = UDim2.new(0.05,0,0.1,0)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Active = true
Frame.Draggable = true
Frame.BorderSizePixel = 0

-- Title
local TitleBar = Instance.new("TextLabel", Frame)
TitleBar.Size = UDim2.new(1,0,0,30)
TitleBar.BackgroundColor3 = Color3.fromRGB(50,50,50)
TitleBar.TextColor3 = Color3.fromRGB(255,255,255)
TitleBar.TextScaled = true
TitleBar.Text = "🚀 Final Teleport GUI"

-- Minimize
local MinBtn = Instance.new("TextButton", Frame)
MinBtn.Size = UDim2.new(0,30,0,30)
MinBtn.Position = UDim2.new(1,-30,0,0)
MinBtn.BackgroundColor3 = Color3.fromRGB(100,50,50)
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.Text = "-"
MinBtn.TextScaled = true

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, child in ipairs(Frame:GetChildren()) do
        if child ~= TitleBar and child ~= MinBtn then
            child.Visible = not minimized
        end
    end
    if minimized then
        Frame.Size = UDim2.new(0,320,0,30)
    else
        Frame.Size = UDim2.new(0,320,0,420)
    end
end)

-- Scrolling frame
local Scroll = Instance.new("ScrollingFrame", Frame)
Scroll.Size = UDim2.new(1,-10,1,-40)
Scroll.Position = UDim2.new(0,5,0,35)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 8

local UIList = Instance.new("UIListLayout", Scroll)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0,5)

-- Koordinat
local CoordLabel = Instance.new("TextLabel", Scroll)
CoordLabel.Size = UDim2.new(1,0,0,25)
CoordLabel.BackgroundColor3 = Color3.fromRGB(40,40,40)
CoordLabel.TextColor3 = Color3.fromRGB(0,255,0)
CoordLabel.TextScaled = true
CoordLabel.Text = "X:0 Y:0 Z:0"

RunService.RenderStepped:Connect(function()
    if hrp then
        local p = hrp.Position
        CoordLabel.Text = string.format("X: %.1f Y: %.1f Z: %.1f",p.X,p.Y,p.Z)
    end
end)

-- Copy Coord
local CopyBtn = Instance.new("TextButton", Scroll)
CopyBtn.Size = UDim2.new(1,0,0,25)
CopyBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
CopyBtn.TextColor3 = Color3.fromRGB(255,255,255)
CopyBtn.TextScaled = true
CopyBtn.Text = "Copy Coord"
CopyBtn.MouseButton1Click:Connect(function()
    if hrp then setclipboard(string.format("%.1f, %.1f, %.1f", hrp.Position.X,hrp.Position.Y,hrp.Position.Z)) end
end)

-- Checkpoints
local checkpoints = {
    {name="Checkpoint 1", pos=Vector3.new(-345.5,457.0,-223.6)},
    {name="Checkpoint 2", pos=Vector3.new(-764.6,996.6,-127.6)},
    {name="Checkpoint 3", pos=Vector3.new(-1657.7,998.4,259.5)}
}

local CPDropdown = Instance.new("TextButton", Scroll)
CPDropdown.Size = UDim2.new(1,0,0,25)
CPDropdown.BackgroundColor3 = Color3.fromRGB(80,50,50)
CPDropdown.TextColor3 = Color3.fromRGB(255,255,255)
CPDropdown.TextScaled = true
CPDropdown.Text = "Select Checkpoint"

local CPList = Instance.new("Frame", Scroll)
CPList.Size = UDim2.new(1,0,0,#checkpoints*30)
CPList.Position = UDim2.new(0,0,0,0)
CPList.BackgroundColor3 = Color3.fromRGB(50,30,30)
CPList.Visible = false

-- Animate dropdown
local function toggleDropdown(drop, list)
    if list.Visible then
        for i = 1, 10 do
            list.Size = UDim2.new(1,0,0,#checkpoints*3*i/10)
            wait(0.01)
        end
        list.Visible = false
    else
        list.Visible = true
        for i = 1, 10 do
            list.Size = UDim2.new(1,0,0,#checkpoints*3*i/10)
            wait(0.01)
        end
    end
end

CPDropdown.MouseButton1Click:Connect(function()
    CPList.Visible = not CPList.Visible
end)

for i, cp in ipairs(checkpoints) do
    local btn = Instance.new("TextButton", CPList)
    btn.Size = UDim2.new(1,0,0,30)
    btn.Position = UDim2.new(0,0,0,(i-1)*30)
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
local PlayerDropdown = Instance.new("TextButton", Scroll)
PlayerDropdown.Size = UDim2.new(1,0,0,25)
PlayerDropdown.BackgroundColor3 = Color3.fromRGB(50,50,80)
PlayerDropdown.TextColor3 = Color3.fromRGB(255,255,255)
PlayerDropdown.TextScaled = true
PlayerDropdown.Text = "Select Player"

local PlayerList = Instance.new("ScrollingFrame", Scroll)
PlayerList.Size = UDim2.new(1,0,0,0)
PlayerList.Position = UDim2.new(0,0,0,0)
PlayerList.BackgroundColor3 = Color3.fromRGB(30,30,60)
PlayerList.ScrollBarThickness = 6
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
            btn.BackgroundColor3 = Color3.fromRGB(50,50,100)
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
    PlayerList.CanvasSize = UDim2.new(0,0,yPos,0)
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- Actions
local RejoinBtn = Instance.new("TextButton", Scroll)
RejoinBtn.Size = UDim2.new(1,0,0,30)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(50,80,50)
RejoinBtn.TextColor3 = Color3.fromRGB(255,255,255)
RejoinBtn.TextScaled = true
RejoinBtn.Text = "Rejoin Server"
RejoinBtn.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)

local RestartBtn = Instance.new("TextButton", Scroll)
RestartBtn.Size = UDim2.new(1,0,0,30)
RestartBtn.BackgroundColor3 = Color3.fromRGB(80,50,80)
RestartBtn.TextColor3 = Color3.fromRGB(255,255,255)
RestartBtn.TextScaled = true
RestartBtn.Text = "Restart Script"
RestartBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sibuatan.lua"))()
end)