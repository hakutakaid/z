local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer
local hrp

-- Function refresh HRP
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

-- GUI
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
container.CanvasSize = UDim2.new(0, 0, 0, 0)

-- Function untuk menambah tombol secara vertikal
local function addButton(parent, text, color, callback)
    local yOffset = #parent:GetChildren() * 40
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 240, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yOffset)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Text = text
    btn.MouseButton1Click:Connect(callback)
    container.CanvasSize = UDim2.new(0,0,0,yOffset + 50)
    return btn
end

-- Koordinat Label
local coordLabel = Instance.new("TextLabel", container)
coordLabel.Size = UDim2.new(0, 240, 0, 35)
coordLabel.Position = UDim2.new(0, 10, 0, 0)
coordLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
coordLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
coordLabel.TextScaled = true
coordLabel.Font = Enum.Font.Code
coordLabel.Text = "X: 0  Y: 0  Z: 0"

RunService.RenderStepped:Connect(function()
    if hrp then
        local pos = hrp.Position
        coordLabel.Text = string.format("X: %.1f  Y: %.1f  Z: %.1f", pos.X, pos.Y, pos.Z)
    end
end)

-- Copy koordinat
addButton(container, "Copy Koordinat", Color3.fromRGB(40,40,40), function()
    if hrp then
        local pos = hrp.Position
        setclipboard(string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z))
    end
end)

-- Submenu Function
local function createSubMenu(title)
    local toggleBtn = addButton(container, title, Color3.fromRGB(80,80,80), function()
        expanded = not expanded
        for _, btn in ipairs(subButtons) do
            btn.Visible = expanded
        end
        updatePositions()
    end)

    local subButtons = {}
    local expanded = false

    local function addSubButton(text, color, callback)
        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(0, 240, 0, 35)
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextScaled = true
        btn.Text = text
        btn.Visible = expanded
        btn.MouseButton1Click:Connect(callback)
        table.insert(subButtons, btn)
        return btn
    end

    local function updatePositions()
        local y = 40
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("TextButton") then
                child.Position = UDim2.new(0, 10, 0, y)
                if child == toggleBtn then
                    y = y + 40
                    for _, sb in ipairs(subButtons) do
                        sb.Position = UDim2.new(0, 10, 0, y)
                        if sb.Visible then
                            y = y + 40
                        end
                    end
                end
            end
        end
        container.CanvasSize = UDim2.new(0,0,0,y)
    end

    return addSubButton, subButtons, updatePositions
end

-- Checkpoints
local addCheckpointBtn, checkpointSub, updateCheckpointPos = createSubMenu("Checkpoints")
local checkpoints = {
    Vector3.new(-345.5, 457.0, -223.6),
    Vector3.new(-764.6, 996.6, -127.6),
    Vector3.new(-1657.7, 998.4, 259.5)
}
for i, pos in ipairs(checkpoints) do
    addCheckpointBtn("Teleport "..i, Color3.fromRGB(50,50,120), function()
        if hrp then hrp.CFrame = CFrame.new(pos) end
    end)
end

-- Teleport Player
local addPlayerBtn, playerSub, updatePlayerPos = createSubMenu("Teleport Player")
local function refreshPlayers()
    for _, btn in ipairs(playerSub) do btn:Destroy() end
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= plr then
            addPlayerBtn(target.Name, Color3.fromRGB(60,60,60), function()
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

-- Rejoin & Restart
addButton(container, "🔄 Rejoin Server", Color3.fromRGB(120,50,50), function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)
addButton(container, "🔁 Restart Script", Color3.fromRGB(80,120,50), function()
    gui:Destroy()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sibuatan.lua"))()
end)

-- Minimize
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    container.Visible = not minimized
    if minimized then
        frame.Size = UDim2.new(0,260,0,30)
        minimizeBtn.Text = "+ Koordinat GUI -"
    else
        frame.Size = UDim2.new(0,260,0,500)
        minimizeBtn.Text = "- Koordinat GUI -"
    end
end)