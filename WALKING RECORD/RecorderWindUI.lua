local WindUI
do
    local ok, result = pcall(function()
        return require("./src/init")
    end)
    if ok then
        WindUI = result
    else
        WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local records = {}
local isRecording = false
local isPlaying = false
local frameTime = 1/30
local currentFileName = "Replay.lua"
local selectedReplayFile = nil
local replayFolder = "HakuXrecord"
if not isfolder(replayFolder) then makefolder(replayFolder) end
local animConn
local isMoving = false

local function setupMovement(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoid or not root then return end
    if animConn then animConn:Disconnect() end
    local lastPos = root.Position
    local jumpCooldown = false
    animConn = RunService.RenderStepped:Connect(function()
        if not isMoving or not root or not root.Parent then return end
        if not humanoid or humanoid.Health <= 0 then return end
        local currentPos = root.Position
        local direction = currentPos - lastPos
        local distance = direction.Magnitude
        if distance > 0.01 then
            humanoid:Move(direction.Unit, false)
        else
            humanoid:Move(Vector3.zero, false)
        end
        local deltaY = currentPos.Y - lastPos.Y
        if deltaY > 0.5 and not jumpCooldown then
            humanoid.Jump = true
            jumpCooldown = true
            task.delay(0.5, function() jumpCooldown = false end)
        end
        lastPos = currentPos
    end)
end

local function startMovement() isMoving = true end
local function stopMovement() isMoving = false end

player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hrp = char:WaitForChild("HumanoidRootPart")
    setupMovement(newChar)
end)
setupMovement(char)

function startRecord()
    if isRecording then return end
    records = {}
    isRecording = true
    if recordBtnProxy and recordBtnProxy.SetTitle then pcall(function() recordBtnProxy:SetTitle("⏸ Pause Record") end) end
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
    if recordBtnProxy and recordBtnProxy.SetTitle then pcall(function() recordBtnProxy:SetTitle("⏺ Start Record") end) end
end

function playRecord()
    if not selectedReplayFile then
        warn("❌ Pilih replay dulu dari list!")
        return
    end
    if #records < 2 or isPlaying then return end
    isPlaying = true
    if playBtnProxy and playBtnProxy.SetTitle then pcall(function() playBtnProxy:SetTitle("Playing...") end) end
    startMovement()
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
    stopPlay()
end

function stopPlay()
    isPlaying = false
    stopMovement()
    if playBtnProxy and playBtnProxy.SetTitle then pcall(function() playBtnProxy:SetTitle("▶️ Play Replay") end) end
end

function saveRecord()
    if #records == 0 then return end
    local name = currentFileName
    if not name:match("%.lua$") then name = name..".lua" end
    local saveContent = {"return {"}
    for _, frame in ipairs(records) do
        local cf = frame.pos
        local pos = cf.Position
        local rx, ry, rz = cf:ToOrientation()
        local line = string.format("\tCFrame.new(%.15g, %.15g, %.15g) * CFrame.Angles(%.15g, %.15g, %.15g),", pos.X, pos.Y, pos.Z, rx, ry, rz)
        table.insert(saveContent, line)
    end
    table.insert(saveContent, "}")
    writefile(replayFolder.."/"..name, table.concat(saveContent, "\n"))
    if reloadReplays then reloadReplays() end
end

local function loadSelectedReplay(filePath)
    local success, func = pcall(function() return loadstring(readfile(filePath)) end)
    if not success or not func then
        warn("❌ Gagal memuat replay: " .. tostring(func))
        return
    end
    local data = func()
    records = {}
    for _, cf in ipairs(data) do
        table.insert(records, {pos = cf})
    end
end

local function listReplayFiles()
    local out = {}
    for _, path in ipairs(listfiles(replayFolder)) do
        local fileName = path:split("/")[#path:split("/")]
        if fileName:match("%.lua$") then
            table.insert(out, fileName)
        end
    end
    return out
end

local Window = WindUI:CreateWindow({
    Title = "Recorder",
    Author = "HakutakaID",
    Folder = "replay_system",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Replay UI",
        CornerRadius = UDim.new(1,0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#e7ff2f"))
    }
})

local RecordTab = Window:Tab({ Title = "Record", Icon = "record-circle" })
local ReplaysTab = Window:Tab({ Title = "Replays", Icon = "folder" })
local AboutTab = Window:Tab({ Title = "About", Icon = "info" })

local RecordSection = RecordTab:Section({ Title = "Controls" })

local nameInput = RecordSection:Input({
    Flag = "ReplayName",
    Title = "Nama File (ex: Replay.lua)",
    Value = currentFileName,
    Placeholder = "Replay.lua",
    Callback = function(value)
        if value == "" then value = "Replay.lua" end
        if not value:match("%.lua$") then value = value..".lua" end
        currentFileName = value
    end
})

local function makeBtnProxy(btn)
    local proxy = {}
    proxy._btn = btn
    function proxy:SetTitle(t)
        pcall(function() if self._btn.Set then self._btn:Set(t) end end)
        pcall(function() if self._btn.SetTitle then self._btn:SetTitle(t) end end)
    end
    return proxy
end

recordBtn = RecordSection:Button({ Title = "⏺ Start Record", Icon = "circle" , Callback = function() if isRecording then stopRecord() else startRecord() end end })
playBtn = RecordSection:Button({ Title = "▶️ Play Replay", Icon = "play" , Callback = function() playRecord() end })
RecordSection:Button({ Title = "⏹ Stop Replay", Icon = "stop-circle", Callback = function() stopPlay() end })
RecordSection:Button({ Title = "💾 Save Replay", Icon = "save", Callback = function() saveRecord() end })

recordBtnProxy = makeBtnProxy(recordBtn)
playBtnProxy = makeBtnProxy(playBtn)

local ReplaysSection = ReplaysTab:Section({ Title = "Manage Replays" })

local function getValues()
    return listReplayFiles()
end

local replayDropdown = ReplaysSection:Dropdown({
    Title = "Pilih Replay",
    Values = getValues(),
    Value = nil,
    Callback = function(option)
        if option then
            selectedReplayFile = replayFolder.."/"..option
            loadSelectedReplay(selectedReplayFile)
        end
    end
})

ReplaysSection:Button({ Title = "🔄 Refresh List", Icon = "refresh-cw", Callback = function() replayDropdown:Refresh(getValues()) end })
ReplaysSection:Button({ Title = "▶️ Play Selected", Icon = "play", Callback = function() if not selectedReplayFile then WindUI:Notify({ Title = "Error", Desc = "Pilih replay dulu." }) return end playRecord() end })
ReplaysSection:Button({ Title = "❌ Delete Selected", Icon = "trash", Callback = function() if selectedReplayFile and isfile(selectedReplayFile) then delfile(selectedReplayFile) replayDropdown:Refresh(getValues()) selectedReplayFile = nil end end })

function reloadReplays()
    replayDropdown:Refresh(getValues())
end

AboutTab:Section({ Title = "About Replay System" })
AboutTab:Button({ Title = "Export List (copy)", Color = Color3.fromHex("#a2ff30"), Callback = function() setclipboard(table.concat(getValues(), "\n")) WindUI:Notify({ Title = "Copied", Desc = "List copied to clipboard" }) end })