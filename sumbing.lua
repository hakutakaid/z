local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer
local hrp

-- ✅ Function refresh HRP
local function refreshHRP(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end

-- Ambil HRP pertama kali
refreshHRP(plr.Character or plr.CharacterAdded:Wait())
-- Update saat respawn
plr.CharacterAdded:Connect(refreshHRP)

-- Auto-cek HRP tiap frame
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
frame.Size = UDim2.new(0, 230, 0, 470)
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

local label = Instance.new("TextLabel", container)
label.Size = UDim2.new(0, 200, 0, 40)
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

-- ✅ Copy angka saja
local copyBtn = Instance.new("TextButton", container)
copyBtn.Size = UDim2.new(0, 200, 0, 35)
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

-- daftar checkpoint
local checkpoints = {
    [1] = Vector3.new(-225.5, 442.6, 2142.4),
    [2] = Vector3.new(-427.7, 850.6, 3204.2),
    [3] = Vector3.new(42.4, 1270.6, 4043.7),
    [4] = Vector3.new(-1142.2, 1554.6, 4900.1),
    [5] = Vector3.new(-718.1, 1940.7, 5333.3),
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
        if pos and hrp then
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

-- ✅ Restart Script
local restartBtn = Instance.new("TextButton", container)
restartBtn.Size = UDim2.new(0, 200, 0, 40)
restartBtn.Position = UDim2.new(0, 10, 0, 420)
restartBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 50)
restartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
restartBtn.TextScaled = true
restartBtn.Text = "🔁 Restart Script"

restartBtn.MouseButton1Click:Connect(function()
    gui:Destroy() -- hapus GUI lama biar nggak dobel
    -- ⬇ ganti link ini dengan link raw pastebin / github tempat scriptmu disimpan
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sumbing.lua"))() 
end)

-- ✅ Minimize
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    container.Visible = not minimized
    if minimized then
        frame.Size = UDim2.new(0, 230, 0, 30)
        minimizeBtn.Text = "+ Koordinat GUI -"
    else
        frame.Size = UDim2.new(0, 230, 0, 470)
        minimizeBtn.Text = "- Koordinat GUI -"
    end
end)