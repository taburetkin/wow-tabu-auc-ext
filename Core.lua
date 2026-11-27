local _, ns = ...

local FACTION_PERCENT = 5
local NEUTRAL_PERCENT = 15
local NEUTRAL_FACTION = "Neutral"
local NEUTRAL_REACTION = 4
local CUT_LAYOUT_INDEX = 64
local RECEIVE_LAYOUT_INDEX = 65
local FOOTER_INSET = 8
local COPPER_PER_GOLD = 10000
local AUCTION_HOUSE_UI = "Blizzard_AuctionHouseUI"

local openFaction = nil

local function HouseFaction(factionGroup, reaction)
	if factionGroup == NEUTRAL_FACTION or factionGroup == "Alliance" or factionGroup == "Horde" then
		return factionGroup
	end
	if type(reaction) == "number" and reaction >= NEUTRAL_REACTION then
		return NEUTRAL_FACTION
	end
	return nil
end

local function CommissionRate(factionGroup)
	local house = HouseFaction(factionGroup, nil)
	if house == NEUTRAL_FACTION then
		return NEUTRAL_PERCENT
	end
	if house == "Alliance" or house == "Horde" then
		return FACTION_PERCENT
	end
	return nil
end

local function ListingQuantity(quantity, quantityShown)
	if not quantityShown then
		return 1
	end
	return quantity
end

local function ListedCopper(quantity, unitPrice)
	if type(quantity) ~= "number" or type(unitPrice) ~= "number" then
		return nil
	end
	if quantity < 0 or unitPrice < 0 then
		return nil
	end
	return quantity * unitPrice
end

local function CommissionCopper(quantity, unitPrice, percent)
	local totalPrice = ListedCopper(quantity, unitPrice)
	if totalPrice == nil or type(percent) ~= "number" or percent < 0 then
		return nil
	end
	return math.floor(totalPrice * percent / 100)
end

local function ReceiveCopper(quantity, unitPrice, percent)
	local totalPrice = ListedCopper(quantity, unitPrice)
	local commission = CommissionCopper(quantity, unitPrice, percent)
	if totalPrice == nil or commission == nil then
		return nil
	end
	return totalPrice - commission
end

local COLOR_GREEN = "green"
local COLOR_RED = "red"

local function VendorDelta(receive, vendorTotal)
	if type(receive) ~= "number" or type(vendorTotal) ~= "number" then
		return nil
	end
	return receive - vendorTotal
end

local function DeltaDisplay(receive, vendorTotal)
	local delta = VendorDelta(receive, vendorTotal)
	if delta == nil then
		return nil, nil
	end
	if delta > 0 then
		return delta, COLOR_GREEN
	end
	if delta < 0 then
		return -delta, COLOR_RED
	end
	return 0, COLOR_RED
end

local function VendorUnitPrice(sellFrame)
	local item = sellFrame:GetItem()
	if item == nil or not item:IsValid() then
		return nil
	end
	local itemLink = C_Item.GetItemLink(item)
	if itemLink == nil or issecretvalue(itemLink) then
		return nil
	end
	local sellPrice = select(11, C_Item.GetItemInfo(itemLink))
	if sellPrice == nil then
		return nil, true
	end
	if issecretvalue(sellPrice) then
		return nil, false
	end
	return sellPrice, false
end

local function MoneyColor(colorName)
	if colorName == COLOR_GREEN then
		return GREEN_FONT_COLOR
	end
	if colorName == COLOR_RED then
		return RED_FONT_COLOR
	end
	return nil
end

local function ApplyMoneyColor(moneyDisplay, color)
	if moneyDisplay == nil then
		return
	end
	local displays = { moneyDisplay.GoldDisplay, moneyDisplay.SilverDisplay, moneyDisplay.CopperDisplay }
	for index = 1, #displays do
		local denomination = displays[index]
		if denomination ~= nil then
			denomination:SetFontObject(PriceFont)
			if color ~= nil and denomination.Text ~= nil then
				denomination.Text:SetTextColor(color:GetRGB())
			end
		end
	end
end

local function UnitPrice(sellFrame)
	if sellFrame.GetPrice ~= nil then
		local bidPrice, buyoutPrice = sellFrame:GetPrice()
		if buyoutPrice ~= nil then
			return buyoutPrice
		end
		if bidPrice ~= nil then
			return bidPrice
		end
		return 0
	end
	return sellFrame:GetUnitPrice()
end

local function Readable(value)
	if issecretvalue(value) then
		return false
	end
	return value ~= nil
end

local function FactionOf(unit)
	if not UnitExists(unit) then
		return nil
	end
	local player = UnitIsPlayer(unit)
	if not issecretvalue(player) and player then
		return nil
	end
	local faction = UnitFactionGroup(unit)
	if not Readable(faction) then
		faction = nil
	end
	local reaction = UnitReaction("player", unit)
	if not Readable(reaction) then
		reaction = nil
	end
	return HouseFaction(faction, reaction)
end

local function CurrentFaction()
	local fromNpc = FactionOf("npc")
	if fromNpc ~= nil then
		return fromNpc
	end
	if UnitExists("npc") then
		return nil
	end
	return FactionOf("target")
end

local function CaptureFaction()
	local faction = CurrentFaction()
	if faction ~= nil then
		openFaction = faction
	end
end

local function EnsurePriceRow(sellFrame, field, layoutIndex, label)
	local row = sellFrame[field]
	if row == nil then
		row = CreateFrame("Frame", nil, sellFrame, "AuctionHouseAlignedPriceDisplayTemplate")
		row:SetLabel(label)
		sellFrame[field] = row
	end
	row.layoutIndex = layoutIndex
	return row
end

local function PinSellFooter(sellFrame)
	local button = sellFrame.PostButton
	if button ~= nil then
		button.ignoreInLayout = true
		button.layoutIndex = nil
		button:ClearAllPoints()
		button:SetPoint("BOTTOMRIGHT", sellFrame, "BOTTOMRIGHT", -FOOTER_INSET, FOOTER_INSET)
	end
	local checkbox = sellFrame.BuyoutModeCheckButton
	if checkbox ~= nil then
		checkbox.ignoreInLayout = true
		checkbox:ClearAllPoints()
		checkbox:SetPoint("BOTTOMLEFT", sellFrame, "BOTTOMLEFT", FOOTER_INSET - 6, FOOTER_INSET - 9)
	end
end

local function RightmostDenomination(moneyDisplay)
	if moneyDisplay.CopperDisplay ~= nil and moneyDisplay.CopperDisplay:IsShown() then
		return moneyDisplay.CopperDisplay
	end
	if moneyDisplay.SilverDisplay ~= nil and moneyDisplay.SilverDisplay:IsShown() then
		return moneyDisplay.SilverDisplay
	end
	return moneyDisplay.GoldDisplay
end

local function EnsureDelta(priceRow)
	local delta = priceRow.TabuAucDelta
	if delta ~= nil then
		return delta
	end
	local source = priceRow.MoneyDisplayFrame
	delta = CreateFrame("Frame", nil, source, "MoneyDisplayFrameTemplate")
	delta.leftAlign = true
	if source.hideCopper then
		delta.hideCopper = true
		delta.CopperDisplay:SetForcedHidden(true)
	end
	if source.useAuctionHouseIcons then
		delta.CopperDisplay:SetDisplayType(MoneyDenominationDisplayType.AuctionHouseCopper)
		delta.SilverDisplay:SetDisplayType(MoneyDenominationDisplayType.AuctionHouseSilver)
		delta.GoldDisplay:SetDisplayType(MoneyDenominationDisplayType.AuctionHouseGold)
	end
	delta:SetResizeToFit(true)
	delta:UpdateAnchoring()
	priceRow.TabuAucDelta = delta
	return delta
end

local DELTA_OFFSET = 20
local SIGN_GAP = 2

local function DeltaSign(colorName, amount)
	if colorName == COLOR_GREEN then
		return "+"
	end
	if colorName == COLOR_RED and amount ~= 0 then
		return "-"
	end
	return ""
end

local function EnsureDeltaSign(priceRow)
	local sign = priceRow.TabuAucDeltaSign
	if sign ~= nil then
		return sign
	end
	sign = priceRow.MoneyDisplayFrame:CreateFontString(nil, "OVERLAY", "PriceFont")
	priceRow.TabuAucDeltaSign = sign
	return sign
end

local function ApplySign(sign, colorName, color, amount)
	local text = DeltaSign(colorName, amount)
	sign:SetText(text)
	if text == "" then
		sign:Hide()
		return
	end
	sign:SetFontObject(PriceFont)
	if color ~= nil then
		sign:SetTextColor(color:GetRGB())
	end
	sign:Show()
end

local function HidesSmallChange(amount)
	return amount >= COPPER_PER_GOLD
end

local function ApplySmallChangeVisibility(delta, amount)
	local hideSmallChange = HidesSmallChange(amount)
	delta.SilverDisplay:SetForcedHidden(hideSmallChange)
	delta.CopperDisplay:SetForcedHidden(hideSmallChange or delta.hideCopper == true)
end

local function ShowDeltaTooltip(delta)
	local amount = delta.TabuAucExact
	if amount == nil then
		return
	end
	GameTooltip:SetOwner(delta, "ANCHOR_RIGHT")
	local text = DeltaSign(delta.TabuAucExactColor, amount) .. GetMoneyString(amount, true)
	local color = MoneyColor(delta.TabuAucExactColor)
	if color ~= nil then
		GameTooltip:SetText(text, color:GetRGB())
	else
		GameTooltip:SetText(text)
	end
	GameTooltip:Show()
end

local function RefreshOwnedDeltaTooltip(delta)
	if GameTooltip:GetOwner() ~= delta then
		return
	end
	if delta.TabuAucExact == nil then
		GameTooltip:Hide()
		return
	end
	ShowDeltaTooltip(delta)
end

local function SetDeltaTooltip(delta, colorName, amount)
	if HidesSmallChange(amount) then
		delta.TabuAucExact = amount
		delta.TabuAucExactColor = colorName
	else
		delta.TabuAucExact = nil
		delta.TabuAucExactColor = nil
	end
	RefreshOwnedDeltaTooltip(delta)
end

local function ClearDeltaTooltip(delta)
	if delta == nil then
		return
	end
	delta.TabuAucExact = nil
	delta.TabuAucExactColor = nil
	RefreshOwnedDeltaTooltip(delta)
end

local function BindDeltaTooltip(delta)
	if delta.TabuAucTooltipBound then
		return
	end
	delta.TabuAucTooltipBound = true
	delta:EnableMouse(true)
	delta:SetScript("OnEnter", ShowDeltaTooltip)
	delta:SetScript("OnLeave", GameTooltip_Hide)
end

local function PlaceDelta(priceRow, delta, sign)
	local anchor = RightmostDenomination(priceRow.MoneyDisplayFrame)
	if anchor == nil then
		return
	end
	delta:UpdateAnchoring()
	local beforeDelta = DELTA_OFFSET
	if sign:IsShown() then
		beforeDelta = DELTA_OFFSET + sign:GetStringWidth() + SIGN_GAP
	end
	delta:ClearAllPoints()
	delta:SetPoint("LEFT", anchor, "RIGHT", beforeDelta, 0)
	if sign:IsShown() then
		sign:ClearAllPoints()
		sign:SetPoint("RIGHT", delta, "LEFT", -SIGN_GAP, 0)
	end
end

local function HasSellItem(sellFrame)
	if sellFrame.GetItem == nil then
		return false
	end
	local item = sellFrame:GetItem()
	if item == nil or not item:IsValid() then
		return false
	end
	return true
end

local function ShowReceive(receiveRow, receive, deltaAmount, deltaColor)
	if receive == nil then
		local wasShown = receiveRow:IsShown()
		if wasShown then
			receiveRow:Hide()
		end
		if receiveRow.TabuAucDelta ~= nil then
			receiveRow.TabuAucDelta:Hide()
			ClearDeltaTooltip(receiveRow.TabuAucDelta)
		end
		if receiveRow.TabuAucDeltaSign ~= nil then
			receiveRow.TabuAucDeltaSign:Hide()
		end
		return wasShown
	end
	local wasHidden = not receiveRow:IsShown()
	receiveRow:SetAmount(receive)
	receiveRow:Show()
	ApplyMoneyColor(receiveRow.MoneyDisplayFrame, nil)
	local color = MoneyColor(deltaColor)
	receiveRow:SetLabelColor(color or NORMAL_FONT_COLOR)
	local delta = EnsureDelta(receiveRow)
	local sign = EnsureDeltaSign(receiveRow)
	if deltaAmount == nil then
		delta:Hide()
		sign:Hide()
		ClearDeltaTooltip(delta)
		return wasHidden
	end
	ApplySmallChangeVisibility(delta, deltaAmount)
	SetDeltaTooltip(delta, deltaColor, deltaAmount)
	BindDeltaTooltip(delta)
	delta:SetAmount(deltaAmount)
	delta:Show()
	ApplySign(sign, deltaColor, color, deltaAmount)
	PlaceDelta(receiveRow, delta, sign)
	ApplyMoneyColor(delta, color)
	return wasHidden
end

local function ListingView(sellFrame)
	local hasItem = HasSellItem(sellFrame)
	local quantityInput = sellFrame.QuantityInput
	local quantityShown = quantityInput ~= nil and quantityInput:IsShown()
	local quantity = ListingQuantity(sellFrame:GetQuantity(), quantityShown)
	local unitPrice = UnitPrice(sellFrame)
	if not hasItem then
		quantity = 0
		unitPrice = 0
	end
	local percent = CommissionRate(openFaction)
	local vendorUnit, vendorPending = nil, false
	if hasItem then
		vendorUnit, vendorPending = VendorUnitPrice(sellFrame)
	end
	local receive = ReceiveCopper(quantity, unitPrice, percent)
	local copper = CommissionCopper(quantity, unitPrice, percent)
	local vendorTotal = nil
	if not hasItem then
		vendorTotal = 0
	elseif vendorUnit ~= nil then
		vendorTotal = ListedCopper(quantity, vendorUnit)
	end
	local deltaAmount, deltaColor = nil, nil
	if receive ~= nil and not vendorPending then
		deltaAmount, deltaColor = DeltaDisplay(receive, vendorTotal)
	end
	return receive, copper, deltaAmount, deltaColor, vendorPending
end

local function ViewKey(receive, copper, deltaAmount, deltaColor)
	return tostring(receive) .. "|" .. tostring(copper) .. "|" .. tostring(deltaAmount) .. "|" .. tostring(deltaColor)
end

local function SearchResultsReady(sellFrame)
	if sellFrame.GetPrice ~= nil then
		local itemKey = sellFrame.listDisplayedItemKey
		if itemKey == nil or issecretvalue(itemKey) then
			return true
		end
		return C_AuctionHouse.HasFullItemSearchResults(itemKey)
	end
	local item = sellFrame:GetItem()
	if item == nil or not item:IsValid() then
		return true
	end
	local itemID = C_Item.GetItemID(item)
	if itemID == nil or issecretvalue(itemID) then
		return true
	end
	return C_AuctionHouse.HasFullCommoditySearchResults(itemID)
end

local function QuotePending(sellFrame)
	if not HasSellItem(sellFrame) then
		return false
	end
	if C_AuctionHouse.ShouldAutoPopulatePrice == nil or not C_AuctionHouse.ShouldAutoPopulatePrice() then
		return false
	end
	return not SearchResultsReady(sellFrame)
end

local function ApplyShown(sellFrame, receive, copper, deltaAmount, deltaColor)
	local cutCreated = sellFrame.TabuAucCut == nil
	local receiveCreated = sellFrame.TabuAucReceive == nil
	local cutRow = EnsurePriceRow(sellFrame, "TabuAucCut", CUT_LAYOUT_INDEX, ns.L.CUT_LABEL)
	local receiveRow = EnsurePriceRow(sellFrame, "TabuAucReceive", RECEIVE_LAYOUT_INDEX, ns.L.RECEIVE_LABEL)
	local layoutChanged = ShowReceive(receiveRow, receive, deltaAmount, deltaColor)
	if copper == nil then
		if cutRow:IsShown() then
			cutRow:Hide()
			layoutChanged = true
		end
	else
		local wasHidden = not cutRow:IsShown()
		cutRow:SetAmount(copper)
		cutRow:Show()
		if wasHidden then
			layoutChanged = true
		end
	end
	PinSellFooter(sellFrame)
	if cutCreated or receiveCreated or layoutChanged then
		sellFrame:MarkDirty()
	end
	sellFrame.TabuAucShown = {
		receive = receive,
		copper = copper,
		deltaAmount = deltaAmount,
		deltaColor = deltaColor,
	}
	sellFrame.TabuAucShownKey = ViewKey(receive, copper, deltaAmount, deltaColor)
end

local function ReapplyShown(sellFrame)
	local shown = sellFrame.TabuAucShown
	if shown == nil then
		return
	end
	ApplyShown(sellFrame, shown.receive, shown.copper, shown.deltaAmount, shown.deltaColor)
end

local function UpdateCut(sellFrame)
	CaptureFaction()
	if QuotePending(sellFrame) then
		ReapplyShown(sellFrame)
		return
	end
	local receive, copper, deltaAmount, deltaColor, vendorPending = ListingView(sellFrame)
	if vendorPending then
		ReapplyShown(sellFrame)
		return
	end
	local key = ViewKey(receive, copper, deltaAmount, deltaColor)
	if sellFrame.TabuAucShownKey == key then
		return
	end
	ApplyShown(sellFrame, receive, copper, deltaAmount, deltaColor)
end

-- IsShown stays true after the auction house hides this frame's parent.
local function SellFrameVisible(sellFrame)
	return sellFrame ~= nil and sellFrame:IsVisible()
end

local cutScheduled = {}

local function ScheduleCut(sellFrame)
	if sellFrame == nil or cutScheduled[sellFrame] then
		return
	end
	cutScheduled[sellFrame] = true
	C_Timer.After(0, function()
		cutScheduled[sellFrame] = nil
		if SellFrameVisible(sellFrame) then
			UpdateCut(sellFrame)
		end
	end)
end

local function OnTotalPriceUpdated(sellFrame)
	if QuotePending(sellFrame) then
		ReapplyShown(sellFrame)
		return
	end
	ScheduleCut(sellFrame)
end

local function HookOneSellFrame(frame)
	if frame == nil or frame.TabuAucExtHooked then
		return
	end
	frame.TabuAucExtHooked = true
	PinSellFooter(frame)
	hooksecurefunc(frame, "Layout", PinSellFooter)
	hooksecurefunc(frame, "UpdateTotalPrice", OnTotalPriceUpdated)
	hooksecurefunc(frame, "OnShow", ScheduleCut)
end

local function HookSellFrames()
	if AuctionHouseFrame == nil then
		return
	end
	HookOneSellFrame(AuctionHouseFrame.ItemSellFrame)
	HookOneSellFrame(AuctionHouseFrame.CommoditiesSellFrame)
end

local function RefreshVisibleSellFrames()
	if AuctionHouseFrame == nil then
		return
	end
	local frames = { AuctionHouseFrame.ItemSellFrame, AuctionHouseFrame.CommoditiesSellFrame }
	for index = 1, #frames do
		local frame = frames[index]
		if SellFrameVisible(frame) then
			ScheduleCut(frame)
		end
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
		CaptureFaction()
		RefreshVisibleSellFrames()
		return
	end
	if event == "AUCTION_HOUSE_CLOSED" then
		openFaction = nil
		return
	end
	if event == "AUCTION_HOUSE_AUCTION_CREATED" then
		RefreshVisibleSellFrames()
		return
	end
	if event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
		RefreshVisibleSellFrames()
	end
end

local listener = CreateFrame("Frame")
listener:RegisterEvent("ADDON_LOADED")
listener:RegisterEvent("AUCTION_HOUSE_SHOW")
listener:RegisterEvent("AUCTION_HOUSE_CLOSED")
listener:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED")
listener:RegisterEvent("GET_ITEM_INFO_RECEIVED")
listener:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED")
listener:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
listener:SetScript("OnEvent", OnEvent)

if C_AddOns.IsAddOnLoaded(AUCTION_HOUSE_UI) then
	HookSellFrames()
end
