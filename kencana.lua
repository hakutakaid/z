-- Koordinat/Checkpoint GUI (refactor dengan UICorner + drag via title bar)

--// Services
local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")

--// Player/Character
local plr = Players.LocalPlayer
local hrp

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

--// GUI Instances
local ScreenGui   = Instance.new("ScreenGui")
ScreenGui.Name    = "KoordinatCheckpoint"
ScreenGui.Parent  = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn   = false

local Frame       = Instance.new("Frame")
Frame.Parent      = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Position    = UDim2.new(0.05, 0, 0.05, 0)
Frame.Size        = UDim2.new(0, 230, 0, 470)
Frame.Active      = true

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 12)
FrameCorner.Parent = Frame

-- Title bar (dipakai drag + tombol minimize)
local TitleBar    = Instance.new("TextButton")
TitleBar.Name     = "TitleBar"
TitleBar.Parent   = Frame
TitleBar.Size     = UDim2.new(1, 0, 0, 30)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.TextScaled = true
TitleBar.AutoButtonColor = false
TitleBar.Text     = "- KENCANA -"

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Container isi
local Container   = Instance.new("ScrollingFrame")
Container.Parent  = Frame
Container.Size    = UDim2.new(1, 0, 1, -30)
Container.Position= UDim2.new(0, 0, 0, 30)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 6
Container.CanvasSize = UDim2.new(0, 0, 0, 800)

-- Helper: bikin tombol rounded
local function makeButton(parent, text, posY, height)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size   = UDim2.new(0, 200, 0, height or 35)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Text = text
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 8)
    return btn
end

-- Label koordinat
local CoordLabel = Instance.new("TextLabel")
CoordLabel.Parent = Container
CoordLabel.Size   = UDim2.new(0, 200, 0, 40)
CoordLabel.Position = UDim2.new(0, 10, 0, 0)
CoordLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CoordLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
CoordLabel.TextScaled = true
CoordLabel.Font = Enum.Font.Code
CoordLabel.Text = "X: 0  Y: 0  Z: 0"
Instance.new("UICorner", CoordLabel).CornerRadius = UDim.new(0, 8)

RunService.RenderStepped:Connect(function()
    if hrp then
        local p = hrp.Position
        CoordLabel.Text = string.format("X: %.1f   Y: %.1f   Z: %.1f", p.X, p.Y, p.Z)
    end
end)

-- Copy koordinat
local CopyBtn = makeButton(Container, "Copy Koordinat", 45)
CopyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CopyBtn.MouseButton1Click:Connect(function()
    if hrp then
        local p = hrp.Position
        setclipboard(string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z))
    end
end)

-- Checkpoints
local checkpoints = {
    [1] = Vector3.new(-205.2, 623.5, -563.5),
    [2] = Vector3.new(2602.3, 948.4, -123.125),
    [3] = Vector3.new(4334.8, 1232.6, 531.7),
    [4] = Vector3.new(4760.6, 1280.4, -270.5),
    [5] = Vector3.new(5661.3, 1975.9, 440.5),
}

for i = 1, 5 do
    local btn = makeButton(Container, "Teleport "..i, 90 + (i * 40))
    btn.MouseButton1Click:Connect(function()
        local pos = checkpoints[i]
        if pos and hrp then
            hrp.CFrame = CFrame.new(pos)
        end
    end)
end

-- Rejoin
local RejoinBtn = makeButton(Container, "🔄 Rejoin Server", 370, 40)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
RejoinBtn.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)

-- Restart Script (load ulang dari raw milikmu)
local RestartBtn = makeButton(Container, "🔁 Restart Script", 420, 40)
RestartBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 50)
RestartBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy() -- bersihkan GUI lama
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/kencana.lua"))()
end)

-- Auto Run CP 1→5 (delay 3s), auto stop di 5
local autoRun = false
local AutoRunBtn = makeButton(Container, "▶ Auto Run", 470, 40)
AutoRunBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 150)

AutoRunBtn.MouseButton1Click:Connect(function()
    if autoRun then return end
    autoRun = true
    AutoRunBtn.Text = "⏳ Running..."
    task.spawn(function()
        for i = 1, math.min(5, #checkpoints) do
            if not autoRun then break end
            if hrp and checkpoints[i] then
                hrp.CFrame = CFrame.new(checkpoints[i])
            end
            task.wait(3)
        end
        autoRun = false
        AutoRunBtn.Text = "▶ Auto Run"
    end)
end)

-- Respawn
local RespawnBtn = makeButton(Container, "❤️ Respawn", 520, 40)
RespawnBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
RespawnBtn.MouseButton1Click:Connect(function()
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end)

-- Minimize toggle (konten disembunyikan, title tetap)
local minimized = false
TitleBar.MouseButton1Click:Connect(function()
    -- klik = toggle minimize (double fungsi: title untuk drag juga)
    minimized = not minimized
    Container.Visible = not minimized
    if minimized then
        Frame.Size = UDim2.new(0, 230, 0, 30)
        TitleBar.Text = "+ KENCANA -"
    else
        Frame.Size = UDim2.new(0, 230, 0, 470)
        TitleBar.Text = "- KENCANA -"
    end
end)

-- DRAG via TitleBar (bukan seluruh frame)
do
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end