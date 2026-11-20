const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const addonRoot = path.join(__dirname, "..");
const lua = fs.readFileSync(path.join(addonRoot, "Core.lua"), "utf8");
const toc = fs.readFileSync(path.join(addonRoot, "tabu-auc-ext.toc"), "utf8");
const ru = fs.readFileSync(path.join(addonRoot, "Locales", "ruRU.lua"), "utf8");

const NEUTRAL_PERCENT = 15;
const FACTION_PERCENT = 5;

function commissionRate(factionGroup) {
	if (factionGroup === "Neutral") {
		return NEUTRAL_PERCENT;
	}
	if (factionGroup === "Alliance" || factionGroup === "Horde") {
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

test("addon identity and Forever TOC", () => {
	assert.equal(path.basename(addonRoot), "tabu-auc-ext");
	assert.match(toc, /^## Interface: 16001/m);
	assert.match(toc, /^## Title: tabu-auc-ext/m);
	assert.match(toc, /^Locales\\Base\.lua$/m);
	assert.match(toc, /^Locales\\ruRU\.lua$/m);
	assert.match(toc, /^Core\.lua$/m);
	assert.equal(toc.includes("SavedVariables"), false);
	assert.match(toc, /^## Notes: /m);
	assert.match(toc, /^## Notes-ruRU: /m);
});

test("neutral auctioneer is 15 percent and faction auctioneer is 5", () => {
	assert.equal(commissionRate("Neutral"), 15);
	assert.equal(commissionRate("Alliance"), 5);
	assert.equal(commissionRate("Horde"), 5);
	assert.equal(commissionRate(null), null);
	assert.equal(commissionRate(undefined), null);
	assert.equal(commissionRate(""), null);
	assert.match(lua, /local NEUTRAL_FACTION = "Neutral"/);
	assert.match(lua, /local FACTION_PERCENT = 5/);
	assert.match(lua, /local NEUTRAL_PERCENT = 15/);
	assert.match(lua, /UnitFactionGroup\("npc"\)/);
	assert.match(lua, /issecretvalue\(faction\)/);
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
	assert.match(lua, /layoutIndex = CUT_LAYOUT_INDEX/);
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
	assert.match(lua, /totalPrice:SetAmount\(receive\)/);
	assert.match(lua, /delta:SetAmount\(deltaAmount\)/);
	assert.match(lua, /totalPrice:SetLabelColor\(color or NORMAL_FONT_COLOR\)/);
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
	assert.match(lua, /totalPrice:SetLabel\(ns\.L\.RECEIVE_LABEL\)/);
	assert.match(ru, /ns\.L\.CUT_LABEL = "Комиссия"/);
	assert.match(ru, /ns\.L\.RECEIVE_LABEL = "На руки"/);
});
