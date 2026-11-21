const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const addonRoot = path.join(__dirname, "..");
const lua = fs.readFileSync(path.join(addonRoot, "Core.lua"), "utf8");
const toc = fs.readFileSync(path.join(addonRoot, "tabu-auc-ext.toc"), "utf8");
const ru = fs.readFileSync(path.join(addonRoot, "Locales", "ruRU.lua"), "utf8");
const fr = fs.readFileSync(path.join(addonRoot, "Locales", "frFR.lua"), "utf8");
const de = fs.readFileSync(path.join(addonRoot, "Locales", "deDE.lua"), "utf8");
const esES = fs.readFileSync(path.join(addonRoot, "Locales", "esES.lua"), "utf8");
const esMX = fs.readFileSync(path.join(addonRoot, "Locales", "esMX.lua"), "utf8");
const ptBR = fs.readFileSync(path.join(addonRoot, "Locales", "ptBR.lua"), "utf8");

const NEUTRAL_PERCENT = 15;
const FACTION_PERCENT = 5;

function houseFaction(factionGroup, reaction) {
	if (factionGroup === "Neutral" || factionGroup === "Alliance" || factionGroup === "Horde") {
		return factionGroup;
	}
	if (typeof reaction === "number" && reaction >= 4) {
		return "Neutral";
	}
	return null;
}

function commissionRate(factionGroup) {
	const house = houseFaction(factionGroup, null);
	if (house === "Neutral") {
		return NEUTRAL_PERCENT;
	}
	if (house === "Alliance" || house === "Horde") {
		return FACTION_PERCENT;
	}
	return null;
}

function listedCopper(quantity, unitPrice) {
	if (typeof quantity !== "number" || typeof unitPrice !== "number") {
		return null;
	}
	if (quantity < 0 || unitPrice < 0) {
		return null;
	}
	return quantity * unitPrice;
}

function commissionCopper(quantity, unitPrice, percent) {
	const totalPrice = listedCopper(quantity, unitPrice);
	if (totalPrice == null || typeof percent !== "number" || percent < 0) {
		return null;
	}
	return Math.floor((totalPrice * percent) / 100);
}

function receiveCopper(quantity, unitPrice, percent) {
	const totalPrice = listedCopper(quantity, unitPrice);
	const commission = commissionCopper(quantity, unitPrice, percent);
	if (totalPrice == null || commission == null) {
		return null;
	}
	return totalPrice - commission;
}

function listingQuantity(quantity, quantityShown) {
	if (!quantityShown) {
		return 1;
	}
	return quantity;
}

function deltaDisplay(receive, vendorTotal) {
	if (typeof receive !== "number" || typeof vendorTotal !== "number") {
		return null;
	}
	const delta = receive - vendorTotal;
	if (delta > 0) {
		return { amount: delta, color: "green" };
	}
	if (delta < 0) {
		return { amount: -delta, color: "red" };
	}
	return { amount: 0, color: "red" };
}

function hidesSmallChange(amount) {
	return amount >= 10000;
}

test("addon identity and Forever TOC", () => {
	assert.equal(path.basename(addonRoot), "tabu-auc-ext");
	assert.match(toc, /^## Interface: 16001/m);
	assert.match(toc, /^## Title: tabu-auc-ext/m);
	assert.match(toc, /^Locales\\Base\.lua$/m);
	assert.match(toc, /^Locales\\ruRU\.lua$/m);
	assert.match(toc, /^Locales\\frFR\.lua$/m);
	assert.match(toc, /^Locales\\deDE\.lua$/m);
	assert.match(toc, /^Locales\\esES\.lua$/m);
	assert.match(toc, /^Locales\\esMX\.lua$/m);
	assert.match(toc, /^Locales\\ptBR\.lua$/m);
	assert.match(toc, /^Core\.lua$/m);
	assert.match(toc, /^## SavedVariables: TabuAucExtDB$/m);
	assert.match(toc, /^## Notes: /m);
	assert.match(toc, /^## Notes-ruRU: /m);
	assert.match(toc, /^## Notes-frFR: /m);
	assert.match(toc, /^## Notes-deDE: /m);
	assert.match(toc, /^## Notes-esES: /m);
	assert.match(toc, /^## Notes-esMX: /m);
	assert.match(toc, /^## Notes-ptBR: /m);
});

test("neutral auctioneer is 15 percent and faction auctioneer is 5", () => {
	assert.equal(commissionRate("Neutral"), 15);
	assert.equal(commissionRate("Alliance"), 5);
	assert.equal(commissionRate("Horde"), 5);
	assert.equal(commissionRate(null), null);
	assert.equal(commissionRate(undefined), null);
	assert.equal(commissionRate(""), null);
	assert.equal(houseFaction(null, 4), "Neutral");
	assert.equal(houseFaction(undefined, 4), "Neutral");
	assert.equal(houseFaction("", 4), "Neutral");
	assert.equal(houseFaction("Alliance", 4), "Alliance");
	assert.equal(houseFaction("Horde", 5), "Horde");
	assert.equal(houseFaction(null, 5), "Neutral");
	assert.equal(houseFaction(null, 8), "Neutral");
	assert.equal(houseFaction(null, 3), null);
	assert.equal(houseFaction(null, null), null);
	assert.match(lua, /local NEUTRAL_FACTION = "Neutral"/);
	assert.match(lua, /local NEUTRAL_REACTION = 4/);
	assert.match(lua, /local FACTION_PERCENT = 5/);
	assert.match(lua, /local NEUTRAL_PERCENT = 15/);
	assert.match(lua, /UnitFactionGroup\(unit\)/);
	assert.match(lua, /UnitReaction\("player", unit\)/);
	assert.match(lua, /return HouseFaction\(faction, reaction\)/);
	assert.match(lua, /FactionOf\("npc"\)/);
	assert.match(lua, /FactionOf\("target"\)/);
	assert.match(lua, /reaction >= NEUTRAL_REACTION/);
	assert.match(lua, /HookScript\("OnShow"/);
});

test("cut is quantity times unit price times the house percent", () => {
	assert.equal(commissionCopper(1, 10000, 5), 500);
	assert.equal(commissionCopper(1, 10000, 15), 1500);
	assert.equal(commissionCopper(20, 10000, 5), 10000);
	assert.equal(commissionCopper(20, 10000, 15), 30000);
	assert.equal(commissionCopper(20, 199, 15), 597);
	assert.equal(commissionCopper(1, 1, 5), 0);
	assert.equal(commissionCopper(0, 10000, 5), 0);
	assert.equal(commissionCopper(null, 10000, 5), null);
	assert.equal(commissionCopper(1, 10000, null), null);
	assert.match(lua, /return quantity \* unitPrice/);
	assert.match(lua, /math\.floor\(totalPrice \* percent \/ 100\)/);
	assert.match(lua, /sellFrame:GetQuantity\(\)/);
	assert.match(lua, /hooksecurefunc\(frame, "UpdateTotalPrice", OnTotalPriceUpdated\)/);
	assert.match(lua, /C_Timer\.After\(0,/);
	assert.match(lua, /HasFullItemSearchResults/);
	assert.match(lua, /HasFullCommoditySearchResults/);
	assert.match(lua, /ITEM_SEARCH_RESULTS_UPDATED/);
	assert.match(lua, /COMMODITY_SEARCH_RESULTS_UPDATED/);
	assert.match(lua, /vendorPending/);
	assert.match(lua, /TabuAucShownKey/);
	assert.match(lua, /AuctionHouseFrame\.ItemSellFrame/);
	assert.match(lua, /AuctionHouseFrame\.CommoditiesSellFrame/);
	assert.match(lua, /AuctionHouseAlignedPriceDisplayTemplate/);
	assert.match(lua, /local CUT_LAYOUT_INDEX = 64/);
	assert.match(lua, /local RECEIVE_LAYOUT_INDEX = 65/);
	assert.match(lua, /button\.ignoreInLayout = true/);
	assert.match(lua, /button\.layoutIndex = nil/);
	assert.match(lua, /SetPoint\("BOTTOMRIGHT", sellFrame, "BOTTOMRIGHT", -FOOTER_INSET, FOOTER_INSET\)/);
	assert.match(lua, /SetPoint\("BOTTOMLEFT", sellFrame, "BOTTOMLEFT", FOOTER_INSET - 6, FOOTER_INSET - 9\)/);
	assert.match(lua, /hooksecurefunc\(frame, "Layout", PinSellFooter\)/);
	assert.match(lua, /EnsurePriceRow\(sellFrame, "TabuAucCut", CUT_LAYOUT_INDEX, ns\.L\.CUT_LABEL\)/);
	assert.match(lua, /EnsurePriceRow\(sellFrame, "TabuAucReceive", RECEIVE_LAYOUT_INDEX, ns\.L\.RECEIVE_LABEL\)/);
	assert.equal(lua.includes("totalPrice:Set"), false);
	assert.equal(lua.includes("TotalPrice:Set"), false);
	assert.equal(receiveCopper(20, 10000, 5), 190000);
	assert.equal(receiveCopper(20, 10000, 15), 170000);
	assert.equal(receiveCopper(1, 199, 5), 190);
	assert.equal(deltaDisplay(190000, 100000).amount, 90000);
	assert.equal(deltaDisplay(190000, 100000).color, "green");
	assert.equal(deltaDisplay(190000, 400000).amount, 210000);
	assert.equal(deltaDisplay(190000, 400000).color, "red");
	assert.equal(deltaDisplay(190000, 190000).amount, 0);
	assert.equal(deltaDisplay(190000, 190000).color, "red");
	assert.equal(deltaDisplay(190000, null), null);
	assert.match(lua, /return receive - vendorTotal/);
	assert.match(lua, /return delta, COLOR_GREEN/);
	assert.match(lua, /return -delta, COLOR_RED/);
	assert.match(lua, /select\(11, C_Item\.GetItemInfo\(itemLink\)\)/);
	assert.match(lua, /GREEN_FONT_COLOR/);
	assert.match(lua, /RED_FONT_COLOR/);
	assert.equal(listingQuantity(0, false), 1);
	assert.equal(listingQuantity(20, false), 1);
	assert.equal(listingQuantity(20, true), 20);
	assert.equal(receiveCopper(listingQuantity(0, false), 10000, 5), 9500);
	assert.match(lua, /if not quantityShown then/);
	assert.match(lua, /return 1/);
	assert.match(lua, /receiveRow:SetAmount\(receive\)/);
	assert.equal(hidesSmallChange(10000), true);
	assert.equal(hidesSmallChange(9999), false);
	assert.match(lua, /local COPPER_PER_GOLD = 10000/);
	assert.match(lua, /return amount >= COPPER_PER_GOLD/);
	assert.match(lua, /delta\.SilverDisplay:SetForcedHidden\(hideSmallChange\)/);
	assert.match(lua, /delta\.CopperDisplay:SetForcedHidden\(hideSmallChange or delta\.hideCopper == true\)/);
	assert.match(lua, /GetMoneyString\(amount, true\)/);
	assert.match(lua, /SetScript\("OnEnter", ShowDeltaTooltip\)/);
	assert.match(lua, /delta:SetResizeToFit\(true\)/);
	assert.match(lua, /delta:SetAmount\(deltaAmount\)/);
	assert.match(lua, /receiveRow:SetLabelColor\(color or NORMAL_FONT_COLOR\)/);
	assert.match(lua, /local DELTA_OFFSET = 20/);
	assert.match(lua, /return "\+"/);
	assert.match(lua, /return "-"/);
	assert.match(lua, /SetPoint\("LEFT", anchor, "RIGHT", beforeDelta, 0\)/);
	assert.match(lua, /SetPoint\("RIGHT", delta, "LEFT", -SIGN_GAP, 0\)/);
	assert.match(lua, /delta:UpdateAnchoring\(\)/);
	assert.equal(commissionCopper(0, 0, 5), 0);
	assert.equal(receiveCopper(0, 0, 5), 0);
	assert.equal(deltaDisplay(0, 0).amount, 0);
	assert.equal(deltaDisplay(0, 0).color, "red");
	assert.match(lua, /return 0, COLOR_RED/);
	assert.match(lua, /amount ~= 0/);
	assert.match(lua, /if not hasItem then/);
	assert.match(lua, /quantity = 0/);
	assert.match(lua, /unitPrice = 0/);
	assert.match(lua, /vendorTotal = 0/);
	assert.match(lua, /AUCTION_HOUSE_AUCTION_CREATED/);
	assert.match(lua, /ns\.L\.RECEIVE_LABEL/);
	assert.match(ru, /ns\.L\.CUT_LABEL = "Комиссия"/);
	assert.match(ru, /ns\.L\.RECEIVE_LABEL = "На руки"/);
	assert.match(fr, /GetLocale\(\) ~= "frFR"/);
	assert.match(fr, /ns\.L\.CUT_LABEL = "Commission"/);
	assert.match(fr, /ns\.L\.RECEIVE_LABEL = "Vous recevez"/);
	assert.match(de, /GetLocale\(\) ~= "deDE"/);
	assert.match(de, /ns\.L\.CUT_LABEL = "Provision"/);
	assert.match(de, /ns\.L\.RECEIVE_LABEL = "Ihr erhaltet"/);
	assert.match(esES, /GetLocale\(\) ~= "esES"/);
	assert.match(esES, /ns\.L\.CUT_LABEL = "Comisión"/);
	assert.match(esES, /ns\.L\.RECEIVE_LABEL = "Recibes"/);
	assert.match(esMX, /GetLocale\(\) ~= "esMX"/);
	assert.match(esMX, /ns\.L\.CUT_LABEL = "Comisión"/);
	assert.match(esMX, /ns\.L\.RECEIVE_LABEL = "Recibes"/);
	assert.match(ptBR, /GetLocale\(\) ~= "ptBR"/);
	assert.match(ptBR, /ns\.L\.CUT_LABEL = "Comissão"/);
	assert.match(ptBR, /ns\.L\.RECEIVE_LABEL = "Você recebe"/);
});

test("a hidden auction house does not refresh the sell frame", () => {
	const refresh = lua.slice(lua.indexOf("local function RefreshVisibleSellFrames"), lua.indexOf("local function OnEvent"));
	const schedule = lua.slice(lua.indexOf("local function ScheduleCut"), lua.indexOf("local function OnTotalPriceUpdated"));
	assert.match(refresh, /SellFrameVisible\(frame\)/);
	assert.match(schedule, /SellFrameVisible\(sellFrame\)/);
	assert.equal(refresh.includes("IsShown()"), false);
	assert.equal(schedule.includes("IsShown()"), false);
});
