--[[
    SCRIPT PEREKAM JALUR DENGAN GUI (UNTUK ANDROID)
    Menghasilkan JSON dengan format {"name":"...", "points":[...]}

    CARA PAKAI:
    1. Execute script ini. Sebuah jendela kecil akan muncul.
    2. Ketik nama jalur di kotak yang tersedia.
    3. Tekan tombol [START] untuk mulai merekam.
    4. Jalan seperti biasa mengikuti rute.
    5. Tekan tombol [STOP & GET JSON] untuk berhenti dan menyalin hasilnya.
]]

-- Services
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local player = game:GetService("Players").LocalPlayer

-- Variabel Internal
local isRecording = false
local recordedPoints = {}
local lastPosition = nil
local connection = nil

-- =================================================================
-- BAGIAN FUNGSI PEREKAM (LOGIKA INTI)
-- =================================================================

local gui -- Variabel untuk menyimpan GUI utama
local nameBox, statusLabel, startButton, stopButton -- Variabel untuk elemen GUI

local function startRecording()
    if isRecording then return end
    isRecording = true
    recordedPoints = {}
    lastPosition = nil
    
    local trackName = nameBox.Text
    if trackName == "" then trackName = "JalurTanpaNama" end

    statusLabel.Text = "MEREKAM: " .. trackName
    statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    
    startButton.Visible = false
    stopButton.Visible = true
    
    connection = RunService.Heartbeat:Connect(function()
        local character = player.Character
        if not character or not character.PrimaryPart then return end
        
        local currentPosition = character.PrimaryPart.Position
        if not lastPosition or (currentPosition - lastPosition).Magnitude > 3 then
            table.insert(recordedPoints, currentPosition)
            lastPosition = currentPosition
            statusLabel.Text = "MEREKAM: " .. trackName .. " (" .. #recordedPoints .. " titik)"
        end
    end)
end

local function stopAndGenerate()
    if not isRecording then return end
    isRecording = false
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    statusLabel.Text = "BERHENTI. Memproses JSON..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    startButton.Visible = true
    stopButton.Visible = false
    
    -- Proses JSON
    if #recordedPoints < 2 then
        statusLabel.Text = "Gagal! Titik terlalu sedikit."
        task.wait(2)
        statusLabel.Text = "Siap Merekam"
        statusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        return
    end
    
    local dataForJson = {}
    for _, pos in ipairs(recordedPoints) do
        table.insert(dataForJson, {pos.X, pos.Y, pos.Z})
    end
    
    local finalTable = {
        name = nameBox.Text,
        points = dataForJson
    }
    
    local success, jsonString = pcall(function()
        return HttpService:JSONEncode(finalTable)
    end)
    
    if success then
        if setclipboard then
            setclipboard(jsonString)
            statusLabel.Text = "JSON Disalin! Siap Merekam."
            statusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        else
            statusLabel.Text = "Gagal! Fungsi clipboard tidak ada."
            warn("Executor ini tidak mendukung 'setclipboard'.")
        end
    else
        statusLabel.Text = "Gagal membuat JSON."
    end
end

-- =================================================================
-- BAGIAN PEMBUATAN GUI
-- =================================================================
function createRecorderGUI()
    if CoreGui:FindFirstChild("PathRecorderGUI") then
        CoreGui.PathRecorderGUI:Destroy()
    end

    gui = Instance.new("ScreenGui")
    gui.Name = "PathRecorderGUI"
    gui.Parent = CoreGui
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 220, 0, 150)
    mainFrame.Position = UDim2.new(0.5, -110, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.BorderColor3 = Color3.fromRGB(120, 120, 120)
    mainFrame.BorderSizePixel = 1
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleBar.Parent = mainFrame
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size = UDim2.new(1, -10, 1, 0)
    titleLabel.Position = UDim2.new(0, 5, 0, 0)
    titleLabel.Text = "Path Recorder"
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1

    statusLabel = Instance.new("TextLabel", mainFrame)
    statusLabel.Size = UDim2.new(1, -10, 0, 20)
    statusLabel.Position = UDim2.new(0, 5, 0, 35)
    statusLabel.Text = "Siap Merekam"
    statusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.BackgroundTransparency = 1

    nameBox = Instance.new("TextBox", mainFrame)
    nameBox.Size = UDim2.new(1, -20, 0, 30)
    nameBox.Position = UDim2.new(0, 10, 0, 60)
    nameBox.PlaceholderText = "Ketik Nama Jalur di Sini"
    nameBox.Text = "YAHAA_Baru"
    nameBox.TextColor3 = Color3.fromRGB(240, 240, 240)
    nameBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    nameBox.TextSize = 14
    nameBox.ClearTextOnFocus = false
    nameBox.Font = Enum.Font.SourceSans
    Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 5)

    startButton = Instance.new("TextButton", mainFrame)
    startButton.Size = UDim2.new(0.5, -15, 0, 40)
    startButton.Position = UDim2.new(0, 10, 0, 100)
    startButton.Text = "START"
    startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    startButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    startButton.Font = Enum.Font.SourceSansBold
    startButton.TextSize = 18
    startButton.MouseButton1Click:Connect(startRecording)
    Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 6)

    stopButton = Instance.new("TextButton", mainFrame)
    stopButton.Size = UDim2.new(1, -20, 0, 40)
    stopButton.Position = UDim2.new(0, 10, 0, 100)
    stopButton.Text = "STOP & GET JSON"
    stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    stopButton.Font = Enum.Font.SourceSansBold
    stopButton.TextSize = 18
    stopButton.Visible = false
    stopButton.MouseButton1Click:Connect(stopAndGenerate)
    Instance.new("UICorner", stopButton).CornerRadius = UDim.new(0, 6)
end

-- Jalankan fungsi untuk membuat GUI
createRecorderGUI()