local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

if game:GetService("CoreGui"):FindFirstChild("AutoFishCerdas_WindUI") then
    game:GetService("CoreGui").AutoFishCerdas_WindUI:Destroy()
end

local config = {
    remoteFolderName = "Remotes",
    remoteEventName = "Fish",
    castTimeout = 15,
    reelTimeout = 10,
    autoSellInterval = 20,
    currentDelay = 0.1
}

local Remotes = ReplicatedStorage:WaitForChild(config.remoteFolderName)
local FishRemote = Remotes:WaitForChild(config.remoteEventName)

local autoFishEnabled = false
local autoSellEnabled = false
local lastCaughtArgs = nil
local lastStateChange = 0
local lastClickTime = 0
local statusElement = nil

local State = { IDLE = "IDLE", CASTING = "CASTING", WAITING = "WAITING", REELING = "REELING" }
local currentState = State.IDLE

local teleportLocations = {
	["Catcher's Camp"] = "Special",
	["Shobati"] = "Catcher's Camp",
	["Scuba Joe"] = "Shobati",
	["Shipwreck Bay"] = "Scuba Joe",
	["Great Vine"] = "Shipwreck Bay",
	["Ice Island"] = "Great Vine",
	["Lava Island"] = "Ice Island",
	["Fishman Island"] = "Special",
	["Sky Island"] = "Special"
}

local npcList = {
    "Mermaid", "Pablo", "James", "Merchant", "Xavier", "Scared", "Paul", "Pirate", 
    "Shipwright", "Simon", "Sally", "Theo", "Appraiser", "Scientist", "Map", 
    "Shipwright2", "Shipwright4", "Shipwright3", "Random2", "BoatMerchant", "Zack", 
    "Retired Catcher", "Captain", "John", "Rob", "Shipwright5", "George", "Jimmy", 
    "Medea", "Samantha", "Theseus", "Althea", "Danny", "Ramy", "Pam", "Farmer", 
    "RodSeller", "Steve", "Bobby", "Banny", "Catcher's Camp", "Fishman Island", "Great Vine"
}
table.sort(npcList)

local questItems = {"Pearl1", "Pearl2", "Pearl3", "Pearl4", "Pearl5"}


local function teleportTo(locationName)
    pcall(function()
        local character = player.Character
        local spawnPoint = workspace.Items.SpawnPoints:FindFirstChild(locationName)
        
        if character and spawnPoint then
            character:PivotTo(spawnPoint.CFrame + Vector3.new(0, 3, 0))
            WindUI:Notify({ Title = "Teleport Berhasil", Content = "Anda telah dipindahkan ke " .. locationName })
        else
            WindUI:Notify({ Title = "Teleport Gagal", Content = "Lokasi " .. locationName .. " tidak ditemukan." })
        end
    end)
end

local function teleportToNpc(npcName)
    pcall(function()
        local character = player.Character
        local npcModel = workspace.NPC:FindFirstChild(npcName)
        
        if character and npcModel and npcModel:FindFirstChild("HumanoidRootPart") then
            character:PivotTo(npcModel.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0))
            WindUI:Notify({ Title = "Teleport Berhasil", Content = "Anda telah dipindahkan ke " .. npcName })
        else
            WindUI:Notify({ Title = "Teleport Gagal", Content = "NPC " .. npcName .. " tidak ditemukan atau tidak valid." })
        end
    end)
end

local function teleportToItem(itemName)
    pcall(function()
        local character = player.Character
        local item = workspace.Items.Quests:FindFirstChild(itemName)
        
        if character and item then
            character:PivotTo(item.CFrame + Vector3.new(0, 3, 0))
            WindUI:Notify({ Title = "Teleport Berhasil", Content = "Anda telah dipindahkan ke " .. itemName })
        else
            WindUI:Notify({ Title = "Teleport Gagal", Content = "Item " .. itemName .. " tidak ditemukan." })
        end
    end)
end

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
        if currentTime - lastClickTime > config.currentDelay then
            click_at(cx, cy)
            lastClickTime = currentTime
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

local Window = WindUI:CreateWindow({
    Title = "AutoFish Cerdas v2.4",
    Size = UDim2.fromOffset(350, 480),
    OpenButton = { Title = "Open Auto Fish", Enabled = true }
})

local MainSection = Window:Section({ Title = "Fitur" })

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

    ControlTab:Slider({
        Title = "Atur Delay Klik",
        Desc = "Mengatur jeda waktu saat menggulung ikan (detik).",
        Value = { Min = 0.05, Max = 0.5, Default = config.currentDelay },
        Step = 0.01,
        Callback = function(value)
            config.currentDelay = value
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

    local TeleportTab = MainSection:Tab({ Title = "Teleportasi", Icon = "map-pin" })
    TeleportTab:Paragraph({ Title = "Pindah Lokasi", Desc = "Klik tombol untuk teleport ke lokasi yang dipilih secara instan." })
    TeleportTab:Divider()
    
    for locationName, _ in pairs(teleportLocations) do
        TeleportTab:Button({
            Title = locationName,
            Callback = function()
                teleportTo(locationName)
            end
        })
    end
    
    TeleportTab:Divider()
    TeleportTab:Paragraph({ Title = "Item Quest", Desc = "Teleport ke lokasi item quest." })
    
    for _, itemName in ipairs(questItems) do
        TeleportTab:Button({
            Title = itemName,
            Callback = function()
                teleportToItem(itemName)
            end
        })
    end

    local NpcTeleportTab = MainSection:Tab({ Title = "Teleport NPC", Icon = "users" })
    NpcTeleportTab:Paragraph({ Title = "Pindah ke NPC", Desc = "Klik tombol untuk teleport ke NPC yang dipilih." })
    NpcTeleportTab:Divider()
    
    for _, npcName in ipairs(npcList) do
        NpcTeleportTab:Button({
            Title = npcName,
            Callback = function()
                teleportToNpc(npcName)
            end
        })
    end

    -- [[ BARU: Tab Teleport Player ]]
    local PlayerTeleportTab = MainSection:Tab({ Title = "Teleport Player", Icon = "user-check" })
    local playerButtons = {}
    local function refreshPlayerList()
        -- Hapus tombol lama
        for _, button in ipairs(playerButtons) do
            pcall(function() button:Destroy() end)
        end
        playerButtons = {}

        -- Buat tombol baru untuk setiap player
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= player then -- Jangan tampilkan diri sendiri
                local newButton = PlayerTeleportTab:Button({
                    Title = targetPlayer.DisplayName,
                    Desc = "Teleport ke player " .. targetPlayer.Name,
                    Callback = function()
                        pcall(function()
                            local myCharacter = player.Character
                            local targetCharacter = targetPlayer.Character
                            if myCharacter and targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                                local targetCFrame = targetCharacter.HumanoidRootPart.CFrame
                                myCharacter:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
                                WindUI:Notify({ Title = "Teleport Sukses", Content = "Berhasil teleport ke " .. targetPlayer.DisplayName })
                            else
                                WindUI:Notify({ Title = "Teleport Gagal", Content = "Player tidak ditemukan atau karakternya tidak valid." })
                            end
                        end)
                    end
                })
                table.insert(playerButtons, newButton)
            end
        end
    end

    PlayerTeleportTab:Button({
        Title = "Refresh List",
        Desc = "Memuat ulang daftar pemain di server.",
        Icon = "refresh-cw",
        Color = Color3.fromHex("#38bdf8"),
        Callback = refreshPlayerList
    })
    PlayerTeleportTab:Divider()
    refreshPlayerList() -- Panggil fungsi sekali untuk memuat daftar saat pertama kali dibuka

    local MiscTab = MainSection:Tab({ Title = "MISC", Icon = "trash-2" })
    MiscTab:Paragraph({ Title = "Fitur Lain-lain", Desc = "Berisi berbagai fungsi tambahan." })
    MiscTab:Divider()

    MiscTab:Button({
        Title = "Hapus Flag",
        Desc = "Menghapus semua objek bernama 'Flag' di dalam game.",
        Callback = function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "Flag" then
                    pcall(function() obj:Destroy() end)
                end
            end
            print("Selesai: semua objek bernama 'Flag' dihancurkan.")
            WindUI:Notify({ Title = "Operasi Selesai", Content = "Semua 'Flag' telah berhasil dihapus." })
        end
    })
end
