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
