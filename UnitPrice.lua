local addonName, ns = ...

ns.UnitPrice = {}

function ns.UnitPrice.ShouldShow(query)
	if query.enabled ~= true then
		return false
	end
	if type(query.vendorPrice) ~= "number" or query.vendorPrice <= 0 then
		return false
	end
	if type(query.maxStack) ~= "number" or query.maxStack <= 1 then
		return false
	end
	if type(query.stackCount) ~= "number" or query.stackCount <= 1 then
		return false
	end
	return true
end

function ns.UnitPrice.Enabled()
	return type(TabuAucExtDB) == "table" and TabuAucExtDB.showUnitPrice == true
end

local function Readable(value)
	return value ~= nil and not issecretvalue(value)
end

local function StackCount(tooltip, tooltipData)
	if tooltipData.guid ~= nil and C_Item.GetItemLocation ~= nil and C_Item.GetStackCount ~= nil then
		local location = C_Item.GetItemLocation(tooltipData.guid)
		if location ~= nil and location:IsValid() then
			local count = C_Item.GetStackCount(location)
			if Readable(count) and type(count) == "number" then
				return count, location
			end
		end
	end
	local owner = tooltip.GetOwner and tooltip:GetOwner()
	if owner ~= nil and Readable(owner.count) and type(owner.count) == "number" then
		return owner.count, nil
	end
	return nil, nil
end

local function MaxStack(location, itemID)
	if location ~= nil and C_Item.GetItemMaxStackSize ~= nil then
		local size = C_Item.GetItemMaxStackSize(location)
		if Readable(size) and type(size) == "number" then
			return size
		end
	end
	if itemID ~= nil and C_Item.GetItemMaxStackSizeByID ~= nil then
		local size = C_Item.GetItemMaxStackSizeByID(itemID)
		if Readable(size) and type(size) == "number" then
			return size
		end
	end
	return nil
end

local function VendorPrice(tooltip, tooltipData)
	local link = nil
	if TooltipUtil ~= nil and TooltipUtil.GetDisplayedItem ~= nil then
		link = select(2, TooltipUtil.GetDisplayedItem(tooltip))
	end
	if link == nil then
		link = tooltipData.hyperlink
	end
	local item = link or tooltipData.id
	if item == nil then
		return nil
	end
	local price = select(11, C_Item.GetItemInfo(item))
	if not Readable(price) or type(price) ~= "number" then
		return nil
	end
	return price
end

-- Same line Sell Price uses: GameTooltip_OnTooltipAddMoney, Forever pin 734f065.
local function AddUnitPriceLine(tooltip, vendorPrice)
	if GameTooltip_AddHighlightLine == nil or MoneyFormatterUtil == nil or GameTooltipMoneyFormat == nil then
		return
	end
	local money = MoneyFormatterUtil.FormatMoney(vendorPrice, GameTooltipMoneyFormat)
	GameTooltip_AddHighlightLine(tooltip, string.format("%s: %s", ns.L.UNIT_PRICE, money))
end

function ns.UnitPrice.OnTooltip(tooltip, tooltipData)
	if not ns.UnitPrice.Enabled() or tooltip == nil or tooltipData == nil then
		return
	end
	local stackCount, location = StackCount(tooltip, tooltipData)
	local query = {
		enabled = true,
		vendorPrice = VendorPrice(tooltip, tooltipData),
		maxStack = MaxStack(location, tooltipData.id),
		stackCount = stackCount,
	}
	if ns.UnitPrice.ShouldShow(query) then
		AddUnitPriceLine(tooltip, query.vendorPrice)
	end
end

if TooltipDataProcessor ~= nil and TooltipDataProcessor.AddTooltipPostCall ~= nil and Enum ~= nil and Enum.TooltipDataType ~= nil then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ns.UnitPrice.OnTooltip)
end

local categoryRegistered = false

local function RegisterOption()
	if categoryRegistered then
		return
	end
	if type(TabuAucExtDB) ~= "table" then
		TabuAucExtDB = {}
	end
	if type(TabuAucExtDB.showUnitPrice) ~= "boolean" then
		TabuAucExtDB.showUnitPrice = false
	end
	if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting and Settings.CreateCheckbox and Settings.RegisterAddOnCategory) then
		print(ns.L.OPTIONS_UNAVAILABLE)
		return
	end
	categoryRegistered = true
	local category = Settings.RegisterVerticalLayoutCategory(addonName)
	local setting = Settings.RegisterAddOnSetting(
		category,
		addonName .. "_showUnitPrice",
		"showUnitPrice",
		TabuAucExtDB,
		Settings.VarType.Boolean,
		ns.L.UNIT_PRICE_OPTION,
		false
	)
	Settings.CreateCheckbox(category, setting, ns.L.UNIT_PRICE_OPTION_TIP)
	Settings.RegisterAddOnCategory(category)
end

local listener = CreateFrame("Frame")
listener:RegisterEvent("ADDON_LOADED")
listener:SetScript("OnEvent", function(_, _, name)
	if name ~= addonName then
		return
	end
	listener:UnregisterEvent("ADDON_LOADED")
	RegisterOption()
end)
