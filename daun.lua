local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local hrp = plr.Character:WaitForChild("HumanoidRootPart")

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "KoordinatCheckpoint"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 230, 0, 430)
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
container.CanvasSize = UDim2.new(0, 0, 0, 700)

local label = Instance.new("TextLabel", container)
label.Size = UDim2.new(0, 200, 0, 40)
label.Position = UDim2.new(0, 10, 0, 0)
label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
label.TextColor3 = Color3.fromRGB(0, 255, 0)
label.TextScaled = true
label.Font = Enum.Font.Code
label.Text = "X: 0  Y: 0  Z: 0"

game:GetService("RunService").RenderStepped:Connect(function()
    local pos = hrp.Position
    label.Text = string.format("X: %.1f   Y: %.1f   Z: %.1f", pos.X, pos.Y, pos.Z)
end)

-- ✅ Copy angka saja
local copyBtn = Instance.new("TextButton", container)
copyBtn.Size = UDim2.new(0, 200, 0, 35)
copyBtn.Position = UDim2.new(0, 10, 0, 45)
copyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.TextScaled = true
copyBtn.Text = "Copy Koordinat"

copyBtn.MouseButton1Click:Connect(function()
    local pos = hrp.Position
    setclipboard(string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z))
end)

-- daftar checkpoint
local checkpoints = {
    [1] = Vector3.new(-642.5, 218.3, -433.1),
    [2] = Vector3.new(-1217.8, 264.5, -402.1),
    [3] = Vector3.new(-1394.7, 545.1, -898.8),
    [4] = Vector3.new(-1505.1, 828.6, -1493.0),
    [5] = Vector3.new(-2655.4, 1236.8, -2027.1),
}

for i = 1, 5 do
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0, 200, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, 90 + (i * 40))
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Text = "Teleport " .. i

    btn.MouseButton1Click:Connect(function()
        local pos = checkpoints[i]
        if pos then
            hrp.CFrame = CFrame.new(pos)
        end
    end)
end

-- ✅ Tombol Rejoin Server
local rejoinBtn = Instance.new("TextButton", container)
rejoinBtn.Size = UDim2.new(0, 200, 0, 40)
rejoinBtn.Position = UDim2.new(0, 10, 0, 370)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rejoinBtn.TextScaled = true
rejoinBtn.Text = "🔄 Rejoin Server"

rejoinBtn.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    container.Visible = not minimized
    if minimized then
        frame.Size = UDim2.new(0, 230, 0, 30)
        minimizeBtn.Text = "+ Koordinat GUI -"
    else
        frame.Size = UDim2.new(0, 230, 0, 430)
        minimizeBtn.Text = "- Koordinat GUI -"
    end
end)