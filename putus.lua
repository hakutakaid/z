-- Server Script di ServerScriptService
local Workspace = game:GetService("Workspace")

-- Fungsi cek apakah object adalah jembatan/tali
local function isBridgePart(obj)
    if obj:IsA("RopeConstraint") then
        return true
    elseif obj:IsA("Part") and obj.Name:lower():find("rope") then
        return true
    end
    return false
end

-- Fungsi memutus jembatan
local function breakBridge(obj)
    if obj:IsA("RopeConstraint") then
        obj:Destroy()
        print("RopeConstraint terputus di server!")
    elseif obj:IsA("Part") then
        -- Hapus constraint yang menahan part
        for _, cons in ipairs(obj:GetChildren()) do
            if cons:IsA("Weld") or cons:IsA("Motor6D") or cons:IsA("HingeConstraint") then
                cons:Destroy()
            end
        end
        obj:BreakJoints()
        print(obj.Name.." terputus di server!")
    end
end

-- Fungsi untuk putus semua jembatan
local function breakAllBridges()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isBridgePart(obj) then
            breakBridge(obj)
        end
    end
end

-- Contoh: otomatis jalan setelah 5 detik
task.delay(5, breakAllBridges)