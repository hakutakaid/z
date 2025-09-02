-- Server Script (ServerScriptService)
local Lighting = game:GetService("Lighting")

-- Set ke jam 08:00 pagi
Lighting.ClockTime = 8

-- Kalau mau supaya waktu tidak berubah (freeze di jam 8)
Lighting.TimeOfDay = "08:00:00"
Lighting.ClockTime = 8
Lighting.Changed:Connect(function()
    if Lighting.ClockTime ~= 8 then
        Lighting.ClockTime = 8
    end
end)