local _, ns = ...

ns.Price = {}

ns.Price.BLIZZARD = "blizzard"
ns.Price.EXACT = "exact"
ns.Price.REMEMBERED = "remembered"
ns.Price.MULTIPLIER = "multiplier"

local function Positive(value)
	return type(value) == "number" and value > 0
end

local function Present(value)
	return type(value) == "number" and value >= 0
end

function ns.Price.FallbackCopper(vendorPrice, multiplier)
	if type(vendorPrice) ~= "number" or type(multiplier) ~= "number" then
		return nil
	end
	return math.floor(vendorPrice * multiplier)
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

function ns.Price.Choose(query)
	if query.searchReady ~= true then
		return nil
	end
	if query.equipment == true then
		if Positive(query.exactPrice) then
			return { amount = query.exactPrice, source = ns.Price.EXACT }
		end
		if Present(query.rememberedPrice) then
			return { amount = query.rememberedPrice, source = ns.Price.REMEMBERED }
		end
		local fallback = ns.Price.FallbackCopper(query.vendorPrice, query.multiplier)
		if fallback ~= nil then
			return { amount = fallback, source = ns.Price.MULTIPLIER }
		end
		return nil
	end
	if Positive(query.blizzardPrice) then
		return { amount = query.blizzardPrice, source = ns.Price.BLIZZARD }
	end
	if Present(query.rememberedPrice) then
		return { amount = query.rememberedPrice, source = ns.Price.REMEMBERED }
	end
	local fallback = ns.Price.FallbackCopper(query.vendorPrice, query.multiplier)
	if fallback ~= nil then
		return { amount = fallback, source = ns.Price.MULTIPLIER }
	end
	return nil
end
