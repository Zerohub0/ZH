--[[
    ZeroHub v3.2.0 | 99 Nights in a Forest
    Modern UI + 5s loading + Update Agent
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

repeat task.wait() until Workspace:FindFirstChildWhichIsA("Model") or Workspace:FindFirstChildWhichIsA("BasePart")

-- ===================== CONFIG =====================
local CURRENT_VERSION = "3.2.0"
local RAW_GITHUB_BASE = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main"  -- CHANGE THIS
local AUTO_UPDATE = true

-- ===================== 5‑SECOND LOADING SCREEN =====================
local loadGui = Instance.new("ScreenGui", CoreGui)
loadGui.Name = "ZeroHub_Loading"

local loadBg = Instance.new("Frame", loadGui)
loadBg.Size = UDim2.new(1,0,1,0)
loadBg.BackgroundColor3 = Color3.fromRGB(10,10,10)
loadBg.BorderSizePixel = 0

local loadTitle = Instance.new("TextLabel", loadBg)
loadTitle.Size = UDim2.new(1,0,0,80)
loadTitle.Position = UDim2.new(0,0,0.30,0)
loadTitle.BackgroundTransparency = 1
loadTitle.Text = "ZEROHUB"
loadTitle.Font = Enum.Font.GothamBold
loadTitle.TextSize = 52
loadTitle.TextColor3 = Color3.fromRGB(0,255,150)

local loadBeta = Instance.new("TextLabel", loadBg)
loadBeta.Size = UDim2.new(1,0,0,24)
loadBeta.Position = UDim2.new(0,0,0.42,0)
loadBeta.BackgroundTransparency = 1
loadBeta.Text = "Initializing..."
loadBeta.Font = Enum.Font.Gotham
loadBeta.TextSize = 20
loadBeta.TextColor3 = Color3.new(1,1,1)

local barBg = Instance.new("Frame", loadBg)
barBg.Size = UDim2.new(0,300,0,10)
barBg.Position = UDim2.new(0.5,-150,0.52,0)
barBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
barBg.BorderSizePixel = 0

local barFill = Instance.new("Frame", barBg)
barFill.Size = UDim2.new(0,0,1,0)
barFill.BackgroundColor3 = Color3.fromRGB(0,255,150)
barFill.BorderSizePixel = 0

local loadList = Instance.new("TextLabel", loadBg)
loadList.Size = UDim2.new(1,0,0,120)
loadList.Position = UDim2.new(0,0,0.58,0)
loadList.BackgroundTransparency = 1
loadList.TextColor3 = Color3.fromRGB(200,200,200)
loadList.Font = Enum.Font.Gotham
loadList.TextSize = 16
loadList.TextWrapped = true
loadList.TextXAlignment = Enum.TextXAlignment.Center
loadList.TextYAlignment = Enum.TextYAlignment.Top
loadList.Text = ""

local fakeFiles = {
    "System.lua",
    "Executor.lua",
    "UI.lua",
    "Bypass.lua",
    "Features.lua",
    "Network.lua",
    "Security.lua"
}

-- 5‑second loading animation
task.spawn(function()
    local startTime = tick()
    local duration = 5
    local loaded = ""

    for i, file in ipairs(fakeFiles) do
        local targetTime = startTime + (i / #fakeFiles) * duration
        loaded = loaded .. "✅ " .. file .. "\n"
        loadList.Text = loaded
        loadBeta.Text = "Loading " .. file .. "..."
        local targetPct = i / #fakeFiles * 100
        TweenService:Create(barFill, TweenInfo.new(0.5), {Size = UDim2.new(targetPct/100,0,1,0)}):Play()
        local waitTime = targetTime - tick()
        if waitTime > 0 then task.wait(waitTime) end
    end

    TweenService:Create(barFill, TweenInfo.new(0.3), {Size = UDim2.new(1,0,1,0)}):Play()
    loadBeta.Text = "Welcome to ZeroHub!"
    task.wait(0.8)
    loadGui:Destroy()
end)

repeat task.wait() until not loadGui or not loadGui.Parent

-- ===================== SMART OBJECT SCANNER =====================
local function scan(patterns, classFilter)
    local res = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if classFilter and not classFilter[obj.ClassName] then continue end
        local name = obj.Name:lower()
        for _, pat in ipairs(patterns) do
            if name:find(pat) then table.insert(res, obj); break end
        end
    end
    return res
end

local function getFireplace() return (scan({"fireplace","campfire","bonfire","fire"}, {BasePart=true}))[1] end
local function getScrapMachine()
    local m = scan({"scrap","machine","recycler"}, {BasePart=true})
    for _,v in m do if v.Name:lower():find("scrap") and v.Name:lower():find("machine") then return v end end
    return m[1]
end
local function getLogs() return scan({"log","wood","branch","firewood"}, {BasePart=true}) end
local function getScraps() return scan({"scrap","metal","gear","spring","bolt"}, {BasePart=true}) end
local function getNPCs()
    local npcs = {}
    for _,v in Workspace:GetDescendants() do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= char then
            local head = v:FindFirstChild("Head")
            if head then table.insert(npcs, head) end
        end
    end
    return npcs
end
local function findNearestLog()
    local logs = getLogs()
    if #logs==0 then return nil end
    table.sort(logs, function(a,b) return (a.Position-root.Position).Magnitude < (b.Position-root.Position).Magnitude end)
    return logs[1]
end
local function findMerchant()
    for _,npc in ipairs(getNPCs()) do
        if npc.Parent.Name:lower():find("merchant") then return npc end
    end
end
local function getEnemiesInRange(range)
    local enemies = {}
    for _,v in Workspace:GetDescendants() do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= char then
            local h = v:FindFirstChild("Humanoid")
            local r = v:FindFirstChild("HumanoidRootPart")
            if h.Health > 0 and r and (r.Position-root.Position).Magnitude <= range then
                table.insert(enemies, {model=v, humanoid=h, root=r})
            end
        end
    end
    return enemies
end

-- ===================== MODERN UI (SIDEBAR) =====================
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "ZeroHub"
gui.ResetOnSpawn = false

local wm = Instance.new("TextLabel", gui)
wm.Size = UDim2.new(0,200,0,24)
wm.Position = UDim2.new(1,-210,0,5)
wm.BackgroundTransparency = 1
wm.TextColor3 = Color3.fromRGB(0,255,150)
wm.TextStrokeTransparency = 0.5
wm.Text = "ZeroHub v"..CURRENT_VERSION
wm.Font = Enum.Font.GothamBold
wm.TextSize = 14

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,600,0,380)
main.Position = UDim2.new(0.5,-300,0.5,-250)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BackgroundTransparency = 0.05
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Active = true
main.Draggable = true

local border = Instance.new("Frame", main)
border.Size = UDim2.new(1,0,1,0)
border.BackgroundColor3 = Color3.fromRGB(0,255,150)
border.BackgroundTransparency = 0.9
border.BorderSizePixel = 0

local topBar = Instance.new("Frame", main)
topBar.Size = UDim2.new(1,0,0,40)
topBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
topBar.BorderSizePixel = 0

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(0,200,1,0)
title.Position = UDim2.new(0,15,0,0)
title.BackgroundTransparency = 1
title.Text = "ZEROHUB"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(0,255,150)

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1,-40,0,0)
closeBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18

closeBtn.MouseButton1Click:Connect(function()
    main:TweenPosition(UDim2.new(0.5,-300,0.5,-250), "In","Quad",0.3,true)
    task.wait(0.3)
    gui:Destroy()
end)

local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0,150,1,-40)
sidebar.Position = UDim2.new(0,0,0,40)
sidebar.BackgroundColor3 = Color3.fromRGB(25,25,25)
sidebar.BorderSizePixel = 0

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1,-150,1,-40)
content.Position = UDim2.new(0,150,0,40)
content.BackgroundColor3 = Color3.fromRGB(20,20,20)
content.BorderSizePixel = 0
content.ClipsDescendants = true

local tabs = {
    {name = "Dashboard", icon = "🏠"},
    {name = "Automation", icon = "⚙️"},
    {name = "Combat", icon = "⚔️"},
    {name = "Visual", icon = "👁️"},
    {name = "Teleports", icon = "📍"},
    {name = "Settings", icon = "🔧"}
}
local curTab = "Dashboard"
local tabFrames = {}
local tabBtns = {}

for i, tab in ipairs(tabs) do
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1,-10,0,36)
    btn.Position = UDim2.new(0,5,0,(i-1)*40 + 5)
    btn.BackgroundColor3 = i==1 and Color3.fromRGB(0,255,150) or Color3.fromRGB(35,35,35)
    btn.Text = "  "..tab.icon.."  "..tab.name
    btn.TextColor3 = i==1 and Color3.new(0,0,0) or Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    tabBtns[tab.name] = btn

    local frame = Instance.new("ScrollingFrame", content)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1
    frame.ScrollBarThickness = 4
    frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frame.CanvasSize = UDim2.new(0,0,0,0)
    frame.Visible = tab.name=="Dashboard"
    tabFrames[tab.name] = frame

    btn.MouseButton1Click:Connect(function()
        if curTab==tab.name then return end
        for _,b in pairs(tabBtns) do
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(35,35,35), TextColor3=Color3.new(1,1,1)}):Play()
        end
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(0,255,150), TextColor3=Color3.new(0,0,0)}):Play()
        for _,f in pairs(tabFrames) do f.Visible=false end
        frame.Visible=true
        curTab=tab.name
    end)
end

main:TweenPosition(UDim2.new(0.5,-300,0.5,-190), "Out","Quad",0.4,true)

-- ===================== UI BUILDERS =====================
local offsets = {}
for _,t in pairs(tabs) do offsets[t.name] = 10 end

local function addToggle(tab, name, def, cb)
    local f = tabFrames[tab]
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1,-20,0,32)
    btn.Position = UDim2.new(0,10,0,offsets[tab])
    btn.BackgroundColor3 = def and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = name..": "..(def and "ON" or "OFF")
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.AutoButtonColor = false
    offsets[tab] += 36
    local state = def
    btn.MouseButton1Click:Connect(function()
        state = not state
        local col = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=col}):Play()
        btn.Text = name..": "..(state and "ON" or "OFF")
        cb(state)
    end)
end

local function addSlider(tab, name, min, max, def, cb)
    local f = tabFrames[tab]
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0,150,0,20)
    lbl.Position = UDim2.new(0,10,0,offsets[tab])
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Text = name..": "..def
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    offsets[tab] += 22
    local box = Instance.new("TextBox", f)
    box.Size = UDim2.new(1,-20,0,26)
    box.Position = UDim2.new(0,10,0,offsets[tab])
    box.Text = tostring(def)
    box.BackgroundColor3 = Color3.fromRGB(50,50,50)
    box.TextColor3 = Color3.new(1,1,1)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n and n>=min and n<=max then
            lbl.Text = name..": "..n
            cb(n)
        end
    end)
    offsets[tab] += 32
end

local function addButton(tab, name, cb)
    local f = tabFrames[tab]
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1,-20,0,32)
    btn.Position = UDim2.new(0,10,0,offsets[tab])
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.MouseButton1Click:Connect(function()
        cb()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(100,100,100)}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(50,50,50)}):Play()
    end)
    offsets[tab] += 36
end

-- ===================== DASHBOARD =====================
local dashLabel = Instance.new("TextLabel", tabFrames["Dashboard"])
dashLabel.Size = UDim2.new(1,-20,0,0)
dashLabel.Position = UDim2.new(0,10,0,10)
dashLabel.BackgroundTransparency = 1
dashLabel.TextColor3 = Color3.new(1,1,1)
dashLabel.Font = Enum.Font.Gotham
dashLabel.TextSize = 13
dashLabel.TextWrapped = true
dashLabel.TextXAlignment = Enum.TextXAlignment.Left
dashLabel.Text = [[
ZeroHub v3.2.0 – Changelog:
• Redesigned modern UI with sidebar
• 5‑second animated loading screen
• Auto Chop, Collect, Fish, Eat, Campfire, Sell
• Night Vision, Auto Torch, Auto Hide
• Kill Aura, Godmode, ESP
• Fly, Speed, Noclip, Item Magnet
• Fullbright, Fog Remover, Coords
• Teleports: Fireplace, Scrap Machine, Merchant, Tree
• Freeze World, Anti-AFK
• Update Agent (check GitHub)
]]

tabFrames["Dashboard"].CanvasSize = UDim2.new(0,0,0,280)
offsets["Dashboard"] = 290

addButton("Dashboard", "Check for Updates", function()
    local msg = "Checking..."
    dashLabel.Text = msg
    task.spawn(function()
        local success, result = pcall(function() return game:HttpGet(RAW_GITHUB_BASE.."/version.txt") end)
        if success and result then
            local latest = result:match("^%s*(.-)%s*$")
            if latest and latest ~= CURRENT_VERSION then
                local cOk, cRaw = pcall(function() return game:HttpGet(RAW_GITHUB_BASE.."/changelog.txt") end)
                dashLabel.Text = "New version "..latest.." available!\n\n"..(cOk and cRaw or "")
            else
                dashLabel.Text = "You are up to date (v"..CURRENT_VERSION..")"
            end
        else
            dashLabel.Text = "Failed to check updates. Check internet or repo URL."
        end
    end)
end)

-- ===================== STATE & FEATURES =====================
local states = {
    autoChop=false, autoCollect=false, autoFish=false, autoEatHeal=false,
    autoCampfire=false, autoSell=false, autoTorch=false, nightVision=false,
    autoHide=false, killAura=false, esp=false, godmode=false,
    fly=false, speed=false, noclip=false, magnet=false,
    instantChest=false, fullbright=false, fogRemove=false, coords=false,
    antiAFK=false, freezeWorld=false,
    speedVal=50, magnetRange=50, killRange=20, hideDistance=30
}

-- ===================== FEATURE LOOPS =====================
task.spawn(function() while task.wait(0.5) do if states.autoChop then local l=findNearestLog() if l then root.CFrame=l.CFrame*CFrame.new(0,3,2) local axe=player.Backpack:FindFirstChild("Axe") or char:FindFirstChild("Axe") if axe and axe:IsA("Tool") then axe.Parent=char axe:Activate() task.wait(0.4) axe:Deactivate() end end end end end)
task.spawn(function() while task.wait(0.3) do if states.autoCollect then for _,i in ipairs(getLogs()) do i.CFrame=root.CFrame*CFrame.new(0,0,2) end for _,i in ipairs(getScraps()) do i.CFrame=root.CFrame*CFrame.new(0,0,2) end end end end)
task.spawn(function() while task.wait(3) do if states.autoFish then local spots=scan({"fishing","water"},{BasePart=true}) if #spots>0 then root.CFrame=spots[1].CFrame+Vector3.new(0,5,2) local rod=player.Backpack:FindFirstChild("FishingRod") or char:FindFirstChild("FishingRod") if rod and rod:IsA("Tool") then rod.Parent=char rod:Activate() task.wait(1.5) rod:Deactivate() end end end end end)
task.spawn(function() while task.wait(2) do if states.autoEatHeal then if hum.Health<hum.MaxHealth*0.6 then local bandage=player.Backpack:FindFirstChild("Bandage") or char:FindFirstChild("Bandage") if bandage and bandage:IsA("Tool") then bandage.Parent=char bandage:Activate() task.wait(0.5) end end if hum.Health<hum.MaxHealth*0.8 then local food=player.Backpack:FindFirstChild("Food") or char:FindFirstChild("Food") if food and food:IsA("Tool") then food.Parent=char food:Activate() task.wait(0.5) end end end end end)
task.spawn(function() while task.wait(1) do if states.autoCampfire then local fire=getFireplace() if fire then root.CFrame=fire.CFrame*CFrame.new(0,2,1) pcall(function() local r=fire.Parent:FindFirstChild("UpgradeRemote") or fire.Parent:FindFirstChild("RemoteEvent") if r then r:FireServer() end end) end end end end)
task.spawn(function() while task.wait(3) do if states.autoSell then local merchant=findMerchant() if merchant then root.CFrame=merchant.CFrame*CFrame.new(0,1,2) pcall(function() local r=merchant.Parent:FindFirstChild("SellRemote") or merchant.Parent:FindFirstChild("RemoteEvent") if r then r:FireServer() end end) end end end end)
task.spawn(function() while task.wait(5) do if states.autoTorch then if Lighting.ClockTime>18 or Lighting.ClockTime<6 then local torch=player.Backpack:FindFirstChild("Torch") or char:FindFirstChild("Torch") if torch and torch:IsA("Tool") then torch.Parent=char end end end end end)
task.spawn(function() while task.wait(1) do if states.nightVision then Lighting.Ambient=Color3.new(1,1,1) Lighting.Brightness=2 elseif not states.fullbright then Lighting.Ambient=Color3.new(0,0,0) Lighting.Brightness=1 end end end)
task.spawn(function() while task.wait(0.5) do if states.autoHide then if #getEnemiesInRange(states.hideDistance)>0 then hum.Sit=true else hum.Sit=false end end end end)
task.spawn(function() while task.wait(0.1) do if states.killAura then for _,e in ipairs(getEnemiesInRange(states.killRange)) do root.CFrame=e.root.CFrame*CFrame.new(0,0,2) local weapon=char:FindFirstChildOfClass("Tool") if weapon then weapon:Activate() task.wait(0.05) weapon:Deactivate() end end end end end)
task.spawn(function() while task.wait(0.1) do if states.godmode and hum then hum.Health=hum.MaxHealth end end end)

-- ===================== FLY, SPEED, VISUALS =====================
local flyGyro, flyVel
local function startFly()
    flyGyro = Instance.new("BodyGyro") flyGyro.MaxTorque=Vector3.new(1,1,1)*1e6 flyGyro.P=1e5 flyGyro.Parent=root
    flyVel = Instance.new("BodyVelocity") flyVel.MaxForce=Vector3.new(1,1,1)*1e6 flyVel.Velocity=Vector3.zero flyVel.Parent=root
    hum.PlatformStand=true
end
local function stopFly()
    if flyGyro then flyGyro:Destroy() flyGyro=nil end
    if flyVel then flyVel:Destroy() flyVel=nil end
    hum.PlatformStand=false
end
UserInputService.InputBegan:Connect(function(i,gpe) if gpe or not states.fly or not flyVel then return end local cam=Workspace.CurrentCamera if i.KeyCode==Enum.KeyCode.W then flyVel.Velocity=cam.CFrame.LookVector*50 elseif i.KeyCode==Enum.KeyCode.S then flyVel.Velocity=cam.CFrame.LookVector*-50 elseif i.KeyCode==Enum.KeyCode.Space then flyVel.Velocity=Vector3.new(0,50,0) elseif i.KeyCode==Enum.KeyCode.LeftControl then flyVel.Velocity=Vector3.new(0,-50,0) end end)
UserInputService.InputEnded:Connect(function(i,_) if states.fly and flyVel then if i.KeyCode==Enum.KeyCode.W or i.KeyCode==Enum.KeyCode.S or i.KeyCode==Enum.KeyCode.Space or i.KeyCode==Enum.KeyCode.LeftControl then flyVel.Velocity=Vector3.zero end end end)
local function updateSpeed() if hum then hum.WalkSpeed=states.speed and states.speedVal or 16 end end
task.spawn(function() while task.wait(0.1) do if states.noclip then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end end)
task.spawn(function() while task.wait(0.3) do if states.magnet then for _,v in ipairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and not v:IsA("Tool") then local n=v.Name:lower() if n:find("fuel") or n:find("gear") or n:find("weapon") or n:find("armor") or n:find("food") then if (v.Position-root.Position).Magnitude<=states.magnetRange then v.CFrame=root.CFrame*CFrame.new(0,0,2) end end end end end end end)
task.spawn(function() while task.wait(0.5) do if states.instantChest then for _,v in ipairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and v.Name:lower():find("chest") then firetouchinterest(root,v,0) firetouchinterest(root,v,1) end end end end end)
local function setFullbright(v) Lighting.Ambient=v and Color3.new(1,1,1) or Color3.new(0,0,0) Lighting.Brightness=v and 2 or 1 end
local function setFogRemove(v) Lighting.FogEnd=v and 1e6 or 1000 Lighting.FogStart=v and 1e6 or 0 for _,sky in ipairs(Lighting:GetChildren()) do if sky:IsA("Sky") then sky.Parent=v and nil or Lighting end end end
local coordGui
local function toggleCoords(v)
    if v then
        coordGui = Instance.new("TextLabel",gui) coordGui.Size=UDim2.new(0,200,0,20) coordGui.Position=UDim2.new(0.8,0,0.02,0) coordGui.BackgroundTransparency=1 coordGui.TextColor3=Color3.new(1,1,1) coordGui.TextStrokeTransparency=0 coordGui.Font=Enum.Font.Gotham coordGui.TextSize=14
        task.spawn(function() while states.coords and coordGui do coordGui.Text=string.format("X:%.1f Y:%.1f Z:%.1f",root.Position.X,root.Position.Y,root.Position.Z) task.wait() end end)
    else if coordGui then coordGui:Destroy() coordGui=nil end end
end
task.spawn(function() while task.wait(300) do if states.antiAFK then pcall(function() VirtualUser:CaptureController() VirtualUser:Button2Down(Vector2.new(0,0),Workspace.CurrentCamera.CFrame) end) end end end)
task.spawn(function() while task.wait(0.5) do if states.freezeWorld then for _,v in ipairs(Workspace:GetDescendants()) do if v:IsA("BasePart") and not v.Anchored then v.Anchored=true end end end end end)

-- ESP
local espItems={}
local function updateESP()
    for _,o in pairs(espItems) do pcall(function() o:Remove() end) end espItems={}
    if not states.esp or not Drawing then return end
    local function addESP(p,l,c)
        local line=Drawing.new("Line") line.Visible=true line.Color=c line.Thickness=2 line.Transparency=1 table.insert(espItems,line)
        local txt=Drawing.new("Text") txt.Visible=true txt.Color=c txt.Size=14 txt.Center=true txt.Outline=true table.insert(espItems,txt)
        task.spawn(function() while states.esp and p and p.Parent do local pos,on=Workspace.CurrentCamera:WorldToViewportPoint(p.Position) if on then line.From=Vector2.new(Workspace.CurrentCamera.ViewportSize.X/2,Workspace.CurrentCamera.ViewportSize.Y) line.To=Vector2.new(pos.X,pos.Y) txt.Position=Vector2.new(pos.X,pos.Y) txt.Text=l.." ["..math.floor((root.Position-p.Position).Magnitude).."m]" line.Visible,txt.Visible=true,true else line.Visible,txt.Visible=false,false end task.wait() end pcall(function() line:Remove() txt:Remove() end) end)
    end
    for _,l in ipairs(getLogs()) do addESP(l,"Log",Color3.fromRGB(0,255,0)) end
    for _,n in ipairs(getNPCs()) do addESP(n,"NPC",Color3.fromRGB(255,0,0)) end
end
task.spawn(function() while task.wait(3) do if states.esp then updateESP() end end end)

-- ===================== BUILD TABS =====================
addToggle("Automation","Auto Chop",false,function(v) states.autoChop=v end)
addToggle("Automation","Auto Collect",false,function(v) states.autoCollect=v end)
addToggle("Automation","Auto Fish",false,function(v) states.autoFish=v end)
addToggle("Automation","Auto Eat/Heal",false,function(v) states.autoEatHeal=v end)
addToggle("Automation","Auto Campfire",false,function(v) states.autoCampfire=v end)
addToggle("Automation","Auto Sell",false,function(v) states.autoSell=v end)
addToggle("Automation","Auto Torch",false,function(v) states.autoTorch=v end)
addToggle("Automation","Night Vision",false,function(v) states.nightVision=v end)
addToggle("Automation","Auto Hide",false,function(v) states.autoHide=v end)
addSlider("Automation","Hide Distance",10,100,30,function(v) states.hideDistance=v end)
addButton("Automation","Find Nearest Log",function() local l=findNearestLog() if l then root.CFrame=l.CFrame+Vector3.new(0,3,2) end end)
addButton("Automation","TP Logs → Fireplace",function() local fire=getFireplace() if fire then for _,l in ipairs(getLogs()) do l.CFrame=fire.CFrame*CFrame.new(0,2,0) end end end)
addButton("Automation","TP Scraps → Scrap Machine",function() local m=getScrapMachine() if m then for _,s in ipairs(getScraps()) do s.CFrame=m.CFrame*CFrame.new(0,2,0) end end end)

addToggle("Combat","Kill Aura",false,function(v) states.killAura=v end)
addSlider("Combat","Kill Range",5,50,20,function(v) states.killRange=v end)
addToggle("Combat","ESP",false,function(v) states.esp=v if v then updateESP() else for _,o in pairs(espItems) do o:Remove() end espItems={} end end)
addToggle("Combat","Godmode",false,function(v) states.godmode=v end)

addToggle("Visual","Fullbright",false,function(v) states.fullbright=v setFullbright(v) end)
addToggle("Visual","Fog Remove",false,function(v) states.fogRemove=v setFogRemove(v) end)
addToggle("Visual","Show Coords",false,function(v) states.coords=v toggleCoords(v) end)

addButton("Teleports","TP to Fireplace",function() local f=getFireplace() if f then root.CFrame=f.CFrame+Vector3.new(0,5,0) end end)
addButton("Teleports","TP to Scrap Machine",function() local m=getScrapMachine() if m then root.CFrame=m.CFrame+Vector3.new(0,5,0) end end)
addButton("Teleports","TP to Merchant",function() local m=findMerchant() if m then root.CFrame=m.CFrame+Vector3.new(0,3,0) end end)
addButton("Teleports","TP to Random Tree",function() local logs=getLogs() if #logs>0 then local t=logs[math.random(#logs)] root.CFrame=t.CFrame+Vector3.new(0,5,0) end end)

addToggle("Settings","Fly",false,function(v) states.fly=v if v then startFly() else stopFly() end end)
addToggle("Settings","Speed Hack",false,function(v) states.speed=v updateSpeed() end)
addSlider("Settings","Speed Value",16,500,50,function(v) states.speedVal=v if states.speed then updateSpeed() end end)
addToggle("Settings","Noclip",false,function(v) states.noclip=v end)
addToggle("Settings","Item Magnet",false,function(v) states.magnet=v end)
addSlider("Settings","Magnet Range",10,200,50,function(v) states.magnetRange=v end)
addToggle("Settings","Instant Chest",false,function(v) states.instantChest=v end)
addToggle("Settings","Anti-AFK",false,function(v) states.antiAFK=v end)
addToggle("Settings","Freeze World",false,function(v) states.freezeWorld=v end)

-- ===================== RESPAWN & AUTO UPDATE =====================
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    root = char:WaitForChild("HumanoidRootPart")
    hum = char:WaitForChild("Humanoid")
    if states.fly then startFly() end
    updateSpeed()
end)

if AUTO_UPDATE and RAW_GITHUB_BASE ~= "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main" then
    task.spawn(function()
        local s,r = pcall(function() return game:HttpGet(RAW_GITHUB_BASE.."/version.txt") end)
        if s and r then
            local latest = r:match("^%s*(.-)%s*$")
            if latest and latest~=CURRENT_VERSION then
                local notif = Instance.new("TextLabel",gui)
                notif.Size = UDim2.new(1,-40,0,60)
                notif.Position = UDim2.new(0,20,0,-60)
                notif.BackgroundColor3=Color3.fromRGB(0,0,0) notif.BackgroundTransparency=0.3
                notif.TextColor3=Color3.new(1,1,1) notif.Text="Update "..latest.." available!" notif.Font=Enum.Font.Gotham notif.TextSize=14
                TweenService:Create(notif,TweenInfo.new(0.5),{Position=UDim2.new(0,20,0,10)}):Play()
                task.delay(8,function() notif:Destroy() end)
            end
        end
    end)
end

print("ZeroHub v3.2.0 loaded successfully.")
