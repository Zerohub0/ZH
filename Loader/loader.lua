--[[
    ZeroHub Loader v4.0 | Zerohub0/ZH
    Enhanced animation: logo rotate + ZH morph + pulse
]]

local GITHUB_URL = "https://raw.githubusercontent.com/Zerohub0/ZH/main/Hub/zerohub.lua"

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local loader = Instance.new("ScreenGui", CoreGui)
loader.Name = "ZeroHub_Loader"

local bg = Instance.new("Frame", loader)
bg.Size = UDim2.new(1,0,1,0)
bg.BackgroundColor3 = Color3.fromRGB(8,12,24)
bg.BorderSizePixel = 0

-- Subtle grid effect (optional)
local grid = Instance.new("ImageLabel", bg)
grid.Size = UDim2.new(1,0,1,0)
grid.BackgroundTransparency = 1
grid.Image = "rbxassetid://0"  -- not needed, just for layout
grid.Visible = false

-- Glowing orb
local orb = Instance.new("Frame", bg)
orb.Size = UDim2.new(0,120,0,120)
orb.Position = UDim2.new(0.5,-60,0.33,-60)
orb.BackgroundColor3 = Color3.fromRGB(0,255,150)
orb.BackgroundTransparency = 0.85
orb.BorderSizePixel = 0
Instance.new("UICorner", orb).CornerRadius = UDim.new(1,0)

-- Logo text
local logo = Instance.new("TextLabel", bg)
logo.Size = UDim2.new(0,500,0,120)
logo.Position = UDim2.new(0.5,-250,0.33,-60)
logo.BackgroundTransparency = 1
logo.Text = "ZEROHUB"
logo.Font = Enum.Font.GothamBold
logo.TextSize = 56
logo.TextColor3 = Color3.fromRGB(0,255,200)
logo.TextStrokeTransparency = 0.7
logo.TextStrokeColor3 = Color3.fromRGB(0,150,100)
logo.Rotation = 0

-- Progress bar container
local barBg = Instance.new("Frame", bg)
barBg.Size = UDim2.new(0,320,0,8)
barBg.Position = UDim2.new(0.5,-160,0.68,0)
barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
barBg.BorderSizePixel = 0
barBg.Visible = false
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

local barFill = Instance.new("Frame", barBg)
barFill.Size = UDim2.new(0,0,1,0)
barFill.BackgroundColor3 = Color3.fromRGB(0,255,200)
barFill.BorderSizePixel = 0
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1,0)

local statusText = Instance.new("TextLabel", bg)
statusText.Size = UDim2.new(1,0,0,30)
statusText.Position = UDim2.new(0,0,0.75,0)
statusText.BackgroundTransparency = 1
statusText.TextColor3 = Color3.new(1,1,1)
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 18
statusText.Text = ""
statusText.Visible = false

-- ===================== ANIMATION =====================
task.spawn(function()
    -- Pulsing orb
    local orbIn = TweenService:Create(orb, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.6})
    local orbOut = TweenService:Create(orb, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.9})
    orbIn:Play()
    orbIn.Completed:Connect(function() orbOut:Play() end)
    orbOut.Completed:Connect(function() orbIn:Play() end)

    -- Fade in logo
    logo.TextTransparency = 1
    TweenService:Create(logo, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
    task.wait(1.0)

    -- Spin logo while changing color
    TweenService:Create(logo, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {Rotation = 360, TextColor3 = Color3.fromRGB(120,0,255)}):Play()
    task.wait(1.0)

    -- Reset rotation and morph to ZH
    logo.Rotation = 0
    TweenService:Create(logo, TweenInfo.new(0.6), {TextSize = 80, Size = UDim2.new(0,160,0,90), Position = UDim2.new(0.5,-80,0.33,-45)}):Play()
    task.wait(0.3)
    logo.Text = "ZH"
    TweenService:Create(logo, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(0,255,200), TextSize = 70}):Play()
    task.wait(0.6)

    -- Show loading bar
    barBg.Visible = true
    statusText.Visible = true
    statusText.Text = "Connecting to ZeroHub..."

    -- Download
    local fetchSuccess, result
    local function updateBar(pct, txt)
        TweenService:Create(barFill, TweenInfo.new(0.3), {Size = UDim2.new(pct/100,0,1,0)}):Play()
        statusText.Text = txt
    end

    task.spawn(function()
        fetchSuccess, result = pcall(game.HttpGet, game, GITHUB_URL)
    end)

    -- Simulate filling while downloading
    for i = 5, 90, 5 do
        updateBar(i, "Downloading ZeroHub...")
        if fetchSuccess ~= nil then break end
        task.wait(0.15)
    end

    while fetchSuccess == nil do
        updateBar(95, "Almost done...")
        task.wait(0.2)
    end

    if fetchSuccess and result then
        updateBar(100, "Launching...")
        TweenService:Create(logo, TweenInfo.new(0.4), {TextColor3 = Color3.fromRGB(255,200,0)}):Play()
        task.wait(0.6)
        -- Fade out
        TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(logo, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TweenService:Create(barBg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        statusText.Visible = false
        task.wait(0.6)
        loader:Destroy()

        local mainFunc, err = loadstring(result)
        if mainFunc then
            mainFunc()
        else
            warn("ZeroHub execution error: " .. tostring(err))
        end
    else
        updateBar(0, "Failed to load – check network / URL")
        TweenService:Create(logo, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255,0,0)}):Play()
        task.wait(3)
        loader:Destroy()
    end
end)
