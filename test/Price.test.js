const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const lua = fs.readFileSync(path.join(__dirname, "..", "Price.lua"), "utf8");
const COPPER_PER_SILVER = 100;

function positive(value) {
	return typeof value === "number" && value > 0;
}

function suggested(query) {
	if (typeof query.suggestedPrice !== "number") {
		return null;
	}
	return { amount: query.suggestedPrice, source: "suggested" };
}

function choose(query) {
	if (query.equipment === true) {
		if (query.exactReady !== true) {
			return null;
		}
		if (positive(query.exactPrice)) {
			return { amount: query.exactPrice, source: "exact" };
		}
		if (query.typeReady !== true) {
			return null;
		}
		if (positive(query.typePrice)) {
			return { amount: query.typePrice, source: "type" };
		}
		return suggested(query);
	}
	if (query.searchReady !== true) {
		return null;
	}
	if (positive(query.blizzardPrice)) {
		return { amount: query.blizzardPrice, source: "blizzard" };
	}
	return suggested(query);
}

// AuctionHouseSellFrameMixin:GetDefaultPrice adds one silver even when the price is already on a silver boundary.
function defaultCopper(vendorPrice) {
	let price = COPPER_PER_SILVER;
	if (typeof vendorPrice === "number") {
		price = vendorPrice * 1.5;
	}
	price = price + (COPPER_PER_SILVER - (price % COPPER_PER_SILVER));
	if (price < COPPER_PER_SILVER) {
		return COPPER_PER_SILVER;
	}
	return price;
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

test("equipment uses the affix buyout, then the default item minimum, then the auction suggestion", () => {
	const ready = {
		equipment: true,
		exactReady: true,
		typeReady: true,
		exactPrice: 900,
		typePrice: 400,
		suggestedPrice: 200,
	};
	assert.deepEqual(choose(ready), { amount: 900, source: "exact" });
	assert.deepEqual(choose({ ...ready, exactPrice: null }), { amount: 400, source: "type" });
	assert.deepEqual(choose({ ...ready, exactPrice: 0, typePrice: null }), { amount: 200, source: "suggested" });
	assert.equal(choose({ ...ready, exactReady: false }), null);
	assert.equal(choose({ ...ready, exactPrice: null, typeReady: false }), null);
	assert.equal(choose({ ...ready, exactPrice: null, typePrice: null, suggestedPrice: null }), null);
});

test("other items use the auction listing, then the auction suggestion", () => {
	const ready = { equipment: false, searchReady: true, blizzardPrice: 120, suggestedPrice: 200 };
	assert.deepEqual(choose(ready), { amount: 120, source: "blizzard" });
	assert.deepEqual(choose({ ...ready, blizzardPrice: 0 }), { amount: 200, source: "suggested" });
	assert.equal(choose({ ...ready, searchReady: false }), null);
	assert.equal(choose({ ...ready, blizzardPrice: null, suggestedPrice: null }), null);
});

test("default auction price is vendor times 1.5, rounded up to the next silver", () => {
	assert.equal(defaultCopper(0), 100);
	assert.equal(defaultCopper(100), 200);
	assert.equal(defaultCopper(150), 300);
	assert.equal(defaultCopper(200), 400);
	assert.equal(defaultCopper(50), 100);
	assert.match(lua, /function ns\.Price\.DefaultCopper\(vendorPrice\)/);
	assert.match(lua, /local DEFAULT_AUCTION_PRICE_MULTIPLIER = 1\.5/);
	assert.match(lua, /price \+ \(COPPER_PER_SILVER - \(price % COPPER_PER_SILVER\)\)/);
});

test("minimum buyout ignores missing and non-positive rows", () => {
	assert.equal(minimumBuyout([null, 0, 40, 15, -1]), 15);
	assert.equal(minimumBuyout([null, 0]), null);
});

test("Price.lua exposes the same decision", () => {
	assert.match(lua, /function ns\.Price\.Choose\(query\)/);
	assert.match(lua, /function ns\.Price\.MinimumBuyout\(amounts\)/);
	assert.match(lua, /ns\.Price\.TYPE/);
	assert.match(lua, /ns\.Price\.SUGGESTED/);
	assert.equal(lua.includes("FallbackCopper"), false);
	assert.equal(lua.includes("MultiplierKey"), false);
	assert.equal(lua.includes("MemoryKey"), false);
	assert.match(toc(), /Price\.lua/);
	assert.equal(toc().includes("Settings.lua"), false);
});

function toc() {
	return fs.readFileSync(path.join(__dirname, "..", "tabu-auc-ext.toc"), "utf8");
}

test("price sources are localized", () => {
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
	assert.match(base, /PRICE_TYPE = "No listings for this affix, so this is the default minimum for this item\."/);
	assert.match(base, /PRICE_SUGGESTED = "This item is not listed\. The auction house suggests its own minimum\."/);
	assert.equal(base.includes("PRICE_REMEMBERED"), false);
	assert.equal(base.includes("PRICE_MULTIPLIER"), false);
	assert.match(ru, /PRICE_BLIZZARD = "Минимум аукциона\."/);
	assert.match(ru, /PRICE_EXACT = "Минимальная цена этого аффикса\."/);
	assert.match(ru, /PRICE_TYPE = "Лотов этого аффикса нет, поэтому это минимум по умолчанию для этого предмета\."/);
	assert.match(ru, /PRICE_SUGGESTED = "Этого предмета нет в продаже\. Аукцион подставляет свой минимум\."/);
	for (const file of [fr, de, es, mx, pt]) {
		assert.match(file, /PRICE_BLIZZARD = "/);
		assert.match(file, /PRICE_TYPE = "/);
		assert.match(file, /PRICE_SUGGESTED = "/);
		assert.equal(file.includes("TYPE_WEAPON"), false);
		assert.equal(file.includes("MULTIPLIER_HEADING"), false);
	}
	assert.equal(fs.existsSync(path.join(root, "Settings.lua")), false);
});

test("sell frame prices from the auction's own search", () => {
	const root = path.join(__dirname, "..");
	const sell = fs.readFileSync(path.join(root, "SellPrice.lua"), "utf8");
	const tocText = fs.readFileSync(path.join(root, "tabu-auc-ext.toc"), "utf8");
	assert.match(tocText, /SellPrice\.lua/);
	assert.equal(sell.includes("QueryItem"), false);
	assert.equal(sell.includes("listDisplayedItemKey ="), false);
	assert.match(sell, /HasFullItemSearchResults\(itemKey\)/);
	assert.match(sell, /sellFrame\.listDisplayedItemKey/);
	assert.match(sell, /MoneyInputFrame/);
	assert.match(sell, /GetAmount/);
	assert.equal(sell.includes("GetUnitPrice"), false);
	assert.match(sell, /ns\.Price\.MinimumBuyout\(CollectBuyouts/);
	assert.match(sell, /ns\.Price\.Choose\(query\)/);
	assert.match(sell, /ns\.Price\.DefaultCopper\(vendorPrice\)/);
	assert.match(sell, /ShouldAutoPopulatePrice/);
	assert.match(sell, /userInput/);
	assert.match(sell, /hooksecurefunc\(editBox, "OnTextChanged"/);
	assert.match(sell, /hooksecurefunc\(sellFrame, "OnShow", ScheduleRefresh\)/);
	assert.equal(sell.includes("HookScript"), false);
	assert.equal(sell.includes("PreClick"), false);
	assert.equal(sell.includes("AUCTION_HOUSE_AUCTION_CREATED"), false);
	assert.equal(sell.includes("ns.Settings"), false);
	assert.match(sell, /\[ns\.Price\.EXACT\] = \{ 0\.64, 0\.21, 0\.93 \}/);
	assert.match(sell, /\[ns\.Price\.TYPE\] = \{ 0\.2, 0\.6, 1 \}/);
	assert.match(sell, /\[ns\.Price\.SUGGESTED\] = \{ 1, 0\.1, 0\.1 \}/);
	assert.equal(sell.includes("1, 0.82, 0.2"), false);
	assert.equal(sell.includes("1, 0.5, 0"), false);
	assert.equal(sell.includes("totalPrice:Set"), false);
	const refresh = sell.slice(sell.indexOf("local function RefreshShownFrames"), sell.indexOf("local function OnItemSet"));
	const schedule = sell.slice(sell.indexOf("local function ScheduleRefresh"), sell.indexOf("local function RefreshShownFrames"));
	assert.match(refresh, /SellFrameVisible\(frames\[index\]\)/);
	assert.match(schedule, /SellFrameVisible\(sellFrame\)/);
	assert.equal(refresh.includes("IsShown()"), false);
	assert.equal(schedule.includes("IsShown()"), false);
});
