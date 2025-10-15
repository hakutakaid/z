--==================================================================--
--                          SETUP PLAYER                            --
--==================================================================--
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hrp = char:WaitForChild("HumanoidRootPart")
end)

--==================================================================--
--                      VARIABEL & KONFIGURASI                      --
--==================================================================--
local records = {}
local isRecording = false
local isPlaying = false
local frameTime = 1/30 -- 30 FPS
local currentFileName = "Replay.lua" -- Ekstensi diubah ke .lua
local selectedReplayFile = nil

local replayFolder = "HakuXrecord"
if not isfolder(replayFolder) then
    makefolder(replayFolder)
end

--==================================================================--
--                     FUNGSI INTI REPLAY SYSTEM                    --
--==================================================================--

function startRecord()
    if isRecording then return end
    records = {}
    isRecording = true
    recordBtn.Text = "⏸ Pause Record"

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
    recordBtn.Text = "⏺ Start Record"
end

function playRecord()
    if not selectedReplayFile then
        warn("❌ Pilih replay dulu dari list!")
        return
    end
    if #records < 2 then return end
    isPlaying = true
    playBtn.Text = "Playing..."

    for i = 1, #records - 1 do
        if not isPlaying then break end
        local startPos = records[i].pos
        local endPos = records[i+1].pos
        local t = 0
        while t < frameTime do
            if not isPlaying then break end
            t += task.wait()
            local alpha = math.min(t / frameTime, 1)
            if hrp and hrp.Parent and hrp:IsDescendantOf(workspace) then
                hrp.CFrame = startPos:Lerp(endPos, alpha)
            end
        end
    end
    isPlaying = false
    playBtn.Text = "▶️ Play Replay"
end

function stopPlay()
    isPlaying = false
    playBtn.Text = "▶️ Play Replay"
end

-- [DIUBAH] Menyimpan rekaman ke format .lua
function saveRecord()
    if #records == 0 then return end
    local name = currentFileName
    if not name:match("%.lua$") then
        name = name..".lua"
    end

    -- Membuat string Lua dari tabel CFrame
    local saveContent = {"return {"}
    for _, frame in ipairs(records) do
        local cf = frame.pos
        local pos = cf.Position
        local rx, ry, rz = cf:ToOrientation()
        
        -- Format setiap CFrame menjadi kode Lua
        local line = string.format("\tCFrame.new(%.15g, %.15g, %.15g) * CFrame.Angles(%.15g, %.15g, %.15g),", pos.X, pos.Y, pos.Z, rx, ry, rz)
        table.insert(saveContent, line)
    end
    table.insert(saveContent, "}")

    writefile(replayFolder.."/"..name, table.concat(saveContent, "\n"))
    print("✅ Replay saved to", replayFolder.."/"..name)
end

-- [DIUBAH] Memuat rekaman dari file .lua
local function loadSelectedReplay(filePath)
    local success, func = pcall(function()
        return loadstring(readfile(filePath))
    end)

    if not success or not func then
        warn("❌ Gagal memuat replay: " .. tostring(func))
        return
    end
    
    local data = func() -- Menjalankan kode Lua untuk mendapatkan tabel CFrame
    records = {}
    for _, cf in ipairs(data) do
        table.insert(records, {pos = cf})
    end
    print("✅ Loaded replay:", filePath:split("/")[#filePath:split("/")], "Frames:", #records)
end

--==================================================================--
--                           PEMBUATAN GUI                          --
--==================================================================--
-- [DIUBAH] Semua ukuran dan posisi GUI dikecilkan 50%

local gui = Instance.new("ScreenGui", game.CoreGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 110, 0, 170) -- Ukuran 50%
frame.Position = UDim2.new(0, 20, 0.5, -85) -- Posisi disesuaikan
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

local textbox = Instance.new("TextBox", frame)
textbox.Size = UDim2.new(1, -10, 0, 15) -- Ukuran 50%
textbox.Position = UDim2.new(0, 5, 0, 5) -- Posisi 50%
textbox.PlaceholderText = "Nama File (ex: Run1.lua)"
textbox.Text = "Replay.lua"
textbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
textbox.TextColor3 = Color3.new(1,1,1)
textbox.Font = Enum.Font.Gotham
textbox.TextSize = 10 -- Ukuran font dikecilkan
Instance.new("UICorner", textbox).CornerRadius = UDim.new(0, 4)
textbox.FocusLost:Connect(function()
    local txt = textbox.Text
    if txt == "" then txt = "Replay.lua" end
    if not txt:match("%.lua$") then txt = txt..".lua" end
    currentFileName = txt
    textbox.Text = currentFileName
end)

local function makeBtn(ref, text, pos, callback, color)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -10, 0, 15) -- Ukuran 50%
    btn.Position = UDim2.new(0, 5, 0, pos) -- Posisi Y disesuaikan
    btn.Text = text
    btn.BackgroundColor3 = color or Color3.fromRGB(0, 170, 255)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10 -- Ukuran font dikecilkan
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
    if ref then
        _G[ref] = btn
    end
    return btn
end

-- Posisi Y disesuaikan dengan layout baru yang lebih kecil
recordBtn = makeBtn("recordBtn", "⏺ Start Record", 25, function()
    if isRecording then stopRecord() else startRecord() end
end)

playBtn = makeBtn("playBtn", "▶️ Play Replay", 45, playRecord)
makeBtn(nil, "⏹ Stop Replay", 65, stopPlay)
makeBtn(nil, "💾 Save Replay", 85, saveRecord, Color3.fromRGB(0,200,100))

local replayFrame
local function loadReplayList()
    if replayFrame then replayFrame:Destroy() end
    replayFrame = Instance.new("Frame", gui)
    replayFrame.Size = UDim2.new(0, 110, 0, 150) -- Ukuran 50%
    replayFrame.Position = UDim2.new(0, 140, 0.5, -75) -- Posisi 50%
    replayFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
    replayFrame.Active = true
    replayFrame.Draggable = true
    Instance.new("UICorner", replayFrame).CornerRadius = UDim.new(0, 6)

    local closeBtn = Instance.new("TextButton", replayFrame)
    closeBtn.Size = UDim2.new(0, 25, 0, 12) -- Ukuran 50%
    closeBtn.Position = UDim2.new(1, -28, 0, 3) -- Posisi 50%
    closeBtn.Text = "X"
    closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.TextSize = 9
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,4)
    closeBtn.MouseButton1Click:Connect(function()
        replayFrame:Destroy()
        replayFrame = nil
    end)

    local yPos = 18 -- Posisi Y awal 50%
    for _, filePath in ipairs(listfiles(replayFolder)) do
        local fileName = filePath:split("/")[#filePath:split("/")]
        if fileName:match("%.lua$") then -- Hanya tampilkan file .lua
            local btn = Instance.new("TextButton", replayFrame)
            btn.Size = UDim2.new(1, -10, 0, 15) -- Ukuran 50%
            btn.Position = UDim2.new(0, 5, 0, yPos)
            btn.Text = fileName
            btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
            btn.TextColor3 = Color3.new(1,1,1)
            btn.TextSize = 9
            btn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)

            btn.MouseButton1Click:Connect(function()
                selectedReplayFile = filePath
                for _, c in ipairs(replayFrame:GetChildren()) do
                    if c:IsA("TextButton") and c ~= closeBtn then
                        c.BackgroundColor3 = Color3.fromRGB(70,70,70)
                    end
                end
                btn.BackgroundColor3 = Color3.fromRGB(0,170,255)
                loadSelectedReplay(filePath)
            end)

            local delBtn = Instance.new("TextButton", replayFrame)
            delBtn.Size = UDim2.new(0, 25, 0, 15) -- Ukuran 50%
            delBtn.Position = UDim2.new(1, -30, 0, yPos)
            delBtn.Text = "DEL"
            delBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
            delBtn.TextColor3 = Color3.new(1,1,1)
            delBtn.TextSize = 9
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0,4)
            delBtn.MouseButton1Click:Connect(function()
                delfile(filePath)
                loadReplayList()
            end)

            yPos = yPos + 20 -- Jarak antar tombol 50%
        end
    end
end

makeBtn(nil, "📂 Load List", 105, loadReplayList, Color3.fromRGB(255,170,0))