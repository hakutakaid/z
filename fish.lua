-- ======================================
-- Fishing + Location GUI (WindUI Refactor)
-- Features: Auto Fishing, Auto Trade, Radar, Sell All, Teleport Location, Teleport Player, Copy Position
-- Pure by hakutakaid (Refactor WindUI by ChatGPT)
-- ======================================

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services
local Players = game:GetService("Players")
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
local netRoot
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
local AwaitTradeResponse = safeFind("RF/AwaitTradeResponse")

-- ======================================
-- AUTO FISHING
-- ======================================
local autoFishing = false
local Config = {
    LoopDelay = 0.8,
    ReelIdleTime = 2.5,
    Direction = -0.75,
    Power = 0.50
}

local function stopAll(animator)
	for _, t in pairs(animator:GetPlayingAnimationTracks()) do
		t:Stop()
	end
end

local function playAnimation(animator, animId)
	stopAll(animator)
	local animation = Instance.new("Animation")
	animation.AnimationId = animId
	local track = animator:LoadAnimation(animation)
	track:Play()
	return track
end

local function RunFishingLoop()
    task.spawn(function()
        while autoFishing do
            local char = plr.Character or plr.CharacterAdded:Wait()
            local humanoid = char:WaitForChild("Humanoid")
            local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

            pcall(function()
                if ChargeFishingRod then
                    ChargeFishingRod:InvokeServer(tick())
                end
            end)

            local reelTrack = playAnimation(animator, "rbxassetid://134965425664034")
            pcall(function()
                if RequestFishingMinigameStarted then
                    RequestFishingMinigameStarted:InvokeServer(Config.Direction, Config.Power)
                end
            end)

            task.wait(Config.ReelIdleTime)

            if reelTrack then reelTrack:Stop() end
            pcall(function()
                if FishingCompleted then
                    FishingCompleted:FireServer()
                end
            end)

            playAnimation(animator, "rbxassetid://96586569072385")

            task.wait(Config.LoopDelay)
        end
    end)
end

-- ======================================
-- AUTO TRADE
-- ======================================
local autoAcceptTrade = false
if AwaitTradeResponse then
    AwaitTradeResponse.OnClientInvoke = function(fromPlayer, timeNow)
        if autoAcceptTrade then
            print("[🤝] Auto accepted trade from:", fromPlayer and fromPlayer.Name or "Unknown")
            return true
        end
        return nil
    end
end

-- ======================================
-- CHECKPOINTS
-- ======================================
local checkpoints = {
    ["Kohana Volcano"]  = CFrame.new(-628.0, 55.8, 200.6),
    ["Crater Island"]   = CFrame.new(952.7, 2.4, 4827.2),
    ["Lost Isle"]       = CFrame.new(-3610.1, 2.4, -1304.6),
    ["Sisyphus Statue"] = CFrame.new(-3788.9, -135.0, -950.0),
    ["Tropical Grove"]  = CFrame.new(-2003.6, 0.1, 3637.4),
    ["Treasure Room"]   = CFrame.new(-3603.8, -282.4, -1666.3),
    ["Esoteric Depths"] = CFrame.new(3256.1, -1300.6, 1392.1),
    ["Weater Machine"] = CFrame.new(-1442, -3, 1926),
    ["Coral Reefs"] = CFrame.new(-2725, 2, 2200),
    ["Snow Sea"] = CFrame.new(2237, 3, 2909),
    ["SPOT Esoteric Depths"] = CFrame.new(3215, -1291, 1286),
    ["SPOT Tropical Grove"] = CFrame.new(-2055, 9, 3775),
}

-- ======================================
-- WINDUI GUI
-- ======================================
local Window = WindUI:CreateWindow({
    Title = "🎣 Fishing GUI",
    Icon = "fish",
    Author = "hakutakaid",
    Folder = "FishingOnly",
    Size = UDim2.fromOffset(480, 340)
})

-- Tab utama
local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
local MainSection = MainTab:Section({ Title = "Fishing Features" })

-- Auto Fishing
MainSection:Toggle({
    Title = "Auto Fishing",
    Icon = "mouse-pointer-2",
    Default = false,
    Callback = function(state)
        autoFishing = state
        if state then RunFishingLoop() end
    end
})

-- Auto Trade
MainSection:Toggle({
    Title = "Auto Accept Trade",
    Default = false,
    Callback = function(state)
        autoAcceptTrade = state
    end
})

-- Radar
MainSection:Toggle({
    Title = "Fishing Radar",
    Default = false,
    Callback = function(state)
        local radarRemote = safeFind("RF/UpdateFishingRadar")
        if radarRemote then
            radarRemote:InvokeServer(state)
        end
    end
})

-- Sell All
MainSection:Button({
    Title = "💰 Sell All Items",
    Callback = function()
        if SellAllItems then
            SellAllItems:InvokeServer()
            print("[💰] Semua item dijual!")
        else
            warn("SellAllItems remote tidak ditemukan.")
        end
    end
})

-- ======================================
-- LOCATION TAB
-- ======================================
local LocationTab = Window:Tab({ Title = "Location", Icon = "map" })
local LocSection = LocationTab:Section({ Title = "Location" })

-- Tombol Checkpoints
for name, cf in pairs(checkpoints) do
    LocSection:Button({
        Title = "📍 " .. name,
        Callback = function()
            if hrp then hrp.CFrame = cf end
        end
    })
end

-- =========================
-- Tombol Copy Position di bawah Teleport Player
-- =========================
local CopyPosSection = LocationTab:Section({ Title = "Other Actions" })

CopyPosSection:Button({
    Title = "📋 Copy Position",
    Callback = function()
        local char = plr.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart"))
        if not root then
            warn("[⚠️] Character or root part not found.")
            return
        end

        local pos = root.Position
        local roundedPos = math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)

        if setclipboard then
            setclipboard(roundedPos)
            print("[📋] Position copied to clipboard:", roundedPos)
        else
            print("[📋] Position:", roundedPos)
        end
    end
})

-- TELEPORT PLAYER
local PlayerSection = LocationTab:Section({ Title = "Teleport Player" })
local playerButtons = {}

local function refreshPlayerList()
    for _, btn in ipairs(playerButtons) do
        btn:Destroy()
    end
    table.clear(playerButtons)

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= plr then
            local btn = PlayerSection:Button({
                Title = "➡️ " .. target.Name,
                Callback = function()
                    if hrp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        hrp.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2, 0)
                    end
                end
            })
            table.insert(playerButtons, btn)
        end
    end
end

PlayerSection:Button({
    Title = "🔄 Refresh Player List",
    Callback = refreshPlayerList
})
refreshPlayerList()

-- Character handling
local function onCharacterAdded(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end
if plr.Character then onCharacterAdded(plr.Character) end
plr.CharacterAdded:Connect(onCharacterAdded)