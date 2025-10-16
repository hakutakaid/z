local ROUTE_URL = "https://raw.githubusercontent.com/hakutakaid/z/master/sara/sarafinal.lua"
local FRAME_TIME = 1 / 30

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local pathFrames = {}
local isExecuting = false
local animConn = nil
local isMoving = false
local toggleBtn

local function stopExecution()
	isExecuting = false
	isMoving = false
	if toggleBtn and toggleBtn.Parent then
		toggleBtn.Text = "▶️ Mulai"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 90)
	end
	print("Eksekusi dihentikan.")
end

local function muatPath()
	print("Mencoba memuat path dari URL...")
	local success, result = pcall(function()
		local source = game:HttpGet(ROUTE_URL)
		local chunk = loadstring(source)
		if chunk then
			local ok, data = pcall(chunk)
			if ok and typeof(data) == "table" then
				return data
			else
				error("Format file tidak valid.")
			end
		else
			error("loadstring() gagal mem-parsing file.")
		end
	end)

	if success and typeof(result) == "table" and #result > 0 then
		pathFrames = result
		print("✅ Path berhasil dimuat dengan", #pathFrames, "titik.")
		return true
	else
		warn("❌ Gagal memuat path! Cek URL, koneksi, atau izin executor.\nError:", tostring(result))
		return false
	end
end

local function cariTitikAwalTerdekat()
	if not hrp or #pathFrames < 1 then return 1 end
	local startIndex, minDistance = 1, math.huge
	local playerPos = hrp.Position

	for i, cf in ipairs(pathFrames) do
		local distance = (cf.Position - playerPos).Magnitude
		if distance < minDistance then
			minDistance = distance
			startIndex = i
		end
	end

	print("Memulai dari titik terdekat, indeks:", startIndex)
	return startIndex
end

local function setupMovement(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not root then return end

	if animConn then animConn:Disconnect() end

	local lastPos = root.Position
	local jumpCooldown = false

	animConn = RunService.RenderStepped:Connect(function()
		if not isMoving or not root or not root.Parent then return end
		if humanoid.Health <= 0 then
			if isExecuting then stopExecution() end
			return
		end

		local direction = root.Position - lastPos
		local dist = direction.Magnitude
		if dist > 0.01 then
			humanoid:Move(direction.Unit * math.clamp(dist * 5, 0, 1), false)
		else
			humanoid:Move(Vector3.zero, false)
		end

		local deltaY = root.Position.Y - lastPos.Y
		if deltaY > 0.9 and not jumpCooldown then
			humanoid.Jump = true
			jumpCooldown = true
			task.delay(0.4, function() jumpCooldown = false end)
		end

		lastPos = root.Position
	end)
end

local function executePath()
	if #pathFrames < 2 then 
		warn("Path tidak cukup panjang untuk dieksekusi.")
		return 
	end

	isExecuting = true
	isMoving = true
	if toggleBtn and toggleBtn.Parent then
		toggleBtn.Text = "⏹️ Berhenti"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
	end
	print("Memulai eksekusi path...")

	local startIndex = cariTitikAwalTerdekat()

	for i = startIndex, #pathFrames - 1 do
		if not isExecuting then break end
		local fromCF = pathFrames[i]
		local toCF = pathFrames[i + 1]
		local duration = FRAME_TIME
		local t = 0

		while t < duration do
			if not isExecuting then break end
			local dt = RunService.Heartbeat:Wait()

			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local speed = humanoid and humanoid.WalkSpeed or 16
			local KECEPATAN_EKSEKUSI = speed / 16

			t = t + (dt * KECEPATAN_EKSEKUSI)
			local alpha = math.min(t / duration, 1)
			if hrp and hrp.Parent then
				hrp.CFrame = fromCF:Lerp(toCF, alpha)
			end
		end
	end

	if isExecuting then
		print("✅ Eksekusi path selesai.")
		stopExecution()
	end
end

player.CharacterAdded:Connect(function(newChar)
	char = newChar
	hrp = newChar:WaitForChild("HumanoidRootPart")
	setupMovement(newChar)
	if isExecuting then stopExecution() end
end)
setupMovement(char)

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 120, 0, 35)
frame.Position = UDim2.new(0, 20, 1, -60)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
frame.BackgroundTransparency = 0.2
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", frame).Color = Color3.fromRGB(120, 90, 255)

toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(1, -10, 1, -10)
toggleBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
toggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Text = "Memuat..."
toggleBtn.TextSize = 14
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
toggleBtn.AutoButtonColor = false
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

toggleBtn.MouseEnter:Connect(function()
	TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
end)
toggleBtn.MouseLeave:Connect(function()
	TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
end)

toggleBtn.MouseButton1Click:Connect(function()
	if not toggleBtn.AutoButtonColor then return end
	if isExecuting then
		stopExecution()
	else
		task.spawn(executePath)
	end
end)

task.spawn(function()
	if muatPath() then
		toggleBtn.Text = "▶️ Mulai"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 90)
		toggleBtn.AutoButtonColor = true
	else
		toggleBtn.Text = "Gagal Muat!"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
	end
end)