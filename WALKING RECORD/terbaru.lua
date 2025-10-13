local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local isRecording = false
local isPaused = false
local recordedPoints = {}
local lastPosition = nil
local connection = nil
local stateConnection = nil
local velocityCheck = nil
local currentAction = "walk"
local trackName = "JalurBaru"

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
repeat task.wait() until WindUI and WindUI.CreateWindow

local function resetRecording()
	recordedPoints = {}
	lastPosition = nil
	currentAction = "walk"
end

local function savePath(name)
	if #recordedPoints < 2 then
		WindUI:Notify({
			Title = "⚠️ Gagal Menyimpan",
			Content = "Jumlah titik terlalu sedikit.",
			Icon = "alert-triangle",
		})
		return
	end
	local points = {}
	for _, p in ipairs(recordedPoints) do
		table.insert(points, { pos = { p.pos.X, p.pos.Y, p.pos.Z }, action = p.action })
	end
	local data = { name = name, points = points }
	local json = HttpService:JSONEncode(data)
	local filename = name .. ".json"
	writefile(filename, json)
	WindUI:Notify({
		Title = "✅ Disimpan",
		Content = "File: " .. filename,
		Icon = "save",
	})
end

local function setupStateDetection(humanoid)
	if stateConnection then
		stateConnection:Disconnect()
	end
	stateConnection = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			currentAction = "jump"
		elseif newState == Enum.HumanoidStateType.Climbing then
			currentAction = "climb"
		elseif newState == Enum.HumanoidStateType.Freefall then
			currentAction = "fall"
		elseif newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics then
			currentAction = "walk"
		elseif newState == Enum.HumanoidStateType.Landed then
			currentAction = "land"
		end
	end)
end

local function setupVelocityDetection(char)
	if velocityCheck then
		velocityCheck:Disconnect()
	end
	local hrp = char:WaitForChild("HumanoidRootPart")
	local humanoid = char:WaitForChild("Humanoid")
	velocityCheck = RunService.Heartbeat:Connect(function()
		if not isRecording or isPaused then return end
		if not hrp or not humanoid then return end
		local yVel = hrp.Velocity.Y
		if yVel > 25 and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
			currentAction = "jump"
		elseif yVel < -25 and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
			currentAction = "fall"
		elseif math.abs(yVel) < 2 and humanoid:GetState() == Enum.HumanoidStateType.Landed then
			currentAction = "land"
		end
	end)
end

local Window = WindUI:CreateWindow({
	Title = "🛰️ Smart Path Recorder",
	Author = "by lutfi",
	HideSearchBar = true,
	Folder = "PathRecorder",
	OpenButton = {
		Title = "Open Path Recorder",
		Enabled = true,
		Color = ColorSequence.new(Color3.fromRGB(50, 255, 106), Color3.fromRGB(231, 255, 47)),
	},
})

local Tab = Window:Tab({
	Title = "Rekaman",
	Icon = "record-circle",
})

local Input = Tab:Input({
	Title = "Nama Jalur",
	Desc = "Masukkan nama file jalur",
	Value = trackName,
	InputIcon = "file-pen-line",
	Type = "Input",
	Placeholder = "contoh: JalurGunung",
	Callback = function(v)
		trackName = v ~= "" and v or "JalurTanpaNama"
	end,
})

Tab:Button({
	Title = "▶️ MULAI REKAM",
	Color = Color3.fromRGB(0, 200, 100),
	Icon = "circle",
	Callback = function()
		if isRecording then return end
		resetRecording()
		isRecording = true
		isPaused = false
		local char = player.Character or player.CharacterAdded:Wait()
		local humanoid = char:WaitForChild("Humanoid")
		setupStateDetection(humanoid)
		setupVelocityDetection(char)
		WindUI:Notify({
			Title = "⏺️ Rekaman Dimulai",
			Content = "Merekam jalur: " .. trackName,
			Icon = "record-circle",
		})
		connection = RunService.Heartbeat:Connect(function()
			if not isRecording or isPaused then return end
			local char = player.Character
			if not char or not char.PrimaryPart then return end
			local pos = char.PrimaryPart.Position
			if not lastPosition or (pos - lastPosition).Magnitude > 3 then
				table.insert(recordedPoints, { pos = pos, action = currentAction })
				lastPosition = pos
			end
		end)
	end,
})

Tab:Button({
	Title = "⏸️ JEDA REKAMAN",
	Color = Color3.fromRGB(255, 170, 0),
	Icon = "pause",
	Callback = function()
		if not isRecording or isPaused then return end
		isPaused = true
		WindUI:Notify({
			Title = "⏸️ Rekaman Dijeda",
			Content = "Rekaman dihentikan sementara. Titik tersimpan: " .. #recordedPoints,
			Icon = "pause",
		})
	end,
})

Tab:Button({
	Title = "▶️ LANJUTKAN",
	Color = Color3.fromRGB(80, 200, 255),
	Icon = "play",
	Callback = function()
		if not isRecording or not isPaused then return end
		isPaused = false
		WindUI:Notify({
			Title = "▶️ Lanjut Merekam",
			Content = "Melanjutkan dari titik ke-" .. #recordedPoints,
			Icon = "play",
		})
	end,
})

Tab:Button({
	Title = "💾 STOP & SIMPAN",
	Color = Color3.fromRGB(200, 50, 50),
	Icon = "save",
	Callback = function()
		if not isRecording then return end
		isRecording = false
		isPaused = false
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if stateConnection then
			stateConnection:Disconnect()
			stateConnection = nil
		end
		if velocityCheck then
			velocityCheck:Disconnect()
			velocityCheck = nil
		end
		savePath(trackName)
		resetRecording()
	end,
})

Tab:Button({
	Title = "❎ BATALKAN",
	Color = Color3.fromRGB(255, 180, 0),
	Icon = "x",
	Callback = function()
		if not isRecording then return end
		isRecording = false
		isPaused = false
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if stateConnection then
			stateConnection:Disconnect()
			stateConnection = nil
		end
		if velocityCheck then
			velocityCheck:Disconnect()
			velocityCheck = nil
		end
		resetRecording()
		WindUI:Notify({
			Title = "⛔ Rekaman Dibatalkan",
			Content = "Semua titik dihapus.",
			Icon = "x",
		})
	end,
})