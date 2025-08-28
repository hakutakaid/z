-- Services
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local hrp

-- Setup HRP
local function setupHRP(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end

-- Force Respawn
local function forceRespawn(callback)
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        plr.Character:BreakJoints()
        local newChar = plr.CharacterAdded:Wait()
        setupHRP(newChar)
        if callback then callback() end
    end
end

-- Daftar checkpoint + delay
local checkpoints = {
    {pos = Vector3.new(-621.7, 251.7, -383.9), delay = 30},   -- CP1 → CP2 (30s)
    {pos = Vector3.new(-1203.2, 263.1, -487.1), delay = 60},  -- CP2 → CP3 (60s)
    {pos = Vector3.new(-1399.3, 579.8, -949.9), delay = 90},  -- CP3 → CP4 (90s)
    {pos = Vector3.new(-1701.0, 818.0, -1400.0), delay = 90}, -- CP4 → CP5 (90s)
    {pos = Vector3.new(-3195.7, 1726.8, -2617.0), delay = 10} -- CP5 (10s sebelum reset)
}

-- Auto Teleport (loop)
local function autoTeleport()
    task.spawn(function()
        local cycleCount = 1
        while true do
            print("\n🚀 Memulai Cycle "..cycleCount.." ...")
            local cycleStart = tick()

            for i, cp in ipairs(checkpoints) do
                forceRespawn(function()
                    if hrp then
                        hrp.CFrame = CFrame.new(cp.pos)
                        print("✅ Teleported ke Checkpoint "..i)
                    end
                end)

                if cp.delay > 0 then
                    print("⏳ Menunggu "..cp.delay.." detik sebelum lanjut...")
                    task.wait(cp.delay)
                end

                -- Kalau sudah sampai CP terakhir (CP5)
                if i == #checkpoints then
                    print("🎯 Sampai CP5! Respawn ulang...")
                    forceRespawn()
                    print("⏳ Tunggu 10 detik sebelum cycle baru...")
                    task.wait(10)

                    -- Ringkasan total waktu cycle
                    local cycleTime = tick() - cycleStart
                    print("📊 Ringkasan Cycle "..cycleCount..": "..string.format("%.2f", cycleTime).." detik ("..math.floor(cycleTime/60).."m "..math.floor(cycleTime%60).."s)")
                end
            end

            cycleCount += 1
        end
    end)
end

-- Jalankan otomatis
if plr.Character then
    setupHRP(plr.Character)
end
plr.CharacterAdded:Connect(setupHRP)

autoTeleport()