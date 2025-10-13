local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local CONFIG = {
	STEEP_SLOPE_THRESHOLD = 5,
	MEDIUM_SLOPE_THRESHOLD = 2,
	STEEP_DURATION_MULTIPLIER = 0.25,
	MEDIUM_DURATION_MULTIPLIER = 0.5,
	MIN_SEGMENT_DURATION = 0.05,
	ROTATION_LERP_ALPHA = 0.2,
	DIRECTION_MAGNITUDE_THRESHOLD = 0.1,
	STEEP_HORIZONTAL_TIME_RATIO = 0.7,
	STEEP_VERTICAL_TIME_RATIO = 0.3,
}
local savedTracks = {}

local tracksURLs = {
	["sara1"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara1.json",
	["sara2"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara2.json",
	["sara3"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara3.json",
	["sara4"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara4.json",
	["sara5"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara5.json",
	["sara6"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara6.json",
	["sara7"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara7.json",
	["sara8"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara8.json",
	["sara9"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara9.json",
	["sara10"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara10.json",
	["sara11"] = "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sara/sara11.json",
}

local orderedTrackNames = {
	"sara1",
	"sara2",
	"sara3",
	"sara4",
	"sara5",
	"sara6",
	"sara7",
	"sara8",
	"sara9",
	"sara10",
	"sara11"
}

for _, name in ipairs(orderedTrackNames) do
	local success, data = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(tracksURLs[name]))
	end)

	if success and data and data.points then
		savedTracks[name] = {}
        for _, p in ipairs(data.points) do
        	local position = Vector3.new(p.pos[1], p.pos[2], p.pos[3])
        	table.insert(savedTracks[name], { pos = position, action = p.action or "walk" })
        end
	else
		warn("Failed to load track:", name)
		savedTracks[name] = {}
	end
end

local running = false
local isPaused = false
local bypassIsActive = false
local bypassConn

local resumeData = {
	trackName = nil,
	trackIndex = 1,
	pointIndex = 1,
	lastFlatDir = Vector3.new(0, 0, 1),
}

local function getHRP()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("HumanoidRootPart")
end

local function getCurrentPlayerSpeed()
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid.WalkSpeed
		end
	end
	return 16
end

local function restoreCharacterControl()
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
			humanoid:Move(Vector3.zero, false)
		end
	end
end

local stopAllTracks = function()
	running = false
	isPaused = false
	bypassIsActive = false
	restoreCharacterControl()
	resumeData = { trackName = nil, trackIndex = 1, pointIndex = 1, lastFlatDir = Vector3.new(0, 0, 1) }
end

local function executeTrackMovement(track, options)
	if not track or #track < 2 then
		return false
	end

	options = options or {}
	local startPointIndex = options.startPointIndex or 1
	if startPointIndex >= #track then
		return true
	end

	local hrp = getHRP()
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	humanoid.AutoRotate = false
	resumeData.lastFlatDir = options.lastDirection or resumeData.lastFlatDir

	local lastAction = "idle"
	local lastChangeTime = tick()

	for i = startPointIndex + 1, #track do
		if not running then
			resumeData.pointIndex = i - 1
			restoreCharacterControl()
			return false
		end

		-- 🧩 Ambil titik dari track
		local startPos = track[i - 1].pos
		local targetPos = track[i].pos
		local actionNow = track[i].action or "auto"

		-- 🧮 Hitung jarak dan kemiringan
		local distance = (targetPos - startPos).Magnitude
		local deltaY = targetPos.Y - startPos.Y
		local absDeltaY = math.abs(deltaY)
		local slope = math.deg(math.atan2(deltaY, distance))

		-- 🚶 Tentukan aksi sekarang
		local currentAction
		if actionNow == "auto" then
			if slope > 60 then
				currentAction = "jump"
			elseif slope > 30 then
				currentAction = "climb"
			elseif slope < -30 then
				currentAction = "fall"
			else
				currentAction = "walk"
			end
		else
			currentAction = actionNow
		end

		-- 🎬 Transisi halus (hindari spam animasi)
		if currentAction ~= lastAction and tick() - lastChangeTime > 0.3 then
			lastChangeTime = tick()
			lastAction = currentAction

			if currentAction == "jump" then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				humanoid:Move(Vector3.new(0, 1, 0), false)
			elseif currentAction == "climb" then
				humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
				humanoid:Move(Vector3.new(0, 1, 0), false)
			elseif currentAction == "fall" then
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			else
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
				humanoid:Move(resumeData.lastFlatDir, false)
			end
		end

		-- 🕒 Durasi perpindahan antar titik
		local currentPlayerSpeed = getCurrentPlayerSpeed()
		local duration = math.max(distance / currentPlayerSpeed, CONFIG.MIN_SEGMENT_DURATION)

		if absDeltaY > CONFIG.STEEP_SLOPE_THRESHOLD then
			duration *= CONFIG.STEEP_DURATION_MULTIPLIER
		elseif absDeltaY > CONFIG.MEDIUM_SLOPE_THRESHOLD then
			duration *= CONFIG.MEDIUM_DURATION_MULTIPLIER
		end

		local elapsed = 0
		while elapsed < duration and running do
			elapsed += RunService.Heartbeat:Wait()
			local t = math.clamp(elapsed / duration, 0, 1)
			local alpha

			-- 🧮 Kurva interpolasi vertikal
			if deltaY > CONFIG.MEDIUM_SLOPE_THRESHOLD then
				alpha = 1 - (1 - t) ^ 3
			elseif deltaY < -CONFIG.MEDIUM_SLOPE_THRESHOLD then
				alpha = t ^ 3
			else
				alpha = t
			end

			-- 🔄 Interpolasi posisi halus
			local currentPos
			if absDeltaY > CONFIG.STEEP_SLOPE_THRESHOLD then
				local t_h = math.clamp(elapsed / (duration * CONFIG.STEEP_HORIZONTAL_TIME_RATIO), 0, 1)
				local t_v = math.clamp(elapsed / (duration * CONFIG.STEEP_VERTICAL_TIME_RATIO), 0, 1)
				local horizPos = startPos:Lerp(Vector3.new(targetPos.X, startPos.Y, targetPos.Z), t_h)
				currentPos = Vector3.new(horizPos.X, startPos.Y + (targetPos.Y - startPos.Y) * t_v, horizPos.Z)
			else
				currentPos = startPos:Lerp(targetPos, alpha)
			end

			-- 🧭 Update arah terakhir
			local direction = Vector3.new(targetPos.X - startPos.X, 0, targetPos.Z - startPos.Z)
			if direction.Magnitude > CONFIG.DIRECTION_MAGNITUDE_THRESHOLD then
				resumeData.lastFlatDir = direction.Unit
			end

			-- 🌀 Gerakkan karakter
			local targetCFrame = CFrame.new(currentPos, currentPos + resumeData.lastFlatDir)
			local lerped = hrp.CFrame:Lerp(targetCFrame, CONFIG.ROTATION_LERP_ALPHA)
			hrp.CFrame = CFrame.new(currentPos) * (lerped - lerped.Position)

			-- 🔍 Debug visual lintasan
			if CONFIG.DEBUG_PATH then
				local part = Instance.new("Part")
				part.Anchored = true
				part.CanCollide = false
				part.Color = Color3.fromRGB(0, 255, 0)
				part.Material = Enum.Material.Neon
				part.Size = Vector3.new(0.1, 0.1, 0.1)
				part.Position = currentPos
				part.Parent = workspace
				game.Debris:AddItem(part, 1)
			end
		end
	end

	restoreCharacterControl()
	return true
end

local function resumeTrack()
	if not resumeData.trackName or not resumeData.trackIndex then
		return
	end

	for i = resumeData.trackIndex, #orderedTrackNames do
		if not running then
			break
		end

		local name = orderedTrackNames[i]
		resumeData.trackName = name
		resumeData.trackIndex = i

		local track = savedTracks[name]
		if track and #track > 1 then
			local options = {
				startPointIndex = resumeData.pointIndex,
				lastDirection = resumeData.lastFlatDir,
			}
			local success, finished = pcall(executeTrackMovement, track, options)
			if not success or not finished then
				break
			end
			resumeData.pointIndex = 1
		end
	end

	if running then
		stopAllTracks()
	end
end

local function runAutoSummitOnce()
	for idx, name in ipairs(orderedTrackNames) do
		if not running then
			break
		end

		resumeData.trackName = name
		resumeData.trackIndex = idx
		resumeData.pointIndex = 1

		local success, finished = pcall(executeTrackMovement, savedTracks[name])
		if not success or not finished then
			break
		end
	end

	if running then
		stopAllTracks()
	end
end

local function setupBypass(char)
	local humanoid = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")
	local lastPos = hrp.Position

	if bypassConn then
		bypassConn:Disconnect()
	end
	bypassConn = RunService.RenderStepped:Connect(function()
		if not hrp or not hrp.Parent then
			return
		end
		if bypassIsActive and running then
			local direction = hrp.Position - lastPos
			humanoid:Move(direction.Magnitude > 0.01 and direction.Unit or Vector3.zero, false)
		end
		lastPos = hrp.Position
	end)
end

player.CharacterAdded:Connect(function(char)
	setupBypass(char)
	task.wait(1)
	if not running then
		restoreCharacterControl()
	end
end)
if player.Character then
	setupBypass(player.Character)
end

local WindUI =
	(pcall(require, "./src/init")) and require("./src/init")
	or loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
	Title = "MT Yahayuk",
	Author = "WindUI Conversion",
	Folder = "mt_yahayuk_windui",
	NewElements = true,
	HideSearchBar = true,
	OpenButton = {
		Title = "MT Yahayuk",
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 0,
		Enabled = true,
		Draggable = true,
		OnlyMobile = false,
		Color = ColorSequence.new(Color3.fromHex("#30A6FF"), Color3.fromHex("#30FFB0")),
	},
})

local MainTab = Window:Tab({ Title = "Main", Icon = "play" })
local MainSection = MainTab:Section({ Title = "Controls" })

MainSection:Button({
	Title = "AUTO SUMMIT",
	Color = Color3.fromHex("#1E90FF"),
	Justify = "Center",
	Icon = "rocket",
	Callback = function()
		if running then
			return
		end
		running = true
		isPaused = false
		bypassIsActive = true
		task.spawn(runAutoSummitOnce)
	end,
})

MainSection:Space()

MainSection:Button({
	Title = "PAUSE/RESUME",
	Color = Color3.fromHex("#FF8C00"),
	Justify = "Center",
	Icon = "pause",
	Callback = function()
		if running then
			running = false
			isPaused = true
			bypassIsActive = false
			restoreCharacterControl()
		else
			if isPaused and resumeData.trackName then
				running = true
				isPaused = false
				bypassIsActive = true
				task.spawn(resumeTrack)
			end
		end
	end,
})

MainSection:Space()

MainSection:Button({
	Title = "STOP ALL",
	Color = Color3.fromHex("#FF3B30"),
	Justify = "Center",
	Icon = "x",
	Callback = stopAllTracks,
})

MainSection:Space()

-- [PERBAIKAN DIMULAI DI SINI]
local StatusSection = MainTab:Section({ Title = "Status" })

-- Menggunakan Input yang dikunci sebagai label status
local statusLabel = StatusSection:Input({
	Title = "State",
	Value = "Idle",
	Locked = true,
})

RunService.Heartbeat:Connect(function()
	local desc
	if running then
		desc = string.format(
			"Running - Track: %s Point: %d",
			tostring(resumeData.trackName or "N/A"),
			resumeData.pointIndex or 1
		)
	elseif isPaused then
		desc = string.format(
			"Paused - Last Track: %s Point: %d",
			tostring(resumeData.trackName or "N/A"),
			resumeData.pointIndex or 1
		)
	else
		desc = "Idle"
	end
    -- Memanggil :Set() pada elemen Input, yang didukung
	statusLabel:Set(desc)
end)

MainSection:Space()

-- ✅ Perbaikan akhir untuk "Mulai dari yang dekat" + stabilisasi aksi

MainSection:Button({
	Title = "MULAI DARI YANG DEKAT",
	Color = Color3.fromHex("#30FFB0"),
	Justify = "Center",
	Icon = "map-pin",
	Callback = function()
		if running then
			warn("Masih berjalan, hentikan dulu sebelum mulai dari yang dekat.")
			return
		end

		local hrp = getHRP()
		local playerPos = hrp.Position

		local nearestTrackName = nil
		local nearestTrackIndex = nil
		local nearestPointIndex = nil
		local nearestDist = math.huge

		-- ✅ Cari lintasan dan titik terdekat (fix: gunakan point.pos)
		for tIndex, name in ipairs(orderedTrackNames) do
			local track = savedTracks[name]
			for pIndex, point in ipairs(track) do
				if point and point.pos then
					local dist = (point.pos - playerPos).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearestTrackName = name
						nearestTrackIndex = tIndex
						nearestPointIndex = pIndex
					end
				end
			end
		end

		if not nearestTrackName then
			warn("Tidak ditemukan lintasan terdekat.")
			return
		end

		print(string.format(
			"Mulai dari lintasan %s di titik ke-%d (jarak %.2f)",
			nearestTrackName, nearestPointIndex, nearestDist
		))

		-- ✅ Set data resume agar bisa lanjut dari sana
		resumeData.trackName = nearestTrackName
		resumeData.trackIndex = nearestTrackIndex
		resumeData.pointIndex = nearestPointIndex
		resumeData.lastFlatDir = Vector3.new(0, 0, 1)

		-- ✅ Jalankan lintasan mulai dari titik terdekat
		running = true
		isPaused = false
		bypassIsActive = true

		task.spawn(resumeTrack)
	end,
})