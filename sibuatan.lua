-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") or plr.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

plr.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FinalTeleportGUI_Redesigned"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 480) -- Ukuran sedikit lebih besar untuk estetika
MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 44, 52) -- Darker, modern background
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Corner radius for the main frame
local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8) -- Sudut sedikit membulat
FrameCorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, 0, 0, 35) -- Sedikit lebih tinggi
TitleBar.BackgroundColor3 = Color3.fromRGB(50, 55, 65) -- Warna title bar yang serasi
TitleBar.TextColor3 = Color3.fromRGB(220, 220, 220) -- Warna teks putih keabu-abuan
TitleBar.Font = Enum.Font.GothamBold -- Font yang lebih modern
TitleBar.TextSize = 18 -- Ukuran font yang pas
TitleBar.Text = "🚀 Final Teleport GUI"
TitleBar.TextWrapped = true
TitleBar.Parent = MainFrame

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -35, 0, 2) -- Posisikan dengan sedikit padding
MinBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Warna merah yang menarik
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.Text = "–" -- Simbol minus yang lebih baik
MinBtn.Parent = MainFrame

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 6)
MinBtnCorner.Parent = MinBtn

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, child in ipairs(MainFrame:GetChildren()) do
        if child ~= TitleBar and child ~= MinBtn and child ~= FrameCorner then -- Pastikan UICorner tidak disembunyikan
            child.Visible = not minimized
        end
    end
    if minimized then
        MainFrame.Size = UDim2.new(0, 320, 0, 35) -- Tinggi sesuai title bar
    else
        MainFrame.Size = UDim2.new(0, 320, 0, 480)
    end
end)

-- Scrolling Frame for Content
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -45) -- Ukuran disesuaikan
ScrollFrame.Position = UDim2.new(0, 5, 0, 40) -- Posisi di bawah title bar
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.Always
ScrollFrame.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 8) -- Padding antar elemen
UIList.Parent = ScrollFrame

local UIPad = Instance.new("UIPadding") -- Tambahkan padding di dalam ScrollingFrame
UIPad.PaddingTop = UDim.new(0, 5)
UIPad.PaddingBottom = UDim.new(0, 5)
UIPad.PaddingLeft = UDim.new(0, 5)
UIPad.PaddingRight = UDim.new(0, 5)
UIPad.Parent = ScrollFrame

-- Coordinate Display
local CoordLabel = Instance.new("TextLabel")
CoordLabel.Size = UDim2.new(1, 0, 0, 30)
CoordLabel.BackgroundColor3 = Color3.fromRGB(60, 65, 75) -- Background yang lebih gelap
CoordLabel.TextColor3 = Color3.fromRGB(46, 204, 113) -- Warna hijau cerah
CoordLabel.Font = Enum.Font.Monospace -- Font monospace untuk koordinat
CoordLabel.TextSize = 16
CoordLabel.Text = "X:0.0 Y:0.0 Z:0.0"
CoordLabel.TextXAlignment = Enum.TextXAlignment.Left
CoordLabel.Parent = ScrollFrame

local CoordPad = Instance.new("UIPadding")
CoordPad.PaddingLeft = UDim.new(0, 10) -- Padding untuk teks koordinat
CoordPad.Parent = CoordLabel

local CoordCorner = Instance.new("UICorner")
CoordCorner.CornerRadius = UDim.new(0, 6)
CoordCorner.Parent = CoordLabel

RunService.RenderStepped:Connect(function()
    if hrp and not minimized then -- Update hanya jika tidak diminimize
        local p = hrp.Position
        CoordLabel.Text = string.format("X: %.1f Y: %.1f Z: %.1f", p.X, p.Y, p.Z)
    end
end)

-- Copy Coord Button
local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(1, 0, 0, 35)
CopyBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219) -- Warna biru cerah
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.TextSize = 16
CopyBtn.Text = "📋 Copy Current Coordinates"
CopyBtn.Parent = ScrollFrame

local CopyBtnCorner = Instance.new("UICorner")
CopyBtnCorner.CornerRadius = UDim.new(0, 6)
CopyBtnCorner.Parent = CopyBtn

CopyBtn.MouseButton1Click:Connect(function()
    if hrp then
        setclipboard(string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
    end
end)

-- Checkpoints
local checkpoints = {
    {name = "Starting Area", pos = Vector3.new(0, 10, 0)},
    {name = "Hidden Treasure", pos = Vector3.new(-345.5, 457.0, -223.6)},
    {name = "Mountaintop View", pos = Vector3.new(-764.6, 996.6, -127.6)},
    {name = "Ancient Ruins", pos = Vector3.new(-1657.7, 998.4, 259.5)},
    {name = "Deep Cave Entrance", pos = Vector3.new(500, -200, 100)}
}

local CPDropdown = Instance.new("TextButton")
CPDropdown.Size = UDim2.new(1, 0, 0, 35)
CPDropdown.BackgroundColor3 = Color3.fromRGB(155, 89, 182) -- Warna ungu
CPDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
CPDropdown.Font = Enum.Font.GothamBold
CPDropdown.TextSize = 16
CPDropdown.Text = "▼ Select Checkpoint"
CPDropdown.Parent = ScrollFrame

local CPDropdownCorner = Instance.new("UICorner")
CPDropdownCorner.CornerRadius = UDim.new(0, 6)
CPDropdownCorner.Parent = CPDropdown

local CPList = Instance.new("Frame")
CPList.Size = UDim2.new(1, 0, 0, 0) -- Mulai dengan tinggi 0
CPList.BackgroundColor3 = Color3.fromRGB(60, 40, 70) -- Background gelap ungu
CPList.Visible = false
CPList.Parent = ScrollFrame

local CPListCorner = Instance.new("UICorner")
CPListCorner.CornerRadius = UDim.new(0, 6)
CPListCorner.Parent = CPList

local CPLayout = Instance.new("UIListLayout")
CPLayout.SortOrder = Enum.SortOrder.LayoutOrder
CPLayout.Padding = UDim.new(0, 2)
CPLayout.Parent = CPList

CPDropdown.MouseButton1Click:Connect(function()
    CPList.Visible = not CPList.Visible
    -- Menyesuaikan ukuran CPList secara dinamis
    CPList.Size = if CPList.Visible then UDim2.new(1, 0, 0, #checkpoints * 30 + (#checkpoints - 1) * CPLayout.Padding.Offset + CPLayout.Padding.Offset*2) else UDim2.new(1, 0, 0, 0)
    CPDropdown.Text = if CPList.Visible then "▲ Select Checkpoint" else "▼ Select Checkpoint"
end)

for i, cp in ipairs(checkpoints) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28) -- Tinggi sedikit lebih kecil
    btn.BackgroundColor3 = Color3.fromRGB(120, 70, 150) -- Warna tombol checkpoint
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = cp.name
    btn.Parent = CPList

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 5)
    BtnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if hrp then hrp.CFrame = CFrame.new(cp.pos) end
        CPList.Visible = false
        CPList.Size = UDim2.new(1, 0, 0, 0)
        CPDropdown.Text = "▼ Select Checkpoint"
    end)
end

-- Player Dropdown
local PlayerDropdown = Instance.new("TextButton")
PlayerDropdown.Size = UDim2.new(1, 0, 0, 35)
PlayerDropdown.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Warna hijau
PlayerDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerDropdown.Font = Enum.Font.GothamBold
PlayerDropdown.TextSize = 16
PlayerDropdown.Text = "▼ Teleport to Player"
PlayerDropdown.Parent = ScrollFrame

local PlayerDropdownCorner = Instance.new("UICorner")
PlayerDropdownCorner.CornerRadius = UDim.new(0, 6)
PlayerDropdownCorner.Parent = PlayerDropdown

local PlayerList = Instance.new("Frame")
PlayerList.Size = UDim2.new(1, 0, 0, 0) -- Mulai dengan tinggi 0
PlayerList.BackgroundColor3 = Color3.fromRGB(30, 60, 40) -- Background gelap hijau
PlayerList.Visible = false
PlayerList.Parent = ScrollFrame

local PlayerListCorner = Instance.new("UICorner")
PlayerListCorner.CornerRadius = UDim.new(0, 6)
PlayerListCorner.Parent = PlayerList

local PlayerLayout = Instance.new("UIListLayout")
PlayerLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerLayout.Padding = UDim.new(0, 2)
PlayerLayout.Parent = PlayerList

PlayerDropdown.MouseButton1Click:Connect(function()
    PlayerList.Visible = not PlayerList.Visible
    PlayerList.Size = if PlayerList.Visible then UDim2.new(1, 0, 0, #PlayerList:GetChildren() * 28 + (#PlayerList:GetChildren() - 1) * PlayerLayout.Padding.Offset + PlayerLayout.Padding.Offset*2) else UDim2.new(1, 0, 0, 0)
    PlayerDropdown.Text = if PlayerList.Visible then "▲ Teleport to Player" else "▼ Teleport to Player"
end)

local function refreshPlayers()
    for _, child in ipairs(PlayerList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= plr then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(70, 180, 90) -- Warna tombol player
            btn.TextColor3 = Color3.fromRGB(220, 220, 220)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Text = target.Name
            btn.Parent = PlayerList

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 5)
            BtnCorner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                if hrp and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    hrp.CFrame = target.Character.HumanoidRootPart.CFrame
                end
                PlayerList.Visible = false
                PlayerList.Size = UDim2.new(1, 0, 0, 0)
                PlayerDropdown.Text = "▼ Teleport to Player"
            end)
        end
    end
    -- Update ukuran PlayerList setelah tombol ditambahkan/dihapus
    PlayerList.Size = if PlayerList.Visible then UDim2.new(1, 0, 0, #PlayerList:GetChildren() * 28 + (#PlayerList:GetChildren() - 1) * PlayerLayout.Padding.Offset + PlayerLayout.Padding.Offset*2) else UDim2.new(1, 0, 0, 0)
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

-- Actions
local RejoinBtn = Instance.new("TextButton")
RejoinBtn.Size = UDim2.new(1, 0, 0, 35)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15) -- Warna kuning
RejoinBtn.TextColor3 = Color3.fromRGB(40, 44, 52) -- Teks gelap untuk kontras
RejoinBtn.Font = Enum.Font.GothamBold
RejoinBtn.TextSize = 16
RejoinBtn.Text = "🔄 Rejoin Server"
RejoinBtn.Parent = ScrollFrame

local RejoinBtnCorner = Instance.new("UICorner")
RejoinBtnCorner.CornerRadius = UDim.new(0, 6)
RejoinBtnCorner.Parent = RejoinBtn

RejoinBtn.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
end)

local RestartBtn = Instance.new("TextButton")
RestartBtn.Size = UDim2.new(1, 0, 0, 35)
RestartBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Warna merah
RestartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RestartBtn.Font = Enum.Font.GothamBold
RestartBtn.TextSize = 16
RestartBtn.Text = "⚡ Restart Script"
RestartBtn.Parent = ScrollFrame

local RestartBtnCorner = Instance.new("UICorner")
RestartBtnCorner.CornerRadius = UDim.new(0, 6)
RestartBtnCorner.Parent = RestartBtn

RestartBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    -- Pastikan URL script ini adalah URL yang benar untuk script Anda
    loadstring(game:HttpGet("https://raw.githubusercontent.com/hakutakaid/z/refs/heads/master/sibuatan.lua"))()
end)

