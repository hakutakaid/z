-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local plr = Players.LocalPlayer
local hrp

-- Setup HRP
local function setupHRP(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end

-- Smooth dropdown function
local function toggleDropdown(frame, open, openSize)
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(frame, tweenInfo, {Size = open and UDim2.new(1,0,0,openSize) or UDim2.new(1,0,0,0)})
    tween:Play()
end

-- Create button helper
local function makeButton(parent, text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,35)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Text = text
    btn.Parent = parent
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0,6)
    return btn
end

-- Main GUI creation
local function createGUI()
    if plr.PlayerGui:FindFirstChild("FinalTeleportGUI_Modern") then return end

    local gui = Instance.new("ScreenGui", plr.PlayerGui)
    gui.Name = "FinalTeleportGUI_Modern"

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0,300,0,450)
    frame.Position = UDim2.new(0.05,0,0.1,0)
    frame.BackgroundColor3 = Color3.fromRGB(40,44,52)
    frame.Active = true
    frame.Draggable = true
    frame.BorderSizePixel = 0
    local frameCorner = Instance.new("UICorner", frame)
    frameCorner.CornerRadius = UDim.new(0,8)

    -- Title Bar
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,35)
    title.BackgroundColor3 = Color3.fromRGB(50,55,65)
    title.TextColor3 = Color3.fromRGB(220,220,220)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Text = "🚀 Teleport GUI Modern"

    -- Minimize
    local minBtn = Instance.new("TextButton", frame)
    minBtn.Size = UDim2.new(0,30,0,30)
    minBtn.Position = UDim2.new(1,-35,0,2)
    minBtn.BackgroundColor3 = Color3.fromRGB(231,76,60)
    minBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minBtn.Text = "–"
    minBtn.Font = Enum.Font.GothamBold
    local minCorner = Instance.new("UICorner", minBtn)
    minCorner.CornerRadius = UDim.new(0,6)
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _,child in ipairs(frame:GetChildren()) do
            if child ~= title and child ~= minBtn and child ~= frameCorner then
                child.Visible = not minimized
            end
        end
        frame.Size = minimized and UDim2.new(0,300,0,35) or UDim2.new(0,300,0,450)
    end)

    -- Scroll Frame
    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1,-10,1,-45)
    scroll.Position = UDim2.new(0,5,0,40)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    local layout = Instance.new("UIListLayout", scroll)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)
    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop = UDim.new(0,5)
    pad.PaddingBottom = UDim.new(0,5)
    pad.PaddingLeft = UDim.new(0,5)
    pad.PaddingRight = UDim.new(0,5)

    -- Coordinate display
    local coord = Instance.new("TextLabel", scroll)
    coord.Size = UDim2.new(1,0,0,30)
    coord.BackgroundColor3 = Color3.fromRGB(60,65,75)
    coord.TextColor3 = Color3.fromRGB(46,204,113)
    coord.Font = Enum.Font.Code
    coord.TextSize = 16
    coord.TextXAlignment = Enum.TextXAlignment.Left
    coord.Text = "X:0 Y:0 Z:0"
    local corner = Instance.new("UICorner", coord)
    corner.CornerRadius = UDim.new(0,6)
    RunService.RenderStepped:Connect(function()
        if hrp and not minimized then
            local p = hrp.Position
            coord.Text = string.format("X:%.1f Y:%.1f Z:%.1f",p.X,p.Y,p.Z)
        end
    end)

    -- Copy Coord Button
    local copyBtn = makeButton(scroll,"📋 Copy Coordinates",Color3.fromRGB(52,152,219))
    copyBtn.MouseButton1Click:Connect(function()
        if hrp then setclipboard(string.format("%.1f, %.1f, %.1f", hrp.Position.X,hrp.Position.Y,hrp.Position.Z)) end
    end)

    -- Checkpoints
    local checkpoints = {
        {name="CP1", pos=Vector3.new(-621.7,251.7,-383.9)},
        {name="CP2", pos=Vector3.new(-1203.2,263.1,-487.1)},
        {name="CP3", pos=Vector3.new(-1399.3,579.8,-949.9)},
    }
    local cpBtn = makeButton(scroll,"▼ Select Checkpoint",Color3.fromRGB(155,89,182))
    local cpList = Instance.new("Frame",scroll)
    cpList.Size = UDim2.new(1,0,0,0)
    cpList.BackgroundColor3 = Color3.fromRGB(60,40,70)
    cpList.Visible = false
    local cpLayout = Instance.new("UIListLayout",cpList)
    cpLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cpLayout.Padding = UDim.new(0,2)
    local cpCorner = Instance.new("UICorner",cpList)
    cpCorner.CornerRadius = UDim.new(0,6)

    cpBtn.MouseButton1Click:Connect(function()
        cpList.Visible = true
        toggleDropdown(cpList,not cpList.Visible,#checkpoints*35)
    end)

    for _,cp in ipairs(checkpoints) do
        local btn = makeButton(cpList,cp.name,Color3.fromRGB(120,70,150))
        btn.MouseButton1Click:Connect(function()
            if hrp then hrp.CFrame = CFrame.new(cp.pos) end
            toggleDropdown(cpList,false,0)
        end)
    end

    -- Player Teleport
    local playerBtn = makeButton(scroll,"▼ Teleport to Player",Color3.fromRGB(46,204,113))
    local playerList = Instance.new("Frame",scroll)
    playerList.Size = UDim2.new(1,0,0,0)
    playerList.BackgroundColor3 = Color3.fromRGB(30,60,40)
    playerList.Visible = false
    local playerLayout = Instance.new("UIListLayout",playerList)
    playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playerLayout.Padding = UDim.new(0,2)
    local playerCorner = Instance.new("UICorner",playerList)
    playerCorner.CornerRadius = UDim.new(0,6)

    local function refreshPlayers()
        for _,c in ipairs(playerList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _,target in ipairs(Players:GetPlayers()) do
            if target ~= plr then
                local btn = makeButton(playerList,target.Name,Color3.fromRGB(70,180,90))
                btn.MouseButton1Click:Connect(function()
                    if hrp and target.Character then
                        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                        if tHRP then hrp.CFrame = tHRP.CFrame end
                    end
                    toggleDropdown(playerList,false,0)
                end)
            end
        end
    end
    Players.PlayerAdded:Connect(refreshPlayers)
    Players.PlayerRemoving:Connect(refreshPlayers)
    refreshPlayers()

    playerBtn.MouseButton1Click:Connect(function()
        local open = not playerList.Visible
        playerList.Visible = true
        toggleDropdown(playerList,open,#Players:GetPlayers()*35)
    end)

    -- Actions Buttons
    local rejoinBtn = makeButton(scroll,"🔄 Rejoin Server",Color3.fromRGB(241,196,15))
    rejoinBtn.MouseButton1Click:Connect(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
    end)
    local restartBtn = makeButton(scroll,"⚡ Restart Script",Color3.fromRGB(231,76,60))
    restartBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/daun.lua"))()
    end)

    -- Respawn Button
    local respawnBtn = makeButton(scroll,"❤️ Respawn",Color3.fromRGB(200,50,50))
    respawnBtn.MouseButton1Click:Connect(function()
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end)
end

-- Handle respawn
local function onCharAdded(char)
    setupHRP(char)
    createGUI()
end

if plr.Character then onCharAdded(plr.Character) end
plr.CharacterAdded:Connect(onCharAdded)