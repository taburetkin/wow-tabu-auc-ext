const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

function shouldShow(query) {
	if (query.enabled !== true) return false;
	if (typeof query.vendorPrice !== "number" || query.vendorPrice <= 0) return false;
	if (typeof query.maxStack !== "number" || query.maxStack <= 1) return false;
	if (typeof query.stackCount !== "number" || query.stackCount <= 1) return false;
	return true;
}

test("unit price shows only for an enabled stack with a vendor price", () => {
	const ready = { enabled: true, vendorPrice: 25, maxStack: 20, stackCount: 5 };
	assert.equal(shouldShow(ready), true);
	assert.equal(shouldShow({ ...ready, enabled: false }), false);
	assert.equal(shouldShow({ ...ready, vendorPrice: 0 }), false);
	assert.equal(shouldShow({ ...ready, vendorPrice: null }), false);
	assert.equal(shouldShow({ ...ready, maxStack: 1 }), false);
	assert.equal(shouldShow({ ...ready, stackCount: 1 }), false);
});

test("unit price line matches the sell price line and defaults off", () => {
	const root = path.join(__dirname, "..");
	const lua = fs.readFileSync(path.join(root, "UnitPrice.lua"), "utf8");
	const toc = fs.readFileSync(path.join(root, "tabu-auc-ext.toc"), "utf8");
	const base = fs.readFileSync(path.join(root, "Locales", "Base.lua"), "utf8");
	const ru = fs.readFileSync(path.join(root, "Locales", "ruRU.lua"), "utf8");
	assert.match(toc, /UnitPrice\.lua/);
	assert.match(toc, /## SavedVariables: TabuAucExtDB/);
	assert.match(lua, /function ns\.UnitPrice\.ShouldShow\(query\)/);
	assert.match(lua, /TabuAucExtDB\.showUnitPrice == true/);
	assert.match(lua, /C_Item\.GetStackCount\(location\)/);
	assert.match(lua, /C_Item\.GetItemMaxStackSize/);
	assert.match(lua, /select\(11, C_Item\.GetItemInfo\(item\)\)/);
	assert.match(lua, /GameTooltip_AddHighlightLine\(tooltip, string\.format\("%s: %s", ns\.L\.UNIT_PRICE, money\)\)/);
	assert.match(lua, /MoneyFormatterUtil\.FormatMoney\(vendorPrice, GameTooltipMoneyFormat\)/);
	assert.match(lua, /Settings\.RegisterAddOnSetting\(/);
	assert.match(lua, /Settings\.CreateCheckbox\(category, setting, ns\.L\.UNIT_PRICE_OPTION_TIP\)/);
	assert.match(lua, /false\s*\)/);
	assert.match(base, /UNIT_PRICE = "Unit Price"/);
	assert.match(ru, /UNIT_PRICE = "Цена за штуку"/);
	for (const name of ["frFR", "deDE", "esES", "esMX", "ptBR"]) {
		const file = fs.readFileSync(path.join(root, "Locales", name + ".lua"), "utf8");
		assert.match(file, /UNIT_PRICE = "/);
		assert.match(file, /UNIT_PRICE_OPTION = "/);
	}
});
