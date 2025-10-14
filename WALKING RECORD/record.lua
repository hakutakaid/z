-- Roblox Replay System by Watax
-- Logika JSON asli, GUI direfactor dengan WindUI

--[[ Load WindUI Library ]]
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

--[[ Variabel & Setup Awal (Dari Skrip Asli) ]]
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hrp = char:WaitForChild("HumanoidRootPart")
end)

local HttpService = game:GetService("HttpService")
local records = {}
local isRecording = false
local isPlaying = false
local frameTime = 1/30 -- 30 FPS
local currentFileName = "Replay.json"
local selectedReplayFile = nil

local replayFolder = "Wataxrecord"
if not isfolder(replayFolder) then
    makefolder(replayFolder)
end

--[[ Fungsi Inti (Logika Asli Anda + Notifikasi WindUI) ]]

function startRecord()
    if isRecording then return end
    records = {}
    isRecording = true
    WindUI:Notify({ Title = "Recording Started", Content = "Mulai merekam gerakan.", Icon = "radio" })

    task.spawn(function()
        while isRecording do
            if hrp then
                table.insert(records, { pos = hrp.CFrame })
            end
            task.wait(frameTime)
        end
    end)
end

function stopRecord()
    if not isRecording then return end
    isRecording = false
    WindUI:Notify({ Title = "Recording Stopped", Content = "Perekaman selesai. Siap disimpan.", Icon = "check-square" })
end

function playRecord()
    if isRecording then
        WindUI:Notify({ Title = "Peringatan", Content = "Hentikan rekaman dulu sebelum memutar!", Icon = "alert-triangle" })
        return
    end
    if not selectedReplayFile then
        WindUI:Notify({ Title = "Error", Content = "Pilih replay dulu dari list!", Icon = "alert-triangle" })
        return
    end
    if #records < 2 then 
        WindUI:Notify({ Title = "Error", Content = "Data replay tidak cukup untuk diputar.", Icon = "alert-triangle" })
        return 
    end

    isPlaying = true
    WindUI:Notify({ Title = "Playback Started", Content = "Memutar replay...", Icon = "play" })

    task.spawn(function()
        for i = 1, #records-1 do
            if not isPlaying then break end
            local startPos = records[i].pos
            local endPos = records[i+1].pos
            local t = 0
            while t < frameTime do
                if not isPlaying then break end
                t += task.wait()
                local alpha = math.min(t/frameTime, 1)
                if hrp and hrp.Parent and hrp:IsDescendantOf(workspace) then
                    hrp.CFrame = startPos:Lerp(endPos, alpha)
                end
            end
        end
        isPlaying = false
        WindUI:Notify({ Title = "Playback Finished", Content = "Replay selesai diputar.", Icon = "check-circle" })
    end)
end

function stopPlay()
    if not isPlaying then return end
    isPlaying = false
    WindUI:Notify({ Title = "Playback Stopped", Content = "Replay dihentikan.", Icon = "stop-circle" })
end

function saveRecord()
    if isRecording then
        WindUI:Notify({ Title = "Peringatan", Content = "Hentikan rekaman dulu sebelum menyimpan!", Icon = "alert-triangle" })
        return
    end
    if #records == 0 then
        WindUI:Notify({ Title = "Error", Content = "Tidak ada data untuk disimpan!", Icon = "alert-triangle" })
        return 
    end

    local name = currentFileName
    if not name:match("%.json$") then name = name..".json" end

    local saveData = {}
    for _, frame in ipairs(records) do
        table.insert(saveData, {
            pos = {frame.pos.Position.X, frame.pos.Position.Y, frame.pos.Position.Z},
            rot = {frame.pos:ToOrientation()}
        })
    end
    writefile(replayFolder.."/"..name, HttpService:JSONEncode(saveData))
    WindUI:Notify({ Title = "Replay Saved", Content = "Berhasil disimpan sebagai " .. name, Icon = "check-circle" })
end

function loadSelectedReplay(filePath)
    local data = HttpService:JSONDecode(readfile(filePath))
    records = {}
    for _, frame in ipairs(data) do
        local rot = frame.rot
        local cf = CFrame.new(frame.pos[1], frame.pos[2], frame.pos[3]) * CFrame.Angles(rot[1], rot[2], rot[3])
        table.insert(records, {pos = cf})
    end
    
    local fileName = filePath:split("/")[#filePath:split("/")][1]
    selectedReplayFile = filePath
    WindUI:Notify({ Title = "Replay Loaded", Content = fileName .. " (" .. #records .. " frames)", Icon = "download" })
end

--[[ WindUI Implementation ]]

local Window = WindUI:CreateWindow({
    Title = "Watax Replay System (JSON)",
    Author = "GUI by WindUI",
    Folder = "WataxReplay"
})

local MainTab = Window:Tab({ Title = "Replay", Icon = "video" })
local controlSection = MainTab:Section({ Title = "Controls" })

controlSection:Input({
    Title = "Nama File", Value = currentFileName, Placeholder = "Replay.json",
    Callback = function(text)
        if not text or text == "" then text = "Replay.json" end
        if not text:match("%.json$") then text = text .. ".json" end
        currentFileName = text
    end
})

-- Tombol Start/Stop dengan logika asli Anda
controlSection:Button({
    Title = "⏺️ Start Record", Icon = "radio",
    Callback = function(self)
        if isRecording then
            stopRecord()
            self:Set("Title", "⏺️ Start Record")
            self:Set("Color", nil)
        else
            startRecord()
            self:Set("Title", "⏹️ Stop Record")
            self:Set("Color", Color3.fromHex("#ff4830"))
        end
    end
})

controlSection:Button({ Title = "▶️ Play Replay", Icon = "play", Color = Color3.fromHex("#30FF6A"), Callback = playRecord })
controlSection:Button({ Title = "⏹️ Stop Replay", Icon = "stop-circle", Callback = stopPlay })
controlSection:Button({ Title = "💾 Save Replay", Icon = "save", Callback = saveRecord })

-- Section untuk daftar file
local listManagementSection = MainTab:Section({ Title = "File Management" })
local replayListSection

local function loadReplayList()
    if replayListSection then replayListSection:Destroy() end
    
    replayListSection = MainTab:Section({ Title = "Saved Replays" })
    local files = listfiles(replayFolder)

    if #files == 0 then
        replayListSection:Section({ Title = "Tidak ada replay yang tersimpan.", TextSize = 14, TextTransparency = 0.3 })
        return
    end

    for _, filePath in ipairs(files) do
        if filePath:match("%.json$") then
            local fileName = filePath:match("([^/]+)$")
            replayListSection:Paragraph({
                Title = fileName, Icon = "file-code",
                Buttons = {
                    {
                        Title = "Load", Icon = "download",
                        Callback = function()
                            loadSelectedReplay(filePath)
                        end
                    },
                    {
                        Title = "Delete", Icon = "trash-2",
                        Callback = function()
                            delfile(filePath)
                            WindUI:Notify({ Title = "File Deleted", Content = fileName .. " telah dihapus.", Icon = "check" })
                            loadReplayList()
                        end
                    }
                }
            })
        end
    end
end

listManagementSection:Button({
    Title = "🔄 Refresh Replay List", Icon = "refresh-cw", Justify = "Center",
    Callback = loadReplayList
})

-- Muat daftar saat skrip dijalankan
loadReplayList()