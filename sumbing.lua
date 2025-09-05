-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Buat window
local Window = WindUI:CreateWindow({
    Title = "Mount Sumbing",
    Icon = "door-open",
    Author = "HakutakaID",
    Folder = "ScriptHub",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    ScrollBarEnabled = true
})

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

-- Helpers
local function getRoot(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function breakVelocity(char)
    local BeenASecond = false
    task.delay(1, function() BeenASecond = true end)
    while not BeenASecond do
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Velocity, v.RotVelocity = Vector3.zero, Vector3.zero
            end
        end
        task.wait()
    end
end

local function tweenTeleport(x, y, z)
    local char = LocalPlayer.Character
    if not char then return end
    local root = getRoot(char)
    if not root then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        humanoid.Sit = false
        task.wait(0.1)
    end

    TweenService:Create(
        root,
        TweenInfo.new(2, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(x, y, z) }
    ):Play()

    breakVelocity(char)
end

local function tweenToPlayer(target)
    if not target.Character or not getRoot(target.Character) then return end
    local myChar = LocalPlayer.Character
    if not myChar or not getRoot(myChar) then return end

    local humanoid = myChar:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        humanoid.Sit = false
        task.wait(0.1)
    end

    TweenService:Create(
        getRoot(myChar),
        TweenInfo.new(1.5, Enum.EasingStyle.Linear),
        { CFrame = getRoot(target.Character).CFrame + Vector3.new(3, 1, 0) }
    ):Play()

    breakVelocity(myChar)
end

-- =========================
-- Tab Shop
-- =========================
local ShopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })
local ShopSection = ShopTab:Section({ Title = "Purchase Items", TextXAlignment = "Left", TextSize = 17 })

-- Fungsi checkout item tunggal
local function checkoutItem(name, price)
    local args = {
        [1] = {
            [1] = { ["Name"] = name, ["Price"] = price }
        }
    }
    game:GetService("ReplicatedStorage").Checkout:InvokeServer(unpack(args))
end

-- Tombol di Shop
ShopSection:Button({ Title = "Buy Medkit ($20000)", Callback = function() checkoutItem("Medkit", 20000) end })
ShopSection:Button({ Title = "Buy Magic Water ($8000)", Callback = function() checkoutItem("Magic Water", 8000) end })
ShopSection:Button({ Title = "Buy Tree Branch ($2500)", Callback = function() checkoutItem("Tree Branch", 2500) end })
ShopSection:Button({ Title = "Buy Machete ($65000)", Callback = function() checkoutItem("Machete", 65000) end })
ShopSection:Button({ Title = "Buy Umbrella ($45000)", Callback = function() checkoutItem("Umbrella", 45000) end })
ShopSection:Button({ Title = "Buy STMJ ($12000)", Callback = function() checkoutItem("STMJ", 12000) end })
ShopSection:Button({ Title = "Buy Lighter ($3500)", Callback = function() checkoutItem("Lighter", 3500) end })

-- =========================
-- Tab Teleport
-- =========================
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

-- === Saved Positions ===
local TeleportSection = TeleportTab:Section({ Title = "Saved Positions", TextXAlignment = "Left", TextSize = 17 })

TeleportSection:Button({ Title = "Teleport Pos1", Callback = function() tweenTeleport(-226, 441, 2142) end })
TeleportSection:Button({ Title = "Teleport Pos2", Callback = function() tweenTeleport(-428, 849, 3204) end })
TeleportSection:Button({ Title = "Teleport Pos3", Callback = function() tweenTeleport(42, 1269, 4044) end })
TeleportSection:Button({ Title = "Teleport Pos4", Callback = function() tweenTeleport(-1142, 1553, 4900) end })
TeleportSection:Button({ Title = "Teleport Pos5", Callback = function() tweenTeleport(-877, 1954, 5357) end })

-- === Teleport Player ===
local PlayerSection = TeleportTab:Section({ Title = "Teleport Player", TextXAlignment = "Left", TextSize = 17 })
local playerButtons = {}

local function refreshPlayerList()
    for _, btn in ipairs(playerButtons) do
        btn:Destroy()
    end
    table.clear(playerButtons)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = PlayerSection:Button({
                Title = plr.Name,
                Callback = function() tweenToPlayer(plr) end
            })
            table.insert(playerButtons, btn)
        end
    end
end

-- Tambah tombol manual refresh
PlayerSection:Button({
    Title = "🔄 Refresh Player List",
    Callback = function()
        refreshPlayerList()
    end
})

-- Load pertama kali
refreshPlayerList()

-- === Auto Teleport (perbaikan: pakai TeleportTab:Slider atau fallback) ===
local AutoSection = TeleportTab:Section({ Title = "Auto Teleport", TextXAlignment = "Left", TextSize = 17 })

local AutoTeleportEnabled = false
local AutoTeleportTask = nil

local minDelay, maxDelay = 1, 20
local teleportDelay = 3 -- default detik

local positions = {
    CFrame.new(-226, 441, 2142),   -- Pos1
    CFrame.new(-428, 849, 3204),   -- Pos2
    CFrame.new(42, 1269, 4044),    -- Pos3
    CFrame.new(-1142, 1553, 4900), -- Pos4
    CFrame.new(-877, 1954, 5357)   -- Pos5
}

-- safe parser
local function clampNum(n)
    if type(n) == "number" then return math.clamp(n, minDelay, maxDelay) end
    if type(n) == "string" then local v = tonumber(n) if v then return math.clamp(v, minDelay, maxDelay) end end
    return nil
end

-- attempt create slider according to docs (Tab:Slider)
local sliderObj = nil
local ok, ret = pcall(function()
    return TeleportTab:Slider({
        Title = "Delay (detik)",
        Step = 1,
        Value = {
            Min = minDelay,
            Max = maxDelay,
            Default = teleportDelay
        },
        Callback = function(val)
            local v = clampNum(val)
            if v then teleportDelay = v end
        end
    })
end)

if ok and ret then
    sliderObj = ret
else
    -- fallback: buat display + +/- buttons (lebih aman kalau slider library bugg)
    warn("Slider unavailable or caused error, using +/- fallback. (", tostring(ret), ")")
    local displayBtn = AutoSection:Button({ Title = "Delay: " .. tostring(teleportDelay) .. "s", Callback = function() end })

    AutoSection:Button({
        Title = "Delay -",
        Callback = function()
            teleportDelay = math.max(minDelay, teleportDelay - 1)
            if displayBtn and displayBtn.SetTitle then displayBtn:SetTitle("Delay: " .. tostring(teleportDelay) .. "s") end
            if sliderObj and sliderObj.Set then pcall(function() sliderObj:Set(teleportDelay) end) end
        end
    })
    AutoSection:Button({
        Title = "Delay +",
        Callback = function()
            teleportDelay = math.min(maxDelay, teleportDelay + 1)
            if displayBtn and displayBtn.SetTitle then displayBtn:SetTitle("Delay: " .. tostring(teleportDelay) .. "s") end
            if sliderObj and sliderObj.Set then pcall(function() sliderObj:Set(teleportDelay) end) end
        end
    })
end

-- auto teleport loop (menunggu tween.Completed, bisa stop cepat)
local function autoTeleportLoop()
    local index = 1
    while AutoTeleportEnabled do
        local pos = positions[index]
        local char = LocalPlayer.Character
        local root = getRoot(char)

        if (not char) or (not root) then
            local okc, newChar = pcall(function() return LocalPlayer.CharacterAdded:Wait(5) end)
            char = okc and newChar or char
            root = getRoot(char)
            if not root then task.wait(0.5) end
        end

        if char and root then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.SeatPart then
                humanoid.Sit = false
                task.wait(0.1)
            end

            local tween = TweenService:Create(root, TweenInfo.new(2, Enum.EasingStyle.Linear), { CFrame = pos })
            tween:Play()

            local finished = false
            local conn = tween.Completed:Connect(function() finished = true end)

            while not finished and AutoTeleportEnabled do
                task.wait(0.1)
            end

            if conn then conn:Disconnect() end
            breakVelocity(char)

            if not AutoTeleportEnabled then break end

            local elapsed = 0
            while elapsed < teleportDelay and AutoTeleportEnabled do
                task.wait(0.1)
                elapsed = elapsed + 0.1
            end
        end

        index = index + 1
        if index > #positions then index = 1 end
    end
    AutoTeleportTask = nil
end

AutoSection:Toggle({
    Title = "Auto Teleport (Pos1 → Pos5)",
    Default = false,
    Callback = function(value)
        if value then
            if AutoTeleportTask then return end
            AutoTeleportEnabled = true
            AutoTeleportTask = task.spawn(autoTeleportLoop)
        else
            AutoTeleportEnabled = false
        end
    end
})

-- =========================
-- Tab Misc
-- =========================
local MiscTab = Window:Tab({ Title = "Misc", Icon = "refresh-cw" })
local MiscSection = MiscTab:Section({ Title = "Misc Actions", TextXAlignment = "Left", TextSize = 17 })

MiscSection:Button({ Title = "Reset Character", Callback = function() game:GetService("ReplicatedStorage").ResetCharacter:FireServer(true) end })
MiscSection:Button({ Title = "Respawn", Callback = function() game:GetService("ReplicatedStorage").ResetCharacter:FireServer(true) end })

-- =========================
-- Anti-Lag Toggle
-- =========================
local AntiLagEnabled = false
local AntiLagConnection

local function enableAntiLag()
    if AntiLagEnabled then return end
    AntiLagEnabled = true

    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 1
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.FogStart = 9e9
    settings().Rendering.QualityLevel = 1

    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        elseif v:IsA("Decal") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Lifetime = NumberRange.new(0)
        end
    end

    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("PostEffect") then
            v.Enabled = false
        end
    end

    AntiLagConnection = workspace.DescendantAdded:Connect(function(child)
        task.spawn(function()
            if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
                RunService.Heartbeat:Wait()
                child:Destroy()
            end
        end)
    end)
end

local function disableAntiLag()
    if not AntiLagEnabled then return end
    AntiLagEnabled = false
    if AntiLagConnection then
        AntiLagConnection:Disconnect()
        AntiLagConnection = nil
    end
    if Terrain then
        Terrain.WaterTransparency = 0.3
    end
    Lighting.GlobalShadows = true
    settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
end

MiscSection:Toggle({
    Title = "Anti-Lag",
    Default = false,
    Callback = function(value)
        if value then enableAntiLag() else disableAntiLag() end
    end
})