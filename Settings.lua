local addonName, ns = ...

ns.Settings = {}

local DEFAULT_MULTIPLIER = 2
local MULTIPLIER_MIN = 0
local MULTIPLIER_MAX = 100

local KEYS = { "weapon", "armor", "consumable", "reagent", "recipe", "bag", "other" }

local LABEL = {
	weapon = "TYPE_WEAPON",
	armor = "TYPE_ARMOR",
	consumable = "TYPE_CONSUMABLE",
	reagent = "TYPE_REAGENT",
	recipe = "TYPE_RECIPE",
	bag = "TYPE_BAG",
	other = "TYPE_OTHER",
}

local function InRange(value)
	return type(value) == "number" and value >= MULTIPLIER_MIN and value <= MULTIPLIER_MAX
end

local function EnsureDB()
	if type(TabuAucExtDB) ~= "table" then
		TabuAucExtDB = {}
	end
	if type(TabuAucExtDB.multipliers) ~= "table" then
		TabuAucExtDB.multipliers = {}
	end
	if type(TabuAucExtDB.prices) ~= "table" then
		TabuAucExtDB.prices = {}
	end
	for index = 1, #KEYS do
		local key = KEYS[index]
		local value = TabuAucExtDB.multipliers[key]
		if value ~= false and not InRange(value) then
			TabuAucExtDB.multipliers[key] = DEFAULT_MULTIPLIER
		end
	end
end

function ns.Settings.Multiplier(classID)
	EnsureDB()
	local key = ns.Price.MultiplierKey(classID)
	local value = TabuAucExtDB.multipliers[key]
	if not InRange(value) then
		return DEFAULT_MULTIPLIER
	end
	return value
end

function ns.Settings.Remembered(itemID, itemSuffix)
	EnsureDB()
	local key = ns.Price.MemoryKey(itemID, itemSuffix)
	if key == nil then
		return nil
	end
	local amount = TabuAucExtDB.prices[key]
	if type(amount) ~= "number" or amount < 0 then
		return nil
	end
	return amount
end

function ns.Settings.Remember(itemID, itemSuffix, amount, userEdited)
	if not ns.Price.ShouldRemember(userEdited) then
		return
	end
	if type(amount) ~= "number" or amount < 0 then
		return
	end
	EnsureDB()
	local key = ns.Price.MemoryKey(itemID, itemSuffix)
	if key == nil then
		return
	end
	TabuAucExtDB.prices[key] = amount
end

local ownedSettings = {}

local function ParseMultiplier(text)
	if type(text) ~= "string" then
		return nil
	end
	local value = tonumber((string.gsub(text, ",", ".")))
	if value == nil then
		return nil
	end
	if value < MULTIPLIER_MIN then
		value = MULTIPLIER_MIN
	elseif value > MULTIPLIER_MAX then
		value = MULTIPLIER_MAX
	end
	return math.floor(value * 10 + 0.5) / 10
end

local function ShowExactAmount(box, setting)
	if box:HasFocus() then
		return
	end
	box:SetText(ns.Price.FormatMultiplier(setting:GetValue()))
end

local function CommitExactAmount(box, setting)
	local value = ParseMultiplier(box:GetText())
	if value == nil then
		box:SetText(ns.Price.FormatMultiplier(setting:GetValue()))
		return
	end
	setting:SetValue(value)
	box:SetText(ns.Price.FormatMultiplier(setting:GetValue()))
end

local function AttachExactInput(control)
	local steppers = control.SliderWithSteppers
	local box = control.TabuAucExactBox
	if box == nil then
		box = CreateFrame("EditBox", nil, control, "InputBoxTemplate")
		box:SetSize(52, 18)
		box:SetAutoFocus(false)
		box:SetMaxLetters(6)
		box:SetJustifyH("CENTER")
		box:SetFontObject("GameFontHighlightSmall")
		box:SetPoint("LEFT", steppers.Slider, "RIGHT", 22, 0)
		box:SetScript("OnEnterPressed", function(self)
			self:ClearFocus()
		end)
		box:SetScript("OnEscapePressed", function(self)
			self.TabuAucRevert = true
			self:ClearFocus()
		end)
		box:SetScript("OnEditFocusLost", function(self)
			local setting = control:GetSetting()
			if self.TabuAucRevert or ownedSettings[setting] == nil then
				self.TabuAucRevert = nil
				if setting ~= nil then
					self:SetText(ns.Price.FormatMultiplier(setting:GetValue()))
				end
				return
			end
			CommitExactAmount(self, setting)
		end)
		control.TabuAucExactBox = box
	end
	box:Show()
	steppers.RightText:Hide()
	ShowExactAmount(box, control:GetSetting())
end

local function RefreshExactInput(control)
	local box = control.TabuAucExactBox
	local setting = control:GetSetting()
	if box == nil or setting == nil or ownedSettings[setting] == nil then
		if box ~= nil then
			box:Hide()
		end
		return
	end
	control.SliderWithSteppers.RightText:Hide()
	ShowExactAmount(box, setting)
end

local function HookExactInput()
	if ns.Settings.ExactInputHooked or SettingsSliderControlMixin == nil then
		return
	end
	ns.Settings.ExactInputHooked = true
	hooksecurefunc(SettingsSliderControlMixin, "Init", function(control)
		if ownedSettings[control:GetSetting()] == nil then
			RefreshExactInput(control)
			return
		end
		AttachExactInput(control)
	end)
	hooksecurefunc(SettingsSliderControlMixin, "OnSettingValueChanged", function(control)
		RefreshExactInput(control)
	end)
end

local function RegisterSliders(category)
	for index = 1, #KEYS do
		local key = KEYS[index]
		local setting = Settings.RegisterAddOnSetting(
			category,
			addonName .. "_" .. key,
			key,
			TabuAucExtDB.multipliers,
			Settings.VarType.Number,
			ns.L[LABEL[key]],
			DEFAULT_MULTIPLIER
		)
		ownedSettings[setting] = true
		local options = Settings.CreateSliderOptions(MULTIPLIER_MIN, MULTIPLIER_MAX, 0.1)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
			return ns.Price.FormatMultiplier(value)
		end)
		Settings.CreateSlider(category, setting, options, ns.L.MULTIPLIER_TOOLTIP)
	end
end

local function RegisterCategory()
	if ns.Settings.CategoryRegistered then
		return
	end
	if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting and Settings.CreateSlider and Settings.RegisterAddOnCategory) then
		print(ns.L.OPTIONS_UNAVAILABLE)
		return
	end
	ns.Settings.CategoryRegistered = true
	local category = Settings.RegisterVerticalLayoutCategory("tabu-auc-ext")
	if CreateSettingsListSectionHeaderInitializer ~= nil then
		local header = CreateSettingsListSectionHeaderInitializer(ns.L.MULTIPLIER_HEADING, ns.L.MULTIPLIER_TOOLTIP)
		Settings.RegisterInitializer(category, header)
	end
	RegisterSliders(category)
	HookExactInput()
	Settings.RegisterAddOnCategory(category)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, loadedName)
	if loadedName ~= addonName then
		return
	end
	EnsureDB()
	RegisterCategory()
end)
