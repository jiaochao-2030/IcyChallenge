
--====================================================
-- STORE SYSTEM
--====================================================
local StoreSystem = {}

function StoreSystem:Init(context)
	self.context = context
	self.player = context.Player
	self.services = context.Services
	self.marketService = game:GetService("MarketplaceService")
	self.robuxSuccess = self.services.ReplicatedStorage:WaitForChild("RE_RobuxSuccess")
	self.ProductShopRE = self.services.ReplicatedStorage:WaitForChild("RE_ProductShop")
	self.GetProductMapRF = self.services.ReplicatedStorage:WaitForChild("RF_GetProductMap")

	local stringValue1 = self.services.ReplicatedStorage:WaitForChild("ProductMap")
	local stringValue2 = self.services.ReplicatedStorage:WaitForChild("ItemIdToProductIdMap")

	-- Wait for the values to be populated by the server (WaitForChild doesn't wait for the .Value)
	while stringValue1.Value == "" or stringValue2.Value == "" do
		task.wait(0.1)
	end

	self.productMap = self.services.HttpService:JSONDecode(stringValue1.Value)
	self.itemIdToProductIdMap = self.services.HttpService:JSONDecode(stringValue2.Value)
end

function StoreSystem:Start()
	self:_createStoreGui()

	self.robuxSuccess.OnClientEvent:Connect(function(itemId)
		print("Robux Purchase Success: " .. itemId)
	end)

	self.ProductShopRE.OnClientEvent:Connect(function(success, message)
		print("Shop Purchase Result: ", success, message)
	end)
end

function StoreSystem:_createStoreGui()
	local playerGui = self.player:WaitForChild("PlayerGui")
	local storeGui = Instance.new("ScreenGui")
	storeGui.Name = "StoreUI"
	storeGui.ResetOnSpawn = false
	storeGui.Parent = playerGui

	local overlay = Instance.new("TextButton")
	overlay.Name = "ClickOutsideOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundTransparency = 1
	overlay.Text = ""
	overlay.Visible = false
	overlay.Parent = storeGui

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.fromScale(0.35, 0.5)
	mainFrame.Position = UDim2.fromScale(0.5, 0.5)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	mainFrame.BackgroundTransparency = 0.2
	mainFrame.Parent = overlay

	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", mainFrame)
	stroke.Color = Color3.fromRGB(60, 60, 80)
	stroke.Thickness = 2

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.15)
	title.BackgroundTransparency = 1
	title.Text = "BOOSTER STORE"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	Instance.new("UIPadding", title).PaddingTop = UDim.new(0.1, 0)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(0.9, 0.65)
	scroll.Position = UDim2.fromScale(0.05, 0.2)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 4
	scroll.Parent = mainFrame

	Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 12)

	local balanceLabel = Instance.new("TextLabel")
	balanceLabel.Name = "BalanceLabel"
	balanceLabel.Size = UDim2.fromScale(0.4, 0.08)
	balanceLabel.Position = UDim2.fromScale(0.3, 0.9)
	balanceLabel.BackgroundTransparency = 1
	balanceLabel.Text = "Credits: $" .. math.floor(self.player:GetAttribute("Balance") or 0)
	balanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	balanceLabel.TextScaled = true
	balanceLabel.Font = Enum.Font.GothamBold
	balanceLabel.Parent = mainFrame

	self.player:GetAttributeChangedSignal("Balance"):Connect(function () 
		balanceLabel.Text = "Credits: $" .. math.floor(self.player:GetAttribute("Balance") or 0)
	end)

	local shopBtn = Instance.new("TextButton")
	shopBtn.Name = "ShopToggle"
	shopBtn.Size = UDim2.fromOffset(120, 45)
	shopBtn.Position = UDim2.new(0, 20, 1, -65)
	shopBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
	shopBtn.Text = "SHOP"
	shopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopBtn.Font = Enum.Font.GothamBold
	shopBtn.TextSize = 18 -- Fixed size instead of TextScaled to keep it smaller
	shopBtn.TextScaled = false
	shopBtn.Parent = storeGui
	Instance.new("UICorner", shopBtn)

	shopBtn.MouseButton1Click:Connect(function()
		overlay.Visible = not overlay.Visible
	end)

	overlay.MouseButton1Click:Connect(function()
		overlay.Visible = false
	end)

	for _, item in pairs(self.productMap) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(0.95, 0, 0, 65)
		card.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		card.Parent = scroll
		Instance.new("UICorner", card)

		local name = Instance.new("TextLabel")
		name.Size = UDim2.fromScale(0.6, 0.4)
		name.Position = UDim2.fromScale(0.05, 0.1)
		name.BackgroundTransparency = 1
		name.Text = item.Name
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextScaled = true
		name.Font = Enum.Font.GothamBold
		name.Parent = card

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.fromScale(0.6, 0.3)
		desc.Position = UDim2.fromScale(0.05, 0.55)
		desc.BackgroundTransparency = 1
		desc.Text = item.Description
		desc.TextColor3 = Color3.fromRGB(180, 180, 190)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextScaled = true
		desc.Parent = card

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.fromScale(0.28, 0.75)
		buyBtn.Position = UDim2.fromScale(0.68, 0.125)
		buyBtn.BackgroundColor3 = item.IsRobuxPrice and Color3.fromRGB(0, 160, 80) or Color3.fromRGB(40, 180, 100)
		buyBtn.Text = "" -- Use custom labels for alignment
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.Parent = card
		Instance.new("UICorner", buyBtn)

		-- Content Aligner for Buy Button
		local aligner = Instance.new("Frame")
		aligner.Size = UDim2.fromScale(1, 1)
		aligner.BackgroundTransparency = 1
		aligner.Parent = buyBtn

		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Padding = UDim.new(0, 6)
		list.Parent = aligner

		if item.IsRobuxPrice then
			local icon = Instance.new("ImageLabel")
			icon.Size = UDim2.fromOffset(28, 28) -- Increased size to match text better
			icon.BackgroundTransparency = 1
			icon.Image = "rbxasset://textures/ui/common/robux@3x.png"
			icon.Parent = aligner

			local priceText = Instance.new("TextLabel")
			priceText.Size = UDim2.fromScale(0.5, 0.8)
			priceText.BackgroundTransparency = 1
			priceText.Text = tostring(item.Price)
			priceText.TextColor3 = Color3.fromRGB(255, 255, 255)
			priceText.Font = Enum.Font.GothamBold
			priceText.TextScaled = true
			priceText.Parent = aligner
		else
			local priceText = Instance.new("TextLabel")
			priceText.Size = UDim2.fromScale(0.8, 0.8)
			priceText.BackgroundTransparency = 1
			priceText.Text = "$ " .. item.Price
			priceText.TextColor3 = Color3.fromRGB(255, 255, 255)
			priceText.Font = Enum.Font.GothamBold
			priceText.TextScaled = true
			priceText.Parent = aligner
		end

		buyBtn.MouseButton1Click:Connect(function()
			if item.IsRobuxPrice then
				self.marketService:PromptProductPurchase(self.player, item.RobuxProductId)
			else
				self.ProductShopRE:FireServer(item.Id)
			end
		end)
	end
end

--====================================================
-- UI SYSTEM
--====================================================
local UiSystem = {}

function UiSystem:Init(context)
	self.context = context
	self.player = context.Player
	self.services = context.Services
	self.iceFailRemote = self.services.ReplicatedStorage:WaitForChild("REV_IceFail")

	self:_createIcyGui(self.player, self.player:WaitForChild("PlayerGui"))

	self.gui = self.player.PlayerGui:WaitForChild("IcyUI")
	self.iceWarningLabel = self.gui:WaitForChild("IceWarning")
	self.speedTimerLabel = self.gui:WaitForChild("SpeedTimer")
	self.failTextLabel = self.gui:WaitForChild("FailText")
end

function UiSystem:Start()
	self.iceFailRemote.OnClientEvent:Connect(function()
		self:_showIceWarning()
		self:_showFailMessage()
	end)
end

function UiSystem:Update(dt)
	local serverBoostEnd = self.player:GetAttribute("SpeedBoostEnd") or 0
	local timeLeft = math.max(0, serverBoostEnd - os.time())

	if timeLeft > 0 then
		self.speedTimerLabel.Visible = true
		self.speedTimerLabel.Text = "⚡ SPEED BOOST: " .. math.ceil(timeLeft) .. "s"
	else
		self.speedTimerLabel.Visible = false
	end
end

function UiSystem:GetSpeedMultiplier()
	local serverBoostEnd = self.player:GetAttribute("SpeedBoostEnd") or 0
	return (serverBoostEnd - os.time()) > 0 and 1.8 or 1.0
end

function UiSystem:_createIcyGui(player, playerGui)
	local icyGui = Instance.new("ScreenGui")
	icyGui.Name = "IcyUI"
	icyGui.ResetOnSpawn = false
	icyGui.Parent = playerGui

	local function createLabel(name, pos, size, color)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.Size = size
		l.Position = pos
		l.BackgroundTransparency = 1
		l.TextScaled = true
		l.TextColor3 = color
		l.Visible = false
		l.Font = Enum.Font.GothamBold
		l.Parent = icyGui
		return l
	end

	createLabel("IceWarning", UDim2.fromScale(0.3, 0.15), UDim2.fromScale(0.4, 0.1), Color3.fromRGB(200, 240, 255))
	createLabel("SpeedTimer", UDim2.fromScale(0.35, 0.05), UDim2.fromScale(0.3, 0.08), Color3.fromRGB(255, 255, 0))
	createLabel("FailText", UDim2.fromScale(0.3, 0.4), UDim2.fromScale(0.4, 0.12), Color3.fromRGB(255, 100, 100))
end

function UiSystem:_fade(label, fadeIn, duration)
	label.Visible = true
	local tween = self.services.TweenService:Create(label, TweenInfo.new(duration or 0.25), { TextTransparency = fadeIn and 0 or 1 })
	tween:Play()
end

function UiSystem:_showIceWarning()
	self.iceWarningLabel.Text = "⚠ ICE SURFACE ⚠"
	self.iceWarningLabel.TextTransparency = 1
	self:_fade(self.iceWarningLabel, true)
	task.delay(1.5, function() self:_fade(self.iceWarningLabel, false) end)
end

function UiSystem:_showFailMessage()
	self.failTextLabel.Text = "You slipped!"
	self.failTextLabel.TextTransparency = 1
	self:_fade(self.failTextLabel, true)
	task.delay(1.5, function() self:_fade(self.failTextLabel, false) end)
end

--====================================================
-- MOVEMENT CONTROLLER
--====================================================
local MovementController = {}	

function MovementController:Init(context)
	self.context = context
	self.player = context.Player
	self.services = context.Services
	self.enabled = true
	self.baseWalkSpeed = 16
end

function MovementController:Update(dt)
	if not self.enabled then return end
	local character = self.player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local multiplier = self.context.Systems.UiSystem:GetSpeedMultiplier()
	humanoid.WalkSpeed = self.baseWalkSpeed * multiplier
end

--====================================================
-- MAIN CLIENT BOOTSTRAP
--====================================================
local function mainClient()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local HttpService = game:GetService("HttpService")

	local player = Players.LocalPlayer
	local systems = {
		UiSystem = UiSystem,
		StoreSystem = StoreSystem,
		MovementController = MovementController,
	}

	local context = {
		Player = player,
		Systems = systems,
		Services = {
			RunService = RunService,
			TweenService = TweenService,
			ReplicatedStorage = ReplicatedStorage,
			HttpService = HttpService,
		},
	}

	for _, system in pairs(systems) do system:Init(context) end
	for _, system in pairs(systems) do if system.Start then system:Start() end end

	RunService.RenderStepped:Connect(function(dt)
		for _, system in pairs(systems) do if system.Update then system:Update(dt) end end
	end)
end

mainClient()
