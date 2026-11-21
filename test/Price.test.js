const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const lua = fs.readFileSync(path.join(__dirname, "..", "Price.lua"), "utf8");

function positive(value) {
	return typeof value === "number" && value > 0;
}

function present(value) {
	return typeof value === "number" && value >= 0;
}

function choose(query) {
	if (!query.searchReady) {
		return null;
	}
	if (query.equipment) {
		if (positive(query.exactPrice)) {
			return { amount: query.exactPrice, source: "exact" };
		}
		if (present(query.rememberedPrice)) {
			return { amount: query.rememberedPrice, source: "remembered" };
		}
		if (present(query.vendorPrice)) {
			return { amount: Math.floor(query.vendorPrice * query.multiplier), source: "multiplier" };
		}
		return null;
	}
	if (positive(query.blizzardPrice)) {
		return { amount: query.blizzardPrice, source: "blizzard" };
	}
	if (present(query.rememberedPrice)) {
		return { amount: query.rememberedPrice, source: "remembered" };
	}
	if (present(query.vendorPrice)) {
		return { amount: Math.floor(query.vendorPrice * query.multiplier), source: "multiplier" };
	}
	return null;
}

function minimumBuyout(amounts) {
	let best = null;
	for (const amount of amounts) {
		if (typeof amount === "number" && amount > 0 && (best === null || amount < best)) {
			best = amount;
		}
	}
	return best;
}

test("equipment uses the exact buyout, then memory, then vendor times multiplier", () => {
	const ready = { equipment: true, searchReady: true, multiplier: 2, vendorPrice: 150, rememberedPrice: 400, exactPrice: 900, blizzardPrice: 100 };
	assert.deepEqual(choose(ready), { amount: 900, source: "exact" });
	assert.deepEqual(choose({ ...ready, exactPrice: null }), { amount: 400, source: "remembered" });
	assert.deepEqual(choose({ ...ready, exactPrice: null, rememberedPrice: 0 }), { amount: 0, source: "remembered" });
	assert.deepEqual(choose({ ...ready, exactPrice: null, rememberedPrice: null }), { amount: 300, source: "multiplier" });
	assert.equal(choose({ ...ready, searchReady: false }), null);
	assert.equal(choose({ ...ready, exactPrice: null, rememberedPrice: null, vendorPrice: null }), null);
});

test("other items use Blizzard, then memory, then vendor times multiplier", () => {
	const ready = { equipment: false, searchReady: true, multiplier: 2, vendorPrice: 50, rememberedPrice: 80, blizzardPrice: 120 };
	assert.deepEqual(choose(ready), { amount: 120, source: "blizzard" });
	assert.deepEqual(choose({ ...ready, blizzardPrice: 0 }), { amount: 80, source: "remembered" });
	assert.deepEqual(choose({ ...ready, blizzardPrice: null, rememberedPrice: null }), { amount: 100, source: "multiplier" });
});

test("minimum buyout ignores missing and non-positive rows", () => {
	assert.equal(minimumBuyout([null, 0, 40, 15, -1]), 15);
	assert.equal(minimumBuyout([null, 0]), null);
});

test("Price.lua exposes the same decision", () => {
	assert.match(lua, /function ns\.Price\.Choose\(query\)/);
	assert.match(lua, /function ns\.Price\.MinimumBuyout\(amounts\)/);
	assert.match(lua, /function ns\.Price\.FallbackCopper\(vendorPrice, multiplier\)/);
	assert.match(lua, /return math\.floor\(vendorPrice \* multiplier\)/);
	assert.match(toc(), /Price\.lua/);
});

function toc() {
	return fs.readFileSync(path.join(__dirname, "..", "tabu-auc-ext.toc"), "utf8");
}

function multiplierKey(classID) {
	if (classID === 2) return "weapon";
	if (classID === 4) return "armor";
	if (classID === 0) return "consumable";
	if (classID === 5 || classID === 7) return "reagent";
	if (classID === 9) return "recipe";
	if (classID === 1) return "bag";
	return "other";
}

function memoryKey(itemID, itemSuffix) {
	if (typeof itemID !== "number") return null;
	const suffix = typeof itemSuffix === "number" ? itemSuffix : 0;
	return itemID + ":" + suffix;
}

function formatMultiplier(value) {
	return value.toFixed(1).replace(/\.0$/, "");
}

test("item class maps onto the seven multiplier keys", () => {
	const priceLua = fs.readFileSync(path.join(__dirname, "..", "Price.lua"), "utf8");
	assert.equal(multiplierKey(2), "weapon");
	assert.equal(multiplierKey(4), "armor");
	assert.equal(multiplierKey(0), "consumable");
	assert.equal(multiplierKey(5), "reagent");
	assert.equal(multiplierKey(7), "reagent");
	assert.equal(multiplierKey(9), "recipe");
	assert.equal(multiplierKey(1), "bag");
	assert.equal(multiplierKey(15), "other");
	assert.equal(multiplierKey(null), "other");
	assert.equal(memoryKey(12345, -18), "12345:-18");
	assert.equal(memoryKey(12345, null), "12345:0");
	assert.equal(memoryKey(null, 0), null);
	assert.equal(formatMultiplier(2), "2");
	assert.equal(formatMultiplier(2.5), "2.5");
	assert.match(priceLua, /function ns\.Price\.MultiplierKey\(classID\)/);
	assert.match(priceLua, /function ns\.Price\.MemoryKey\(itemID, itemSuffix\)/);
	assert.match(priceLua, /function ns\.Price\.FormatMultiplier\(value\)/);
	assert.match(priceLua, /function ns\.Price\.ShouldRemember\(userEdited\)/);
	assert.match(priceLua, /classID == 7/);
});

test("price sources and multiplier labels are localized", () => {
	const root = path.join(__dirname, "..");
	const base = fs.readFileSync(path.join(root, "Locales", "Base.lua"), "utf8");
	const ru = fs.readFileSync(path.join(root, "Locales", "ruRU.lua"), "utf8");
	const fr = fs.readFileSync(path.join(root, "Locales", "frFR.lua"), "utf8");
	const de = fs.readFileSync(path.join(root, "Locales", "deDE.lua"), "utf8");
	const es = fs.readFileSync(path.join(root, "Locales", "esES.lua"), "utf8");
	const mx = fs.readFileSync(path.join(root, "Locales", "esMX.lua"), "utf8");
	const pt = fs.readFileSync(path.join(root, "Locales", "ptBR.lua"), "utf8");
	assert.match(base, /PRICE_BLIZZARD = "Auction house minimum\."/);
	assert.match(base, /PRICE_EXACT = "Lowest price for this affix\."/);
	assert.match(base, /PRICE_REMEMBERED = "Last price you entered for this item\."/);
	assert.match(base, /PRICE_MULTIPLIER = "Vendor price × %s \(%s\)\."/);
	assert.match(base, /TYPE_WEAPON = "Weapons"/);
	assert.match(base, /TYPE_ARMOR = "Armor"/);
	assert.match(base, /TYPE_CONSUMABLE = "Consumables"/);
	assert.match(base, /TYPE_REAGENT = "Reagents"/);
	assert.match(base, /TYPE_RECIPE = "Recipes"/);
	assert.match(base, /TYPE_BAG = "Bags"/);
	assert.match(base, /TYPE_OTHER = "Other"/);
	assert.match(base, /MULTIPLIER_HEADING = "Vendor price multiplier\. 2 is double\."/);
	assert.match(ru, /PRICE_BLIZZARD = "Минимум аукциона\."/);
	assert.match(ru, /PRICE_EXACT = "Минимальная цена этого аффикса\."/);
	assert.match(ru, /PRICE_REMEMBERED = "Последняя цена, которую вы ввели для этого предмета\."/);
	assert.match(ru, /PRICE_MULTIPLIER = "Цена торговцу × %s \(%s\)\."/);
	assert.match(ru, /TYPE_WEAPON = "Оружие"/);
	assert.match(ru, /TYPE_REAGENT = "Реагенты"/);
	assert.match(ru, /TYPE_OTHER = "Прочее"/);
	assert.match(ru, /MULTIPLIER_HEADING = "Множитель цены торговцу\. 2 — двойная цена\."/);
	for (const file of [fr, de, es, mx, pt]) {
		assert.match(file, /PRICE_BLIZZARD = "/);
		assert.match(file, /TYPE_WEAPON = "/);
		assert.match(file, /TYPE_OTHER = "/);
		assert.match(file, /MULTIPLIER_HEADING = "/);
	}
});

test("settings store seven multipliers and remembered prices", () => {
	const root = path.join(__dirname, "..");
	const settings = fs.readFileSync(path.join(root, "Settings.lua"), "utf8");
	const toc = fs.readFileSync(path.join(root, "tabu-auc-ext.toc"), "utf8");
	assert.match(toc, /## SavedVariables: TabuAucExtDB/);
	assert.match(toc, /Settings\.lua/);
	assert.match(settings, /local DEFAULT_MULTIPLIER = 2/);
	assert.match(settings, /local MULTIPLIER_MIN = 0/);
	assert.match(settings, /local MULTIPLIER_MAX = 100/);
	assert.match(settings, /Settings\.RegisterVerticalLayoutCategory\("tabu-auc-ext"\)/);
	assert.match(settings, /Settings\.RegisterAddOnCategory\(category\)/);
	assert.match(settings, /Settings\.CreateSliderOptions\(MULTIPLIER_MIN, MULTIPLIER_MAX, 0\.1\)/);
	assert.match(settings, /CreateSettingsListSectionHeaderInitializer\(ns\.L\.MULTIPLIER_HEADING/);
	assert.match(settings, /CreateFrame\("EditBox"/);
	assert.match(settings, /function ns\.Settings\.Multiplier\(classID\)/);
	assert.match(settings, /function ns\.Settings\.Remembered\(itemID, itemSuffix\)/);
	assert.match(settings, /function ns\.Settings\.Remember\(itemID, itemSuffix, amount, userEdited\)/);
	assert.match(settings, /ns\.Price\.ShouldRemember\(userEdited\)/);
	assert.equal(settings.includes("RegisterVerticalLayoutCategory"), true);
	const registrations = settings.match(/Settings\.RegisterAddOnCategory\(/g);
	assert.equal(registrations.length, 1);
});

test("sell frame queries the real equipment key and colors the price", () => {
	const root = path.join(__dirname, "..");
	const sell = fs.readFileSync(path.join(root, "SellPrice.lua"), "utf8");
	const toc = fs.readFileSync(path.join(root, "tabu-auc-ext.toc"), "utf8");
	assert.match(toc, /SellPrice\.lua/);
	assert.match(sell, /C_AuctionHouse\.MakeItemKey\(fresh\.itemID, fresh\.itemLevel, fresh\.itemSuffix, fresh\.battlePetSpeciesID\)/);
	assert.match(sell, /QueryItem\(sellFrame:GetSearchContext\(\), exactKey, false\)/);
	assert.equal(sell.includes("exactKey, true"), false);
	assert.match(sell, /MoneyInputFrame/);
	assert.match(sell, /GetAmount/);
	assert.equal(sell.includes("GetUnitPrice"), false);
	assert.match(sell, /HasFullItemSearchResults\(exactKey\)/);
	assert.match(sell, /ns\.Price\.MinimumBuyout\(amounts\)/);
	assert.match(sell, /ns\.Price\.Choose\(query\)/);
	assert.match(sell, /userInput/);
	assert.match(sell, /PreClick/);
	assert.match(sell, /AUCTION_HOUSE_AUCTION_CREATED/);
	assert.match(sell, /ns\.Settings\.Remember\(snapshot\.itemID, snapshot\.itemSuffix, snapshot\.amount, snapshot\.userEdited\)/);
	assert.match(sell, /0\.2, 0\.6, 1/);
	assert.match(sell, /0\.64, 0\.21, 0\.93/);
	assert.match(sell, /1, 0\.5, 0/);
	assert.equal(sell.includes("totalPrice:Set"), false);
});