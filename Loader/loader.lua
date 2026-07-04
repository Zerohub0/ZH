-- ZeroHub Loader v6.0 | Remote config via npoint.io
local CONFIG_URL = "https://api.npoint.io/e00fe3bb6747ca25eef5"  -- ← paste your npoint URL here

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local currentVersion = ""  -- will be set later

-- ========== LOADING GUI (same clean animation) ==========
local loader = Instance.new("ScreenGui", CoreGui)
loader.Name = "ZeroHub_Loader"

local bg = Instance.new("Frame", loader)
bg.Size = UDim2.new(1,0,1,0)
bg.BackgroundColor3 = Color3.fromRGB(12,18,30)
bg.BorderSizePixel = 0

local orb = Instance.new("Frame", bg)
orb.Size = UDim2.new(0,120,0,120)
orb.Position = UDim2.new(0.5,-60,0.35,-60)
orb.BackgroundColor3 = Color3.fromRGB(0,255,150)
orb.BackgroundTransparency = 0.85
orb.BorderSizePixel = 0
Instance.new("UICorner", orb).CornerRadius = UDim.new(1,0)

local logo = Instance.new("TextLabel", bg)
logo.Size = UDim2.new(0,500,0,120)
logo.Position = UDim2.new(0.5,-250,0.35,-60)
logo.BackgroundTransparency = 1
logo.Text = "ZEROHUB"
logo.Font = Enum.Font.GothamBold
logo.TextSize = 56
logo.TextColor3 = Color3.fromRGB(0,255,200)
logo.TextStrokeTransparency = 0.7
logo.Rotation = 0

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

-- ========== ANIMATION & FETCH LOGIC ==========
task.spawn(function()
    -- Pulse orb
    local orbIn = TweenService:Create(orb, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.6})
    local orbOut = TweenService:Create(orb, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.9})
    orbIn:Play()
    orbIn.Completed:Connect(function() orbOut:Play() end)
    orbOut.Completed:Connect(function() orbIn:Play() end)

    -- Fade in logo
    logo.TextTransparency = 1
    TweenService:Create(logo, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
    task.wait(1.2)

    -- Spin & colour shift
    TweenService:Create(logo, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {Rotation = 360, TextColor3 = Color3.fromRGB(120,0,255)}):Play()
    task.wait(1.0)
    logo.Rotation = 0

    -- Morph to "ZH"
    TweenService:Create(logo, TweenInfo.new(0.6), {TextSize = 80, Size = UDim2.new(0,160,0,90), Position = UDim2.new(0.5,-80,0.35,-45)}):Play()
    task.wait(0.3)
    logo.Text = "ZH"
    TweenService:Create(logo, TweenInfo.new(0.5), {TextColor3 = Color3.fromRGB(0,255,200), TextSize = 70}):Play()
    task.wait(0.6)

    barBg.Visible = true
    statusText.Visible = true
    statusText.Text = "Fetching update config..."

    -- Fetch remote JSON config
    local configData, hubScript
    local function updateBar(pct, txt)
        TweenService:Create(barFill, TweenInfo.new(0.3), {Size = UDim2.new(pct/100,0,1,0)}):Play()
        statusText.Text = txt
    end

    -- Fetch config
    local success, result = pcall(game.HttpGet, game, CONFIG_URL)
    if success and result then
        local config = HttpService:JSONDecode(result)
        currentVersion = config.version
        -- Update changelog on Dashboard (not shown here, but we can store it globally)
        _G.ZeroHubChangelog = config.changelog
        _G.ZeroHubVersion = config.version
        updateBar(30, "Config loaded. v" .. config.version)

        -- Now fetch the actual hub from the URL in config
        task.wait(0.3)
        updateBar(50, "Downloading ZeroHub...")
        local hubOk, hubResult = pcall(game.HttpGet, game, config.hub_url)
        if hubOk and hubResult then
            hubScript = hubResult
            updateBar(90, "Starting...")
        else
            updateBar(0, "Failed to download hub.")
            TweenService:Create(logo, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255,0,0)}):Play()
            task.wait(3)
            loader:Destroy()
            return
        end
    else
        -- Fallback: try the old direct URL just in case
        local fallbackUrl = "https://raw.githubusercontent.com/Zerohub0/ZH/main/Hub/zerohub.lua"
        updateBar(20, "Config failed, trying direct...")
        local fbOk, fbResult = pcall(game.HttpGet, game, fallbackUrl)
        if fbOk and fbResult then
            hubScript = fbResult
            _G.ZeroHubChangelog = "Direct load (no config)"
            _G.ZeroHubVersion = "unknown"
        else
            updateBar(0, "Failed to load. Check network.")
            TweenService:Create(logo, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255,0,0)}):Play()
            task.wait(3)
            loader:Destroy()
            return
        end
    end

    updateBar(100, "Launching...")
    TweenService:Create(logo, TweenInfo.new(0.4), {TextColor3 = Color3.fromRGB(255,200,0)}):Play()
    task.wait(0.6)

    -- Fade out loader
    TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(logo, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TweenService:Create(barBg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    statusText.Visible = false
    task.wait(0.6)
    loader:Destroy()

    -- Execute the hub
    local mainFunc, err = loadstring(hubScript)
    if mainFunc then
        mainFunc()
    else
        warn("ZeroHub execution error: " .. tostring(err))
    end
end)
