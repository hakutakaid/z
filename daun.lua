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

-- Create button helper
local function makeButton(parent, text, color, callback)
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
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    return btn
end

-- Helper buat dropdown item
local function makeDropdownItem(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,30)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = text
    btn.Parent = parent
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0,5)
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    return btn
end

-- Fungsi dropdown modern: anak langsung ScreenGui
local function createDropdown(gui, parentFrame, titleText, items)
    local container = Instance.new("Frame", parentFrame)
    container.Size = UDim2.new(1,0,0,35)
    container.BackgroundTransparency = 1

    local mainBtn = Instance.new("TextButton", container)
    mainBtn.Size = UDim2.new(1,0,0,35)
    mainBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    mainBtn.TextColor3 = Color3.fromRGB(255,255,255)
    mainBtn.Font = Enum.Font.GothamBold
    mainBtn.TextSize = 16
    mainBtn.Text = "▼ "..titleText
    local mainCorner = Instance.new("UICorner", mainBtn)
    mainCorner.CornerRadius = UDim.new(0,6)

    -- Dropdown frame langsung di ScreenGui supaya bebas clipping
    local listFrame = Instance.new("Frame", gui)
    listFrame.Size = UDim2.new(0, mainBtn.AbsoluteSize.X, 0, 0)
    listFrame.Position = mainBtn.AbsolutePosition + Vector2.new(0, mainBtn.AbsoluteSize.Y)
    listFrame.BackgroundColor3 = Color3.fromRGB(60,60,70)
    listFrame.ClipsDescendants = false
    listFrame.ZIndex = 10

    local layout = Instance.new("UIListLayout", listFrame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,2)

    local open = false
    mainBtn.MouseButton1Click:Connect(function()
        open = not open
        -- Update posisi dropdown sesuai tombol (jika window digeser)
        listFrame.Position = mainBtn.AbsolutePosition + Vector2.new(0, mainBtn.AbsoluteSize.Y)
        local targetSize = open and UDim2.new(0, mainBtn.AbsoluteSize.X, 0, #items*32) or UDim2.new(0, mainBtn.AbsoluteSize.X, 0, 0)
        TweenService:Create(listFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=targetSize}):Play()
    end)

    for _,item in ipairs(items) do
        makeDropdownItem(listFrame,item.name,item.color,item.callback)
    end

    return container, listFrame
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
    makeButton(scroll,"📋 Copy Coordinates",Color3.fromRGB(52,152,219),function()
        if hrp then setclipboard(string.format("%.1f, %.1f, %.1f", hrp.Position.X,hrp.Position.Y,hrp.Position.Z)) end
    end)

    -- Checkpoints
    local checkpoints = {
        {name="CP1", pos=Vector3.new(-621.7,251.7,-383.9)},
        {name="CP2", pos=Vector3.new(-1203.2,263.1,-487.1)},
        {name="CP3", pos=Vector3.new(-1399.3,579.8,-949.9)},
        {name="CP4", pos=Vector3.new(-1701.0, 818.0, -1400.0)},
        {name="CP5", pos=Vector3.new(-2815.3, 1631.9, -2436.9)},
        {name="CP6", pos=Vector3.new(-3102.4, 1694.7, -2561.0)},
    }
    local cpItems = {}
    for _,cp in ipairs(checkpoints) do
        table.insert(cpItems,{
            name = cp.name,
            color = Color3.fromRGB(120,70,150),
            callback = function()
                if hrp then hrp.CFrame = CFrame.new(cp.pos) end
            end
        })
    end
    createDropdown(gui, scroll, "Select Checkpoint", cpItems)

    -- Teleport Player
    local function refreshPlayersDropdownItems()
        local t = {}
        for _,target in ipairs(Players:GetPlayers()) do
            if target ~= plr then
                table.insert(t,{
                    name = target.Name,
                    color = Color3.fromRGB(70,180,90),
                    callback = function()
                        if hrp and target.Character then
                            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                            if tHRP then hrp.CFrame = tHRP.CFrame end
                        end
                    end
                })
            end
        end
        return t
    end

    local playerDropdown = createDropdown(gui, scroll, "Teleport Player", refreshPlayersDropdownItems())

    Players.PlayerAdded:Connect(function()
        playerDropdown:Destroy()
        playerDropdown = createDropdown(gui, scroll, "Teleport Player", refreshPlayersDropdownItems())
    end)
    Players.PlayerRemoving:Connect(function()
        playerDropdown:Destroy()
        playerDropdown = createDropdown(gui, scroll, "Teleport Player", refreshPlayersDropdownItems())
    end)

    -- Action Buttons
    makeButton(scroll,"❤️ Respawn",Color3.fromRGB(200,50,50),function()
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end)
    makeButton(scroll,"🔄 Rejoin Server",Color3.fromRGB(241,196,15),function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
    end)
    makeButton(scroll,"⚡ Restart Script",Color3.fromRGB(231,76,60),function()
        gui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/daun.lua"))()
    end)
end

-- Handle respawn
local function onCharAdded(char)
    setupHRP(char)
    createGUI()
end

if plr.Character then onCharAdded(plr.Character) end
plr.CharacterAdded:Connect(onCharAdded)