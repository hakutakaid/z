local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local hrp = plr.Character:WaitForChild("HumanoidRootPart")

-- GUI utama
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "KoordinatCheckpoint"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 800)
frame.Position = UDim2.new(0, 50, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true

local uiCorner = Instance.new("UICorner", frame)
uiCorner.CornerRadius = UDim.new(0, 10)

-- Tombol minimize
local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
minimizeBtn.Position = UDim2.new(1, -45, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextScaled = true
minimizeBtn.Text = "-"
local minimized = false

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -50, 0, 40)
title.Position = UDim2.new(0, 5, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Text = "🏁 Checkpoint Menu"

-- Scroll untuk checkpoint
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -20, 0, 350)
scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0, 5)

-- Data checkpoint
local checkpoints = {
    Vector3.new(-345.5, 457.0, -223.6)
}

-- Buat tombol checkpoint
for i, pos in ipairs(checkpoints) do
    local btn = Instance.new("TextButton", scroll)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Text = "Checkpoint " .. i

    btn.MouseButton1Click:Connect(function()
        if hrp then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        end
    end)
end

scroll.CanvasSize = UDim2.new(0, 0, 0, #checkpoints * 40)

-- Tombol Respawn
local respawnBtn = Instance.new("TextButton", frame)
respawnBtn.Size = UDim2.new(0, 230, 0, 40)
respawnBtn.Position = UDim2.new(0, 15, 0, 420)
respawnBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
respawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
respawnBtn.TextScaled = true
respawnBtn.Text = "🔄 Respawn"

respawnBtn.MouseButton1Click:Connect(function()
    plr:LoadCharacter()
end)

-- Tombol Rejoin (Private Room)
local rejoinBtn = Instance.new("TextButton", frame)
rejoinBtn.Size = UDim2.new(0, 230, 0, 40)
rejoinBtn.Position = UDim2.new(0, 15, 0, 470)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rejoinBtn.TextScaled = true
rejoinBtn.Text = "🔁 Rejoin"

rejoinBtn.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)

-- Label Player List
local playersLabel = Instance.new("TextLabel", frame)
playersLabel.Size = UDim2.new(0, 230, 0, 30)
playersLabel.Position = UDim2.new(0, 15, 0, 520)
playersLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
playersLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
playersLabel.TextScaled = true
playersLabel.Font = Enum.Font.GothamBold
playersLabel.Text = "👥 Player List"

-- ScrollingFrame player list
local playersFrame = Instance.new("ScrollingFrame", frame)
playersFrame.Size = UDim2.new(0, 230, 0, 200)
playersFrame.Position = UDim2.new(0, 15, 0, 560)
playersFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
playersFrame.ScrollBarThickness = 6
playersFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local uiList = Instance.new("UIListLayout", playersFrame)
uiList.Padding = UDim.new(0, 5)

-- Buat tombol player
local function createPlayerButton(p)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Text = "Teleport → " .. p.Name
    btn.Parent = playersFrame

    btn.MouseButton1Click:Connect(function()
        local targetChar = p.Character
        local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        if targetHRP and hrp then
            hrp.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        end
    end)
end

-- Refresh player list
local function refreshPlayers()
    playersFrame:ClearAllChildren()
    local layout = Instance.new("UIListLayout", playersFrame)
    layout.Padding = UDim.new(0, 5)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr then
            createPlayerButton(p)
        end
    end

    playersFrame.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 40)
end

refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)

-- Auto refresh setiap 5 detik
task.spawn(function()
    while task.wait(5) do
        refreshPlayers()
    end
end)

-- Fungsi minimize
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        for _, child in ipairs(frame:GetChildren()) do
            if child ~= title and child ~= minimizeBtn then
                child.Visible = false
            end
        end
        frame.Size = UDim2.new(0, 260, 0, 50)
        minimizeBtn.Text = "+"
    else
        for _, child in ipairs(frame:GetChildren()) do
            child.Visible = true
        end
        frame.Size = UDim2.new(0, 260, 0, 800)
        minimizeBtn.Text = "-"
    end
end)