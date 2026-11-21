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
	RegisterSliders(category)
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
