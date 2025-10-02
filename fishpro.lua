--[[
-- Auto Fish + Auto-handle FishCaught (Android / Delta)
-- Versi Final dengan Slider Delay yang Fungsional & Auto Jual
]]

--================================================================
--[[ Services & Pustaka ]]
--================================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Hapus GUI lama jika ada
if game:GetService("CoreGui"):FindFirstChild("AutoFishCerdas_WindUI") then
    game:GetService("CoreGui").AutoFishCerdas_WindUI:Destroy()
end

--================================================================
--[[ Konfigurasi ]]
--================================================================
local config = {
    remoteFolderName = "Remotes",
    remoteEventName = "Fish",
    castTimeout = 15,
    reelTimeout = 10,
    autoSellInterval = 20,
    currentDelay = 0.1 -- Nilai delay default, akan diatur oleh slider
}

--================================================================
--[[ State & Variabel ]]
--================================================================
local Remotes = ReplicatedStorage:WaitForChild(config.remoteFolderName)
local FishRemote = Remotes:WaitForChild(config.remoteEventName)

local autoFishEnabled = false
local autoSellEnabled = false
local lastCaughtArgs = nil
local lastStateChange = 0
local lastClickTime = 0 -- Variabel baru untuk mengatur kecepatan klik
local statusElement = nil

-- State Machine
local State = { IDLE = "IDLE", CASTING = "CASTING", WAITING = "WAITING", REELING = "REELING" }
local currentState = State.IDLE

--================================================================
--[[ Fungsi Helper & Loop ]]
--================================================================
local function click_at(x, y)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(x, y))
        task.wait()
        VirtualUser:Button1Up(Vector2.new(x, y))
    end)
end

local function getCenterXY()
    return camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
end

local function setState(newState)
    if currentState ~= newState then
        currentState = newState
        lastStateChange = tick()
        if statusElement then
            statusElement:SetTitle("Status: " .. currentState)
        end
    end
end

FishRemote.OnClientEvent:Connect(function(...)
    if not autoFishEnabled then return end
    local args = {...}
    local eventName = tostring(args[1]):lower()
    if eventName:find("reel") or eventName:find("shake") or eventName:find("stop") then
        setState(State.REELING)
        return
    end
    if eventName:find("caught") or eventName:find("catch") or eventName:find("fish") then
        local fishId, qty
        if type(args[2]) == "number" then
            fishId, qty = args[2], (type(args[3]) == "number" and args[3] or 1)
        end
        lastCaughtArgs = {id = fishId, qty = qty}
        pcall(function() FishRemote:FireServer("FishCaught", lastCaughtArgs.id, lastCaughtArgs.qty) end)
        setState(State.CASTING)
    end
end)

RunService.Heartbeat:Connect(function(deltaTime)
    if not autoFishEnabled then return end
    local cx, cy = getCenterXY()
    local currentTime = tick()

    if currentState == State.CASTING then
        pcall(function() FishRemote:FireServer("StartFish", 0) end)
        setState(State.WAITING)
    elseif currentState == State.WAITING and currentTime - lastStateChange > config.castTimeout then
        setState(State.CASTING)
    elseif currentState == State.REELING then
        -- [LOGIKA DELAY BARU] Hanya klik jika sudah melewati waktu delay
        if currentTime - lastClickTime > config.currentDelay then
            click_at(cx, cy)
            lastClickTime = currentTime -- Atur ulang timer klik
        end
        if currentTime - lastStateChange > config.reelTimeout then
            setState(State.CASTING)
        end
    end
end)

local function autoSellLoop()
    while autoSellEnabled do
        pcall(function()
            local args = {[1] = "SellAllFish"}
            FishRemote:FireServer(unpack(args))
        end)
        for i = 1, config.autoSellInterval do
            if not autoSellEnabled then break end
            task.wait(1)
        end
    end
end

--================================================================
--[[ UI (WindUI) ]]
--================================================================
local Window = WindUI:CreateWindow({
    Title = "AutoFish Cerdas",
    Size = UDim2.fromOffset(350, 450), -- Ukuran window disesuaikan
    OpenButton = { Title = "Open Auto Fish", Enabled = true }
})

local MainSection = Window:Section({ Title = "Kontrol Utama" })

do
    local ControlTab = MainSection:Tab({ Title = "Otomatisasi", Icon = "flame" })
    statusElement = ControlTab:Paragraph({ Title = "Status: IDLE", Desc = "Menampilkan status auto-fish saat ini.", TextColor = Color3.fromHex("#90e0ef") })
    ControlTab:Divider()

    ControlTab:Toggle({
        Title = "Aktifkan Auto Fish",
        Desc = "Mulai atau hentikan proses memancing otomatis.",
        Value = autoFishEnabled,
        Callback = function(state)
            autoFishEnabled = state
            setState(state and State.CASTING or State.IDLE)
        end
    })

    --- [ TOMBOL DELAY DIGANTI DENGAN SLIDER DI SINI ] ---
    ControlTab:Slider({
        Title = "Atur Delay Klik",
        Desc = "Mengatur jeda waktu saat menggulung ikan (detik).",
        Value = { Min = 0.05, Max = 0.5, Default = config.currentDelay },
        Step = 0.01, -- Tingkat presisi slider
        Callback = function(value)
            config.currentDelay = value -- Simpan nilai baru dari slider
            WindUI:Notify({ 
                Title = "Delay Diubah", 
                Content = string.format("Delay klik sekarang: %.2f detik", value)
            })
        end
    })

    ControlTab:Divider()

    ControlTab:Button({
        Title = "Jual Semua Ikan (Manual)",
        Desc = "Menjual semua ikan di inventory Anda.",
        Icon = "dollar-sign",
        Color = Color3.fromHex("#4ade80"),
        Callback = function()
            local args = {[1] = "SellAllFish"}
            FishRemote:FireServer(unpack(args))
            WindUI:Notify({ Title = "Penjualan Ikan", Content = "Perintah untuk menjual semua ikan telah terkirim!" })
        end
    })
    
    ControlTab:Toggle({
        Title = "Otomatis Jual Ikan",
        Desc = "Aktifkan untuk menjual semua ikan setiap " .. config.autoSellInterval .. " detik.",
        Value = autoSellEnabled,
        Callback = function(state)
            autoSellEnabled = state
            if state then
                task.spawn(autoSellLoop)
                WindUI:Notify({ Title = "Auto Jual", Content = "Otomatis jual ikan diaktifkan."})
            else
                WindUI:Notify({ Title = "Auto Jual", Content = "Otomatis jual ikan dimatikan."})
            end
        end
    })
end