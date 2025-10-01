local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

if game:GetService("CoreGui"):FindFirstChild("AutoFishGUI") then
	game:GetService("CoreGui").AutoFishGUI:Destroy()
end

local rodOptions = {"Basic Rod","Party Rod","Shark Rod","Piranha Rod","Flowers Rod","Thermo Rod","Trisula Rod","Feather Rod","Wave Rod","Duck Rod"}
local sellModes = {"All under 50 Kg","All under 100 Kg","All under 400 Kg","All under 600 Kg","All under 800 Kg","All under 1000 Kg","Sell this fish","Sell All"}

_G.AutoFishEnabled = false
_G.AutoSellEnabled = false
_G.AntiAFKEnabled = true
_G.SelectedRodName = rodOptions[1]
_G.SelectedSellMode = sellModes[1]
_G.SellInterval = 30
local running, globalReleaseFlag = false, false
local waitingBite, fishDetected = false, false

local REMOTE = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("RodRemoteEvent")
local SellRemote = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("SellItemRemoteFunction")

local function getRod(equipped)
	if not plr.Character then return end
	return equipped and plr.Character:FindFirstChild(_G.SelectedRodName) or plr.Backpack:FindFirstChild(_G.SelectedRodName)
end

local function forceEquipRod()
	local rod = getRod()
	if rod and plr.Character then
		local hum = plr.Character:FindFirstChild("Humanoid")
		if hum then pcall(function() hum:EquipTool(rod) end) end
		REMOTE:FireServer("Equipped", rod)
		return true
	end
	return false
end

local function unequipRod()
	if plr.Character then
		local hum = plr.Character:FindFirstChild("Humanoid")
		if hum then pcall(function() hum:UnequipTools() end) end
	end
end

local function throwRod()
	if getRod() then forceEquipRod() end
	local rod = getRod(true)
	if rod then
		REMOTE:FireServer(unpack({"Throw", rod, workspace:WaitForChild("Terrain")}))
		return true
	end
	return false
end

local function seekAndImmediateFollow(bars)
	local function getRedBar()
		for _, c in pairs(bars:GetChildren()) do
			if c:IsA("Frame") and c.Name == "RedBar" and c.Visible then return c end
		end
		return nil
	end
	
	local holded = false
    local whiteBar = bars:FindFirstChild("WhiteBar")
    
	task.spawn(function()
		while plr.PlayerGui:FindFirstChild("Reeling") and plr.PlayerGui.Reeling.Enabled do
			local red = getRedBar()
			if red and red.Visible and whiteBar then
				whiteBar.Position = red.Position
				whiteBar.Size = UDim2.new(red.Size.X.Scale, red.Size.X.Offset, whiteBar.Size.Y.Scale, whiteBar.Size.Y.Offset)
			else
				break
			end
			task.wait(0.005)
		end
	end)
	
	while plr.PlayerGui:FindFirstChild("Reeling") and plr.PlayerGui.Reeling.Enabled do
		local red = getRedBar()
		if red and red.Visible then
            local redCt = Vector2.new(red.AbsolutePosition.X + red.AbsoluteSize.X / 2, red.AbsolutePosition.Y + red.AbsoluteSize.Y / 2)
			VirtualInputManager:SendMouseButtonEvent(redCt.X, redCt.Y, 0, true, game, 1)
			holded = true
		else
			break
		end
		task.wait(0.01)
	end
	
	if holded then
		local red = getRedBar()
		if red then
            local redCt = Vector2.new(red.AbsolutePosition.X + red.AbsoluteSize.X / 2, red.AbsolutePosition.Y + red.AbsoluteSize.Y / 2)
			VirtualInputManager:SendMouseButtonEvent(redCt.X, redCt.Y, 0, false, game, 1)
		end
	end
	return true
end

local function setupBiteListener()
	REMOTE.OnClientEvent:Connect(function(action)
		if waitingBite and tostring(action):lower():find("reeling") then
			fishDetected = true
		end
	end)
end
setupBiteListener()

local function doSell()
    local mode = _G.SelectedSellMode
    if mode == "Sell this fish" then
        SellRemote:InvokeServer("SellFish")
    else
        SellRemote:InvokeServer("SellFish", mode)
    end
end

local function autoFishLoop(statElement)
    running = _G.AutoFishEnabled
    
	while running do
		statElement:SetTitle("Status: Standby | Anti-AFK: " .. (_G.AntiAFKEnabled and "ON" or "OFF"))
		task.wait(0.7)
		
		if not workspace:FindFirstChild("Pelampung-" .. plr.Name) then
			statElement:SetTitle("Status: Throw | Anti-AFK: " .. (_G.AntiAFKEnabled and "ON" or "OFF"))
			throwRod()
		end
		task.wait(0.38)
		
		statElement:SetTitle("Status: Wait Fish Bait | Anti-AFK: " .. (_G.AntiAFKEnabled and "ON" or "OFF"))
		waitingBite, fishDetected = true, false
		local t0 = tick()
		while running and not fishDetected and (tick() - t0 < 35) do
			task.wait(0.22)
			if not workspace:FindFirstChild("Pelampung-" .. plr.Name) then
				throwRod()
			end
			statElement:SetTitle("Status: Wait Fish Bait... " .. math.floor(tick() - t0) .. "s | Anti-AFK: " .. (_G.AntiAFKEnabled and "ON" or "OFF"))
            running = _G.AutoFishEnabled
		end
		waitingBite = false
		if not running then break end
		
		if not fishDetected then
			statElement:SetTitle("Status: Timeout, retry | Anti-AFK: " .. (_G.AntiAFKEnabled and "ON" or "OFF"))
			task.wait(1.1)
		else
			statElement:SetTitle("Status: Perfect Overlap | Anti-AFK: " .. (_G.AntiAFKEnabled and "ON" or "OFF"))
            local reelingGui = plr.PlayerGui:FindFirstChild("Reeling")
			local bars = reelingGui and reelingGui.Frame and reelingGui.Frame:FindFirstChild("Frame")
            
			while reelingGui and reelingGui.Enabled and not globalReleaseFlag do
				if bars and bars:FindFirstChild("WhiteBar") and bars.WhiteBar.Visible then
					seekAndImmediateFollow(bars)
					break
				end
				if not running or not reelingGui.Enabled then break end
				task.wait(0.01)
			end
		end
		
		statElement:SetTitle("Status: Standby | Anti-AFK: " .. (_G.AntiAFKEnabled and "ON" or "OFF"))
		fishDetected = false
		task.wait(0.7)
        running = _G.AutoFishEnabled
	end
    
	statElement:SetTitle("Status: Standby | Anti-AFK: " .. (_G.AntiAFKEnabled and "ON" or "OFF"))
	waitingBite = false
	fishDetected = false
    unequipRod()
end

local function autoSellLoop()
    task.spawn(function()
        while _G.AutoSellEnabled do
            doSell()
            local n = tonumber(_G.SellInterval)
            n = (n and n >= 2) and n or 30
            for i = 1, n do
                if not _G.AutoSellEnabled then break end
                task.wait(1)
            end
        end
    end)
end

task.spawn(function()
	while task.wait(120) do
		if _G.AntiAFKEnabled and plr.Character then
			local humanoid = plr.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end
end)

local Window = WindUI:CreateWindow({
    Title = "AutoFish",
    Author = "HakutakaID",
    Size = UDim2.fromOffset(450, 450),
    OpenButton = {
        Title = "Open Auto Fish UI",
        Enabled = true,
        Color = ColorSequence.new(Color3.fromHex("#14D3FF"), Color3.fromHex("#FF8930"))
    }
})

local MainSection = Window:Section({
    Title = "Farming Automation",
    Icon = "anchor",
    Opened = true
})

do
    local FishTab = MainSection:Tab({ Title = "Auto Fishing", Icon = "fish" })
    
    local statElement = FishTab:Paragraph({
        Title = "Status: Standby | Anti-AFK: ON",
        Desc = "Menampilkan status loop Auto Fish saat ini.",
        TextColor = Color3.fromHex("#ADFFB9"),
        TextSize = 14,
        TextTransparency = 0.1,
    })

    FishTab:Divider()

    FishTab:Dropdown({
        Title = "Pilih Joran",
        Desc = "Pilih joran yang akan digunakan untuk memancing.",
        Values = rodOptions,
        Value = _G.SelectedRodName,
        Callback = function(rod, index)
            _G.SelectedRodName = rod
            WindUI:Notify({ Title = "Joran", Content = "Joran diatur ke: " .. rod })
        end
    })

    FishTab:Toggle({
        Title = "Auto Fish (Reeling Included)",
        Desc = "Aktifkan/Matikan loop Auto Fish.",
        Value = _G.AutoFishEnabled,
        Callback = function(state)
            _G.AutoFishEnabled = state
            if state then
                globalReleaseFlag = false
                task.spawn(autoFishLoop, statElement)
                statElement:SetTitle("Status: Starting... | Anti-AFK: " .. (_G.AntiAFKEnabled and "ON" or "OFF"))
            else
                globalReleaseFlag = true
                statElement:SetTitle("Status: Stopping... | Anti-AFK: " .. (_G.AntiAFKEnabled and "ON" or "OFF"))
            end
        end
    })

    FishTab:Button({
        Title = "Open Rod Shop",
        Desc = "Membuka GUI Rod Shop game.",
        Color = Color3.fromHex("#FFA07A"), 
        Icon = "cart",
        Callback = function()
            local rodShopGui = plr.PlayerGui:FindFirstChild("RodShop")
            if rodShopGui then
                rodShopGui.Enabled = true
                WindUI:Notify({ Title = "Shop", Content = "Rod Shop berhasil dibuka!" })
            else
                WindUI:Notify({ Title = "Shop Error", Content = "Rod Shop GUI tidak ditemukan." })
            end
        end
    })
end

do
    local SellTab = MainSection:Tab({ Title = "Sell & Utility", Icon = "settings" })

    SellTab:Toggle({
        Title = "Anti-AFK",
        Desc = "Mencegah Anda ter-kick dari server.",
        Value = _G.AntiAFKEnabled,
        Callback = function(state)
            _G.AntiAFKEnabled = state
        end
    })
    
    SellTab:Divider()

    SellTab:Dropdown({
        Title = "Mode Auto Sell",
        Desc = "Pilih kriteria ikan yang akan dijual.",
        Values = sellModes,
        Value = _G.SelectedSellMode,
        Callback = function(mode)
            _G.SelectedSellMode = mode
            WindUI:Notify({ Title = "Mode Jual", Content = "Mode jual diatur ke: " .. mode })
        end
    })
    
    SellTab:Input({
        Title = "Interval Jual (Detik)",
        Desc = "Waktu tunggu antara setiap aksi jual. Minimal 2 detik.",
        Value = _G.SellInterval,
        Type = "Number",
        Callback = function(value)
            _G.SellInterval = math.max(2, tonumber(value) or 30)
        end
    })

    SellTab:Toggle({
        Title = "Enable Auto Sell",
        Desc = "Aktifkan/Matikan loop penjualan otomatis.",
        Value = _G.AutoSellEnabled,
        Callback = function(state)
            _G.AutoSellEnabled = state
            if state then
                autoSellLoop()
                WindUI:Notify({ Title = "Auto Sell", Content = "Auto Sell diaktifkan." })
            else
                WindUI:Notify({ Title = "Auto Sell", Content = "Auto Sell dimatikan." })
            end
        end
    })

    SellTab:Button({
        Title = "Jual Sekarang (Manual)",
        Desc = "Menjual ikan sesuai Mode yang dipilih.",
        Color = Color3.fromHex("#30ff6a"),
        Icon = "dollar-sign",
        Callback = function()
            doSell()
            WindUI:Notify({ Title = "Jual Manual", Content = "Ikan berhasil dijual sesuai mode: " .. _G.SelectedSellMode })
        end
    })
end
