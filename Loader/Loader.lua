--[[
    ZeroHub Loader v3.0
    Vibrant animation + ZH transformation
    Replace the URL below with your actual hub URL.
]]

local GITHUB_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/Hub/zerohub.lua"

-- Services
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Loader GUI
local loader = Instance.new("ScreenGui", CoreGui)
loader.Name = "ZeroHub_Loader"

local bg = Instance.new("Frame", loader)
bg.Size = UDim2.new(1,0,1,0)
bg.BackgroundColor3 = Color3.fromRGB(5,10,20)
bg.BorderSizePixel = 0

local gradient = Instance.new("Frame", bg)
gradient.Size = UDim2.new(1,0,0.5,0)
gradient.BackgroundColor3 = Color3.fromRGB(15,25,45)
gradient.BorderSizePixel = 0
gradient.BackgroundTransparency = 0.5

local glow = Instance.new("Frame", bg)
glow.Size = UDim2.new(0,200,0,200)
glow.Position = UDim2.new(0.5,-100,0.35,-100)
glow.BackgroundColor3 = Color3.fromRGB(0,255,150)
glow.BackgroundTransparency = 0.9
glow.BorderSizePixel = 0
Instance.new("UICorner", glow).CornerRadius = UDim.new(1,0)

local logo = Instance.new("TextLabel", bg)
logo.Size = UDim2.new(0,500,0,150)
logo.Position = UDim2.new(0.5,-250,0.35,-75)
logo.BackgroundTransparency = 1
logo.Text = "ZEROHUB"
logo.Font = Enum.Font.GothamBold
logo.TextSize = 60
logo.TextColor3 = Color3.fromRGB(0,255,200)
logo.TextStrokeTransparency = 0.7
logo.TextStrokeColor3 = Color3.fromRGB(0,150,100)

local barBg = Instance.new("Frame", bg)
barBg.Size = UDim2.new(0,300,0,10)
barBg.Position = UDim2.new(0.5,-150,0.65,0)
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
statusText.Position = UDim2.new(0,0,0.72,0)
statusText.BackgroundTransparency = 1
statusText.TextColor3 = Color3.new(1,1,1)
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 18
statusText.Text = ""
statusText.Visible = false

-- Animation sequence
task.spawn(function()
    local glowIn = TweenService:Create(glow, TweenInfo.new(1.5), {BackgroundTransparency = 0.7})
    local glowOut = TweenService:Create(glow, TweenInfo.new(1.5), {BackgroundTransparency = 0.95})
    glowIn:Play()
    glowIn.Completed:Connect(function() glowOut:Play() end)
    glowOut.Completed:Connect(function() glowIn:Play() end)

    logo.TextTransparency = 1
    TweenService:Create(logo, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
    task.wait(1.2)

    TweenService:Create(logo, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(100,0,255)}):Play()
    task.wait(0.2)
    TweenService:Create(logo, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(255,0,150)}):Play()
    task.wait(0.3)

    local morphInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    local shrink = TweenService:Create(logo, morphInfo, {TextSize = 90, Size = UDim2.new(0,150,0,100), Position = UDim2.new(0.5,-75,0.35,-50)})
    shrink:Play()
    task.wait(0.2)
    logo.Text = "ZH"
    TweenService:Create(logo, TweenInfo.new(0.4), {TextColor3 = Color3.fromRGB(0,255,200)}):Play()
    task.wait(0.6)

    barBg.Visible = true
    statusText.Visible = true
    statusText.Text = "Connecting to ZeroHub..."

    local fetchSuccess, result
    local function updateBar(percent, text)
        TweenService:Create(barFill, TweenInfo.new(0.2), {Size = UDim2.new(percent/100,0,1,0)}):Play()
        statusText.Text = text
    end

    task.spawn(function()
        fetchSuccess, result = pcall(game.HttpGet, game, GITHUB_URL)
    end)

    for i = 1, 90, 5 do
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
        TweenService:Create(logo, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255,200,0)}):Play()
        task.wait(0.5)
        TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(logo, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TweenService:Create(barBg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        statusText.Visible = false
        task.wait(0.6)
        loader:Destroy()

        local mainFunction, err = loadstring(result)
        if mainFunction then
            mainFunction()
        else
            warn("Error executing ZeroHub: " .. tostring(err))
        end
    else
        updateBar(0, "Failed to load. Check URL / internet.")
        TweenService:Create(logo, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255,0,0)}):Play()
        task.wait(3)
        loader:Destroy()
    end
end)
