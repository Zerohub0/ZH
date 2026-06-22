-- ============================================
-- ROBLOX GAME ENGINE - PROFESSIONAL SCRIPT
-- ============================================
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- ============================================
-- GAME CONFIGURATION
-- ============================================

local CONFIG = {
	startingGold = 500,
	startingHealth = 100,
	startingLevel = 1,
	expPerLevel = 500,
	saveInterval = 60,
	respawnTime = 5,
}

local PLAYER_DATA = {}
local ACTIVE_SESSIONS = {}

-- ============================================
-- DATA STORE SETUP
-- ============================================

local playerDataStore = DataStoreService:GetDataStore("PlayerGameData_v1")
local playerStatsStore = DataStoreService:GetDataStore("PlayerStats_v1")

-- ============================================
-- PLAYER CLASS
-- ============================================

local Player = {}
Player.__index = Player

function Player.new(humanoidRootPart, userId)
	local self = setmetatable({}, Player)

	self.userId = userId
	self.humanoidRootPart = humanoidRootPart
	self.humanoid = humanoidRootPart.Parent:WaitForChild("Humanoid")
	self.character = humanoidRootPart.Parent

	-- Core stats
	self.level = CONFIG.startingLevel
	self.experience = 0
	self.gold = CONFIG.startingGold
	self.health = CONFIG.startingHealth

	-- Inventory
	self.inventory = {}
	self.equipment = {}

	-- Combat stats
	self.attack = 10
	self.defense = 5
	self.attackSpeed = 1

	-- Status
	self.inCombat = false
	self.isDead = false
	self.lastDamageTime = 0

	-- UI
	self.screenGui = Instance.new("ScreenGui")
	self.screenGui.Parent = game.Players:FindFirstChild(tostring(userId)).PlayerGui if game.Players:FindFirstChild(tostring(userId)) else nil

	return self
end

function Player:update()
	self.humanoid.Health = self.health
end

function Player:addExperience(amount)
	self.experience = self.experience + amount
	local threshold = self.level * CONFIG.expPerLevel

	if self.experience >= threshold then
		self:levelUp()
	end
end

function Player:levelUp()
	self.level = self.level + 1
	self.experience = 0
	self.health = self.health + 20
	self.attack = self.attack + 3
	self.defense = self.defense + 2
	self:notify("⬆️ Level " .. self.level .. "!")
end

function Player:takeDamage(amount)
	local damageReduction = self.defense * 0.1
	local actualDamage = math.max(1, amount - damageReduction)
	self.health = math.max(0, self.health - actualDamage)
	self:update()

	if self.health <= 0 then
		self:die()
	end

	self:notify("-" .. math.floor(actualDamage) .. " HP")
end

function Player:heal(amount)
	self.health = math.min(self.health + amount, 100 + (self.level * 10))
	self:update()
	self:notify("+" .. amount .. " HP")
end

function Player:addGold(amount)
	self.gold = self.gold + amount
	self:notify("+" .. amount .. " Gold")
end

function Player:addToInventory(itemName, amount)
	amount = amount or 1
	if not self.inventory[itemName] then
		self.inventory[itemName] = 0
	end
	self.inventory[itemName] = self.inventory[itemName] + amount
	self:notify("Added " .. itemName .. " x" .. amount)
end

function Player:die()
	self.isDead = true
	self:notify("💀 You died!")

	-- Respawn after delay
	task.wait(CONFIG.respawnTime)
	self.health = 100 + (self.level * 10)
	self.isDead = false
	self.humanoidRootPart.CFrame = CFrame.new(0, 50, 0)
	self:update()
	self:notify("Respawned!")
end

function Player:notify(message)
	-- Send notification to client
	if self.screenGui then
		local notification = Instance.new("TextLabel")
		notification.Text = message
		notification.TextScaled = true
		notification.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
		notification.TextColor3 = Color3.fromRGB(255, 255, 255)
		notification.BorderSizePixel = 0
		notification.Size = UDim2.new(0, 200, 0, 50)
		notification.Position = UDim2.new(0.5, -100, 0, 10)
		notification.Parent = self.screenGui

		game:GetService("Debris"):AddItem(notification, 2)
	end
end

function Player:saveData()
	local success, err = pcall(function()
		local data = {
			level = self.level,
			experience = self.experience,
			gold = self.gold,
			health = self.health,
			attack = self.attack,
			defense = self.defense,
			attackSpeed = self.attackSpeed,
			inventory = self.inventory,
			equipment = self.equipment,
			lastSave = os.time(),
		}
		playerDataStore:SetAsync(self.userId, data)
	end)

	if not success then
		warn("Failed to save player data for " .. self.userId .. ": " .. err)
	end
end

function Player:loadData()
	local success, data = pcall(function()
		return playerDataStore:GetAsync(self.userId)
	end)

	if success and data then
		self.level = data.level or CONFIG.startingLevel
		self.experience = data.experience or 0
		self.gold = data.gold or CONFIG.startingGold
		self.health = data.health or CONFIG.startingHealth
		self.attack = data.attack or 10
		self.defense = data.defense or 5
		self.attackSpeed = data.attackSpeed or 1
		self.inventory = data.inventory or {}
		self.equipment = data.equipment or {}
	end
	self:update()
end

-- ============================================
-- ENEMY CLASS
-- ============================================

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(humanoidRootPart, enemyType)
	local self = setmetatable({}, Enemy)

	self.humanoidRootPart = humanoidRootPart
	self.humanoid = humanoidRootPart.Parent:WaitForChild("Humanoid")
	self.character = humanoidRootPart.Parent
	self.enemyType = enemyType or "goblin"

	-- Enemy stats
	self.level = 1
	self.health = 50
	self.maxHealth = 50
	self.attack = 8
	self.defense = 2
	self.experience = 100
	self.goldDrop = 50

	self.isDead = false
	self.targetPlayer = nil
	self.inCombat = false
	self.lastAttackTime = 0
	self.attackCooldown = 1.5

	return self
end

function Enemy:update()
	self.humanoid.Health = self.health
end

function Enemy:takeDamage(amount)
	local damageReduction = self.defense * 0.1
	local actualDamage = math.max(1, amount - damageReduction)
	self.health = math.max(0, self.health - actualDamage)
	self:update()

	if self.health <= 0 then
		self:die()
	end
end

function Enemy:attack(targetPlayer)
	if tick() - self.lastAttackTime < self.attackCooldown then
		return
	end

	self.lastAttackTime = tick()
	local damage = self.attack + math.random(-2, 2)
	targetPlayer:takeDamage(damage)
end

function Enemy:die()
	self.isDead = true
	if self.targetPlayer then
		self.targetPlayer:addExperience(self.experience)
		self.targetPlayer:addGold(self.goldDrop)
	end
	self.character:Destroy()
end

function Enemy:moveTowards(position)
	local direction = (position - self.humanoidRootPart.Position).Unit
	self.humanoid:MoveTo(self.humanoidRootPart.Position + direction * 5)
end

-- ============================================
-- COMBAT SYSTEM
-- ============================================

local Combat = {}

function Combat.playerAttack(player, enemy)
	if player.isDead or enemy.isDead then
		return
	end

	local damage = player.attack + math.random(-3, 3)
	enemy:takeDamage(damage)

	if not player.inCombat then
		player.inCombat = true
		enemy.inCombat = true
		enemy.targetPlayer = player
	end
end

function Combat.enemyAttack(enemy, player)
	if enemy.isDead or player.isDead then
		return
	end

	enemy:attack(player)
end

-- ============================================
-- PLAYER MANAGEMENT
-- ============================================

local function createPlayer(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	local gamePlayer = Player.new(humanoidRootPart, player.UserId)
	gamePlayer:loadData()

	PLAYER_DATA[player.UserId] = gamePlayer
	ACTIVE_SESSIONS[player.UserId] = {
		player = gamePlayer,
		joinTime = tick(),
		lastSaveTime = tick(),
	}

	print("Player " .. player.Name .. " created with ID: " .. player.UserId)

	-- Setup respawn
	character.Humanoid.Died:Connect(function()
		if PLAYER_DATA[player.UserId] then
			PLAYER_DATA[player.UserId]:die()
		end
	end)

	-- Handle new character
	player.CharacterAdded:Connect(function(newCharacter)
		newCharacter:WaitForChild("HumanoidRootPart")
		local newHRP = newCharacter.HumanoidRootPart
		gamePlayer.humanoidRootPart = newHRP
		gamePlayer.character = newCharacter
		gamePlayer.humanoid = newCharacter.Humanoid
		gamePlayer:update()
	end)

	return gamePlayer
end

local function removePlayer(player)
	if PLAYER_DATA[player.UserId] then
		PLAYER_DATA[player.UserId]:saveData()
		PLAYER_DATA[player.UserId] = nil
	end
	ACTIVE_SESSIONS[player.UserId] = nil
	print("Player " .. player.Name .. " removed")
end

-- ============================================
-- PLAYER EVENTS
-- ============================================

Players.PlayerAdded:Connect(function(player)
	task.wait(0.5) -- Wait for character to load
	createPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	removePlayer(player)
end)

-- ============================================
-- MAIN GAME LOOP
-- ============================================

RunService.Heartbeat:Connect(function(deltaTime)
	-- Update all active players
	for userId, session in pairs(ACTIVE_SESSIONS) do
		local gamePlayer = session.player

		if gamePlayer and gamePlayer.character then
			-- Auto-heal over time
			if gamePlayer.health < (100 + gamePlayer.level * 10) then
				gamePlayer.health = gamePlayer.health + 0.1
				gamePlayer:update()
			end

			-- Save periodically
			if tick() - session.lastSaveTime > CONFIG.saveInterval then
				gamePlayer:saveData()
				session.lastSaveTime = tick()
			end
		end
	end
end)

-- ============================================
-- ENEMY SPAWNING SYSTEM
-- ============================================

local EnemySpawner = {}

function EnemySpawner.spawnEnemy(position, enemyType)
	enemyType = enemyType or "goblin"

	-- Create enemy model (you should use actual models)
	local enemyModel = Instance.new("Model")
	enemyModel.Name = "Enemy_" .. enemyType

	local humanoidRootPart = Instance.new("Part")
	humanoidRootPart.Name = "HumanoidRootPart"
	humanoidRootPart.Shape = Enum.PartType.Ball
	humanoidRootPart.Size = Vector3.new(2, 2, 2)
	humanoidRootPart.CanCollide = false
	humanoidRootPart.CFrame = CFrame.new(position)
	humanoidRootPart.Parent = enemyModel

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = enemyModel

	enemyModel.Parent = workspace

	local enemy = Enemy.new(humanoidRootPart, enemyType)
	return enemy
end

-- ============================================
-- SHOP SYSTEM
-- ============================================

local Shop = {}
Shop.items = {
	healthPotion = { name = "Health Potion", cost = 50, healAmount = 50 },
	manaPotion = { name = "Mana Potion", cost = 75, manaAmount = 50 },
	sword = { name = "Iron Sword", cost = 200, attack = 15 },
	armor = { name = "Steel Armor", cost = 250, defense = 10 },
}

function Shop.buy(player, itemName)
	if not Shop.items[itemName] then
		player:notify("Item not found")
		return false
	end

	local item = Shop.items[itemName]

	if player.gold < item.cost then
		player:notify("Not enough gold!")
		return false
	end

	player.gold = player.gold - item.cost

	if itemName == "healthPotion" then
		player:heal(item.healAmount)
	elseif itemName == "sword" then
		player.attack = player.attack + item.attack
		player:addToInventory("Iron Sword")
	elseif itemName == "armor" then
		player.defense = player.defense + item.defense
		player:addToInventory("Steel Armor")
	end

	player:notify("Purchased: " .. item.name)
	return true
end

-- ============================================
-- NPC DIALOGUE SYSTEM
-- ============================================

local NPC = {}

function NPC.createTrader(position)
	local npcModel = Instance.new("Model")
	npcModel.Name = "Trader_NPC"

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1, 1, 1)
	head.CanCollide = true
	head.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	head.Parent = npcModel

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = npcModel

	npcModel.Parent = workspace

	return npcModel
end

-- ============================================
-- QUEST SYSTEM
-- ============================================

local Quest = {}
Quest.quests = {
	defeatenemies = {
		name = "Defeat Enemies",
		description = "Defeat 5 enemies",
		targetCount = 5,
		reward = 500,
		rewardGold = 200,
	},
	collectItems = {
		name = "Collect Items",
		description = "Collect 10 items",
		targetCount = 10,
		reward = 300,
		rewardGold = 150,
	},
}

function Quest.startQuest(player, questName)
	if not Quest.quests[questName] then
		player:notify("Quest not found")
		return
	end

	local quest = Quest.quests[questName]
	player:notify("Started Quest: " .. quest.name)
	-- Implementation of quest tracking would go here
end

-- ============================================
-- GAME COMMANDS (For testing)
-- ============================================

local Commands = {}

function Commands.processCommand(player, command, args)
	local gamePlayer = PLAYER_DATA[player.UserId]
	if not gamePlayer then
		return
	end

	if command == "addexp" then
		local amount = tonumber(args[1]) or 100
		gamePlayer:addExperience(amount)
		gamePlayer:notify("Added " .. amount .. " XP")
	elseif command == "addgold" then
		local amount = tonumber(args[1]) or 100
		gamePlayer:addGold(amount)
	elseif command == "levelup" then
		gamePlayer:levelUp()
	elseif command == "heal" then
		gamePlayer:heal(50)
	elseif command == "damage" then
		local amount = tonumber(args[1]) or 10
		gamePlayer:takeDamage(amount)
	elseif command == "spawn_enemy" then
		local enemyType = args[1] or "goblin"
		EnemySpawner.spawnEnemy(gamePlayer.humanoidRootPart.Position + Vector3.new(5, 0, 0), enemyType)
		gamePlayer:notify("Enemy spawned!")
	elseif command == "buy" then
		local itemName = args[1] or "healthPotion"
		Shop.buy(gamePlayer, itemName)
	elseif command == "stats" then
		gamePlayer:notify(
			"Level: "
				.. gamePlayer.level
				.. " | HP: "
				.. math.floor(gamePlayer.health)
				.. " | Gold: "
				.. gamePlayer.gold
		)
	elseif command == "save" then
		gamePlayer:saveData()
		gamePlayer:notify("Saved!")
	end
end

-- ============================================
-- CHATTED EVENT (For commands)
-- ============================================

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local parts = string.split(message, " ")
		local command = parts[1]:lower()
		local args = { unpack(parts, 2) }

		if command:sub(1, 1) == "/" then
			command = command:sub(2)
			Commands.processCommand(player, command, args)
		end
	end)
end)

-- ============================================
-- INITIALIZATION
-- ============================================

print("🎮 Professional Roblox Game Engine Loaded")
print("Commands: /addexp /addgold /levelup /heal /damage /spawn_enemy /buy /stats /save")

-- Handle existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		createPlayer(player)
	end)
end

-- ============================================
-- EXAMPLE: AUTO COMBAT LOOP FOR ENEMIES
-- ============================================

task.spawn(function()
	while true do
		task.wait(0.5)

		-- Find all enemies in workspace
		local enemies = {}
		for _, child in pairs(workspace:GetChildren()) do
			if child:FindFirstChild("Humanoid") and child.Name:match("^Enemy_") then
				table.insert(enemies, child)
			end
		end

		-- Combat loop
		for userId, session in pairs(ACTIVE_SESSIONS) do
			local gamePlayer = session.player
			if gamePlayer and gamePlayer.character and not gamePlayer.isDead then
				local playerPos = gamePlayer.humanoidRootPart.Position

				-- Find nearest enemy
				local nearestEnemy = nil
				local nearestDistance = math.huge

				for _, enemyModel in pairs(enemies) do
					if enemyModel:FindFirstChild("HumanoidRootPart") then
						local distance = (enemyModel.HumanoidRootPart.Position - playerPos).Magnitude

						if distance < 100 and distance < nearestDistance then
							nearestDistance = distance
							nearestEnemy = enemyModel
						end
					end
				end

				-- Attack if close enough
				if nearestEnemy and nearestDistance < 20 then
					local enemy = Enemy.new(
						nearestEnemy:FindFirstChild("HumanoidRootPart"),
						nearestEnemy.Name
					)
					Combat.playerAttack(gamePlayer, enemy)
				end
			end
		end
	end
end)

return {
	Player = Player,
	Enemy = Enemy,
	Combat = Combat,
	Shop = Shop,
	Quest = Quest,
	EnemySpawner = EnemySpawner,
	Commands = Commands,
}
