-- ZeroHub Loader v9.0 – clear, 4‑second animation, remote config
local CONFIG_URL = "https://api.npoint.io/ddb0afe5e45666ec1974"

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local loader = Instance.new("ScreenGui", CoreGui)
loader.Name = "ZeroHub_Loader"

local bg = Instance.new("Frame", loader)
bg.Size = UDim2.new(1,0,1,0)
bg.BackgroundColor3 = Color3.fromRGB(18,20,25)
bg.BorderSizePixel = 0

local logo = Instance.new("TextLabel", bg)
logo.Size = UDim2.new(0,200,0,80)
logo.Position = UDim2.new(0.5,-100,0.42,-40)
logo.BackgroundTransparency = 1
logo.Text = "ZH"
logo.Font = Enum.Font.GothamBold
logo.TextSize = 72
logo.TextColor3 = Color3.new(1,1,1)

local statusText = Instance.new("TextLabel", bg)
statusText.Size = UDim2.new(1,0,0,24)
statusText.Position = UDim2.new(0,0,0.54,0)
statusText.BackgroundTransparency = 1
statusText.TextColor3 = Color3.new(1,1,1)
statusText.Text = "Loading..."
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 20

local versionText = Instance.new("TextLabel", bg)
versionText.Size = UDim2.new(1,0,0,20)
versionText.Position = UDim2.new(0,0,0.62,0)
versionText.BackgroundTransparency = 1
versionText.TextColor3 = Color3.fromRGB(0,255,150)
versionText.Text = ""
versionText.Font = Enum.Font.Gotham
versionText.TextSize = 14

local barBg = Instance.new("Frame", bg)
barBg.Size = UDim2.new(0,300,0,6)
barBg.Position = UDim2.new(0.5,-150,0.68,0)
barBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
barBg.BorderSizePixel = 0
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1,0)

local barFill = Instance.new("Frame", barBg)
barFill.Size = UDim2.new(0,0,1,0)
barFill.BackgroundColor3 = Color3.fromRGB(0,255,150)
barFill.BorderSizePixel = 0
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1,0)

-- Animate & fetch
task.spawn(function()
    logo.TextTransparency = 1
    TweenService:Create(logo, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    task.wait(0.6)

    local function updateBar(pct, txt, ver)
        TweenService:Create(barFill, TweenInfo.new(0.2), {Size = UDim2.new(pct/100,0,1,0)}):Play()
        statusText.Text = txt
        if ver then versionText.Text = "v" .. ver end
    end

    updateBar(10, "Fetching config...")
    local success, result = pcall(game.HttpGet, game, CONFIG_URL)
    if success and result then
        local config = HttpService:JSONDecode(result)
        _G.ZeroHubVersion = config.version
        _G.ZeroHubChangelog = config.changelog
        updateBar(30, "Config loaded", config.version)

        local hubOk, hubResult = pcall(game.HttpGet, game, config.hub_url)
        if hubOk and hubResult then
            updateBar(60, "Downloading ZeroHub...")
            task.wait(0.3)
            updateBar(100, "Launching!")
            task.wait(0.5)
            TweenService:Create(bg, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(logo, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            statusText.Visible = false
            versionText.Visible = false
            barBg.Visible = false
            task.wait(0.3)
            loader:Destroy()
            local f = loadstring(hubResult)
            if f then f() else warn("ZeroHub loadstring error") end
        else
            updateBar(0, "Hub download failed")
            task.wait(2)
            loader:Destroy()
        end
    else
        updateBar(0, "Config failed")
        task.wait(2)
        loader:Destroy()
    end
end)
