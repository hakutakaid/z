-- Load WindUI
-- local WindUI
-- do
    -- local ok, result = pcall(function()
        -- return require("./src/init")
    -- end)
    -- if ok then
        -- WindUI = result
    -- else
WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    -- end
-- end

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local ROUTE_LIST = {
    ["Mount Hikari"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/MOUNT/DATABASE/MThikari.lua",
    ["Mount Yahayuk"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/MOUNT/DATABASE/YHY.lua",
}

local SELECTED_ROUTE
local ROUTE_URL
local pathFrames = {}
local isExecuting = false
local KECEPATAN_EKSEKUSI = 1

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

------------------------------------------------------------
-- ANIMASI GERAK (seperti versi lama)
------------------------------------------------------------
local animConn
local isMoving = false

local function setupMovement(character)
	local hum = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	if animConn then animConn:Disconnect() end
	
	local lastPos = root.Position
	local jumpCooldown = false

	animConn = RunService.RenderStepped:Connect(function()
		if not isMoving or not root or not root.Parent then return end
		if hum.Health <= 0 then
			isExecuting = false
			isMoving = false
			return
		end

		local direction = root.Position - lastPos
		local dist = direction.Magnitude

		-- Simulasi langkah karakter
		if dist > 0.01 then
			hum:Move(direction.Unit * math.clamp(dist * 5, 0, 1), false)
		else
			hum:Move(Vector3.zero, false)
		end

		-- Simulasi loncat jika beda tinggi
		local deltaY = root.Position.Y - lastPos.Y
		if deltaY > 0.9 and not jumpCooldown then
			hum.Jump = true
			jumpCooldown = true
			task.delay(0.4, function() jumpCooldown = false end)
		end

		lastPos = root.Position
	end)
end

setupMovement(char)
player.CharacterAdded:Connect(function(c)
	char = c
	hrp = c:WaitForChild("HumanoidRootPart")
	humanoid = c:WaitForChild("Humanoid")
	setupMovement(c)
	if isExecuting then isExecuting = false end
end)

------------------------------------------------------------
-- FUNGSI EKSEKUSI ROUTE
------------------------------------------------------------
local function stopExecution()
	isExecuting = false
	isMoving = false
end

local function muatPath(url)
	local success, result = pcall(function()
		local source = game:HttpGet(url)
		local chunk = loadstring(source)
		if chunk then
			local ok, data = pcall(chunk)
			if ok and typeof(data) == "table" then
				return data
			end
		end
		error("Format tidak valid.")
	end)

	if success then
		pathFrames = result
		return true
	else
		warn(result)
		return false
	end
end

local function cariTitikAwalTerdekat()
	if not hrp or #pathFrames == 0 then return 1 end
	local idx, minDist = 1, math.huge
	for i, cf in ipairs(pathFrames) do
		local dist = (cf.Position - hrp.Position).Magnitude
		if dist < minDist then
			minDist = dist
			idx = i
		end
	end
	return idx
end

local function executePath()
	if #pathFrames < 2 then return end
	isExecuting = true
	isMoving = true

	local FRAME_TIME = 1 / 30
	local start = cariTitikAwalTerdekat()

	for i = start, #pathFrames - 1 do
		if not isExecuting then break end
		local fromCF, toCF = pathFrames[i], pathFrames[i + 1]
		local t, dur = 0, FRAME_TIME / KECEPATAN_EKSEKUSI
		while t < dur do
			if not isExecuting then break end
			t += RunService.Heartbeat:Wait()
			local alpha = math.clamp(t / dur, 0, 1)
			if hrp then
				hrp.CFrame = fromCF:Lerp(toCF, alpha)
			end
		end
	end

	isExecuting = false
	isMoving = false
end

------------------------------------------------------------
-- WINDUI WINDOW
------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "🏔️ Route Executor",
    Author = "Hakutakaid",
    Folder = "RouteBot",
    NewElements = true,
    HideSearchBar = true,
    OpenButton = {
        Title = "Open Route Executor",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"),
            Color3.fromHex("#e7ff2f")
        )
    }
})

------------------------------------------------------------
-- SECTION & TAB
------------------------------------------------------------
local RouteSection = Window:Section({
    Title = "Auto Walk Mount",
    Icon = "map"
})

local ControlTab = RouteSection:Tab({
    Title = "Main Controls",
    Icon = "play"
})

------------------------------------------------------------
-- Dropdown Route
------------------------------------------------------------
ControlTab:Dropdown({
    Flag = "SelectedRoute",
    Title = "Pilih Route",
    Desc = "Pilih lokasi mount",
    Values = (function()
        local t = {}
        for k in pairs(ROUTE_LIST) do table.insert(t, k) end
        return t
    end)(),
    Value = nil,
    Callback = function(option)
        SELECTED_ROUTE = option
        ROUTE_URL = ROUTE_LIST[option]
        if muatPath(ROUTE_URL) then
            WindUI:Notify({
                Title = "✅ Route Loaded",
                Content = option,
            })
        else
            WindUI:Notify({
                Title = "❌ Failed to Load Route",
                Content = option,
            })
        end
    end
})

------------------------------------------------------------
-- Slider Kecepatan
------------------------------------------------------------
ControlTab:Slider({
    Flag = "SpeedExec",
    Title = "Kecepatan Eksekusi",
    Step = 0.1,
    Value = {
        Min = 0.5,
        Max = 3,
        Default = 1,
    },
    Callback = function(value)
        KECEPATAN_EKSEKUSI = value
    end
})

------------------------------------------------------------
-- Tombol Eksekusi
------------------------------------------------------------
ControlTab:Button({
    Title = "▶️ Mulai / Stop",
    Color = Color3.fromHex("#305dff"),
    Callback = function()
        if not SELECTED_ROUTE then
            WindUI:Notify({
                Title = "⚠️ Pilih route dulu",
                Content = "Kamu belum memilih route",
            })
            return
        end
        if isExecuting then
            stopExecution()
            WindUI:Notify({
                Title = "⏹️ Dihentikan",
                Content = "Eksekusi route dihentikan.",
            })
        else
            task.spawn(executePath)
            WindUI:Notify({
                Title = "🚶‍♂️ Jalan dimulai...",
                Content = SELECTED_ROUTE,
            })
        end
    end
})