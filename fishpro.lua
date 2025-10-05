local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PlayerGui = player:WaitForChild("PlayerGui")

if game:GetService("CoreGui"):FindFirstChild("AutoFishCerdas_WindUI") then
    game:GetService("CoreGui").AutoFishCerdas_WindUI:Destroy()
end

local config = {
    remoteFolderName = "Remotes",
    remoteEventName = "Fish",
    castTimeout = 15,
    reelTimeout = 10,
    autoSellInterval = 20,
    currentDelay = 0.3
}

local Remotes = ReplicatedStorage:WaitForChild(config.remoteFolderName)
local FishRemote = Remotes:WaitForChild(config.remoteEventName)
local QuestRemote = Remotes:WaitForChild("Quest")

local autoFishEnabled, autoSellEnabled, lastCaughtArgs, lastStateChange, lastClickTime, statusElement = false, false, nil, 0, 0, nil
local hideGuiEnabled, hideGuiConnection = false, nil
local autoQuestEnabled = false
local crateOpeningDelay = 0.3
local autoOpenBasic, autoOpenAdvanced, autoOpenDivine, autoOpenCelestial = false, false, false, false

local State = { IDLE = "IDLE", CASTING = "CASTING", WAITING = "WAITING", REELING = "REELING" }
local currentState = State.IDLE

local teleportLocations = {["Catcher's Camp"] = "Special", ["Shobati"] = "Catcher's Camp", ["Scuba Joe"] = "Shobati", ["Shipwreck Bay"] = "Scuba Joe", ["Great Vine"] = "Shipwreck Bay", ["Ice Island"] = "Great Vine", ["Lava Island"] = "Ice Island", ["Fishman Island"] = "Special", ["Sky Island"] = "Special"}
local npcList = {"Mermaid", "Pablo", "James", "Merchant", "Xavier", "Scared", "Paul", "Pirate", "Shipwright", "Simon", "Sally", "Theo", "Appraiser", "Scientist", "Map", "Shipwright2", "Shipwright4", "Shipwright3", "Random2", "BoatMerchant", "Zack", "Retired Catcher", "Captain", "John", "Rob", "Shipwright5", "George", "Jimmy", "Medea", "Samantha", "Theseus", "Althea", "Danny", "Ramy", "Pam", "Farmer", "RodSeller", "Steve", "Bobby", "Banny", "Catcher's Camp", "Fishman Island", "Great Vine"}
table.sort(npcList)
local questItems = { "Pearl1", "Pearl2", "Pearl3", "Pearl4", "Pearl5" }
local customTeleportLocations = {["Enchant Rod"] = CFrame.new(-7032.4956, 51.5197, 310.6900, 0.1352, 0.0000, 0.9908, 0.0000, 1.0000, -0.0000, -0.9908, 0.0000, 0.1352), ["Abyss Secret"] = CFrame.new(-1474.0933, -1601.8058, 344.1434, -0.5192, 0.0000, -0.8547, -0.0000, 1.0000, 0.0000, 0.8547, 0.0000, -0.5192), ["Mahi Spot"] = CFrame.new(1450.7202, 4.2160, -1517.4034, -0.7036, 0.0000, -0.7106, 0.0000, 1.0000, -0.0000, 0.7106, -0.0000, -0.7036), ["Blue Tang Spot"] = CFrame.new(-3654.2112, -1.5234, -9.4238, -0.9745, -0.0000, 0.2242, -0.0000, 1.0000, 0.0000, -0.2242, 0.0000, -0.9745)}

local function teleportTo(locationName) pcall(function() local char=player.Character; local sp=workspace.Items.SpawnPoints:FindFirstChild(locationName); if char and sp then char:PivotTo(sp.CFrame+Vector3.new(0,3,0)); WindUI:Notify({Title="Teleport Berhasil",Content="Pindah ke "..locationName}) else WindUI:Notify({Title="Teleport Gagal",Content="Lokasi "..locationName.." tidak ada."}) end end) end
local function teleportToCFrame(targetCFrame, locationName) pcall(function() local char=player.Character; if char and char:FindFirstChild("HumanoidRootPart") then char:PivotTo(targetCFrame); WindUI:Notify({Title="Teleport Berhasil",Content="Pindah ke "..locationName}) else WindUI:Notify({Title="Teleport Gagal",Content="Karakter tidak ditemukan."}) end end) end
local function teleportToNpc(npcName) pcall(function() local char=player.Character; local npc=workspace.NPC:FindFirstChild(npcName); if char and npc and npc:FindFirstChild("HumanoidRootPart") then char:PivotTo(npc.HumanoidRootPart.CFrame+Vector3.new(0,3,0)); WindUI:Notify({Title="Teleport Berhasil",Content="Pindah ke "..npcName}) else WindUI:Notify({Title="Teleport Gagal",Content="NPC "..npcName.." tidak ada."}) end end) end
local function teleportToItem(itemName) pcall(function() local char=player.Character; local item=workspace.Items.Quests:FindFirstChild(itemName); if char and item then char:PivotTo(item.CFrame+Vector3.new(0,3,0)); WindUI:Notify({Title="Teleport Berhasil",Content="Pindah ke "..itemName}) else WindUI:Notify({Title="Teleport Gagal",Content="Item "..itemName.." tidak ada."}) end end) end
local function click_at(x,y) pcall(function() VirtualUser:CaptureController(); VirtualUser:Button1Down(Vector2.new(x,y)); task.wait(); VirtualUser:Button1Up(Vector2.new(x,y)) end) end
local function getCenterXY() return camera.ViewportSize.X/2, camera.ViewportSize.Y/2 end
local function setState(newState) if currentState~=newState then currentState=newState; lastStateChange=tick(); if statusElement then statusElement:SetTitle("Status: "..currentState) end end end

local function autoSellLoop()
    while autoSellEnabled do
        pcall(function() FishRemote:FireServer("SellAllFish") end)
        for i = 1, config.autoSellInterval do
            if not autoSellEnabled then break end
            task.wait(1)
        end
    end
end

local function autoOpenLoop(crateName, stateProvider)
    while stateProvider() do
        pcall(function() FishRemote:FireServer("RollBait", crateName) end)
        task.wait(crateOpeningDelay)
    end
end

local function autoQuestLoop()
    while autoQuestEnabled do
        pcall(function() QuestRemote:FireServer("Accept", "Theseus") end)
        task.wait(5)
        if not autoQuestEnabled then break end
        pcall(function() QuestRemote:FireServer("Claim") end)
        task.wait(0.3)
        if not autoQuestEnabled then break end
        pcall(function() QuestRemote:FireServer("Claim") end)
        task.wait(5)
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

local Window = WindUI:CreateWindow({
    Title = "AutoFish Cerdas v4.8.1",
    Size = UDim2.fromOffset(350, 480),
    OpenButton = {Title = "Open Auto Fish", Enabled = true}
})

local MainSection = Window:Section({Title = "Fitur"})

do
    local ControlTab = MainSection:Tab({Title = "Otomatisasi", Icon = "flame"})
    statusElement = ControlTab:Paragraph({Title = "Status: IDLE", Desc = "Menampilkan status auto-fish saat ini.", TextColor = Color3.fromHex("#90e0ef")})
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
        Value = {Min = 0.5, Max = 3, Default = config.currentDelay},
        Step = 0.01,
        Callback = function(value)
            config.currentDelay = value
        end
    })
    ControlTab:Divider()
    ControlTab:Toggle({
        Title = "Otomatis Jual Ikan",
        Desc = "Aktifkan untuk menjual semua ikan setiap " .. config.autoSellInterval .. " detik.",
        Value = autoSellEnabled,
        Callback = function(state)
            autoSellEnabled = state
            if state then
                task.spawn(autoSellLoop)
                WindUI:Notify({Title = "Auto Jual", Content = "Aktif."})
            else
                WindUI:Notify({Title = "Auto Jual", Content = "Nonaktif."})
            end
        end
    })
    ControlTab:Divider()
    ControlTab:Toggle({
        Title = "Aktifkan Auto Quest (Theseus)",
        Desc = "Loop Terima & Klaim quest dari Theseus.",
        Value = autoQuestEnabled,
        Callback = function(state)
            autoQuestEnabled = state
            if state then
                task.spawn(autoQuestLoop)
                WindUI:Notify({Title = "Auto Quest", Content = "Aktif."})
            else
                WindUI:Notify({Title = "Auto Quest", Content = "Nonaktif."})
            end
        end
    })
    ControlTab:Button({
        Title = "Masak Zesty Lemon Fish",
        Desc = "Membuat Zesty Lemon Fish sekali.",
        Callback = function()
            pcall(function()
                FishRemote:FireServer("CraftRecipe", "Zesty Lemon Fish")
                WindUI:Notify({Title = "Memasak", Content = "Zesty Lemon Fish dibuat."})
            end)
        end
    })

    local TeleportTab = MainSection:Tab({Title = "Teleportasi", Icon = "map-pin"})
    TeleportTab:Paragraph({Title = "Pindah Lokasi", Desc = "Klik tombol untuk teleport ke lokasi."})
    TeleportTab:Divider()
    for locationName, _ in pairs(teleportLocations) do
        TeleportTab:Button({Title = locationName, Callback = function() teleportTo(locationName) end})
    end
    TeleportTab:Divider()
    TeleportTab:Paragraph({Title = "Item Quest", Desc = "Teleport ke lokasi item quest."})
    for _, itemName in ipairs(questItems) do
        TeleportTab:Button({Title = itemName, Callback = function() teleportToItem(itemName) end})
    end
    TeleportTab:Divider()
    TeleportTab:Paragraph({Title = "Lokasi Kustom", Desc = "Teleport ke lokasi yang Anda simpan."})
    for name, cf in pairs(customTeleportLocations) do
        TeleportTab:Button({Title = name, Callback = function() teleportToCFrame(cf, name) end})
    end

    local NpcTeleportTab = MainSection:Tab({Title = "Teleport NPC", Icon = "users"})
    NpcTeleportTab:Paragraph({Title = "Pindah ke NPC", Desc = "Klik tombol untuk teleport ke NPC."})
    NpcTeleportTab:Divider()
    for _, npcName in ipairs(npcList) do
        NpcTeleportTab:Button({Title = npcName, Callback = function() teleportToNpc(npcName) end})
    end

    local playerTeleportTab = MainSection:Tab({Title = "Teleport Player", Icon = "user-check"})
    local playerTeleportButtons = {}
    local function refreshPlayerTeleportList()
        for _, button in ipairs(playerTeleportButtons) do
            if button and button.Object and button.Object.Parent then
                pcall(function() button:Destroy() end)
            end
        end
        table.clear(playerTeleportButtons)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local btn = playerTeleportTab:Button({
                    Title = p.DisplayName,
                    Desc = "Teleport ke " .. p.Name,
                    Callback = function()
                        pcall(function()
                            local t = Players:FindFirstChild(p.Name)
                            if not t then
                                WindUI:Notify({Title = "Gagal", Content = "Player " .. p.Name .. " tidak ada."})
                                return
                            end
                            local myC, tC = player.Character, t.Character
                            if myC and tC and tC:FindFirstChild("HumanoidRootPart") then
                                myC:PivotTo(tC.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0))
                                WindUI:Notify({Title = "Sukses", Content = "Teleport ke " .. t.DisplayName})
                            else
                                WindUI:Notify({Title = "Gagal", Content = "Karakter tidak valid."})
                            end
                        end)
                    end
                })
                table.insert(playerTeleportButtons, btn)
            end
        end
    end
    playerTeleportTab:Button({
        Title = "Refresh List",
        Desc = "Memuat ulang daftar pemain.",
        Icon = "refresh-cw",
        Color = Color3.fromHex("#38bdf8"),
        Callback = function()
            refreshPlayerTeleportList()
            WindUI:Notify({Title = "Player List", Content = "Diperbarui."})
        end
    })
    playerTeleportTab:Divider()
    refreshPlayerTeleportList()

    local SpawnBoatTab = MainSection:Tab({Title = "Spawn Boat", Icon = "anchor"})
    SpawnBoatTab:Paragraph({Title = "Panggil Perahu", Desc = "Klik tombol untuk memunculkan perahu di dekat Anda."})
    SpawnBoatTab:Divider()
    local boatList = {"Bamboo Raft", "Raft", "Dinghy", "Jetski", "Fishing Boat", "Speed Boat", "Subski"}
    for _, boatName in ipairs(boatList) do
        SpawnBoatTab:Button({
            Title = boatName,
            Callback = function()
                pcall(function()
                    FishRemote:FireServer("SpawnBoat", boatName)
                    WindUI:Notify({Title = "Spawn Boat", Content = boatName .. " telah dipanggil."})
                end)
            end
        })
    end

    local ShopTab = MainSection:Tab({Title = "Shop", Icon = "shopping-cart"})
    ShopTab:Paragraph({Title = "Pembelian Otomatis", Desc = "Beli item dalam jumlah banyak."})
    ShopTab:Divider()
    local purchaseAmount = 1
    ShopTab:Input({
        Title = "Jumlah Pembelian",
        Desc = "Masukkan berapa kali item dibeli.",
        Placeholder = "1",
        Callback = function(text)
            local n = tonumber(text)
            if n and n > 0 then
                purchaseAmount = math.floor(n)
            else
                purchaseAmount = 1
            end
        end
    })
    ShopTab:Divider()
    ShopTab:Paragraph({Title = "Beli Totem", Desc = "Beli totem cuaca/waktu."})
    local function createTotemButton(tN, tDN)
        ShopTab:Button({
            Title = "Beli (" .. tDN .. ")",
            Desc = "Beli '" .. tDN .. "'",
            Callback = function()
                task.spawn(function()
                    local r = ReplicatedStorage.Remotes:FindFirstChild("World")
                    if not r then return end
                    for i = 1, purchaseAmount do
                        pcall(function() r:FireServer("Buy", tN) end)
                        task.wait(0.3)
                    end
                end)
            end
        })
    end
    createTotemButton("Night", "Night Totem")
    createTotemButton("Day", "Day Totem")
    createTotemButton("Rain", "Rain Totem")
    createTotemButton("Blood Moon", "Blood Moon Totem")
    ShopTab:Divider()
    ShopTab:Paragraph({Title = "Beli Crate", Desc = "Beli peti umpan."})
    local function createCrateButton(cN)
        ShopTab:Button({
            Title = "Beli (" .. cN .. ")",
            Desc = "Beli '" .. cN .. "'",
            Callback = function()
                task.spawn(function()
                    local r = ReplicatedStorage.Remotes:FindFirstChild("Rod")
                    if not r then return end
                    for i = 1, purchaseAmount do
                        pcall(function() r:FireServer({"BuyBaitCrate", cN}) end)
                        task.wait(0.3)
                    end
                end)
            end
        })
    end
    createCrateButton("Basic Crate")
    createCrateButton("Advanced Crate")
    createCrateButton("Divine Crate")
    createCrateButton("Celestial Crate")

    local AutoPetiTab = MainSection:Tab({Title = "Auto Peti", Icon = "archive"})
    AutoPetiTab:Paragraph({Title = "Otomatis Buka Peti", Desc = "Aktifkan untuk membuka peti secara terus-menerus."})
    AutoPetiTab:Slider({
        Title = "Jeda Buka Peti (Detik)",
        Desc = "Mengatur jeda waktu antar pembukaan peti.",
        Value = {Min = 0.1, Max = 2, Default = crateOpeningDelay},
        Step = 0.1,
        Callback = function(value) crateOpeningDelay = value end
    })
    AutoPetiTab:Divider()
    AutoPetiTab:Toggle({
        Title = "Auto Basic Crate",
        Desc = "Otomatis membuka Basic Crate.",
        Value = autoOpenBasic,
        Callback = function(state)
            autoOpenBasic = state
            if state then
                task.spawn(function() autoOpenLoop("Basic Crate", function() return autoOpenBasic end) end)
                WindUI:Notify({Title = "Auto Basic Crate", Content = "Aktif."})
            else
                WindUI:Notify({Title = "Auto Basic Crate", Content = "Nonaktif."})
            end
        end
    })
    AutoPetiTab:Toggle({
        Title = "Auto Advanced Crate",
        Desc = "Otomatis membuka Advanced Crate.",
        Value = autoOpenAdvanced,
        Callback = function(state)
            autoOpenAdvanced = state
            if state then
                task.spawn(function() autoOpenLoop("Advanced Crate", function() return autoOpenAdvanced end) end)
                WindUI:Notify({Title = "Auto Advanced Crate", Content = "Aktif."})
            else
                WindUI:Notify({Title = "Auto Advanced Crate", Content = "Nonaktif."})
            end
        end
    })
    AutoPetiTab:Toggle({
        Title = "Auto Divine Crate",
        Desc = "Otomatis membuka Divine Crate.",
        Value = autoOpenDivine,
        Callback = function(state)
            autoOpenDivine = state
            if state then
                task.spawn(function() autoOpenLoop("Divine Crate", function() return autoOpenDivine end) end)
                WindUI:Notify({Title = "Auto Divine Crate", Content = "Aktif."})
            else
                WindUI:Notify({Title = "Auto Divine Crate", Content = "Nonaktif."})
            end
        end
    })
    AutoPetiTab:Toggle({
        Title = "Auto Celestial Crate",
        Desc = "Otomatis membuka Celestial Crate.",
        Value = autoOpenCelestial,
        Callback = function(state)
            autoOpenCelestial = state
            if state then
                task.spawn(function() autoOpenLoop("Celestial Crate", function() return autoOpenCelestial end) end)
                WindUI:Notify({Title = "Auto Celestial Crate", Content = "Aktif."})
            else
                WindUI:Notify({Title = "Auto Celestial Crate", Content = "Nonaktif."})
            end
        end
    })

    local FishHolderTab = MainSection:Tab({Title = "Fish Holder", Icon = "box"})
    local FavoriteSection = FishHolderTab:Section({Title = "Favorite Actions"})
    local UnfavoriteSection = FishHolderTab:Section({Title = "Unfavorite Actions"})
    local favorite_buttons = {}
    local unfavorite_buttons = {}

    local function performFavoriteAction(targetFishName, shouldBeFavorite)
        task.spawn(function()
            local actionText = shouldBeFavorite and "Memfavoritkan" or "Menghapus favorit"
            local fishText = targetFishName or "semua ikan"
            -- WindUI:Notify({Title = "Proses", Content = actionText .. " " .. fishText .. "..."})
            local MainGui, InventoryFrame, FishHolder = PlayerGui:WaitForChild("Main"), PlayerGui.Main:WaitForChild("Inventory"), PlayerGui.Main.Inventory:WaitForChild("FishHolder")
            if not FishHolder then return end
            for _, fishObject in ipairs(FishHolder:GetChildren()) do
                if not targetFishName or string.find(fishObject.Name, targetFishName .. ":") then
                    local uuid = fishObject.Name:split(":")[2]
                    if uuid then
                        FishRemote:FireServer("FavoriteFish", uuid, shouldBeFavorite)
                        task.wait(0.05)
                    end
                end
            end
            InventoryFrame.Visible = false
            task.wait(0.1)
            -- InventoryFrame.Visible = true
            WindUI:Notify({Title = "Selesai", Content = fishText .. " berhasil diproses."})
        end)
    end
    
    -- [KODE DIPERBARUI] Fungsi ini sekarang menghitung jumlah ikan
    local function createFishButtons(parentSection, buttonTable, isFavoriteAction)
        for _, button in ipairs(buttonTable) do pcall(function() button:Destroy() end) end
        table.clear(buttonTable)

        local actionText = isFavoriteAction and "Favorite" or "Unfavorite"
        -- WindUI:Notify({Title = "Inventory Scan", Content = "Memindai dan menghitung ikan untuk daftar " .. actionText .. "..."})

        local FishHolder = PlayerGui:WaitForChild("Main"):WaitForChild("Inventory"):WaitForChild("FishHolder")
        if not FishHolder then
            WindUI:Notify({Title = "Error", Content = "Inventory tidak ditemukan."})
            return
        end

        -- Menghitung jumlah untuk setiap jenis ikan
        local fishCounts = {}
        for _, fishObject in ipairs(FishHolder:GetChildren()) do
            local fishName = string.split(fishObject.Name, ":")[1]
            if fishName then
                fishCounts[fishName] = (fishCounts[fishName] or 0) + 1
            end
        end

        -- Mengurutkan nama ikan berdasarkan abjad
        local sortedFishNames = {}
        for fishName in pairs(fishCounts) do
            table.insert(sortedFishNames, fishName)
        end
        table.sort(sortedFishNames)

        if #sortedFishNames == 0 then
            WindUI:Notify({Title = "Inventory Scan", Content = "Tidak ada ikan di inventory."})
            return
        end

        -- Membuat tombol dengan jumlah ikan
        for _, fishName in ipairs(sortedFishNames) do
            local count = fishCounts[fishName]
            local btn = parentSection:Button({
                Title = fishName .. " (" .. tostring(count) .. ")",
                Callback = function() performFavoriteAction(fishName, isFavoriteAction) end
            })
            table.insert(buttonTable, btn)
        end
        WindUI:Notify({Title = "Inventory Scan", Content = "Daftar " .. actionText .. " berhasil diperbarui!"})
    end

    FavoriteSection:Button({
        Title = "Refresh Favorite List",
        Desc = "Pindai ulang inventory untuk daftar Favorite.",
        Icon = "refresh-cw",
        Color = Color3.fromHex("#38bdf8"),
        Callback = function() createFishButtons(FavoriteSection, favorite_buttons, true) end
    })

    UnfavoriteSection:Button({
        Title = "Refresh Unfavorite List",
        Desc = "Pindai ulang inventory untuk daftar Unfavorite.",
        Icon = "refresh-cw",
        Color = Color3.fromHex("#38bdf8"),
        Callback = function() createFishButtons(UnfavoriteSection, unfavorite_buttons, false) end
    })

    local MiscTab = MainSection:Tab({Title = "MISC", Icon = "settings"})
    MiscTab:Paragraph({Title = "Fitur Lain & Pengaturan", Desc = "Berisi berbagai fungsi tambahan."})
    MiscTab:Divider()
    MiscTab:Toggle({
        Title = "Sembunyikan Notifikasi Game",
        Desc = "Secara aktif membersihkan teks notifikasi bawaan game yang spam.",
        Value = hideGuiEnabled,
        Callback = function(state)
            hideGuiEnabled = state
            if state then
                hideGuiConnection = RunService.RenderStepped:Connect(function()
                    for _, v in ipairs(PlayerGui:GetDescendants()) do
                        if v:IsA("TextLabel") and (string.find(v.Name:lower(), "autosold") or string.find(v.Text:lower(), "auto sold")) then
                            v.Text = ""
                        end
                    end
                end)
                WindUI:Notify({Title = "Penyembunyi GUI Aktif", Content = "Notifikasi game akan disembunyikan."})
            else
                if hideGuiConnection then
                    hideGuiConnection:Disconnect()
                    hideGuiConnection = nil
                end
                WindUI:Notify({Title = "Penyembunyi GUI Nonaktif", Content = "Notifikasi game akan ditampilkan lagi."})
            end
        end
    })
    MiscTab:Divider()
    MiscTab:Button({
        Title = "Salin Posisi & Arah (CFrame)",
        Desc = "Menyalin CFrame karakter Anda ke clipboard untuk membuat lokasi teleport.",
        Callback = function()
            pcall(function()
                if not setclipboard then
                    WindUI:Notify({Title = "Error", Content = "Executor Anda tidak mendukung setclipboard."})
                    return
                end
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local cf = hrp.CFrame
                    local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
                    local cframeString = string.format("CFrame.new(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f)", x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
                    setclipboard(cframeString)
                    WindUI:Notify({Title = "Sukses", Content = "CFrame karakter telah disalin."})
                else
                    WindUI:Notify({Title = "Gagal", Content = "Tidak dapat menemukan karakter."})
                end
            end)
        end
    })
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
            WindUI:Notify({Title = "Operasi Selesai", Content = "Semua 'Flag' dihapus."})
        end
    })
end