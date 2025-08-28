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
    {pos = Vector3.new(-621.7, 251.7, -383.9), delay = 30},       -- CP1 (30s)
    {pos = Vector3.new(-1203.2, 263.1, -487.1), delay = 30},     -- CP2 (30s)
    {pos = Vector3.new(-1399.3, 579.8, -949.9), delay = 60},     -- CP3 (60s)
    {pos = Vector3.new(-1701.0, 818.0, -1400.0), delay = 110},   -- CP4 (100s)
    {pos = Vector3.new(-3195.7, 1726.8, -2617.0), delay = 10},  -- CP5 (120s)
}

-- Auto Teleport (loop)
local function autoTeleport()
    task.spawn(function()
        while true do
            for i, cp in ipairs(checkpoints) do
                forceRespawn(function()
                    if hrp then
                        hrp.CFrame = CFrame.new(cp.pos)
                        print("✅ Teleported to Checkpoint "..i)
                    end
                end)
                if cp.delay > 0 then
                    print("⏳ Waiting "..cp.delay.."s before next checkpoint...")
                    task.wait(cp.delay)
                end

                -- Kalau sudah sampai CP terakhir (CP5)
                if i == #checkpoints then
                    print("🎯 Sampai CP5, respawn ulang...")
                    forceRespawn()
                    print("⏳ Tunggu 10 detik sebelum mulai cycle baru...")
                    task.wait(10)
                end
            end
        end
    end)
end

-- Jalankan otomatis
if plr.Character then
    setupHRP(plr.Character)
end
plr.CharacterAdded:Connect(setupHRP)

autoTeleport()