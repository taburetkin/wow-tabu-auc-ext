local _, ns = ...

ns.Price = {}

ns.Price.BLIZZARD = "blizzard"
ns.Price.EXACT = "exact"
ns.Price.TYPE = "type"
ns.Price.SUGGESTED = "suggested"

local COPPER_PER_SILVER = 100
-- AuctionHouseSellFrameMixin:GetDefaultPrice, Forever pin 9dc84f0.
-- DEFAULT_AUCTION_PRICE_MULTIPLIER is 1.5. A price already on a silver boundary still moves up one silver.
local DEFAULT_AUCTION_PRICE_MULTIPLIER = 1.5

local function Positive(value)
	return type(value) == "number" and value > 0
end

function ns.Price.DefaultCopper(vendorPrice)
	local price = COPPER_PER_SILVER
	if type(vendorPrice) == "number" then
		price = vendorPrice * DEFAULT_AUCTION_PRICE_MULTIPLIER
	end
	price = price + (COPPER_PER_SILVER - (price % COPPER_PER_SILVER))
	if price < COPPER_PER_SILVER then
		return COPPER_PER_SILVER
	end
	return price
end

function ns.Price.MinimumBuyout(amounts)
	local best = nil
	for index = 1, #amounts do
		local amount = amounts[index]
		if Positive(amount) and (best == nil or amount < best) then
			best = amount
		end
	end
	return best
end

local function Suggested(query)
	if type(query.suggestedPrice) ~= "number" then
		return nil
	end
	return { amount = query.suggestedPrice, source = ns.Price.SUGGESTED }
end

function ns.Price.Choose(query)
	if query.equipment == true then
		if query.exactReady ~= true then
			return nil
		end
		if Positive(query.exactPrice) then
			return { amount = query.exactPrice, source = ns.Price.EXACT }
		end
		if query.typeReady ~= true then
			return nil
		end
		if Positive(query.typePrice) then
			return { amount = query.typePrice, source = ns.Price.TYPE }
		end
		return Suggested(query)
	end
	if query.searchReady ~= true then
		return nil
	end
	if Positive(query.blizzardPrice) then
		return { amount = query.blizzardPrice, source = ns.Price.BLIZZARD }
	end
	return Suggested(query)
end
