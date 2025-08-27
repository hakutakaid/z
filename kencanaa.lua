-- Auto Run CP1→CP5 lalu auto rejoin (loop tanpa klik)
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local hrp = plr.Character:WaitForChild("HumanoidRootPart")

-- daftar checkpoints
local checkpoints = {
    Vector3.new(-205.2, 623.5, -563.5),
    Vector3.new(2602.3, 948.4, -123.125),
    Vector3.new(4334.8, 1232.6, 531.7),
    Vector3.new(4760.6, 1280.4, -270.5),
    Vector3.new(5661.3, 1975.9, 440.5),
}

local function autoRunLoop()
    while true do
        -- jalanin CP1 → CP5
        for i = 1, #checkpoints do
            if hrp and checkpoints[i] then
                hrp.CFrame = CFrame.new(checkpoints[i])
            end
            task.wait(2)
        end
        -- setelah selesai → auto rejoin ke server yg sama
        task.wait(2)
        TeleportService:Teleport(game.PlaceId, plr)
        task.wait(2) -- jaga-jaga kalau Teleport delay
    end
end

-- tunggu karakter siap dulu
task.spawn(function()
    repeat task.wait() until hrp
    task.wait(2)
    autoRunLoop()
end)