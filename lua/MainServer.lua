
-- MainServer.server.lua
-- Fully self-contained 

-- =====================================================
-- Ice Config
-- =====================================================
local IceConfig = {}
IceConfig.IceDuration     = 2          -- seconds ice stays active
IceConfig.IceInterval     = 2          -- seconds between ice spawns
IceConfig.MaxIcePerStage  = 2          -- simultaneous icy segments
IceConfig.WarningTime     = 1.2        -- seconds before ice activates
IceConfig.IceColor        = Color3.fromRGB(173, 216, 230)
IceConfig.IceMaterial     = Enum.Material.Ice
IceConfig.IceRate         = 0.1        -- probability of ice spawning per segment

-- =====================================================
-- Stage Config
-- =====================================================
local StageConfig = {}
StageConfig.Stages = {
	[1] = { Length = 400, Width = 20, IceRate = 0.1, SegmentLength = 20, SlopeAngle = math.rad(10), BaseHeight = 3, StageDirectionAngle = math.rad(0) },
	[2] = { Length = 700, Width = 22, IceRate = 0.2, SegmentLength = 20, SlopeAngle = math.rad(10), BaseHeight = 30, StageDirectionAngle = math.rad(90) },
	[3] = { Length = 1000, Width = 24, IceRate = 0.3, SegmentLength = 20, SlopeAngle = math.rad(10), BaseHeight = 60, StageDirectionAngle = math.rad(180) },
	[4] = { Length = 1500, Width = 24, IceRate = 0.3, SegmentLength = 20, SlopeAngle = math.rad(10), BaseHeight = 90, StageDirectionAngle = math.rad(270) },
}

-- =====================================================
-- StageSystem
-- =====================================================
local StageSystem = {}
StageSystem.Inited = false

function StageSystem:_getSegmentEndCFrame(part)
	return part.CFrame * CFrame.new(0, 0, -part.Size.Z / 2)
end

function StageSystem:_createSlideSegment(stageId, segmentId, previousSegment, segmentCount)
	local config = self.StageConfig[stageId]
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new(config.Width, 1, config.SegmentLength)
	part.Material = Enum.Material.SmoothPlastic
	local cframe
	if previousSegment then
		cframe = self:_getSegmentEndCFrame(previousSegment) * CFrame.new(0, 0, -config.SegmentLength / 2)
	else
		cframe = CFrame.new(0, config.BaseHeight, 0) * CFrame.Angles(config.SlopeAngle, 0, 0)
	end
	part.CFrame = cframe
	part:SetAttribute("StageId", stageId)
	part:SetAttribute("SegmentId", segmentId)
	part:SetAttribute("IsIcy", false)
	local colors = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 165, 0), Color3.fromRGB(128, 0, 128) }
	part.Color = colors[(segmentId % #colors) + 1]
	part:SetAttribute("BaseColor", part.Color)
	part:SetAttribute("BaseMaterial", part.Material.Name)
	if segmentId == segmentCount then
		part.Name = "Finish"
		part:SetAttribute("NextStageId", math.min(stageId + 1, #self.StageConfig))
	end
	part.Parent = self.StagesFolder
	return part
end

function StageSystem:_turnStage(stageId)
	local config = self.StageConfig[stageId]
	for _, part in ipairs(self.StagesFolder:GetChildren()) do
		if part:GetAttribute("StageId") == stageId then
			part.CFrame = CFrame.Angles(0, config.StageDirectionAngle, 0) * part.CFrame
		end
	end
end

function StageSystem:_generateStage(stageId)
	local config = self.StageConfig[stageId]
	local segmentCount = math.floor(config.Length / config.SegmentLength)
	local previous = nil
	for i = 1, segmentCount do previous = self:_createSlideSegment(stageId, i, previous, segmentCount) end
end

function StageSystem:_onFinishTouched(finish, hit)
	local character = hit.Parent
	local player = self.Players:GetPlayerFromCharacter(character)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not hrp then return end
	local nextStageId = finish:GetAttribute("NextStageId")
	player:SetAttribute("CurrentStage", nextStageId)
	hrp.CFrame = CFrame.new(0, self.StageConfig[nextStageId].BaseHeight + 4, 0)
end

function StageSystem:Init()
	if self.Inited then return end
	self.Inited = true
	self.Players = game:GetService("Players")
	self.StageConfig = StageConfig.Stages
	self.StagesFolder = workspace:FindFirstChild("Stages") or Instance.new("Folder", workspace)
	self.StagesFolder.Name = "Stages"
	for stageId in ipairs(self.StageConfig) do
		self:_generateStage(stageId)
		self:_turnStage(stageId)
	end
	self.Players.PlayerAdded:Connect(function(player) player:SetAttribute("CurrentStage", 1) end)
	for _, part in ipairs(self.StagesFolder:GetChildren()) do
		if part.Name == "Finish" then part.Touched:Connect(function(hit) self:_onFinishTouched(part, hit) end) end
	end
end

-- =====================================================
-- IceSystem
-- =====================================================
local IceSystem = {}
function IceSystem:_updateSegment(segment)
	if segment:GetAttribute("SegmentId") == 1 then
		return -- first segment has no ice
	end
	local state = segment:GetAttribute("IceState") or "None"
	if state == "Warning" then
		if os.clock() - segment:GetAttribute("IceWarningAt") >= self.IceConfig.WarningTime then
			segment:SetAttribute("IceState", "Ice"); segment:SetAttribute("IsIcy", true); segment:SetAttribute("IceAt", os.clock())
			segment.Color = self.IceConfig.IceColor; segment.Material = self.IceConfig.IceMaterial
		end
	elseif state == "Ice" then
		if os.clock() - segment:GetAttribute("IceAt") >= self.IceConfig.IceDuration then
			segment:SetAttribute("IceState", "None"); segment:SetAttribute("IsIcy", false)
			segment.Color = segment:GetAttribute("BaseColor"); segment.Material = Enum.Material[segment:GetAttribute("BaseMaterial")]
		end
	elseif math.random() < self.IceConfig.IceRate then
		segment:SetAttribute("IceState", "Warning"); segment:SetAttribute("IceWarningAt", os.clock()); segment.Color = Color3.new(1, 1, 1)
	end
end
function IceSystem:Init()
	self.IceConfig = IceConfig; self.Elapsed = 0
end
function IceSystem:Start()
	self.StagesFolder = workspace:WaitForChild("Stages"); self.Segments = {}
	for _, part in ipairs(self.StagesFolder:GetChildren()) do if part:GetAttribute("SegmentId") then table.insert(self.Segments, part) end end
end
function IceSystem:Update(dt)
	self.Elapsed += dt
	if self.Elapsed >= self.IceConfig.IceInterval then
		self.Elapsed = 0; for _, s in ipairs(self.Segments) do self:_updateSegment(s) end
	end
end

-- =====================================================
-- StoreServer
-- =====================================================
local StoreSystem = {}

function StoreSystem:_GetItemFromProductId(productId)
	local item = self.ProductMap[productId]
	return item
end
function StoreSystem:_GetItemFromItemId(itemId)
	local productId = self.ItemIdToProductIdMap[itemId]
	return self.ProductMap[productId]
end
function StoreSystem:Init(context)
	self.Players = game:GetService("Players")
	self.ReplicatedStorage = game:GetService("ReplicatedStorage")
	self.MarketplaceService = game:GetService("MarketplaceService")
	self.HttpService = game:GetService("HttpService")
	self.Systems = context.Systems
	self.ItemIdToProductIdMap = {
		SpeedBooster = 3529599654,
		IcyCoin10K = 3530195917,
	}
	self.ProductMap = {
		[3529599654] = {
				Id = "SpeedBooster",
				Name = "👟 Turbo Soles",
				Description = "30s of +12 WalkSpeed",
				Price = 1000,
				IsRobuxPrice = false,
				RobuxProductId = 3529599654,
			},
		[3530195917] = {
				Id = "IcyCoin10K",
				Name = "💎 Icy Coin 10K Pack",
				Description = "10,000 Icy Coins",
				Price = 50,
				IsRobuxPrice = true,
				RobuxProductId = 3530195917,
			},
		}
	local stringValue = Instance.new("StringValue")
	stringValue.Name = "ProductMap"
	stringValue.Value = self.HttpService:JSONEncode(self.ProductMap)
	stringValue.Parent = self.ReplicatedStorage
	
	local stringValue2 = Instance.new("StringValue")
	stringValue2.Name = "ItemIdToProductIdMap"
	stringValue2.Value = self.HttpService:JSONEncode(self.ItemIdToProductIdMap)
	stringValue2.Parent = self.ReplicatedStorage
	
	local rf = Instance.new("RemoteFunction")
	rf.Name = "RF_GetProductMap"
	rf.Parent = self.ReplicatedStorage
	self.GetProductMapRF = rf

	-- Robux Success RE
	local re1 = Instance.new("RemoteEvent")
	re1.Name = "RE_RobuxSuccess"
	re1.Parent = self.ReplicatedStorage
	self.RobuxSuccessRE = re1
	
	local re2 = Instance.new("RemoteEvent")
	re2.Name = "RE_ProductShop"
	re2.Parent = self.ReplicatedStorage
	self.ProductShopRE = re2


	self.GetProductMapRF.OnServerInvoke = function(player)
		return self.ProductMap
	end

	-- non robux product purchase
	self.ProductShopRE.OnServerEvent:Connect(function(player, itemId)
		local item = self:_GetItemFromItemId(itemId)
		if not player or not item then
			return
		end
		
		local price = item.Price
		local balance = self.Systems.SaveSystem:PlayerDataGet(player, "Balance")
		
		if balance and balance >= price then 
			if itemId == "SpeedBooster" then
				local currentBoostEnd = player:GetAttribute("SpeedBoostEnd") or os.time()
				player:SetAttribute("SpeedBoostEnd", math.max(currentBoostEnd, os.time()) + 30)
			end
			
			self.Systems.SaveSystem:PlayerDataAdd(player, "Balance", -price)
			self.ProductShopRE:FireClient(player, true, "Purchase successful")
		else
			self.ProductShopRE:FireClient(player, false, "Insufficient funds")
		end
	end)
	
	-- Robux Receipt Handler
	self.MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = self.Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local item = self:_GetItemFromProductId(receiptInfo.ProductId)
		if not item then return Enum.ProductPurchaseDecision.NotProcessedYet end
		
		local itemId = item.Id
		if itemId == "IcyCoin10K" then
			local success = self.Systems.SaveSystem:PlayerDataAdd(player, "Balance", 10000)
			if success then
				self.RobuxSuccessRE:FireClient(player, itemId)
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	self.Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("SpeedBoostEnd", 0)
	end)
end

-- =====================================================
-- FailSystem
-- =====================================================
local FailSystem = {}
FailSystem.FailingPlayers = {}

function FailSystem:_isOnIce(character)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local raycastParams = RaycastParams.new(); raycastParams.FilterType = Enum.RaycastFilterType.Exclude; raycastParams.FilterDescendantsInstances = { character }
	local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), raycastParams)
	return ray and ray.Instance and ray.Instance:GetAttribute("IsIcy") == true
end

function FailSystem:_fail(player)
	if self.FailingPlayers[player] then return end
	if player:GetAttribute("IceImmune") then return end

	self.FailingPlayers[player] = true
	local char = player.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local humanoid = char and char:FindFirstChild("Humanoid")
	if not hrp or not humanoid then self.FailingPlayers[player] = nil; return end

	game:GetService("ReplicatedStorage").REV_IceFail:FireClient(player)
	humanoid.WalkSpeed = 0; humanoid.JumpPower = 0
	local start = hrp.CFrame; 
	local currentStage = player:GetAttribute("CurrentStage") or 1
	local stageCfg = StageConfig.Stages[currentStage] or StageConfig.Stages[1]
	local target = CFrame.new(0, stageCfg.BaseHeight + 4, 0)
	
	local startTime = os.clock()
	local conn; conn = game:GetService("RunService").Heartbeat:Connect(function()
		local a = math.clamp((os.clock() - startTime) / 1.2, 0, 1)
		hrp.CFrame = start:Lerp(target, a)
		if a >= 1 then conn:Disconnect(); humanoid.WalkSpeed = 16; humanoid.JumpPower = 50; self.FailingPlayers[player] = nil end
	end)
end

function FailSystem:Init(context)
	self.Players = game:GetService("Players"); self.RunService = game:GetService("RunService")
	if not game:GetService("ReplicatedStorage"):FindFirstChild("REV_IceFail") then
		local rev = Instance.new("RemoteEvent", game:GetService("ReplicatedStorage")); rev.Name = "REV_IceFail"
	end
end
function FailSystem:Update(dt)
	for _, p in ipairs(self.Players:GetPlayers()) do if not self.FailingPlayers[p] and p.Character and self:_isOnIce(p.Character) then self:_fail(p) end end
end

-- =====================================================
-- Save System
-- =====================================================
local SaveSystem = {}
SaveSystem.Data = {}

function SaveSystem:Init(context)
	self.DataStore = game:GetService("DataStoreService"):GetDataStore("PlayerData_v1")
	self.Players = game:GetService("Players")
	self.Players.PlayerAdded:Connect(function(p) self:_loadData(p) end)
	self.Players.PlayerRemoving:Connect(function(p) self:_saveData(p); self.Data[p.UserId] = nil end)
	self.Systems = context.Systems
	self.OnDataChanged = Instance.new("BindableEvent")
	self.OnDataChanged.Name = "OnDataChanged"
	self.OnDataChanged.Parent = game:GetService("ServerScriptService")
	
	game:BindToClose(function() for _, p in ipairs(self.Players:GetPlayers()) do self:_saveData(p) end end)
end
function SaveSystem:Update(dt) 
	for playerId, playerData in pairs(self.Data) do
		local player = self.Players:GetPlayerByUserId(playerId)
		if not player then continue end
		self:PlayerDataAdd(player, "Balance", 1 * dt) 
	end
end
function SaveSystem:PlayerDataGet(player, key)
	local data = self.Data[player.UserId]
	if not data then return nil end
	return data[key]
end
function SaveSystem:PlayerDataAdd(player, key, value)
	local data = self.Data[player.UserId]
	if not data then return false end
	local old = data[key] or 0
	data[key] = old + value
	player:SetAttribute(key, data[key])
	self.OnDataChanged:Fire(player, key, data[key], old)
	return true
end
function SaveSystem:PlayerDataSet(player, key, value)
	local data = self.Data[player.UserId]
	if not data then return false end
	local old = data[key]
	data[key] = value
	player:SetAttribute(key, value)
	self.OnDataChanged:Fire(player, key, value, old)
	return true
end

function SaveSystem:_loadData(player)
	local key = player.UserId
	local success, data = pcall(function() return self.DataStore:GetAsync(key) end)
	if success and data then 
		self.Data[key] = data
	else 
		self.Data[key] = { CurrentStage = 1, Balance = 0 }
	end
	for k, v in pairs(self.Data[key]) do player:SetAttribute(k, v) end
end

function SaveSystem:_saveData(player)
	local key = player.UserId
	local data = self.Data[key]
	if data then pcall(function() self.DataStore:SetAsync(key, data) end) end
end

-- =====================================================
-- MainServer Bootstrap
-- =====================================================
local function MainServer()
	local orderdSystems = { "SaveSystem", "StageSystem", "IceSystem", "StoreSystem", "FailSystem" }
	local SYSTEMS = { SaveSystem=SaveSystem, StageSystem=StageSystem, IceSystem=IceSystem, StoreSystem=StoreSystem, FailSystem=FailSystem }
	local context = { Systems = SYSTEMS }
	for _, sName in ipairs(orderdSystems) do local s = SYSTEMS[sName]; if s.Init then s:Init(context) end end
	for _, sName in ipairs(orderdSystems) do local s = SYSTEMS[sName]; if s.Start then s:Start() end end
	game:GetService("RunService").Heartbeat:Connect(function(dt) for _, sName in ipairs(orderdSystems) do local s = SYSTEMS[sName]; if s.Update then s:Update(dt) end end end)
	print("✅ MainServer fully initialized")
end
MainServer()
