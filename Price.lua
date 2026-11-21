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

local CLASS_CONSUMABLE = 0
local CLASS_CONTAINER = 1
local CLASS_WEAPON = 2
local CLASS_ARMOR = 4
local CLASS_REAGENT = 5
local CLASS_TRADEGOODS = 7
local CLASS_RECIPE = 9

function ns.Price.MultiplierKey(classID)
	if classID == CLASS_WEAPON then
		return "weapon"
	end
	if classID == CLASS_ARMOR then
		return "armor"
	end
	if classID == CLASS_CONSUMABLE then
		return "consumable"
	end
	if classID == CLASS_REAGENT or classID == CLASS_TRADEGOODS or classID == 7 then
		return "reagent"
	end
	if classID == CLASS_RECIPE then
		return "recipe"
	end
	if classID == CLASS_CONTAINER then
		return "bag"
	end
	return "other"
end

function ns.Price.MemoryKey(itemID, itemSuffix)
	if type(itemID) ~= "number" then
		return nil
	end
	local suffix = itemSuffix
	if type(suffix) ~= "number" then
		suffix = 0
	end
	return tostring(itemID) .. ":" .. tostring(suffix)
end

function ns.Price.FormatMultiplier(value)
	local text = string.format("%.1f", value)
	return (text:gsub("%.0$", ""))
end

function ns.Price.ShouldRemember(userEdited)
	return userEdited == true
end
