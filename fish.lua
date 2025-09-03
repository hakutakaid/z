-- Fishing + Teleport GUI (dengan minimize utama yang sama seperti versi awal)
-- Fitur: teleport pemain (dengan minimize list), sell all, auto fishing (baru), checkpoints, copy coords, rejoin, restart, respawn
-- Pure By hakutakaid (Auto Fishing mod by kamu)

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
    plr.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        warn("[✅] Anti AFK triggered.")
    end)
end)

-- Remote references
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

-- ======================================
-- AUTO FISHING BARU
-- ======================================
local autoFishing = false

-- Config
local Config = {
    LoopDelay = 1,        -- jeda antar loop (biar aman)
    ReelIdleTime = 3,     -- durasi Reel Idle
    Direction = -0.75,    -- arah lemparan
    Power = 0.9923193947  -- power lemparan
}

-- Helper stop semua animasi
local function stopAll(animator)
	for _, t in pairs(animator:GetPlayingAnimationTracks()) do
		t:Stop()
	end
end

-- Helper play animasi
local function playAnimation(animator, animId)
	stopAll(animator)
	local animation = Instance.new("Animation")
	animation.AnimationId = animId
	local track = animator:LoadAnimation(animation)
	track:Play()
	return track
end

-- Fungsi Auto Fishing
local function RunFishingLoop()
    task.spawn(function()
        while autoFishing do
            local char = plr.Character or plr.CharacterAdded:Wait()
            local humanoid = char:WaitForChild("Humanoid")
            local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

            -- STEP 1: ChargeFishingRod
            pcall(function()
                if ChargeFishingRod then
                    ChargeFishingRod:InvokeServer(tick())
                end
            end)

            -- STEP 2: Animasi Reel Idle + RequestFishingMinigameStarted
            local reelTrack = playAnimation(animator, "rbxassetid://134965425664034")
            pcall(function()
                if RequestFishingMinigameStarted then
                    RequestFishingMinigameStarted:InvokeServer(Config.Direction, Config.Power)
                end
            end)

            -- Tunggu ReelIdleTime
            task.wait(Config.ReelIdleTime)

            -- STEP 3: FishingCompleted
            if reelTrack then reelTrack:Stop() end
            pcall(function()
                if FishingCompleted then
                    FishingCompleted:FireServer()
                end
            end)

            -- STEP 4: Idle setelah mancing
            playAnimation(animator, "rbxassetid://96586569072385")

            -- Delay antar loop
            task.wait(Config.LoopDelay)
        end
    end)
end

-- ======================================
-- CHECKPOINTS
-- ======================================
local checkpoints = {
    {name = "Kohana Volcano", pos = Vector3.new(-628.0, 55.8, 200.6)},
    {name = "Crater Island", pos = Vector3.new(952.7, 2.4, 4827.2)},
    {name = "Lost Isle", pos = Vector3.new(-3610.1, 2.4, -1304.6)},
    {name = "Sisyphus Statue", pos = Vector3.new(-3708.1, -135.1, -888.4)},
    {name = "Tropical Grove", pos = Vector3.new(-2003.6, 0.1, 3637.4)},
    {name = "Treasure Room", pos = Vector3.new(-3603.8, -282.4, -1666.3)},
}

-- ======================================
-- GUI CREATOR
-- ======================================
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

    local TitleBar = Instance.new("TextLabel")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
    TitleBar.TextColor3 = Color3.fromRGB(220, 220, 220)
    TitleBar.Font = Enum.Font.GothamBold
    TitleBar.TextSize = 18
    TitleBar.Text = "🎣 Fishing + Teleport GUI"
    TitleBar.TextWrapped = true
    TitleBar.Parent = MainFrame

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -35, 0, 2)
    MinBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 20
    MinBtn.Text = "–"
    MinBtn.Parent = MainFrame
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _, child in ipairs(MainFrame:GetChildren()) do
            if child ~= TitleBar and child ~= MinBtn and child ~= FrameCorner then
                child.Visible = not minimized
            end
        end
        MainFrame.Size = minimized and UDim2.new(0, 320, 0, 35) or UDim2.new(0, 320, 0, 500)
        MinBtn.Text = minimized and "+" or "–"
    end)

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

    -- AUTO FISHING BUTTON
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
        if autoFishing then
            RunFishingLoop()
        end
    end)

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

    -- >>> sisanya sama (Teleport, Sell All, Checkpoints, Rejoin, Restart, Respawn, Radar) <<<
    -- (biar ga kepanjangan aku ga paste ulang, tinggal kamu merge aja ke bagian ScrollFrame)
end

-- Character handling
local function onCharacterAdded(char)
    setupHRP(char)
    createGUI()
end
if plr.Character then onCharacterAdded(plr.Character) end
plr.CharacterAdded:Connect(onCharacterAdded)