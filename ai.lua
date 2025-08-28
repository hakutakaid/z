-- Services
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

-- Lokasi tujuan (misalnya puncak gunung)
local target = Vector3.new(5661.3, 1975.9, 440.5) -- ubah sesuai koordinat puncak

-- Fungsi: buat path
local function createPath(destination)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 10,
        AgentMaxSlope = 45,
    })
    path:ComputeAsync(hrp.Position, destination)
    return path
end

-- Fungsi: jalankan path
local function followPath(path)
    if path.Status == Enum.PathStatus.Complete then
        for _, waypoint in pairs(path:GetWaypoints()) do
            humanoid:MoveTo(waypoint.Position)
            humanoid.MoveToFinished:Wait()

            -- Kalau waypoint butuh lompat
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
        end
        print("Sampai tujuan!")
    else
        warn("Path gagal dibuat, coba lagi...")
    end
end

-- Jalankan AI climbing
local path = createPath(target)
followPath(path)