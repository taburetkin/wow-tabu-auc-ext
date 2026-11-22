local _, ns = ...

local AUCTION_HOUSE_UI = "Blizzard_AuctionHouseUI"
local CLASS_WEAPON = 2
local CLASS_ARMOR = 4
local ITEM_CLASS_INDEX = 6

local SOURCE_COLOR = {
	[ns.Price.BLIZZARD] = { 1, 1, 1 },
	[ns.Price.EXACT] = { 0.64, 0.21, 0.93 },
	[ns.Price.TYPE] = { 0.2, 0.6, 1 },
	[ns.Price.SUGGESTED] = { 1, 0.1, 0.1 },
}
local DEFAULT_COLOR = { 1, 1, 1 }

local function IsEquipment(classID)
	return classID == CLASS_WEAPON or classID == CLASS_ARMOR
end

local function ItemClassID(itemID)
	return select(ITEM_CLASS_INDEX, C_Item.GetItemInfoInstant(itemID))
end

local function Readable(value)
	return value ~= nil and not issecretvalue(value)
end

local function UnitPriceAmount(sellFrame)
	local priceInput = sellFrame.PriceInput
	if priceInput == nil or priceInput.GetAmount == nil then
		return nil
	end
	local amount = priceInput:GetAmount()
	if not Readable(amount) or type(amount) ~= "number" then
		return nil
	end
	return amount
end

local function SellFrames()
	local frames = {}
	if AuctionHouseFrame == nil then
		return frames
	end
	if AuctionHouseFrame.ItemSellFrame ~= nil then
		frames[#frames + 1] = AuctionHouseFrame.ItemSellFrame
	end
	if AuctionHouseFrame.CommoditiesSellFrame ~= nil then
		frames[#frames + 1] = AuctionHouseFrame.CommoditiesSellFrame
	end
	return frames
end

local function FreshItemKey(sellFrame)
	local itemLocation = sellFrame:GetItem()
	if itemLocation == nil or not itemLocation:IsValid() then
		return nil
	end
	local fresh = C_AuctionHouse.GetItemKeyFromItem(itemLocation)
	if not Readable(fresh) then
		return nil
	end
	return fresh
end

local function VendorUnitPrice(sellFrame)
	local item = sellFrame:GetItem()
	if item == nil or not item:IsValid() then
		return nil
	end
	local itemLink = C_Item.GetItemLink(item)
	if not Readable(itemLink) then
		return nil
	end
	local sellPrice = select(11, C_Item.GetItemInfo(itemLink))
	if not Readable(sellPrice) or type(sellPrice) ~= "number" then
		return nil, false
	end
	return sellPrice, true
end

local function ForEachDigit(priceInput, action)
	local money = priceInput.MoneyInputFrame
	if money == nil then
		return
	end
	local boxes = { money.GoldBox, money.SilverBox, money.CopperBox }
	for index = 1, 3 do
		if boxes[index] ~= nil then
			action(boxes[index])
		end
	end
end

local function PaintDigits(priceInput, color)
	ForEachDigit(priceInput, function(digit)
		digit:SetTextColor(unpack(color))
	end)
end

local function TooltipText(choice)
	if choice.source == ns.Price.BLIZZARD then
		return ns.L.PRICE_BLIZZARD
	end
	if choice.source == ns.Price.EXACT then
		return ns.L.PRICE_EXACT
	end
	if choice.source == ns.Price.TYPE then
		return ns.L.PRICE_TYPE
	end
	if choice.source == ns.Price.SUGGESTED then
		return ns.L.PRICE_SUGGESTED
	end
	return nil
end

local function ShowTooltip(priceInput)
	local text = priceInput.TabuAucTooltip
	if text == nil then
		return
	end
	GameTooltip:SetOwner(priceInput, "ANCHOR_RIGHT")
	GameTooltip:SetText(text)
	GameTooltip:Show()
end

-- One value per exact item in the slot. A different item level is a different item.
local function SlotItemKey(fresh)
	return strjoin(":", tostringall(fresh.itemID, fresh.itemLevel, fresh.itemSuffix, fresh.battlePetSpeciesID))
end

local function SetShownItem(sellFrame, slotItem)
	if sellFrame.TabuAucShownItem ~= slotItem then
		sellFrame.TabuAucUserEdited = nil
	end
	sellFrame.TabuAucShownItem = slotItem
end

-- The item in the slot changed: forget the edit lock and what was painted for the old item.
local function TrackSlotItem(sellFrame, slotItem)
	if sellFrame.TabuAucSlotItem == slotItem then
		return
	end
	sellFrame.TabuAucSlotItem = slotItem
	sellFrame.TabuAucUserEdited = nil
	sellFrame.TabuAucShownSource = nil
	sellFrame.TabuAucApplied = nil
	SetShownItem(sellFrame, nil)
	sellFrame.PriceInput.TabuAucTooltip = nil
	PaintDigits(sellFrame.PriceInput, DEFAULT_COLOR)
end

local function SameLevelAndSuffix(rowKey, fresh)
	if not Readable(rowKey) then
		return false
	end
	return (rowKey.itemLevel or 0) == (fresh.itemLevel or 0)
		and (rowKey.itemSuffix or 0) == (fresh.itemSuffix or 0)
end

local function CollectBuyouts(itemKey, includeRow)
	local amounts = {}
	for index = 1, C_AuctionHouse.GetNumItemSearchResults(itemKey) do
		local info = C_AuctionHouse.GetItemSearchResultInfo(itemKey, index)
		if Readable(info) and includeRow(info)
			and Readable(info.buyoutAmount) and type(info.buyoutAmount) == "number" then
			amounts[#amounts + 1] = info.buyoutAmount
		end
	end
	return amounts
end

-- GetBestEntry ignores item level for uncommon gear and pets. Other gear uses the same item level, any affix.
local function IgnoreItemLevel(sellFrame, fresh)
	if (fresh.battlePetSpeciesID or 0) ~= 0 then
		return true
	end
	local item = sellFrame:GetItem()
	if item == nil or C_Item.GetItemQuality == nil then
		return false
	end
	local quality = C_Item.GetItemQuality(item)
	if not Readable(quality) then
		return false
	end
	local uncommon = 2
	if Enum ~= nil and Enum.ItemQuality ~= nil and Enum.ItemQuality.Uncommon ~= nil then
		uncommon = Enum.ItemQuality.Uncommon
	end
	return quality == uncommon
end

local function SuggestedPrice(vendorPrice, vendorReady)
	if vendorReady ~= true then
		return nil
	end
	if C_AuctionHouse.ShouldAutoPopulatePrice ~= nil and not C_AuctionHouse.ShouldAutoPopulatePrice() then
		return nil
	end
	return ns.Price.DefaultCopper(vendorPrice)
end

local function OtherItemSearchReady(sellFrame, itemID)
	if sellFrame.GetPrice == nil then
		return C_AuctionHouse.HasFullCommoditySearchResults(itemID)
	end
	local itemKey = sellFrame.listDisplayedItemKey
	if not Readable(itemKey) then
		return false
	end
	return C_AuctionHouse.HasFullItemSearchResults(itemKey)
end

local function OtherItemListingCount(sellFrame, itemID)
	if sellFrame.GetPrice == nil then
		return C_AuctionHouse.GetNumCommoditySearchResults(itemID)
	end
	return C_AuctionHouse.GetNumItemSearchResults(sellFrame.listDisplayedItemKey)
end

local function BlizzardUnitPrice(sellFrame)
	local unitPrice = UnitPriceAmount(sellFrame)
	if unitPrice ~= nil and unitPrice > 0 then
		return unitPrice
	end
	return nil
end

local function BuildQuery(sellFrame, fresh, classID)
	local equipment = IsEquipment(classID)
	local vendorPrice, vendorReady = VendorUnitPrice(sellFrame)
	local query = {
		equipment = equipment,
		suggestedPrice = SuggestedPrice(vendorPrice, vendorReady),
	}
	if equipment then
		-- The sell frame already searches this item with any affix. A second query replaces that search and leaves the list on Searching.
		local itemKey = sellFrame.listDisplayedItemKey
		local ready = Readable(itemKey) and C_AuctionHouse.HasFullItemSearchResults(itemKey)
		query.exactReady = ready
		query.typeReady = ready
		if ready then
			query.exactPrice = ns.Price.MinimumBuyout(CollectBuyouts(itemKey, function(info)
				return SameLevelAndSuffix(info.itemKey, fresh)
			end))
			local ignoreLevel = IgnoreItemLevel(sellFrame, fresh)
			query.typePrice = ns.Price.MinimumBuyout(CollectBuyouts(itemKey, function(info)
				if ignoreLevel then
					return true
				end
				return Readable(info.itemKey) and (info.itemKey.itemLevel or 0) == (fresh.itemLevel or 0)
			end))
		end
		return query
	end
	query.searchReady = OtherItemSearchReady(sellFrame, fresh.itemID)
	if query.searchReady and OtherItemListingCount(sellFrame, fresh.itemID) > 0 then
		query.blizzardPrice = BlizzardUnitPrice(sellFrame)
	end
	return query
end

local function ApplyChoice(sellFrame, choice, slotItem)
	local priceInput = sellFrame.PriceInput
	priceInput.TabuAucApplying = true
	priceInput:SetAmount(choice.amount)
	priceInput.TabuAucApplying = false
	SetShownItem(sellFrame, slotItem)
	sellFrame.TabuAucApplied = { amount = choice.amount, source = choice.source }
	sellFrame.TabuAucShownSource = choice.source
	PaintDigits(priceInput, SOURCE_COLOR[choice.source] or DEFAULT_COLOR)
	priceInput.TabuAucTooltip = TooltipText(choice)
end

local function RefreshPrice(sellFrame)
	local fresh = FreshItemKey(sellFrame)
	if fresh == nil then
		TrackSlotItem(sellFrame, nil)
		return
	end
	local slotItem = SlotItemKey(fresh)
	TrackSlotItem(sellFrame, slotItem)
	if sellFrame.TabuAucUserEdited == true then
		return
	end
	local classID = ItemClassID(fresh.itemID)
	local applied = sellFrame.TabuAucApplied
	if applied ~= nil and sellFrame.TabuAucShownItem == slotItem then
		if UnitPriceAmount(sellFrame) ~= applied.amount then
			ApplyChoice(sellFrame, applied, slotItem)
		end
		return
	end
	local query = BuildQuery(sellFrame, fresh, classID)
	local choice = ns.Price.Choose(query)
	if choice == nil then
		return
	end
	ApplyChoice(sellFrame, choice, slotItem)
end

-- IsShown stays true after the auction house hides this frame's parent.
local function SellFrameVisible(sellFrame)
	return sellFrame ~= nil and sellFrame:IsVisible()
end

local refreshScheduled = {}

local function ScheduleRefresh(sellFrame)
	if sellFrame == nil or refreshScheduled[sellFrame] then
		return
	end
	refreshScheduled[sellFrame] = true
	C_Timer.After(0, function()
		refreshScheduled[sellFrame] = nil
		if SellFrameVisible(sellFrame) then
			RefreshPrice(sellFrame)
		end
	end)
end

local function RefreshShownFrames()
	local frames = SellFrames()
	for index = 1, #frames do
		if frames[index].TabuAucPriceHooked and SellFrameVisible(frames[index]) then
			ScheduleRefresh(frames[index])
		end
	end
end

local function OnItemSet(sellFrame)
	local fresh = FreshItemKey(sellFrame)
	if fresh == nil then
		TrackSlotItem(sellFrame, nil)
		return
	end
	TrackSlotItem(sellFrame, SlotItemKey(fresh))
	ScheduleRefresh(sellFrame)
end

local function WatchBox(editBox, sellFrame)
	if editBox == nil or editBox.TabuAucWatch then
		return
	end
	editBox.TabuAucWatch = true
	editBox:HookScript("OnTextChanged", function(_, userInput)
		if userInput and not sellFrame.PriceInput.TabuAucApplying then
			sellFrame.TabuAucUserEdited = true
		end
	end)
end

-- After our first apply, a SetAmount we did not make (a listing click) is the player's price.
local function HookPlayerAmount(sellFrame)
	local priceInput = sellFrame.PriceInput
	if priceInput.SetAmount == nil then
		return
	end
	hooksecurefunc(priceInput, "SetAmount", function()
		if sellFrame.TabuAucApplied ~= nil and not priceInput.TabuAucApplying then
			sellFrame.TabuAucUserEdited = true
		end
	end)
end

local function HookTooltip(widget, priceInput)
	if widget == nil or widget.TabuAucTooltipHooked then
		return
	end
	widget.TabuAucTooltipHooked = true
	widget:HookScript("OnEnter", function()
		ShowTooltip(priceInput)
	end)
	widget:HookScript("OnLeave", GameTooltip_Hide)
end

local function HookSellFrame(sellFrame)
	if sellFrame == nil or sellFrame.TabuAucPriceHooked or sellFrame.PriceInput == nil then
		return
	end
	sellFrame.TabuAucPriceHooked = true
	local priceInput = sellFrame.PriceInput
	hooksecurefunc(sellFrame, "SetItem", OnItemSet)
	sellFrame:HookScript("OnShow", ScheduleRefresh)
	HookPlayerAmount(sellFrame)
	ForEachDigit(priceInput, function(box)
		WatchBox(box, sellFrame)
		HookTooltip(box, priceInput)
	end)
	HookTooltip(priceInput, priceInput)
end

local function HookSellFrames()
	local frames = SellFrames()
	for index = 1, #frames do
		HookSellFrame(frames[index])
	end
end

local function OnEvent(_, event, name)
	if event == "ADDON_LOADED" then
		if name == AUCTION_HOUSE_UI then
			HookSellFrames()
		end
		return
	end
	if event == "AUCTION_HOUSE_SHOW" then
		HookSellFrames()
		RefreshShownFrames()
		return
	end
	RefreshShownFrames()
end

local listener = CreateFrame("Frame")
listener:RegisterEvent("ADDON_LOADED")
listener:RegisterEvent("AUCTION_HOUSE_SHOW")
listener:RegisterEvent("GET_ITEM_INFO_RECEIVED")
listener:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED")
listener:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
listener:SetScript("OnEvent", OnEvent)

if C_AddOns.IsAddOnLoaded(AUCTION_HOUSE_UI) then
	HookSellFrames()
end
