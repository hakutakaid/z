-- Fishing + Teleport GUI (dengan minimize utama yang sama seperti versi awal)
-- Fitur: teleport pemain (dengan minimize list), sell all, auto fishing (on/off), checkpoints, copy coords, rejoin, restart, respawn
-- Pure By hakutakaid

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local hrp

-- Anti AFK
pcall(function()
    local vu = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        warn("[✅] Anti AFK triggered.")
    end)
end)

-- Remote references (cek aman)
local netRoot = nil
pcall(function()
    local idx = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("_Index")
    if idx then
        local pack = idx:FindFirstChild("sleitnick_net@0.2.0")
        if pack then
            netRoot = pack:FindFirstChild("net")
        end
    end
end)

local function safeFind(name)
    if not netRoot then return nil end
    -- can be RF/... or RE/...; use FindFirstChild for exact name
    return netRoot:FindFirstChild(name)
end

local ChargeFishingRod = safeFind("RF/ChargeFishingRod")
local RequestFishingMinigameStarted = safeFind("RF/RequestFishingMinigameStarted")
local FishingCompleted = safeFind("RE/FishingCompleted")
local SellAllItems = safeFind("RF/SellAllItems")

-- HRP setup
local function setupHRP(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end

-- Auto Fishing Flag
local autoFishing = false

-- Fungsi mancing sekali (cek remote exist)
local function FishOnce()
    pcall(function()
        if ChargeFishingRod then
            ChargeFishingRod:InvokeServer(1755155355.562756)
        end
    end)
    task.wait(0.9)
    pcall(function()
        if RequestFishingMinigameStarted then
            RequestFishingMinigameStarted:InvokeServer(-1.2379989624023438, 0.9786020416845042)
        end
    end)
    task.wait(1.7)
    pcall(function()
        if FishingCompleted then
            FishingCompleted:FireServer()
        end
    end)
end

-- Loop Auto Fishing
task.spawn(function()
    while task.wait(0.5) do
        if autoFishing then
            FishOnce()
            -- print singkat supaya console gak kebanjiran
            -- print("[🎣] Auto Fishing: tick")
        end
    end
end)

-- Checkpoints list (sama seperti mentahanmu)
local checkpoints = {
    {name = "Kohana Volcano", pos = Vector3.new(-628.0, 55.8, 200.6)},
    {name = "Crater Island", pos = Vector3.new(952.7, 2.4, 4827.2)},
    {name = "Lost Isle", pos = Vector3.new(-3610.1, 2.4, -1304.6)},
    {name = "Sisyphus Statue", pos = Vector3.new(-3708.1, -135.1, -888.4)},
    {name = "Tropical Grove", pos = Vector3.new(-2003.6, 0.1, 3637.4)},
    {name = "Treasure Room", pos = Vector3.new(-3603.8, -282.4, -1666.3)},
}

-- Fungsi respawn (force)
local function forceRespawn(callback)
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        plr.Character:BreakJoints()
        plr.CharacterAdded:Wait()
        setupHRP(plr.Character)
        if callback then callback() end
    end
end

-- GUI creator
local function createGUI()
    if plr.PlayerGui:FindFirstChild("FishingTeleportGUI") then return end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FishingTeleportGUI"
    ScreenGui.Parent = plr.PlayerGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 320, 0, 500)
    MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 8)
    FrameCorner.Parent = MainFrame

    -- Title (TextLabel) — ini sesuai versi awal sehingga minimize utama bekerja
    local TitleBar = Instance.new("TextLabel")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
    TitleBar.TextColor3 = Color3.fromRGB(220, 220, 220)
    TitleBar.Font = Enum.Font.GothamBold
    TitleBar.TextSize = 18
    TitleBar.Text = "🎣 Fishing + Teleport GUI"
    TitleBar.TextWrapped = true
    TitleBar.Parent = MainFrame

    -- Minimize Button (Main) — sibling dari TitleBar (seperti versi awal)
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

    -- Minimize behavior (pakai style awal: sembunyikan semua child selain TitleBar, MinBtn, FrameCorner)
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
            MainFrame.Size = UDim2.new(0, 320, 0, 500)
        end
        MinBtn.Text = minimized and "+" or "–"
    end)

    -- Scrolling area
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
        if hrp and setclipboard then
            setclipboard(string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
            print("[📋] Coordinates copied.")
        end
    end)

    -- Checkpoints dropdown (ringkas)
    local CPDropdown = Instance.new("TextButton")
    CPDropdown.Size = UDim2.new(1, 0, 0, 35)
    CPDropdown.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    CPDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    CPDropdown.Font = Enum.Font.GothamBold
    CPDropdown.TextSize = 16
    CPDropdown.Text = "▼ Select Place"
    CPDropdown.Parent = ScrollFrame
    Instance.new("UICorner", CPDropdown).CornerRadius = UDim.new(0,6)

    local CPList = Instance.new("Frame")
    CPList.Size = UDim2.new(1, 0, 0, 0)
    CPList.BackgroundColor3 = Color3.fromRGB(60, 40, 70)
    CPList.Visible = false
    CPList.Parent = ScrollFrame
    Instance.new("UICorner", CPList).CornerRadius = UDim.new(0,6)

    local CPLayout = Instance.new("UIListLayout")
    CPLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CPLayout.Padding = UDim.new(0, 2)
    CPLayout.Parent = CPList

    CPDropdown.MouseButton1Click:Connect(function()
        CPList.Visible = not CPList.Visible
        local count = #checkpoints
        if CPList.Visible then
            CPList.Size = UDim2.new(1,0,0,count*30 + 10)
            CPDropdown.Text = "▲ Select Place"
        else
            CPList.Size = UDim2.new(1,0,0,0)
            CPDropdown.Text = "▼ Select Place"
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
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

        btn.MouseButton1Click:Connect(function()
            if hrp then hrp.CFrame = CFrame.new(cp.pos) end
            CPList.Visible = false
            CPList.Size = UDim2.new(1,0,0,0)
            CPDropdown.Text = "▼ Select Checkpoint"
        end)
    end

    -- Sell All Button
    local SellBtn = Instance.new("TextButton")
    SellBtn.Size = UDim2.new(1,0,0,35)
    SellBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
    SellBtn.TextColor3 = Color3.fromRGB(255,255,255)
    SellBtn.Font = Enum.Font.GothamBold
    SellBtn.TextSize = 16
    SellBtn.Text = "💰 Sell All Items"
    SellBtn.Parent = ScrollFrame
    Instance.new("UICorner", SellBtn).CornerRadius = UDim.new(0,6)

    SellBtn.MouseButton1Click:Connect(function()
        local ok, err = pcall(function()
            if SellAllItems then
                SellAllItems:InvokeServer()
                print("[💰] Semua item dijual!")
            else
                warn("[💰] Remote SellAllItems tidak ditemukan.")
            end
        end)
        if not ok then warn("Error SellAll: "..tostring(err)) end
    end)

    -- Auto Fishing Toggle
    local AutoFishBtn = Instance.new("TextButton")
    AutoFishBtn.Size = UDim2.new(1,0,0,35)
    AutoFishBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    AutoFishBtn.TextColor3 = Color3.fromRGB(255,255,255)
    AutoFishBtn.Font = Enum.Font.GothamBold
    AutoFishBtn.TextSize = 16
    AutoFishBtn.Text = "▶️ Start Auto Fishing"
    AutoFishBtn.Parent = ScrollFrame
    Instance.new("UICorner", AutoFishBtn).CornerRadius = UDim.new(0,6)

    AutoFishBtn.MouseButton1Click:Connect(function()
        autoFishing = not autoFishing
        AutoFishBtn.Text = autoFishing and "⏸ Stop Auto Fishing" or "▶️ Start Auto Fishing"
        print("[🎣] Auto Fishing:", autoFishing and "ON" or "OFF")
    end)

    -- Teleport header with its own minimize button
    local TeleportFrame = Instance.new("Frame")
    TeleportFrame.Size = UDim2.new(1,0,0,35)
    TeleportFrame.BackgroundColor3 = Color3.fromRGB(70,70,80)
    TeleportFrame.Parent = ScrollFrame
    Instance.new("UICorner", TeleportFrame).CornerRadius = UDim.new(0,6)

    local TeleportLabel = Instance.new("TextLabel")
    TeleportLabel.Size = UDim2.new(1,-40,1,0)
    TeleportLabel.Position = UDim2.new(0,10,0,0)
    TeleportLabel.BackgroundTransparency = 1
    TeleportLabel.Text = "👥 Teleport Player"
    TeleportLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TeleportLabel.Font = Enum.Font.GothamBold
    TeleportLabel.TextSize = 16
    TeleportLabel.TextXAlignment = Enum.TextXAlignment.Left
    TeleportLabel.Parent = TeleportFrame

    local TPMinBtn = Instance.new("TextButton")
    TPMinBtn.Size = UDim2.new(0,30,0,30)
    TPMinBtn.Position = UDim2.new(1,-35,0,2)
    TPMinBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    TPMinBtn.Text = "-"
    TPMinBtn.TextColor3 = Color3.fromRGB(255,255,255)
    TPMinBtn.Font = Enum.Font.GothamBold
    TPMinBtn.TextSize = 20
    TPMinBtn.Parent = TeleportFrame
    Instance.new("UICorner", TPMinBtn).CornerRadius = UDim.new(0,6)

    local PlayerList = Instance.new("Frame")
    PlayerList.Size = UDim2.new(1,0,0,0)
    PlayerList.BackgroundColor3 = Color3.fromRGB(30,60,40)
    PlayerList.Visible = true
    PlayerList.Parent = ScrollFrame
    Instance.new("UICorner", PlayerList).CornerRadius = UDim.new(0,6)

    local PlayerLayout = Instance.new("UIListLayout")
    PlayerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PlayerLayout.Padding = UDim.new(0,2)
    PlayerLayout.Parent = PlayerList

    -- refresh player list (buat tombol teleport per player)
    local function refreshPlayers()
        for _, child in ipairs(PlayerList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= plr then
                local btn = Instance.new("TextButton")
                btn.Name = "TP_"..target.UserId
                btn.Size = UDim2.new(1,0,0,30)
                btn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                btn.TextColor3 = Color3.fromRGB(255,255,255)
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.Text = "➡️ "..target.Name
                btn.Parent = PlayerList
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

                btn.MouseButton1Click:Connect(function()
                    if hrp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        hrp.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0,2,0)
                        print("[🚀] Teleported to "..target.Name)
                    else
                        warn("Target tidak tersedia.")
                    end
                end)
            end
        end
        -- set PlayerList size based on children
        local count = #Players:GetPlayers()-1
        if count < 0 then count = 0 end
        PlayerList.Size = UDim2.new(1,0,0, math.max(0, count*30 + 10))
    end

    TPMinBtn.MouseButton1Click:Connect(function()
        PlayerList.Visible = not PlayerList.Visible
        TPMinBtn.Text = PlayerList.Visible and "-" or "+"
    end)

    refreshPlayers()
    Players.PlayerAdded:Connect(refreshPlayers)
    Players.PlayerRemoving:Connect(refreshPlayers)

    -- Utility buttons: Rejoin, Restart, Respawn
    local RejoinBtn = Instance.new("TextButton")
    RejoinBtn.Size = UDim2.new(1,0,0,35)
    RejoinBtn.BackgroundColor3 = Color3.fromRGB(241,196,15)
    RejoinBtn.TextColor3 = Color3.fromRGB(40,44,52)
    RejoinBtn.Font = Enum.Font.GothamBold
    RejoinBtn.TextSize = 16
    RejoinBtn.Text = "🔄 Rejoin Server"
    RejoinBtn.Parent = ScrollFrame
    Instance.new("UICorner", RejoinBtn).CornerRadius = UDim.new(0,6)

    RejoinBtn.MouseButton1Click:Connect(function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
        end)
    end)

    local RestartBtn = Instance.new("TextButton")
    RestartBtn.Size = UDim2.new(1,0,0,35)
    RestartBtn.BackgroundColor3 = Color3.fromRGB(231,76,60)
    RestartBtn.TextColor3 = Color3.fromRGB(255,255,255)
    RestartBtn.Font = Enum.Font.GothamBold
    RestartBtn.TextSize = 16
    RestartBtn.Text = "⚡ Restart Script"
    RestartBtn.Parent = ScrollFrame
    Instance.new("UICorner", RestartBtn).CornerRadius = UDim.new(0,6)

    RestartBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        -- ganti link sesuai kebutuhan kalau mau load script lain
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/fishit.lua"))()
    end)

    local RespawnBtn = Instance.new("TextButton")
    RespawnBtn.Size = UDim2.new(1,0,0,35)
    RespawnBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    RespawnBtn.TextColor3 = Color3.fromRGB(255,255,255)
    RespawnBtn.Font = Enum.Font.GothamBold
    RespawnBtn.TextSize = 16
    RespawnBtn.Text = "💀 Respawn"
    RespawnBtn.Parent = ScrollFrame
    Instance.new("UICorner", RespawnBtn).CornerRadius = UDim.new(0,6)

    RespawnBtn.MouseButton1Click:Connect(function()
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.Health = 0
        end
    end)
    -- Radar Toggle Button
    local RadarBtn = Instance.new("TextButton")
    RadarBtn.Size = UDim2.new(1,0,0,35)
    RadarBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    RadarBtn.TextColor3 = Color3.fromRGB(255,255,255)
    RadarBtn.Font = Enum.Font.GothamBold
    RadarBtn.TextSize = 16
    RadarBtn.Text = "👁️ Turn Radar ON"
    RadarBtn.Parent = ScrollFrame
    Instance.new("UICorner", RadarBtn).CornerRadius = UDim.new(0,6)
    
    local radarOn = false
    RadarBtn.MouseButton1Click:Connect(function()
        radarOn = not radarOn
        RadarBtn.Text = radarOn and "👁️ Turn Radar OFF" or "👁️ Turn Radar ON"
        -- Panggil remote sesuai toggle
        pcall(function()
            local radarRemote = safeFind("RF/UpdateFishingRadar")
            if radarRemote then
                radarRemote:InvokeServer(radarOn)
                print("[👁️] Radar", radarOn and "ON" or "OFF")
            else
                warn("Radar remote tidak ditemukan.")
            end
        end)
    end)
end

-- Character handling
local function onCharacterAdded(char)
    setupHRP(char)
    createGUI()
end

if plr.Character then
    onCharacterAdded(plr.Character)
end

plr.CharacterAdded:Connect(onCharacterAdded)