local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer
local hrp

-- ✅ Function refresh HRP
local function refreshHRP(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end

refreshHRP(plr.Character or plr.CharacterAdded:Wait())
plr.CharacterAdded:Connect(refreshHRP)

RunService.Heartbeat:Connect(function()
    if not hrp or not hrp.Parent then
        local char = plr.Character or plr.CharacterAdded:Wait()
        hrp = char:WaitForChild("HumanoidRootPart")
    end
end)

-- ✅ GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "KoordinatCheckpoint"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 500)
frame.Position = UDim2.new(0.05, 0, 0.05, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
frame.Draggable = true

local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(1, 0, 0, 30)
minimizeBtn.Position = UDim2.new(0, 0, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextScaled = true
minimizeBtn.Text = "- Koordinat GUI -"

local container = Instance.new("ScrollingFrame", frame)
container.Size = UDim2.new(1, 0, 1, -30)
container.Position = UDim2.new(0, 0, 0, 30)
container.BackgroundTransparency = 1
container.ScrollBarThickness = 6
container.CanvasSize = UDim2.new(0, 0, 0, 800)

-- ✅ Koordinat Player
local label = Instance.new("TextLabel", container)
label.Size = UDim2.new(0, 240, 0, 40)
label.Position = UDim2.new(0, 10, 0, 0)
label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
label.TextColor3 = Color3.fromRGB(0, 255, 0)
label.TextScaled = true
label.Font = Enum.Font.Code
label.Text = "X: 0  Y: 0  Z: 0"

RunService.RenderStepped:Connect(function()
    if hrp then
        local pos = hrp.Position
        label.Text = string.format("X: %.1f   Y: %.1f   Z: %.1f", pos.X, pos.Y, pos.Z)
    end
end)

-- ✅ Copy Koordinat
local copyBtn = Instance.new("TextButton", container)
copyBtn.Size = UDim2.new(0, 240, 0, 35)
copyBtn.Position = UDim2.new(0, 10, 0, 45)
copyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.TextScaled = true
copyBtn.Text = "Copy Koordinat"

copyBtn.MouseButton1Click:Connect(function()
    if hrp then
        local pos = hrp.Position
        setclipboard(string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z))
    end
end)

-- ✅ Fungsi Toggle Menu
local function createToggleMenu(parent, title)
    local mainBtn = Instance.new("TextButton", parent)
    mainBtn.Size = UDim2.new(0, 240, 0, 35)
    mainBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainBtn.TextScaled = true
    mainBtn.Text = title

    local menuFrame = Instance.new("Frame", parent)
    menuFrame.Size = UDim2.new(0, 240, 0, 0)
    menuFrame.Position = UDim2.new(0, 0, 0, 0)
    menuFrame.BackgroundTransparency = 1
    menuFrame.ClipsDescendants = true

    local expanded = false
    mainBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            menuFrame.Size = UDim2.new(0, 240, 0, menuFrame:GetChildrenCount()*40)
        else
            menuFrame.Size = UDim2.new(0, 240, 0, 0)
        end
        container.CanvasSize = UDim2.new(0,0,0,frame.Size.Y.Offset + menuFrame.AbsoluteSize.Y + 200)
    end)

    return menuFrame
end

-- ✅ Checkpoints
local checkpointMenu = createToggleMenu(container, "Checkpoints")
local checkpoints = {
    Vector3.new(-345.5, 457.0, -223.6),
    Vector3.new(-764.6, 996.6, -127.6),
    Vector3.new(-1657.7, 998.4, 259.5)
}

for i, pos in ipairs(checkpoints) do
    local btn = Instance.new("TextButton", checkpointMenu)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, (i-1)*40)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Text = "Teleport Checkpoint " .. i

    btn.MouseButton1Click:Connect(function()
        if hrp then
            hrp.CFrame = CFrame.new(pos)
        end
    end)
end

-- ✅ Teleport Player
local playerMenu = createToggleMenu(container, "Teleport Player")

local function updatePlayers()
    for _, child in ipairs(playerMenu:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local yOffset = 0
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= plr then
            local btn = Instance.new("TextButton", playerMenu)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Position = UDim2.new(0, 0, 0, yOffset)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextScaled = true
            btn.Text = target.Name

            btn.MouseButton1Click:Connect(function()
                if hrp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    hrp.CFrame = target.Character.HumanoidRootPart.CFrame
                end
            end)
            yOffset = yOffset + 35
        end
    end
    playerMenu.Size = UDim2.new(0, 240, 0, yOffset)
    container.CanvasSize = UDim2.new(0,0,0,playerMenu.AbsolutePosition.Y + playerMenu.AbsoluteSize.Y + 50)
end

Players.PlayerAdded:Connect(updatePlayers)
Players.PlayerRemoving:Connect(updatePlayers)
updatePlayers()

-- ✅ Rejoin & Restart
local rejoinBtn = Instance.new("TextButton", container)
rejoinBtn.Size = UDim2.new(0, 240, 0, 40)
rejoinBtn.Position = UDim2.new(0, 10, 0, 900)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rejoinBtn.TextScaled = true
rejoinBtn.Text = "🔄 Rejoin Server"

rejoinBtn.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)

local restartBtn = Instance.new("TextButton", container)
restartBtn.Size = UDim2.new(0, 240, 0, 40)
restartBtn.Position = UDim2.new(0, 10, 0, 950)
restartBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 50)
restartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
restartBtn.TextScaled = true
restartBtn.Text = "🔁 Restart Script"

restartBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sibuatan.lua"))()
end)

-- ✅ Minimize
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    container.Visible = not minimized
    if minimized then
        frame.Size = UDim2.new(0, 260, 0, 30)
        minimizeBtn.Text = "+ Koordinat GUI -"
    else
        frame.Size = UDim2.new(0, 260, 0, 500)
        minimizeBtn.Text = "- Koordinat GUI -"
    end
end)