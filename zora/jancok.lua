-- ✅ WindUI Path Recorder (Fully Working 2025 Fix + Pause/Resume)

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local isRecording = false
local isPaused = false
local recordedPoints = {}
local lastPosition = nil
local connection = nil
local trackName = "JalurBaru"

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

repeat task.wait() until WindUI and WindUI.CreateWindow

-- Fungsi reset
local function resetRecording()
	recordedPoints = {}
	lastPosition = nil
end

-- Fungsi simpan JSON
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
		table.insert(points, { p.X, p.Y, p.Z })
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

-- Buat window utama
local Window = WindUI:CreateWindow({
	Title = "🛰️ Path Recorder",
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

-- Input nama jalur
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

-- Tombol MULAI
Tab:Button({
	Title = "▶️ MULAI REKAM",
	Color = Color3.fromRGB(0, 200, 100),
	Icon = "circle",
	Callback = function()
		if isRecording then return end
		resetRecording()
		isRecording = true
		isPaused = false
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
				table.insert(recordedPoints, pos)
				lastPosition = pos
			end
		end)
	end,
})

-- Tombol JEDA
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

-- Tombol LANJUT
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

-- Tombol STOP & SIMPAN
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
		savePath(trackName)
		resetRecording()
	end,
})

-- Tombol BATAL
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
		resetRecording()
		WindUI:Notify({
			Title = "⛔ Rekaman Dibatalkan",
			Content = "Semua titik dihapus.",
			Icon = "x",
		})
	end,
})