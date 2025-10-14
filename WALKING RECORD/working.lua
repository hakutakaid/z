-- WataX Script
-- Logika Asli 100% dipertahankan, GUI direfactor dengan WindUI

--[[ Services & Initial Setup ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local player = Players.LocalPlayer
local hrp

--[[ Route Loading (Logika Asli Anda) ]]
local ROUTE_LINKS = {
    "https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/TEA/yahayuk.lua",
}
local routes = {}
for i, link in ipairs(ROUTE_LINKS) do
    if link ~= "" then
        local ok, data = pcall(function() return loadstring(game:HttpGet(link))() end)
        if ok and typeof(data) == "table" and #data > 0 then
            table.insert(routes, {"Route "..i, data})
        end
    end
end
if #routes == 0 then
    WindUI:Notify({Title = "WataX Error", Content = "Tidak ada rute valid yang ditemukan.", Icon = "alert-triangle"})
    return
end

--[[ Character & Movement Logic (Logika Asli Anda - TIDAK DIUBAH) ]]
local animConn
local isMoving = false
local frameTime = 1/32
local playbackRate = 1
local isReplayRunning = false
local triggeredCP = {} 
local lastReplayPos = nil
local lastReplayIndex = 1
local CP_COOLDOWN = 25 

local function refreshHRP(char)
    if not char then char = player.Character or player.CharacterAdded:Wait() end
    hrp = char:WaitForChild("HumanoidRootPart")
end

local function setupMovement(char)
    task.spawn(function()
        if not char then char = player.Character or player.CharacterAdded:Wait() end
        local humanoid = char:WaitForChild("Humanoid", 5)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not root then return end

        humanoid.Died:Connect(function()
            WindUI:Notify({Title = "WataX", Content = "Karakter mati, replay berhenti.", Icon = "skull"})
            isReplayRunning = false
            stopMovement()
        end)

        if animConn then animConn:Disconnect() end
        local lastPos = root.Position
        local jumpCooldown = false

        animConn = RunService.RenderStepped:Connect(function()
            if not isMoving or not hrp or not hrp.Parent or not humanoid or humanoid.Health <= 0 then return end
            
            local direction = root.Position - lastPos
            local dist = direction.Magnitude
            if dist > 0.01 then
                humanoid:Move(direction.Unit * math.clamp(dist * 5, 0, 1), false)
            else
                humanoid:Move(Vector3.zero, false)
            end

            if root.Position.Y - lastPos.Y > 0.9 and not jumpCooldown then
                humanoid.Jump = true
                jumpCooldown = true
                task.delay(0.4, function() jumpCooldown = false end)
            end
            lastPos = root.Position
        end)
    end)
end

local function startMovement() isMoving = true end
local function stopMovement() isMoving = false end

--[[ Route Adjustment & Calculation (Logika Asli Anda - TIDAK DIUBAH) ]]
local function getCurrentHeight()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    return humanoid.HipHeight + (char:FindFirstChild("Head") and char.Head.Size.Y or 2)
end

-- Hitung DEFAULT_HEIGHT otomatis dari karakter pemain
local function getDefaultHeight()
    local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local head = char:FindFirstChild("Head")
    if head then
        return humanoid.HipHeight + head.Size.Y
    else
        return humanoid.HipHeight + 2 -- fallback
    end
end

local DEFAULT_HEIGHT = getDefaultHeight() -- sekarang otomatis

local function adjustRoute(frames)
    local adjusted = {}
    local offsetY = getDefaultHeight() - DEFAULT_HEIGHT -- selalu update tinggi asli
    for _, cf in ipairs(frames) do
        local pos = cf.Position
        local rotX, rotY, rotZ = cf:ToOrientation()
        table.insert(adjusted, CFrame.new(pos.X, pos.Y + offsetY, pos.Z) * CFrame.Angles(rotX, rotY, rotZ))
    end
    return adjusted
end


for i, data in ipairs(routes) do
    data[2] = adjustRoute(data[2])
end

local function getNearestRoute()
    local nearestIdx, dist = 1, math.huge
    if hrp then
        local pos = hrp.Position
        for i, data in ipairs(routes) do
            for _, cf in ipairs(data[2]) do
                local d = (cf.Position - pos).Magnitude
                if d < dist then dist = d; nearestIdx = i end
            end
        end
    end
    return nearestIdx
end

local function getNearestFrameIndex(frames)
    local startIdx, dist = 1, math.huge
    if hrp then
        local pos = hrp.Position
        for i, cf in ipairs(frames) do
            local d = (cf.Position - pos).Magnitude
            if d < dist then dist = d; startIdx = i end
        end
    end
    if startIdx >= #frames then startIdx = math.max(1, #frames - 1) end
    return startIdx
end

local function lerpCF(fromCF, toCF)
    local duration = frameTime / math.max(0.05, playbackRate)
    local startTime = os.clock()
    local t = 0
    while t < duration and isReplayRunning do
        RunService.Heartbeat:Wait()
        t = os.clock() - startTime
        local alpha = math.min(t / duration, 1)
        if hrp and hrp.Parent and hrp:IsDescendantOf(workspace) then
            hrp.CFrame = fromCF:Lerp(toCF, alpha)
        end
    end
end

local function walkTo(targetPos)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not hrp then return end
    local path = PathfindingService:CreatePath()
    path:ComputeAsync(hrp.Position, targetPos)
    local waypoints = path:GetWaypoints()
    for _, waypoint in ipairs(waypoints) do
        if not humanoid or humanoid.Health <= 0 then break end
        humanoid:MoveTo(waypoint.Position)
        humanoid.MoveToFinished:Wait()
    end
end

local function findNearestCP(radius)
    if not hrp then return nil end
    local nearest, dist = nil, radius
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "cp" then
            local d = (part.Position - hrp.Position).Magnitude
            local size = part.Size.Magnitude / 2
            if d < dist + size then
                local lastTriggered = triggeredCP[part]
                if not lastTriggered or tick() - lastTriggered >= CP_COOLDOWN then
                    dist = d
                    nearest = part
                end
            end
        end
    end
    return nearest
end

local function runRoute(startIdx)
    if #routes == 0 then return end
    if not hrp then refreshHRP() end
    isReplayRunning = true
    startMovement()
    local idx = getNearestRoute()
    local frames = routes[idx][2]
    if #frames < 2 then isReplayRunning = false; stopMovement(); return end
    local sIdx = startIdx or getNearestFrameIndex(frames)
    for i = sIdx, #frames - 1 do
        if not isReplayRunning then break end
        lastReplayIndex = i
        lastReplayPos = frames[i].Position
        lerpCF(frames[i], frames[i + 1])
    end
    isReplayRunning = false
    stopMovement()
end

local function stopRoute()
    if not isReplayRunning then return end
    isReplayRunning = false
    stopMovement()
end

task.spawn(function()
    while task.wait(0.3) do
        if isReplayRunning and hrp then
            local cp = findNearestCP(15)
            if cp then
                triggeredCP[cp] = tick()
                WindUI:Notify({Title = "WataX", Content = "CP Terdeteksi, cooldown " .. CP_COOLDOWN .. " detik...", Icon = "flag"})
                isReplayRunning = false
                stopMovement()
                task.spawn(function()
                    walkTo(cp.Position)
                    task.wait(0.2)
                    if lastReplayPos then walkTo(lastReplayPos) end
                    WindUI:Notify({Title = "WataX", Content = "Melanjutkan replay...", Icon = "play"})
                    task.wait(0.2)
                    runRoute(lastReplayIndex)
                end)
            end
        end
    end
end)

--[[ WindUI Implementation ]]
local Window = WindUI:CreateWindow({
    Title = "WataX Script",
    Author = "Route Player",
    Folder = "WataX"
})

local MainTab = Window:Tab({ Title = "Controls", Icon = "gamepad-2" })
local controlSection = MainTab:Section({ Title = "Main Controls" })

-- Tombol Start Terpisah
controlSection:Button({
    Title = "▶️ Start",
    Icon = "play",
    Color = Color3.fromHex("#30FF6A"),
    Callback = function()
        if isReplayRunning then
            WindUI:Notify({ Title = "Info", Content = "Rute sudah berjalan.", Icon = "info" })
            return
        end
        WindUI:Notify({ Title = "WataX", Content = "Memulai rute...", Icon = "play" })
        task.spawn(runRoute)
    end
})

-- Tombol Stop Terpisah
controlSection:Button({
    Title = "⏹️ Stop",
    Icon = "square",
    Color = Color3.fromHex("#ff4830"),
    Callback = function()
        if not isReplayRunning then
            WindUI:Notify({ Title = "Info", Content = "Tidak ada rute yang sedang berjalan.", Icon = "info" })
            return
        end
        WindUI:Notify({ Title = "WataX", Content = "Rute dihentikan.", Icon = "stop-circle" })
        stopRoute()
    end
})

-- Kontrol Kecepatan (Slider adalah cara modern di WindUI)
controlSection:Slider({
    Title = "Playback Speed",
    Desc = "Atur kecepatan pemutaran rute",
    Value = {
        Min = 0.25,
        Max = 3,
        Default = 1,
    },
    Step = 0.25,
    Callback = function(value)
        playbackRate = value -- Variabel ini dari skrip asli Anda
    end
})

--[[ Character Event Handling (Logika Asli Anda) ]]
local function onCharacter(char)
    refreshHRP(char)
    setupMovement(char)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then
    onCharacter(player.Character)
end