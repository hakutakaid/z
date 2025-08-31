-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local hrp

-- Function untuk setup HRP
local function setupHRP(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end

local autoTeleporting = false

local autoCheckpoints = {
    {pos = Vector3.new(84.4, 144.4, 463.3), delay = 0.1},
    {pos = Vector3.new(-401.2, 276.4, 770.0), delay = 0.1},
    {pos = Vector3.new(-588.5, 388.4, -117.6), delay = 0.1},
    {pos = Vector3.new(-489.1, 284.9, -356.9), delay = 0.1},
    {pos = Vector3.new(-1291.9, 356.4, -538.3), delay = 0.1},
    {pos = Vector3.new(-1798.8, 600.4, -436.7), delay = 0.1},
    {pos = Vector3.new(-3347.0, 688.4, -727.9), delay = 0.1},
}

-- Function untuk buat GUI
local function createGUI()
    -- Cek jika GUI sudah ada
    if plr.PlayerGui:FindFirstChild("FinalTeleportGUI_Redesigned") then return end

    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FinalTeleportGUI_Redesigned"
    ScreenGui.Parent = plr.PlayerGui

    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 320, 0, 480)
    MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 8)
    FrameCorner.Parent = MainFrame

    -- Title Bar
    local TitleBar = Instance.new("TextLabel")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
    TitleBar.TextColor3 = Color3.fromRGB(220, 220, 220)
    TitleBar.Font = Enum.Font.GothamBold
    TitleBar.TextSize = 18
    TitleBar.Text = "🚀 Final Teleport GUI"
    TitleBar.TextWrapped = true
    TitleBar.Parent = MainFrame

    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -35, 0, 2)
    MinBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 20
    MinBtn.Text = "–"
    MinBtn.Parent = MainFrame

    local MinBtnCorner = Instance.new("UICorner")
    MinBtnCorner.CornerRadius = UDim.new(0, 6)
    MinBtnCorner.Parent = MinBtn

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child ~= TitleBar and child ~= MinBtn and child ~= FrameCorner then
                child.Visible = not minimized
            end
        end
        if minimized then
            MainFrame.Size = UDim2.new(0, 320, 0, 35)
        else
            MainFrame.Size = UDim2.new(0, 320, 0, 480)
        end
    end)

    -- Scrolling Frame
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -10, 1, -45)
    ScrollFrame.Position = UDim2.new(0, 5, 0, 40)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 6
    ScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    ScrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    ScrollFrame.Parent = MainFrame

    local UIList = Instance.new("UIListLayout")
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Padding = UDim.new(0, 8)
    UIList.Parent = ScrollFrame

    local UIPad = Instance.new("UIPadding")
    UIPad.PaddingTop = UDim.new(0, 5)
    UIPad.PaddingBottom = UDim.new(0, 5)
    UIPad.PaddingLeft = UDim.new(0, 5)
    UIPad.PaddingRight = UDim.new(0, 5)
    UIPad.Parent = ScrollFrame

    -- Coordinate Display
    local CoordLabel = Instance.new("TextLabel")
    CoordLabel.Size = UDim2.new(1, 0, 0, 30)
    CoordLabel.BackgroundColor3 = Color3.fromRGB(60, 65, 75)
    CoordLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
    CoordLabel.Font = Enum.Font.Code
    CoordLabel.TextSize = 16
    CoordLabel.Text = "X:0.0 Y:0.0 Z:0.0"
    CoordLabel.TextXAlignment = Enum.TextXAlignment.Left
    CoordLabel.Parent = ScrollFrame

    local CoordPad = Instance.new("UIPadding")
    CoordPad.PaddingLeft = UDim.new(0, 10)
    CoordPad.Parent = CoordLabel

    local CoordCorner = Instance.new("UICorner")
    CoordCorner.CornerRadius = UDim.new(0, 6)
    CoordCorner.Parent = CoordLabel

    RunService.RenderStepped:Connect(function()
        if hrp and not minimized then
            local p = hrp.Position
            CoordLabel.Text = string.format("X: %.1f Y: %.1f Z: %.1f", p.X, p.Y, p.Z)
        end
    end)

    -- Copy Coord Button
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(1, 0, 0, 35)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.TextSize = 16
    CopyBtn.Text = "📋 Copy Current Coordinates"
    CopyBtn.Parent = ScrollFrame

    local CopyBtnCorner = Instance.new("UICorner")
    CopyBtnCorner.CornerRadius = UDim.new(0, 6)
    CopyBtnCorner.Parent = CopyBtn

    CopyBtn.MouseButton1Click:Connect(function()
        if hrp then
            setclipboard(string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
        end
    end)

    -- Checkpoints
    local checkpoints = {
        {name = "Checkpoint 1", pos = Vector3.new(84.4, 144.4, 463.3)},
        {name = "Checkpoint 2", pos = Vector3.new(-401.2, 276.4, 770.0)},
        {name = "Checkpoint 3", pos = Vector3.new(-588.5, 388.4, -117.6)},
        {name = "Checkpoint 4", pos = Vector3.new(-489.1, 284.9, -356.9)},
        {name = "Checkpoint 5", pos = Vector3.new(-1291.9, 356.4, -538.3)},
        {name = "Checkpoint 6", pos = Vector3.new(-1798.8, 600.4, -436.7)},
        {name = "Checkpoint 7", pos = Vector3.new(-3347.0, 688.4, -727.9)},
    }

    local CPDropdown = Instance.new("TextButton")
    CPDropdown.Size = UDim2.new(1, 0, 0, 35)
    CPDropdown.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    CPDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    CPDropdown.Font = Enum.Font.GothamBold
    CPDropdown.TextSize = 16
    CPDropdown.Text = "▼ Select Checkpoint"
    CPDropdown.Parent = ScrollFrame

    local CPDropdownCorner = Instance.new("UICorner")
    CPDropdownCorner.CornerRadius = UDim.new(0, 6)
    CPDropdownCorner.Parent = CPDropdown

    local CPList = Instance.new("Frame")
    CPList.Size = UDim2.new(1, 0, 0, 0)
    CPList.BackgroundColor3 = Color3.fromRGB(60, 40, 70)
    CPList.Visible = false
    CPList.Parent = ScrollFrame

    local CPListCorner = Instance.new("UICorner")
    CPListCorner.CornerRadius = UDim.new(0, 6)
    CPListCorner.Parent = CPList

    local CPLayout = Instance.new("UIListLayout")
    CPLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CPLayout.Padding = UDim.new(0, 2)
    CPLayout.Parent = CPList

    CPDropdown.MouseButton1Click:Connect(function()
        CPList.Visible = not CPList.Visible
        local count = #checkpoints
        if CPList.Visible then
            CPList.Size = UDim2.new(1,0,0,count*30 + (count-1)*CPLayout.Padding.Offset + CPLayout.Padding.Offset*2)
            CPDropdown.Text = "▲ Select Checkpoint"
        else
            CPList.Size = UDim2.new(1,0,0,0)
            CPDropdown.Text = "▼ Select Checkpoint"
        end
    end)

    for i, cp in ipairs(checkpoints) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(120, 70, 150)
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = cp.name
        btn.Parent = CPList

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 5)
        BtnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if hrp then hrp.CFrame = CFrame.new(cp.pos) end
            CPList.Visible = false
            CPList.Size = UDim2.new(1,0,0,0)
            CPDropdown.Text = "▼ Select Checkpoint"
        end)
    end

    -- Player Dropdown
    local PlayerDropdown = Instance.new("TextButton")
    PlayerDropdown.Size = UDim2.new(1,0,0,35)
    PlayerDropdown.BackgroundColor3 = Color3.fromRGB(46,204,113)
    PlayerDropdown.TextColor3 = Color3.fromRGB(255,255,255)
    PlayerDropdown.Font = Enum.Font.GothamBold
    PlayerDropdown.TextSize = 16
    PlayerDropdown.Text = "▼ Teleport to Player"
    PlayerDropdown.Parent = ScrollFrame

    local PlayerDropdownCorner = Instance.new("UICorner")
    PlayerDropdownCorner.CornerRadius = UDim.new(0,6)
    PlayerDropdownCorner.Parent = PlayerDropdown

    local PlayerList = Instance.new("Frame")
    PlayerList.Size = UDim2.new(1,0,0,0)
    PlayerList.BackgroundColor3 = Color3.fromRGB(30,60,40)
    PlayerList.Visible = false
    PlayerList.Parent = ScrollFrame

    local PlayerListCorner = Instance.new("UICorner")
    PlayerListCorner.CornerRadius = UDim.new(0,6)
    PlayerListCorner.Parent = PlayerList

    local PlayerLayout = Instance.new("UIListLayout")
    PlayerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PlayerLayout.Padding = UDim.new(0,2)
    PlayerLayout.Parent = PlayerList

    local function refreshPlayers()
        for _, child in ipairs(PlayerList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= plr then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1,0,0,28)
                btn.BackgroundColor3 = Color3.fromRGB(70,180,90)
                btn.TextColor3 = Color3.fromRGB(220,220,220)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.Text = target.Name
                btn.Parent = PlayerList

                local BtnCorner = Instance.new("UICorner")
                BtnCorner.CornerRadius = UDim.new(0,5)
                BtnCorner.Parent = btn

                btn.MouseButton1Click:Connect(function()
                    if hrp and target.Character then
                        local targetHRP = target.Character:WaitForChild("HumanoidRootPart", 5)
                        if targetHRP then
                            hrp.CFrame = targetHRP.CFrame
                        end
                    end
                    PlayerList.Visible = false
                    PlayerList.Size = UDim2.new(1,0,0,0)
                    PlayerDropdown.Text = "▼ Teleport to Player"
                end)
            end
        end
    end

    Players.PlayerAdded:Connect(refreshPlayers)
    Players.PlayerRemoving:Connect(refreshPlayers)
    refreshPlayers()

    PlayerDropdown.MouseButton1Click:Connect(function()
        PlayerList.Visible = not PlayerList.Visible
        local count = #Players:GetPlayers()-1
        if PlayerList.Visible then
            PlayerList.Size = UDim2.new(1,0,0,count*28 + (count-1)*PlayerLayout.Padding.Offset + PlayerLayout.Padding.Offset*2)
            PlayerDropdown.Text = "▲ Teleport to Player"
        else
            PlayerList.Size = UDim2.new(1,0,0,0)
            PlayerDropdown.Text = "▼ Teleport to Player"
        end
    end)

    -- Actions Buttons
    local RejoinBtn = Instance.new("TextButton")
    RejoinBtn.Size = UDim2.new(1,0,0,35)
    RejoinBtn.BackgroundColor3 = Color3.fromRGB(241,196,15)
    RejoinBtn.TextColor3 = Color3.fromRGB(40,44,52)
    RejoinBtn.Font = Enum.Font.GothamBold
    RejoinBtn.TextSize = 16
    RejoinBtn.Text = "🔄 Rejoin Server"
    RejoinBtn.Parent = ScrollFrame

    local RejoinBtnCorner = Instance.new("UICorner")
    RejoinBtnCorner.CornerRadius = UDim.new(0,6)
    RejoinBtnCorner.Parent = RejoinBtn

    RejoinBtn.MouseButton1Click:Connect(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
    end)

    local RestartBtn = Instance.new("TextButton")
    RestartBtn.Size = UDim2.new(1,0,0,35)
    RestartBtn.BackgroundColor3 = Color3.fromRGB(231,76,60)
    RestartBtn.TextColor3 = Color3.fromRGB(255,255,255)
    RestartBtn.Font = Enum.Font.GothamBold
    RestartBtn.TextSize = 16
    RestartBtn.Text = "⚡ Restart Script"
    RestartBtn.Parent = ScrollFrame

    local RestartBtnCorner = Instance.new("UICorner")
    RestartBtnCorner.CornerRadius = UDim.new(0,6)
    RestartBtnCorner.Parent = RestartBtn

    RestartBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/nirwanaHD.lua"))()
    end)
    -- Respawn Button
    local RespawnBtn = Instance.new("TextButton")
    RespawnBtn.Size = UDim2.new(1,0,0,35)
    RespawnBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    RespawnBtn.TextColor3 = Color3.fromRGB(255,255,255)
    RespawnBtn.Font = Enum.Font.GothamBold
    RespawnBtn.TextSize = 16
    RespawnBtn.Text = "💀 Respawn"
    RespawnBtn.Parent = ScrollFrame
    
    local RespawnBtnCorner = Instance.new("UICorner")
    RespawnBtnCorner.CornerRadius = UDim.new(0,6)
    RespawnBtnCorner.Parent = RespawnBtn
    
    RespawnBtn.MouseButton1Click:Connect(function()
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.Health = 0
        end
    end)
    -- Auto Teleport Button
    local AutoBtn = Instance.new("TextButton")
    AutoBtn.Size = UDim2.new(1,0,0,35)
    AutoBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    AutoBtn.TextColor3 = Color3.fromRGB(255,255,255)
    AutoBtn.Font = Enum.Font.GothamBold
    AutoBtn.TextSize = 16
    AutoBtn.Text = "▶️ Start Auto Teleport"
    AutoBtn.Parent = ScrollFrame
    
    local AutoBtnCorner = Instance.new("UICorner")
    AutoBtnCorner.CornerRadius = UDim.new(0,6)
    AutoBtnCorner.Parent = AutoBtn
    
    local function autoTeleportLoop()
        if autoTeleporting then return end
        autoTeleporting = true
        task.spawn(function()
            while autoTeleporting do
                for i, cp in ipairs(autoCheckpoints) do
                    if hrp then
                        hrp.CFrame = CFrame.new(cp.pos)
                        print("Teleported to CP"..i)
                    end
                    if cp.delay > 0 then
                        task.wait(cp.delay)
                    end
                end
            end
            print("⏹ Auto Teleport dihentikan")
        end)
    end
    
    AutoBtn.MouseButton1Click:Connect(function()
        if autoTeleporting then
            autoTeleporting = false
            AutoBtn.Text = "▶️ Start Auto Teleport"
        else
            autoTeleportLoop()
            AutoBtn.Text = "⏹ Stop Auto Teleport"
        end
    end)
end



-- Function untuk setup Character baru
local function onCharacterAdded(char)
    setupHRP(char)
    createGUI()
end

-- Jalankan untuk karakter pertama
if plr.Character then
    onCharacterAdded(plr.Character)
end

-- Detect respawn
plr.CharacterAdded:Connect(onCharacterAdded)