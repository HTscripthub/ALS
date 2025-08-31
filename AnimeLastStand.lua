-- Load UI Library với error handling
local success, err = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not success then
    warn("Lỗi khi tải UI Library: " .. tostring(err))
    return
end

-- Đợi đến khi Fluent được tải hoàn tất
if not Fluent then
    warn("Không thể tải thư viện Fluent!")
    return
end

-- Hệ thống lưu trữ cấu hình
local ConfigSystem = {}
ConfigSystem.FileName = "HTHubHuntyZombies_" .. game:GetService("Players").LocalPlayer.Name .. ".json"
ConfigSystem.DefaultConfig = {
    -- Auto Play Settings
    AutoVoteEnabled = false,
    AutoAttackEnabled = false,
    AutoSkillEnabled = false,
    AutoFarmEnabled = false,
    AutoRetryEnabled = false,
}
ConfigSystem.CurrentConfig = {}

-- Hàm để lưu cấu hình
ConfigSystem.SaveConfig = function()
    local success, err = pcall(function()
        writefile(ConfigSystem.FileName, game:GetService("HttpService"):JSONEncode(ConfigSystem.CurrentConfig))
    end)
    if success then
        print("Đã lưu cấu hình thành công!")
    else
        warn("Lưu cấu hình thất bại:", err)
    end
end

-- Hàm để tải cấu hình
ConfigSystem.LoadConfig = function()
    local success, content = pcall(function()
        if isfile(ConfigSystem.FileName) then
            return readfile(ConfigSystem.FileName)
        end
        return nil
    end)
    
    if success and content then
        local data = game:GetService("HttpService"):JSONDecode(content)
        ConfigSystem.CurrentConfig = data
        return true
    else
        ConfigSystem.CurrentConfig = table.clone(ConfigSystem.DefaultConfig)
        ConfigSystem.SaveConfig()
        return false
    end
end

-- Tải cấu hình khi khởi động
ConfigSystem.LoadConfig()

-- Biến lưu trạng thái của tab Main
local autoVoteEnabled = ConfigSystem.CurrentConfig.AutoVoteEnabled or false
local autoAttackEnabled = ConfigSystem.CurrentConfig.AutoAttackEnabled or false
local autoSkillEnabled = ConfigSystem.CurrentConfig.AutoSkillEnabled or false
local autoFarmEnabled = ConfigSystem.CurrentConfig.AutoFarmEnabled or false
local autoRetryEnabled = ConfigSystem.CurrentConfig.AutoRetryEnabled or false

-- Lấy tên người chơi
local playerName = game:GetService("Players").LocalPlayer.Name

-- Cấu hình UI
local Window = Fluent:CreateWindow({
    Title = "HT HUB | Hunty Zombies",
    SubTitle = "",
    TabWidth = 80,
    Size = UDim2.fromOffset(300, 220),
    Acrylic = true,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Hệ thống Tạo Tab

-- Tạo Tab Main
local MainTab = Window:AddTab({ Title = "Farm", Icon = "rbxassetid://14163693256" })
-- Tạo Tab Settings
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "rbxassetid://14163671806" })

-- Tab Main
-- Section Auto Play trong tab Main
local AutoPlaySection = MainTab:AddSection("Farm")

AutoPlaySection:AddToggle("Auto Attack", { 
    Flag = "AutoAttackEnabled",
    State = autoAttackEnabled,
    Callback = function(state) 
        autoAttackEnabled = state
        ConfigSystem.CurrentConfig.AutoAttackEnabled = state
        ConfigSystem.SaveConfig()
    end
})

AutoPlaySection:AddToggle("Auto Skill", { 
    Flag = "AutoSkillEnabled",
    State = autoSkillEnabled,
    Callback = function(state) 
        autoSkillEnabled = state
        ConfigSystem.CurrentConfig.AutoSkillEnabled = state
        ConfigSystem.SaveConfig()
    end
})

AutoPlaySection:AddToggle("Auto Farm", {
    Flag = "AutoFarmEnabled",
    State = autoFarmEnabled,
    Callback = function(state)
        autoFarmEnabled = state
        ConfigSystem.CurrentConfig.AutoFarmEnabled = state
        ConfigSystem.SaveConfig()
    end
})

local function executeAutoRetry()
    -- Code for Auto Retry
end

local function executeAutoAttack()
    local args = {
        buffer.fromstring("\b\004\000")
    }
    game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args))
end

local function executeAutoSkill()
    local args1 = {
        buffer.fromstring("\b\003\000")
    }
    game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args1))

    local args2 = {
        buffer.fromstring("\b\005\000")
    }
    game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args2))

    local args3 = {
        buffer.fromstring("\b\006\000")
    }
    game:GetService("ReplicatedStorage"):WaitForChild("ByteNetReliable"):FireServer(unpack(args3))
end

local function executeAutoFarm()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local humanoidRootPart = character.HumanoidRootPart

    local zombiesFolder = game:GetService("Workspace"):FindFirstChild("Entities"):FindFirstChild("Zombie")
    if not zombiesFolder then return end

    local targetZombie = nil
    local minDistance = math.huge

    for i, zombie in pairs(zombiesFolder:GetChildren()) do
        if zombie:IsA("Model") and zombie:FindFirstChild("HumanoidRootPart") then
            local distance = (humanoidRootPart.Position - zombie.HumanoidRootPart.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                targetZombie = zombie
            end
        end
    end

    if targetZombie then
        local targetPosition = targetZombie.HumanoidRootPart.Position - Vector3.new(0,0,5) -- Di chuyển đến gần zombie một chút
        game:GetService("TweenService"):Create(humanoidRootPart, TweenInfo.new(0.5), {CFrame = CFrame.new(targetPosition)}):Play()
        
        -- Đợi cho đến khi zombie bị tiêu diệt
        repeat wait(0.5) until not targetZombie.Parent or targetZombie.Parent ~= zombiesFolder
    end
end

-- Loop chính cho Auto functions
spawn(function()
    while true do
        wait(2) -- Đợi 2 giây giữa mỗi lần thực hiện để tránh spam
        
        if autoVoteEnabled then
            executeAutoVote()
        end
        
        -- Auto Attack và Auto Skill sẽ có loop riêng

        if autoRetryEnabled then
            executeAutoRetry()
        end
    end
end)

-- Loop riêng cho Auto Attack
spawn(function()
    while true do
        wait(0.5)
        if autoAttackEnabled then
            executeAutoAttack()
        end
    end
end)

-- Loop riêng cho Auto Skill
spawn(function()
    while true do
        wait(0.5)
        if autoSkillEnabled then
            executeAutoSkill()
        end
    end
end)

-- Loop riêng cho Auto Farm
spawn(function()
    while true do
        wait(0.5)
        if autoFarmEnabled then
            executeAutoFarm()
        end
    end
end)

-- Settings tab configuration
local SettingsSection = SettingsTab:AddSection("Script Settings")

-- Integration with SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Thay đổi cách lưu cấu hình để sử dụng tên người chơi
InterfaceManager:SetFolder("HTHubHuntyZombies")
SaveManager:SetFolder("HTHubHuntyZombies/" .. playerName)

-- Thêm thông tin vào tab Settings
SettingsTab:AddParagraph({
    Title = "Cấu hình tự động",
    Content = "Cấu hình của bạn đang được tự động lưu theo tên nhân vật: " .. playerName
})

SettingsTab:AddParagraph({
    Title = "Phím tắt",
    Content = "Nhấn LeftControl để ẩn/hiện giao diện"
})

-- Auto Save Config
local function AutoSaveConfig()
    spawn(function()
        while wait(5) do -- Lưu mỗi 5 giây
            pcall(function()
                ConfigSystem.SaveConfig()
            end)
        end
    end)
end

-- Thực thi tự động lưu cấu hình
AutoSaveConfig()

-- Thêm event listener để lưu ngay khi thay đổi giá trị
local function setupSaveEvents()
    for _, tab in pairs({MainTab, SettingsTab}) do
        if tab and tab._components then
            for _, element in pairs(tab._components) do
                if element and element.OnChanged then
                    element.OnChanged:Connect(function()
                        pcall(function()
                            ConfigSystem.SaveConfig()
                        end)
                    end)
                end
            end
        end
    end
end

-- Thiết lập events
setupSaveEvents()

-- Tạo logo để mở lại UI khi đã minimize
task.spawn(function()
    local success, errorMsg = pcall(function()
        if not getgenv().LoadedMobileUI == true then 
            getgenv().LoadedMobileUI = true
            local OpenUI = Instance.new("ScreenGui")
            local ImageButton = Instance.new("ImageButton")
            local UICorner = Instance.new("UICorner")
            
            -- Kiểm tra môi trường
            if syn and syn.protect_gui then
                syn.protect_gui(OpenUI)
                OpenUI.Parent = game:GetService("CoreGui")
            elseif gethui then
                OpenUI.Parent = gethui()
            else
                OpenUI.Parent = game:GetService("CoreGui")
            end
            
            OpenUI.Name = "OpenUI"
            OpenUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            
            ImageButton.Parent = OpenUI
            ImageButton.BackgroundColor3 = Color3.fromRGB(105,105,105)
            ImageButton.BackgroundTransparency = 0.8
            ImageButton.Position = UDim2.new(0.9,0,0.1,0)
            ImageButton.Size = UDim2.new(0,50,0,50)
            ImageButton.Image = "rbxassetid://13099788281" -- Logo HT Hub
            ImageButton.Draggable = true
            ImageButton.Transparency = 0.2
            
            UICorner.CornerRadius = UDim.new(0,200)
            UICorner.Parent = ImageButton
            
            -- Khi click vào logo sẽ mở lại UI
            ImageButton.MouseButton1Click:Connect(function()
                game:GetService("VirtualInputManager"):SendKeyEvent(true,Enum.KeyCode.LeftControl,false,game)
            end)
        end
    end)
    
    if not success then
        warn("Lỗi khi tạo nút Logo UI: " .. tostring(errorMsg))
    end
end)

print("HT Hub Hunty Zombies Script đã tải thành công!")
print("Sử dụng Left Ctrl để thu nhỏ/mở rộng UI")
