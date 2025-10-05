local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services
local SERVICES = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
    CoreGui = game:GetService("CoreGui")
}

-- Player Data
local LOCAL_PLAYER = SERVICES.Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")
local CAMERA = workspace.CurrentCamera

-- Configuration
local CONFIG = {
    RemoteFolderName = "Remotes",
    RemoteEventName = "Fish",
    CastTimeout = 15,
    ReelTimeout = 10,
    AutoSellInterval = 20,
    ClickDelay = 0.3,
    CrateOpeningDelay = 0.3
}

-- Remotes
local REMOTES = SERVICES.ReplicatedStorage:WaitForChild(CONFIG.RemoteFolderName)
local FISH_REMOTE = REMOTES:WaitForChild(CONFIG.RemoteEventName)
local QUEST_REMOTE = REMOTES:WaitForChild("Quest")

-- State Management
local State = { IDLE = "IDLE", CASTING = "CASTING", WAITING = "WAITING", REELING = "REELING" }
local currentState = State.IDLE

local state = {
    autoFishEnabled = false,
    autoSellEnabled = false,
    autoQuestEnabled = false,
    autoOpenActive = false,
    autoEnchantActive = false,
    isGuiHidden = true,
    lastCaughtArgs = nil,
    lastStateChange = 0,
    lastClickTime = 0,
    lastReceivedEnchant = nil,
    selectedCrate = "Basic Crate",
    targetEnchant = "Mighty",
    selectedArtifact = "Regular Artifact"
}

-- UI Elements
local uiElements = {
    status = nil,
    autoEnchantToggle = nil
}

if SERVICES.CoreGui:FindFirstChild("AutoFishCerdas_WindUI") then
    SERVICES.CoreGui.AutoFishCerdas_WindUI:Destroy()
end

-- Data Tables
local TELEPORT_LOCATIONS = {
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

local CUSTOM_TELEPORT_LOCATIONS = {
    ["Enchant Rod"] = CFrame.new(-7032.4956, 51.5197, 310.6900, 0.1352, 0.0000, 0.9908, 0.0000, 1.0000, -0.0000, -0.9908, 0.0000, 0.1352),
    ["Abyss Secret"] = CFrame.new(-1474.0933, -1601.8058, 344.1434, -0.5192, 0.0000, -0.8547, -0.0000, 1.0000, 0.0000, 0.8547, 0.0000, -0.5192),
    ["Mahi Spot"] = CFrame.new(1450.7202, 4.2160, -1517.4034, -0.7036, 0.0000, -0.7106, 0.0000, 1.0000, -0.0000, 0.7106, -0.0000, -0.7036),
    ["Blue Tang Spot"] = CFrame.new(-3654.2112, -1.5234, -9.4238, -0.9745, -0.0000, 0.2242, -0.0000, 1.0000, 0.0000, -0.2242, 0.0000, -0.9745),
    ["Door Secret"] = CFrame.new(-3098.8677, -741.0842, -334.6655, 0.9961, 0.0263, -0.0842, 0.0001, 0.9545, 0.2984, 0.0882, -0.2972, 0.9507)
}

local NPC_LIST = {"Mermaid", "Pablo", "James", "Merchant", "Xavier", "Scared", "Paul", "Pirate", "Shipwright", "Simon", "Sally", "Theo", "Appraiser", "Scientist", "Map", "Shipwright2", "Shipwright4", "Shipwright3", "Random2", "BoatMerchant", "Zack", "Retired Catcher", "Captain", "John", "Rob", "Shipwright5", "George", "Jimmy", "Medea", "Samantha", "Theseus", "Althea", "Danny", "Ramy", "Pam", "Farmer", "RodSeller", "Steve", "Bobby", "Banny", "Catcher's Camp", "Fishman Island", "Great Vine"}
table.sort(NPC_LIST)

local QUEST_ITEMS = { "Pearl1", "Pearl2", "Pearl3", "Pearl4", "Pearl5" }

-- Helper Functions
local function notify(title, content, duration)
    WindUI:Notify({ Title = title, Content = content, Duration = duration or 5 })
end

local function setState(newState)
    if currentState ~= newState then
        currentState = newState
        state.lastStateChange = tick()
        if uiElements.status then
            uiElements.status:SetTitle("Status: " .. currentState)
        end
    end
end

local function clickAt(x, y)
    pcall(function()
        SERVICES.VirtualUser:CaptureController()
        SERVICES.VirtualUser:Button1Down(Vector2.new(x, y))
        task.wait()
        SERVICES.VirtualUser:Button1Up(Vector2.new(x, y))
    end)
end

local function getCenterXY()
    return CAMERA.ViewportSize.X / 2, CAMERA.ViewportSize.Y / 2
end

local function getCharacter()
    return LOCAL_PLAYER.Character
end

-- Teleport Functions
local function teleportTo(locationName, destination, type)
    pcall(function()
        local character = getCharacter()
        if not character or not destination then
            notify("Teleport Gagal", type .. " " .. locationName .. " tidak ada.")
            return
        end
        local targetCFrame = (type == "CFrame") and destination or destination.CFrame + Vector3.new(0, 3, 0)
        character:PivotTo(targetCFrame)
        notify("Teleport Berhasil", "Pindah ke " .. locationName)
    end)
end

local function teleportToLocation(locationName)
    local spawnPoint = workspace.Items.SpawnPoints:FindFirstChild(locationName)
    teleportTo(locationName, spawnPoint, "Lokasi")
end

local function teleportToNpc(npcName)
    local npc = workspace.NPC:FindFirstChild(npcName)
    local hrp = npc and npc:FindFirstChild("HumanoidRootPart")
    teleportTo(npcName, hrp, "NPC")
end

local function teleportToItem(itemName)
    local item = workspace.Items.Quests:FindFirstChild(itemName)
    teleportTo(itemName, item, "Item")
end

local function teleportToCFrame(cframe, locationName)
    teleportTo(locationName, cframe, "CFrame")
end

-- GUI Functions
local function updateGuiVisibility(isHidden)
    local elementsToToggle = {
        PLAYER_GUI.Main and PLAYER_GUI.Main:FindFirstChild("TopNotification"),
        PLAYER_GUI.FishUI and PLAYER_GUI.FishUI:FindFirstChild("FishDisplay") and PLAYER_GUI.FishUI.FishDisplay:FindFirstChild("InfoDisplay")
    }
    local count = 0
    for _, element in ipairs(elementsToToggle) do
        if element and element:IsA("GuiObject") then
            element.Visible = not isHidden
            count = count + 1
        end
    end
    return count
end

-- Automation Loops
local function autoSellLoop()
    while state.autoSellEnabled do
        pcall(function() FISH_REMOTE:FireServer("SellAllFish") end)
        for _ = 1, CONFIG.AutoSellInterval do
            if not state.autoSellEnabled then break end
            task.wait(1)
        end
    end
end

local function autoQuestLoop()
    while state.autoQuestEnabled do
        pcall(function() QUEST_REMOTE:FireServer("Accept", "Theseus") end)
        task.wait(5)
        if not state.autoQuestEnabled then break end
        pcall(function() QUEST_REMOTE:FireServer("Claim") end)
        task.wait(0.3)
        if not state.autoQuestEnabled then break end
        pcall(function() QUEST_REMOTE:FireServer("Claim") end)
        task.wait(5)
    end
end

local function autoOpenLoop()
    while state.autoOpenActive do
        pcall(function() FISH_REMOTE:FireServer("RollBait", state.selectedCrate) end)
        task.wait(CONFIG.CrateOpeningDelay)
    end
end

local function autoEnchantLoop(statusElement)
    while state.autoEnchantActive do
        state.lastReceivedEnchant = nil
        statusElement:SetTitle("Status: Mencari " .. state.selectedArtifact)
        local fishHolder = PLAYER_GUI.Main.Inventory.FishHolder
        local artifactUUID
        for _, item in ipairs(fishHolder:GetChildren()) do
            if item.Name:find(state.selectedArtifact .. ":") then
                artifactUUID = item.Name:split(":")[2]
                break
            end
        end

        if not artifactUUID then
            statusElement:SetTitle("Status: Artifact habis! Berhenti.")
            notify("Auto Enchant", state.selectedArtifact .. " tidak ditemukan.")
            state.autoEnchantActive = false
            break
        end

        statusElement:SetTitle("Status: Menjalankan enchant...")
        local rodRemote = REMOTES:FindFirstChild("Rod")
        if rodRemote then
            rodRemote:FireServer({"EnchantRod", artifactUUID})
        end

        local timeout = 5
        repeat
            task.wait(0.1)
            timeout -= 0.1
        until state.lastReceivedEnchant or not state.autoEnchantActive or timeout <= 0

        if state.lastReceivedEnchant then
            if state.lastReceivedEnchant:lower() == state.targetEnchant:lower() then
                statusElement:SetTitle("BERHASIL! Dapat: " .. state.targetEnchant)
                notify("Auto Enchant Sukses!", "Berhasil mendapatkan enchant: " .. state.targetEnchant, 10)
                state.autoEnchantActive = false
            else
                statusElement:SetTitle("Dapat: " .. state.lastReceivedEnchant .. ". Coba lagi...")
                task.wait(1.5)
            end
        elseif timeout <= 0 then
            statusElement:SetTitle("Status: Timeout. Coba lagi...")
            task.wait(2)
        end
    end

    if not state.autoEnchantActive then
        if not statusElement.Title:find("BERHASIL") then statusElement:SetTitle("Status: IDLE") end
        if uiElements.autoEnchantToggle then uiElements.autoEnchantToggle:SetState(false) end
    end
end

-- Event Handlers
FISH_REMOTE.OnClientEvent:Connect(function(...)
    if not state.autoFishEnabled then return end
    local args = {...}
    local eventName = tostring(args[1]):lower()

    if eventName:find("reel") or eventName:find("shake") or eventName:find("stop") then
        setState(State.REELING)
    elseif eventName:find("caught") or eventName:find("catch") or eventName:find("fish") then
        local fishId, qty
        if type(args[2]) == "number" then
            fishId = args[2]
            qty = (type(args[3]) == "number") and args[3] or 1
        end
        state.lastCaughtArgs = {id = fishId, qty = qty}
        pcall(function() FISH_REMOTE:FireServer("FishCaught", state.lastCaughtArgs.id, state.lastCaughtArgs.qty) end)
        setState(State.CASTING)
    end
end)

SERVICES.RunService.Heartbeat:Connect(function()
    if not state.autoFishEnabled then return end
    local currentTime = tick()
    
    if currentState == State.CASTING then
        pcall(function() FISH_REMOTE:FireServer("StartFish", 0) end)
        setState(State.WAITING)
    elseif currentState == State.WAITING and currentTime - state.lastStateChange > CONFIG.CastTimeout then
        setState(State.CASTING)
    elseif currentState == State.REELING then
        if currentTime - state.lastClickTime > CONFIG.ClickDelay then
            local cx, cy = getCenterXY()
            clickAt(cx, cy)
            state.lastClickTime = currentTime
        end
        if currentTime - state.lastStateChange > CONFIG.ReelTimeout then
            setState(State.CASTING)
        end
    end
end)

pcall(function()
    local replicaSet = SERVICES.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ReplicaSet")
    replicaSet.OnClientEvent:Connect(function(...)
        if not state.autoEnchantActive then return end
        local args = {...}
        if #args > 2 and type(args[#args]) == "string" and type(args[2]) == "table" then
            local dataTable = args[2]
            if #dataTable >= 3 and dataTable[1] == "Rods" and dataTable[3] == "Enchantment" then
                state.lastReceivedEnchant = args[#args]
            end
        end
    end)
end)


-- GUI Construction
local Window = WindUI:CreateWindow({
    Title = "AutoFish Cerdas v5.6",
    Size = UDim2.fromOffset(380, 520),
    OpenButton = {Title = "Open Auto Fish", Enabled = true}
})

local MainSection = Window:Section({Title = "Fitur"})

local function createControlTab(parent)
    local tab = parent:Tab({Title = "Otomatisasi", Icon = "flame"})
    uiElements.status = tab:Paragraph({Title = "Status: IDLE"})
    tab:Divider()

    tab:Toggle({Title = "Aktifkan Auto Fish", Value = state.autoFishEnabled, Callback = function(s)
        state.autoFishEnabled = s
        setState(s and State.CASTING or State.IDLE)
    end})
    tab:Slider({Title = "Atur Delay Klik", Value = {Min = 0.5, Max = 3, Default = CONFIG.ClickDelay}, Step = 0.01, Callback = function(v)
        CONFIG.ClickDelay = v
    end})

    tab:Divider()
    tab:Toggle({Title = "Otomatis Jual Ikan", Value = state.autoSellEnabled, Callback = function(s)
        state.autoSellEnabled = s
        notify("Auto Jual", s and "Aktif." or "Nonaktif.")
        if s then task.spawn(autoSellLoop) end
    end})

    tab:Divider()
    tab:Toggle({Title = "Auto Quest (Theseus)", Value = state.autoQuestEnabled, Callback = function(s)
        state.autoQuestEnabled = s
        notify("Auto Quest", s and "Aktif." or "Nonaktif.")
        if s then task.spawn(autoQuestLoop) end
    end})

    tab:Button({Title = "Masak Zesty Lemon Fish", Callback = function()
        pcall(function()
            FISH_REMOTE:FireServer("CraftRecipe", "Zesty Lemon Fish")
            notify("Memasak", "Zesty Lemon Fish dibuat.")
        end)
    end})

    tab:Toggle({Title = "Sembunyikan GUI Mancing", Value = state.isGuiHidden, Callback = function(s)
        state.isGuiHidden = s
        local count = updateGuiVisibility(s)
        local statusText = s and "disembunyikan" or "ditampilkan"
        notify("Operasi Selesai", ("Berhasil mengubah %d elemen GUI menjadi %s."):format(count, statusText))
    end})
end

local function createTeleportTab(parent)
    local tab = parent:Tab({Title = "Teleportasi", Icon = "map-pin"})
    
    local locNames = {}
    for name in pairs(TELEPORT_LOCATIONS) do table.insert(locNames, name) end
    table.sort(locNames)
    local selectedLocation = locNames[1]
    tab:Dropdown({Title = "Pilih Lokasi", Values = locNames, Value = selectedLocation, Callback = function(val) selectedLocation = val end})
    tab:Button({Title = "Teleport ke Lokasi", Callback = function() teleportToLocation(selectedLocation) end})
    tab:Divider()

    local selectedNpc = NPC_LIST[1]
    tab:Dropdown({Title = "Pilih NPC", Values = NPC_LIST, Value = selectedNpc, Callback = function(val) selectedNpc = val end})
    tab:Button({Title = "Teleport ke NPC", Callback = function() teleportToNpc(selectedNpc) end})
    tab:Divider()

    local customNames = {}
    for name in pairs(CUSTOM_TELEPORT_LOCATIONS) do table.insert(customNames, name) end
    table.sort(customNames)
    local selectedCustom = customNames[1]
    tab:Dropdown({Title = "Lokasi Kustom", Values = customNames, Value = selectedCustom, Callback = function(val) selectedCustom = val end})
    tab:Button({Title = "Teleport ke Kustom", Callback = function() teleportToCFrame(CUSTOM_TELEPORT_LOCATIONS[selectedCustom], selectedCustom) end})
    tab:Divider()

    local selectedQuest = QUEST_ITEMS[1]
    tab:Dropdown({Title = "Item Quest", Values = QUEST_ITEMS, Value = selectedQuest, Callback = function(val) selectedQuest = val end})
    tab:Button({Title = "Teleport ke Item", Callback = function() teleportToItem(selectedQuest) end})
end

local function createPlayerTeleportTab(parent)
    local tab = parent:Tab({Title = "Teleport Player", Icon = "user-check"})
    local playerButtons = {}
    
    local function refreshPlayerList()
        for _, btn in pairs(playerButtons) do btn:Destroy() end
        table.clear(playerButtons)
        
        for _, p in ipairs(SERVICES.Players:GetPlayers()) do
            if p ~= LOCAL_PLAYER then
                playerButtons[p.Name] = tab:Button({
                    Title = p.DisplayName,
                    Callback = function()
                        pcall(function()
                            local target = SERVICES.Players:FindFirstChild(p.Name)
                            if not target then
                                notify("Gagal", "Player " .. p.Name .. " tidak ada.")
                                return
                            end
                            local myChar, targetChar = getCharacter(), target.Character
                            if myChar and targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                                myChar:PivotTo(targetChar.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0))
                                notify("Sukses", "Teleport ke " .. target.DisplayName)
                            else
                                notify("Gagal", "Karakter tidak valid.")
                            end
                        end)
                    end
                })
            end
        end
    end
    
    tab:Button({Title = "Refresh List", Icon = "refresh-cw", Color = Color3.fromHex("#38bdf8"), Callback = function()
        refreshPlayerList()
        notify("Player List", "Diperbarui.")
    end})
    tab:Divider()
    refreshPlayerList()
end

local function createUtilityTabs(parent)
    local spawnBoatTab = parent:Tab({Title = "Spawn Boat", Icon = "anchor"})
    local boatList = {"Bamboo Raft", "Raft", "Dinghy", "Jetski", "Fishing Boat", "Speed Boat", "Subski"}
    local selectedBoat = boatList[1]
    spawnBoatTab:Dropdown({Title = "Pilih Perahu", Values = boatList, Value = selectedBoat, Callback = function(val) selectedBoat = val end})
    spawnBoatTab:Button({Title = "Panggil Perahu", Callback = function()
        pcall(function()
            FISH_REMOTE:FireServer("SpawnBoat", selectedBoat)
            notify("Spawn Boat", selectedBoat .. " telah dipanggil.")
        end)
    end})

    local autoPetiTab = parent:Tab({Title = "Auto Peti", Icon = "archive"})
    autoPetiTab:Paragraph({Title = "Otomatis Buka Peti"})
    autoPetiTab:Slider({Title = "Jeda Buka Peti (Detik)", Value = {Min = 0.1, Max = 2, Default = CONFIG.CrateOpeningDelay}, Step = 0.1, Callback = function(v) CONFIG.CrateOpeningDelay = v end})
    autoPetiTab:Divider()
    local crateList = {"Basic Crate", "Advanced Crate", "Divine Crate", "Celestial Crate"}
    state.selectedCrate = crateList[1]
    autoPetiTab:Dropdown({Title = "Pilih Jenis Peti", Values = crateList, Value = state.selectedCrate, Callback = function(s) state.selectedCrate = s end})
    autoPetiTab:Toggle({Title = "Mulai Auto Buka Peti", Value = state.autoOpenActive, Callback = function(s)
        state.autoOpenActive = s
        if s then
            task.spawn(autoOpenLoop)
            notify("Auto Buka Peti", "Aktif untuk: " .. state.selectedCrate)
        else
            notify("Auto Buka Peti", "Nonaktif.")
        end
    end})
end

local function createShopTab(parent)
    local tab = parent:Tab({Title = "Shop", Icon = "shopping-cart"})
    local purchaseAmount = 1
    tab:Input({Title = "Jumlah Pembelian", Placeholder = "1", Callback = function(text)
        local n = tonumber(text)
        purchaseAmount = (n and n > 0) and math.floor(n) or 1
    end})
    tab:Divider()
    
    tab:Paragraph({Title = "Beli Totem"})
    local totems = { Night = "Night Totem", Day = "Day Totem", Rain = "Rain Totem", ["Blood Moon"] = "Blood Moon Totem" }
    for name, displayName in pairs(totems) do
        tab:Button({Title = "Beli " .. displayName, Callback = function()
            task.spawn(function()
                local remote = REMOTES:FindFirstChild("World")
                if not remote then return end
                for _ = 1, purchaseAmount do
                    pcall(function() remote:FireServer("Buy", name) end)
                    task.wait(0.3)
                end
            end)
        end})
    end
    
    tab:Divider()
    tab:Paragraph({Title = "Beli Crate"})
    local crates = {"Basic Crate", "Advanced Crate", "Divine Crate", "Celestial Crate"}
    for _, crateName in ipairs(crates) do
        tab:Button({Title = "Beli " .. crateName, Callback = function()
            task.spawn(function()
                local remote = REMOTES:FindFirstChild("Rod")
                if not remote then return end
                for _ = 1, purchaseAmount do
                    pcall(function() remote:FireServer({"BuyBaitCrate", crateName}) end)
                    task.wait(0.3)
                end
            end)
        end})
    end
end

local function createFishHolderTab(parent)
    local tab = parent:Tab({Title = "Fish Holder", Icon = "box"})
    local favSection = tab:Section({Title = "Favorite Actions"})
    local unfavSection = tab:Section({Title = "Unfavorite Actions"})
    local buttonTables = { favorite = {}, unfavorite = {} }

    local function performFavoriteAction(targetFishName, shouldBeFavorite)
        task.spawn(function()
            local fishHolder = PLAYER_GUI.Main.Inventory.FishHolder
            if not fishHolder then return end

            for _, fishObject in ipairs(fishHolder:GetChildren()) do
                if not targetFishName or fishObject.Name:find(targetFishName .. ":") then
                    local uuid = fishObject.Name:split(":")[2]
                    if uuid then
                        FISH_REMOTE:FireServer("FavoriteFish", uuid, shouldBeFavorite)
                        task.wait(0.05)
                    end
                end
            end
            PLAYER_GUI.Main.Inventory.Visible = false
            task.wait(0.1)
            notify("Selesai", (targetFishName or "semua ikan") .. " berhasil diproses.")
        end)
    end
    
    local function createFishButtons(section, btnTable, isFavoriteAction)
        for _, button in ipairs(btnTable) do pcall(function() button:Destroy() end) end
        table.clear(btnTable)

        local fishHolder = PLAYER_GUI.Main.Inventory.FishHolder
        if not fishHolder then notify("Error", "Inventory tidak ditemukan."); return end
        
        local fishCounts = {}
        for _, fishObject in ipairs(fishHolder:GetChildren()) do
            local fishName = fishObject.Name:split(":")[1]
            if fishName then fishCounts[fishName] = (fishCounts[fishName] or 0) + 1 end
        end
        
        local sortedNames = {}
        for name in pairs(fishCounts) do table.insert(sortedNames, name) end
        table.sort(sortedNames)
        
        if #sortedNames == 0 then notify("Inventory Scan", "Tidak ada ikan di inventory."); return end
        
        for _, name in ipairs(sortedNames) do
            local count = fishCounts[name]
            local btn = section:Button({Title = name .. " (" .. tostring(count) .. ")", Callback = function() performFavoriteAction(name, isFavoriteAction) end})
            table.insert(btnTable, btn)
        end
        notify("Inventory Scan", "Daftar berhasil diperbarui!")
    end

    favSection:Button({Title = "Refresh Favorite List", Icon = "refresh-cw", Color = Color3.fromHex("#38bdf8"), Callback = function() createFishButtons(favSection, buttonTables.favorite, true) end})
    unfavSection:Button({Title = "Refresh Unfavorite List", Icon = "refresh-cw", Color = Color3.fromHex("#38bdf8"), Callback = function() createFishButtons(unfavSection, buttonTables.unfavorite, false) end})
end

local function createEnchantTab(parent)
    local tab = parent:Tab({Title = "Auto Enchant", Icon = "sparkles"})
    local enchantStatus = tab:Paragraph({Title = "Status: IDLE"})
    tab:Divider()

    local artifactList = {}
    pcall(function() for _, v in ipairs(SERVICES.ReplicatedStorage.Assets.Artifact:GetChildren()) do table.insert(artifactList, v.Name) end end)
    table.sort(artifactList)
    if #artifactList > 0 then state.selectedArtifact = artifactList[1] end
    
    tab:Dropdown({Title = "Pilih Artifact", Values = artifactList, Value = state.selectedArtifact, Callback = function(val) state.selectedArtifact = val end})
    tab:Button({Title = "Enchant Manual (1x)", Callback = function()
        task.spawn(function()
            local fishHolder = PLAYER_GUI.Main.Inventory.FishHolder
            local artifactUUID
            for _, item in ipairs(fishHolder:GetChildren()) do
                if item.Name:find(state.selectedArtifact .. ":") then
                    artifactUUID = item.Name:split(":")[2]
                    break
                end
            end
            if artifactUUID then
                notify("Enchanting...", "Menggunakan 1x " .. state.selectedArtifact)
                local rodRemote = REMOTES:FindFirstChild("Rod")
                if rodRemote then rodRemote:FireServer({"EnchantRod", artifactUUID}) end
            else
                notify("Gagal", state.selectedArtifact .. " tidak ditemukan.")
            end
        end)
    end})
    tab:Divider()

    tab:Paragraph({Title = "Auto Enchant ke Target"})
    local enchantList = {"Quick", "Lightning", "Bubble", "Resilient", "HeavyPull", "Minty", "Controlled", "Knowledgable", "Variance", "Rare", "QuickCatch", "Lucky", "Leprechaun", "Marathon", "Longevity", "Heavy", "Mighty", "Colossal", "Chaos", "Golden"}
    table.sort(enchantList)
    
    tab:Dropdown({Title = "Pilih Enchant Target", Values = enchantList, Value = state.targetEnchant, Callback = function(s)
        state.targetEnchant = s
        notify("Target Diubah", "Target enchant: " .. s)
    end})
    uiElements.autoEnchantToggle = tab:Toggle({Title = "Mulai Auto Enchant", Value = state.autoEnchantActive, Callback = function(s)
        state.autoEnchantActive = s
        if s then task.spawn(function() autoEnchantLoop(enchantStatus) end) end
    end})
end

local function createMiscTab(parent)
    local tab = parent:Tab({Title = "MISC", Icon = "settings"})
    tab:Paragraph({Title = "Fitur Lain & Pengaturan"})
    tab:Divider()
    
    tab:Button({Title = "Salin Posisi & Arah (CFrame)", Callback = function()
        pcall(function()
            if not setclipboard then notify("Error", "Executor tidak mendukung setclipboard."); return end
            local char = getCharacter()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local cf = hrp.CFrame
                local cfs = string.format("CFrame.new(%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f)", cf:GetComponents())
                setclipboard(cfs)
                notify("Sukses", "CFrame karakter telah disalin.")
            else
                notify("Gagal", "Karakter tidak ditemukan.")
            end
        end)
    end})
    tab:Divider()
    
    tab:Button({Title = "Hapus Flag", Callback = function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "Flag" then pcall(function() obj:Destroy() end) end
        end
        notify("Operasi Selesai", "Semua 'Flag' dihapus.")
    end})
end

-- Initialize UI
createControlTab(MainSection)
createTeleportTab(MainSection)
createPlayerTeleportTab(MainSection)
createUtilityTabs(MainSection)
createShopTab(MainSection)
createFishHolderTab(MainSection)
createEnchantTab(MainSection)
createMiscTab(MainSection)

-- Initial setup
updateGuiVisibility(state.isGuiHidden)