# Affix sell price Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On the sell tab, price equipment from an exact auction query for that affix, and price everything else from Blizzard, then a hand-entered memory, then vendor price times a per-type multiplier.

**Architecture:** `Price.lua` holds the pure decision, buyout minimum, vendor fallback, item-class bucket, memory key, and multiplier text. `Settings.lua` owns the account SavedVariables and the native settings category. `SellPrice.lua` queries, paints the unit-price field, and records a price only after a manual edit followed by a successful post. `Core.lua` keeps the cut and payout math and reads whatever unit price is already in the field.

**Tech Stack:** WoW Forever 1.60.1 Lua 5.1, Interface 16001, node:test mirroring the pure Lua, native `Settings` sliders.

## Global Constraints

- Forever, Interface 16001. Source pin `9dc84f0d3bbae1768ac3405b3716000bd93eda06`.
- Non-equipment order: Blizzard price, else remembered price, else `floor(vendor × multiplier)`.
- Equipment order: exact query using `itemID`, `itemLevel`, and `itemSuffix` before Blizzard zeroes them; else remembered price; else `floor(vendor × multiplier)`.
- The sell list for equipment shows that exact query.
- Do not choose a price while the search that branch needs is unfinished.
- A positive Blizzard price is the price the sell frame would have filled. No listings or no positive buyout means there is no Blizzard price.
- Equipment minimum is the lowest positive `buyoutAmount`. Rows without a buyout do not count. The search is complete when `HasFullItemSearchResults` is true for that key.
- Do not replace a price the player has typed while the same item stays in the slot. Changing the item clears that lock.
- Fallback copper is `floor(vendor × multiplier)`. Unknown vendor price waits. Vendor price 0 produces 0.
- Colors on the unit-price digits only: Blizzard white, exact blue, remembered purple, multiplier orange. Cut and payout keep green and red.
- Tooltips, enUS: `Auction house minimum.` / `Lowest price for this affix.` / `Last price you entered for this item.` / `Vendor price × %s (%s).`
- Tooltips, ruRU: `Минимум аукциона.` / `Минимальная цена этого аффикса.` / `Последняя цена, которую вы ввели для этого предмета.` / `Цена торговцу × %s (%s).`
- Orange tooltip multiplier text has no trailing `.0` (`2`, not `2.0`). The type name is localized.
- Remember the unit price only when the player edited the field after the last programmatic fill and the auction is then created. Capture it before the slot is cleared. Key is `itemID` and `itemSuffix` (`0` when there is no affix).
- Seven sliders in one native category registered once: weapon, armor, consumable, reagent (`Reagent` and `Tradegoods`), recipe, bag (`Container`), other. Min 0, max 100, step 0.1, default 2.
- Category title stays `tabu-auc-ext` in every locale. Setting variable names stay English.
- Account-wide `SavedVariables`. A stored `false` is kept. A missing or out-of-range multiplier becomes 2.
- Commission, payout, vendor delta, 5% and 15% house cut, and the pinned post button and buyout checkbox do not change formula or layout.
- Tests live in `test/` and mirror the source file name: `Price.lua` → `test/Price.test.js`.

---

### Task 1: Choose the sell price

**Files:**
- Create: `D:\dev\wow\forever\tabu-auc-ext\Price.lua`
- Create: `D:\dev\wow\forever\tabu-auc-ext\test\Price.test.js`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\tabu-auc-ext.toc`

**Interfaces:**
- Consumes: nothing
- Produces: `ns.Price.BLIZZARD`, `ns.Price.EXACT`, `ns.Price.REMEMBERED`, `ns.Price.MULTIPLIER`, `ns.Price.Choose(query) -> { amount: number, source: string } | nil`, `ns.Price.MinimumBuyout(amounts) -> number | nil`, `ns.Price.FallbackCopper(vendorPrice, multiplier) -> number | nil`

`query` fields: `equipment` boolean, `searchReady` boolean, `blizzardPrice`, `exactPrice`, `rememberedPrice`, `vendorPrice` (number or nil), `multiplier` number.

- [ ] **Step 1: Write the failing test**

Create `test/Price.test.js`:

```js
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run from `D:\dev\wow\forever\tabu-auc-ext`: `node --test test/Price.test.js`

Expected: FAIL because `Price.lua` does not exist.

- [ ] **Step 3: Write the minimal implementation**

Create `Price.lua`:

```lua
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
```

Insert `Price.lua` in `tabu-auc-ext.toc` after the locale files and before `Core.lua`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `node --test test/Price.test.js`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Price.lua test/Price.test.js tabu-auc-ext.toc
git commit -m "Choose the sell price from the affix, memory, or vendor multiplier."
```

### Task 2: Item type, memory key, multiplier text

**Files:**
- Modify: `D:\dev\wow\forever\tabu-auc-ext\Price.lua`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\test\Price.test.js`

**Interfaces:**
- Consumes: `ns.Price` from Task 1
- Produces: `ns.Price.MultiplierKey(classID) -> string`, `ns.Price.MemoryKey(itemID, itemSuffix) -> string | nil`, `ns.Price.FormatMultiplier(value) -> string`, `ns.Price.ShouldRemember(userEdited) -> boolean`

Class ids from `Enum.ItemClass` at the pinned commit: Consumable 0, Container 1, Weapon 2, Armor 4, Reagent 5, Tradegoods 7, Recipe 9. Every other id, including nil, is `other`.

- [ ] **Step 1: Write the failing test**

Append to `test/Price.test.js`:

```js
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
	assert.match(lua, /function ns\.Price\.MultiplierKey\(classID\)/);
	assert.match(lua, /function ns\.Price\.MemoryKey\(itemID, itemSuffix\)/);
	assert.match(lua, /function ns\.Price\.FormatMultiplier\(value\)/);
	assert.match(lua, /function ns\.Price\.ShouldRemember\(userEdited\)/);
	assert.match(lua, /classID == 7/);
});
```

Reload `lua` inside the test file after implementation. The existing top-level `fs.readFileSync` runs before the file exists in Task 1 and after it exists here; move that read into each test that matches source, or re-read at the start of this test:

```js
const priceLua = fs.readFileSync(path.join(__dirname, "..", "Price.lua"), "utf8");
```

Use `priceLua` in the new assertions instead of the outer `lua` if the outer read is stale. Node loads the file once per process, so reading inside the test is the one that sees the edit.

- [ ] **Step 2: Run the test to verify it fails**

Run: `node --test test/Price.test.js`

Expected: FAIL on `function ns.Price.MultiplierKey` missing.

- [ ] **Step 3: Write the minimal implementation**

Append to `Price.lua`:

```lua
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
	if classID == CLASS_REAGENT or classID == CLASS_TRADEGOODS then
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
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `node --test test/Price.test.js`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Price.lua test/Price.test.js
git commit -m "Map item class and affix onto the saved price key."
```

### Task 3: Price and setting strings

**Files:**
- Modify: `D:\dev\wow\forever\tabu-auc-ext\Locales\Base.lua`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\Locales\ruRU.lua`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\Locales\frFR.lua`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\Locales\deDE.lua`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\Locales\esES.lua`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\Locales\esMX.lua`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\Locales\ptBR.lua`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\test\Price.test.js`

**Interfaces:**
- Consumes: `ns.L`
- Produces: `ns.L.PRICE_BLIZZARD`, `ns.L.PRICE_EXACT`, `ns.L.PRICE_REMEMBERED`, `ns.L.PRICE_MULTIPLIER`, `ns.L.TYPE_WEAPON`, `ns.L.TYPE_ARMOR`, `ns.L.TYPE_CONSUMABLE`, `ns.L.TYPE_REAGENT`, `ns.L.TYPE_RECIPE`, `ns.L.TYPE_BAG`, `ns.L.TYPE_OTHER`, `ns.L.OPTIONS_UNAVAILABLE`, `ns.L.MULTIPLIER_TOOLTIP`

- [ ] **Step 1: Write the failing test**

Append:

```js
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
	assert.match(ru, /PRICE_BLIZZARD = "Минимум аукциона\."/);
	assert.match(ru, /PRICE_EXACT = "Минимальная цена этого аффикса\."/);
	assert.match(ru, /PRICE_REMEMBERED = "Последняя цена, которую вы ввели для этого предмета\."/);
	assert.match(ru, /PRICE_MULTIPLIER = "Цена торговцу × %s \(%s\)\."/);
	assert.match(ru, /TYPE_WEAPON = "Оружие"/);
	assert.match(ru, /TYPE_REAGENT = "Реагенты"/);
	assert.match(ru, /TYPE_OTHER = "Прочее"/);
	for (const file of [fr, de, es, mx, pt]) {
		assert.match(file, /PRICE_BLIZZARD = "/);
		assert.match(file, /TYPE_WEAPON = "/);
		assert.match(file, /TYPE_OTHER = "/);
	}
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node --test test/Price.test.js`

Expected: FAIL on `PRICE_BLIZZARD` missing.

- [ ] **Step 3: Write the strings**

Add to `Locales/Base.lua` inside `ns.L`:

```lua
	PRICE_BLIZZARD = "Auction house minimum.",
	PRICE_EXACT = "Lowest price for this affix.",
	PRICE_REMEMBERED = "Last price you entered for this item.",
	PRICE_MULTIPLIER = "Vendor price × %s (%s).",
	TYPE_WEAPON = "Weapons",
	TYPE_ARMOR = "Armor",
	TYPE_CONSUMABLE = "Consumables",
	TYPE_REAGENT = "Reagents",
	TYPE_RECIPE = "Recipes",
	TYPE_BAG = "Bags",
	TYPE_OTHER = "Other",
	OPTIONS_UNAVAILABLE = "Auction price settings could not be registered.",
	MULTIPLIER_TOOLTIP = "Used when this item has no auction price and no price you entered.",
```

Add to `Locales/ruRU.lua` before the file ends:

```lua
ns.L.PRICE_BLIZZARD = "Минимум аукциона."
ns.L.PRICE_EXACT = "Минимальная цена этого аффикса."
ns.L.PRICE_REMEMBERED = "Последняя цена, которую вы ввели для этого предмета."
ns.L.PRICE_MULTIPLIER = "Цена торговцу × %s (%s)."
ns.L.TYPE_WEAPON = "Оружие"
ns.L.TYPE_ARMOR = "Доспехи"
ns.L.TYPE_CONSUMABLE = "Расходники"
ns.L.TYPE_REAGENT = "Реагенты"
ns.L.TYPE_RECIPE = "Рецепты"
ns.L.TYPE_BAG = "Сумки"
ns.L.TYPE_OTHER = "Прочее"
ns.L.OPTIONS_UNAVAILABLE = "Не удалось открыть настройки цены аукциона."
ns.L.MULTIPLIER_TOOLTIP = "Берётся, когда у предмета нет цены аукциона и нет введённой вами цены."
```

Add the same keys in the other locale files:

```lua
-- frFR
ns.L.PRICE_BLIZZARD = "Minimum de l'hôtel des ventes."
ns.L.PRICE_EXACT = "Prix le plus bas pour ce suffixe."
ns.L.PRICE_REMEMBERED = "Dernier prix que vous avez saisi pour cet objet."
ns.L.PRICE_MULTIPLIER = "Prix du marchand × %s (%s)."
ns.L.TYPE_WEAPON = "Armes"
ns.L.TYPE_ARMOR = "Armure"
ns.L.TYPE_CONSUMABLE = "Consommables"
ns.L.TYPE_REAGENT = "Composants"
ns.L.TYPE_RECIPE = "Recettes"
ns.L.TYPE_BAG = "Sacs"
ns.L.TYPE_OTHER = "Autre"
ns.L.OPTIONS_UNAVAILABLE = "Impossible d'enregistrer les paramètres de prix."
ns.L.MULTIPLIER_TOOLTIP = "Utilisé quand l'objet n'a ni prix d'enchère ni prix saisi par vous."

-- deDE
ns.L.PRICE_BLIZZARD = "Minimum des Auktionshauses."
ns.L.PRICE_EXACT = "Niedrigster Preis für diese Eigenschaft."
ns.L.PRICE_REMEMBERED = "Letzter Preis, den Ihr für diesen Gegenstand eingegeben habt."
ns.L.PRICE_MULTIPLIER = "Händlerpreis × %s (%s)."
ns.L.TYPE_WEAPON = "Waffen"
ns.L.TYPE_ARMOR = "Rüstung"
ns.L.TYPE_CONSUMABLE = "Verbrauchbares"
ns.L.TYPE_REAGENT = "Reagenzien"
ns.L.TYPE_RECIPE = "Rezepte"
ns.L.TYPE_BAG = "Taschen"
ns.L.TYPE_OTHER = "Sonstiges"
ns.L.OPTIONS_UNAVAILABLE = "Preiseinstellungen konnten nicht registriert werden."
ns.L.MULTIPLIER_TOOLTIP = "Gilt, wenn der Gegenstand keinen Auktionspreis und keinen von Euch eingegebenen Preis hat."

-- esES and esMX, same strings in each file
ns.L.PRICE_BLIZZARD = "Mínimo de la casa de subastas."
ns.L.PRICE_EXACT = "Precio más bajo de este afijo."
ns.L.PRICE_REMEMBERED = "Último precio que introdujiste para este objeto."
ns.L.PRICE_MULTIPLIER = "Precio del vendedor × %s (%s)."
ns.L.TYPE_WEAPON = "Armas"
ns.L.TYPE_ARMOR = "Armadura"
ns.L.TYPE_CONSUMABLE = "Consumibles"
ns.L.TYPE_REAGENT = "Componentes"
ns.L.TYPE_RECIPE = "Recetas"
ns.L.TYPE_BAG = "Bolsas"
ns.L.TYPE_OTHER = "Otros"
ns.L.OPTIONS_UNAVAILABLE = "No se pudieron registrar los ajustes de precio."
ns.L.MULTIPLIER_TOOLTIP = "Se usa cuando el objeto no tiene precio de subasta ni un precio que hayas escrito."

-- ptBR
ns.L.PRICE_BLIZZARD = "Mínimo da casa de leilões."
ns.L.PRICE_EXACT = "Menor preço deste afixo."
ns.L.PRICE_REMEMBERED = "Último preço que você digitou para este item."
ns.L.PRICE_MULTIPLIER = "Preço do comerciante × %s (%s)."
ns.L.TYPE_WEAPON = "Armas"
ns.L.TYPE_ARMOR = "Armadura"
ns.L.TYPE_CONSUMABLE = "Consumíveis"
ns.L.TYPE_REAGENT = "Reagentes"
ns.L.TYPE_RECIPE = "Receitas"
ns.L.TYPE_BAG = "Bolsas"
ns.L.TYPE_OTHER = "Outros"
ns.L.OPTIONS_UNAVAILABLE = "Não foi possível registrar as opções de preço."
ns.L.MULTIPLIER_TOOLTIP = "Usado quando o item não tem preço de leilão nem um preço que você digitou."
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `node --test test/Price.test.js`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Locales test/Price.test.js
git commit -m "Name each sell-price source and item-type multiplier."
```

### Task 4: Account multipliers in the native settings category

**Files:**
- Create: `D:\dev\wow\forever\tabu-auc-ext\Settings.lua`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\tabu-auc-ext.toc`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\test\Price.test.js`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\docs\requirements.md` (REQ-006 becomes the seven multipliers; drop "настроек нет")

**Interfaces:**
- Consumes: `ns.L.TYPE_*`, `ns.L.OPTIONS_UNAVAILABLE`, `ns.L.MULTIPLIER_TOOLTIP`, `ns.Price.MultiplierKey`
- Produces: global `TabuAucExtDB = { multipliers = { weapon = 2, ... }, prices = {} }`, `ns.Settings.Multiplier(classID) -> number`, `ns.Settings.Remembered(itemID, itemSuffix) -> number | nil`, `ns.Settings.Remember(itemID, itemSuffix, amount, userEdited)`

- [ ] **Step 1: Write the failing test**

Append assertions that read `Settings.lua` and the toc:

```js
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
	assert.match(settings, /function ns\.Settings\.Multiplier\(classID\)/);
	assert.match(settings, /function ns\.Settings\.Remembered\(itemID, itemSuffix\)/);
	assert.match(settings, /function ns\.Settings\.Remember\(itemID, itemSuffix, amount\)/);
	assert.match(settings, /ns\.Price\.ShouldRemember\(userEdited\)/);
	assert.equal(settings.includes("RegisterVerticalLayoutCategory"), true);
	const registrations = settings.match(/RegisterAddOnCategory/g);
	assert.equal(registrations.length, 1);
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node --test test/Price.test.js`

Expected: FAIL because `Settings.lua` does not exist.

- [ ] **Step 3: Write the minimal implementation**

Add `## SavedVariables: TabuAucExtDB` under the Version line in the toc. Load `Settings.lua` after `Price.lua` and before `Core.lua`.

Create `Settings.lua`:

```lua
local addonName, ns = ...

ns.Settings = {}

local DEFAULT_MULTIPLIER = 2
local MULTIPLIER_MIN = 0
local MULTIPLIER_MAX = 100

local KEYS = { "weapon", "armor", "consumable", "reagent", "recipe", "bag", "other" }

local LABEL = {
	weapon = "TYPE_WEAPON",
	armor = "TYPE_ARMOR",
	consumable = "TYPE_CONSUMABLE",
	reagent = "TYPE_REAGENT",
	recipe = "TYPE_RECIPE",
	bag = "TYPE_BAG",
	other = "TYPE_OTHER",
}

local function InRange(value)
	return type(value) == "number" and value >= MULTIPLIER_MIN and value <= MULTIPLIER_MAX
end

local function EnsureDB()
	if type(TabuAucExtDB) ~= "table" then
		TabuAucExtDB = {}
	end
	if type(TabuAucExtDB.multipliers) ~= "table" then
		TabuAucExtDB.multipliers = {}
	end
	if type(TabuAucExtDB.prices) ~= "table" then
		TabuAucExtDB.prices = {}
	end
	for index = 1, #KEYS do
		local key = KEYS[index]
		local value = TabuAucExtDB.multipliers[key]
		if value ~= false and not InRange(value) then
			TabuAucExtDB.multipliers[key] = DEFAULT_MULTIPLIER
		end
	end
end

function ns.Settings.Multiplier(classID)
	EnsureDB()
	local key = ns.Price.MultiplierKey(classID)
	local value = TabuAucExtDB.multipliers[key]
	if not InRange(value) then
		return DEFAULT_MULTIPLIER
	end
	return value
end

function ns.Settings.Remembered(itemID, itemSuffix)
	EnsureDB()
	local key = ns.Price.MemoryKey(itemID, itemSuffix)
	if key == nil then
		return nil
	end
	local amount = TabuAucExtDB.prices[key]
	if type(amount) ~= "number" or amount < 0 then
		return nil
	end
	return amount
end

function ns.Settings.Remember(itemID, itemSuffix, amount, userEdited)
	if not ns.Price.ShouldRemember(userEdited) then
		return
	end
	if type(amount) ~= "number" or amount < 0 then
		return
	end
	EnsureDB()
	local key = ns.Price.MemoryKey(itemID, itemSuffix)
	if key == nil then
		return
	end
	TabuAucExtDB.prices[key] = amount
end

local function RegisterSliders(category)
	for index = 1, #KEYS do
		local key = KEYS[index]
		local setting = Settings.RegisterAddOnSetting(
			category,
			addonName .. "_" .. key,
			key,
			TabuAucExtDB.multipliers,
			Settings.VarType.Number,
			ns.L[LABEL[key]],
			DEFAULT_MULTIPLIER
		)
		local options = Settings.CreateSliderOptions(MULTIPLIER_MIN, MULTIPLIER_MAX, 0.1)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
			return ns.Price.FormatMultiplier(value)
		end)
		Settings.CreateSlider(category, setting, options, ns.L.MULTIPLIER_TOOLTIP)
	end
end

local function RegisterCategory()
	if ns.Settings.CategoryRegistered then
		return
	end
	if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting and Settings.CreateSlider and Settings.RegisterAddOnCategory) then
		print(ns.L.OPTIONS_UNAVAILABLE)
		return
	end
	ns.Settings.CategoryRegistered = true
	local category = Settings.RegisterVerticalLayoutCategory("tabu-auc-ext")
	RegisterSliders(category)
	Settings.RegisterAddOnCategory(category)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, loadedName)
	if loadedName ~= addonName then
		return
	end
	EnsureDB()
	RegisterCategory()
end)

```

- [ ] **Step 4: Run the test to verify it passes**

Run: `node --test test/Price.test.js`

Expected: PASS. Also run `node --test test/Core.test.js` and expect PASS. The Core toc assertion does not forbid `SavedVariables`; it only checks that the old file list remains. If it asserts the toc equals an exact file list, update that assertion to require `Price.lua` and `Settings.lua` in addition to `Core.lua`.

- [ ] **Step 5: Commit**

```bash
git add Settings.lua tabu-auc-ext.toc test/Price.test.js test/Core.test.js docs/requirements.md
git commit -m "Store per-type vendor multipliers in the addon settings."
```

In `docs/requirements.md`, replace REQ-006 with: seven multipliers in the native addon category, default 2, account `TabuAucExtDB`. Remove the sentence "Настроек нет" from the scope line.

### Task 5: Paint the sell price and remember a manual post

**Files:**
- Create: `D:\dev\wow\forever\tabu-auc-ext\SellPrice.lua`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\tabu-auc-ext.toc`
- Modify: `D:\dev\wow\forever\tabu-auc-ext\test\Price.test.js`

**Interfaces:**
- Consumes: `ns.Price.Choose`, `ns.Price.MinimumBuyout`, `ns.Price.MemoryKey`, `ns.Settings.Multiplier`, `ns.Settings.Remembered`, `ns.Settings.Remember`, `ns.L.PRICE_*`, `ns.L.TYPE_*`
- Produces: sell-frame behavior only. No new public function is required.

- [ ] **Step 1: Write the failing test**

Append source assertions:

```js
test("sell frame queries the real equipment key and colors the price", () => {
	const root = path.join(__dirname, "..");
	const sell = fs.readFileSync(path.join(root, "SellPrice.lua"), "utf8");
	const toc = fs.readFileSync(path.join(root, "tabu-auc-ext.toc"), "utf8");
	assert.match(toc, /SellPrice\.lua/);
	assert.match(sell, /C_AuctionHouse\.MakeItemKey\(fresh\.itemID, fresh\.itemLevel, fresh\.itemSuffix, fresh\.battlePetSpeciesID\)/);
	assert.match(sell, /QueryItem\(sellFrame:GetSearchContext\(\), exactKey, true\)/);
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node --test test/Price.test.js`

Expected: FAIL because `SellPrice.lua` does not exist.

- [ ] **Step 3: Write the sell-frame behavior**

Load `SellPrice.lua` after `Settings.lua` and before `Core.lua`.

`GetItemInfoInstant` at this client returns `classID` as the 6th value. Use that. Equipment is class 2 or 4.

Color digits by walking `PriceInput.GoldDisplay`, `SilverDisplay`, and `CopperDisplay` the same way `Core.lua` walks a money display, and also `GoldBox`, `SilverBox`, and `CopperBox` when those edit boxes exist. White means `SetTextColor(1, 1, 1)`. Blue is `0.2, 0.6, 1`. Purple is `0.64, 0.21, 0.93`. Orange is `1, 0.5, 0`.

Tooltip text:

```lua
local function TooltipText(choice, classID)
	if choice.source == ns.Price.BLIZZARD then
		return ns.L.PRICE_BLIZZARD
	end
	if choice.source == ns.Price.EXACT then
		return ns.L.PRICE_EXACT
	end
	if choice.source == ns.Price.REMEMBERED then
		return ns.L.PRICE_REMEMBERED
	end
	local typeKey = ns.Price.MultiplierKey(classID)
	local typeLabel = ns.L["TYPE_" .. string.upper(typeKey)]
	return string.format(ns.L.PRICE_MULTIPLIER, ns.Price.FormatMultiplier(ns.Settings.Multiplier(classID)), typeLabel)
end
```

`TYPE_WEAPON` matches `string.upper("weapon")`. Do that for all seven keys. Add `TYPE_` names exactly as in Task 3.

On `AuctionHouseFrame.ItemSellFrame:SetItem`, after the original call:

```lua
local itemLocation = sellFrame:GetItem() and sellFrame:GetItem():GetItemLocation() or nil
```

If the location is missing, stop. Read a fresh key with `C_AuctionHouse.GetItemKeyFromItem(itemLocation)`. If `select(6, C_Item.GetItemInfoInstant(fresh.itemID))` is not 2 or 4, stop. Build `exactKey` with `C_AuctionHouse.MakeItemKey(fresh.itemID, fresh.itemLevel, fresh.itemSuffix, fresh.battlePetSpeciesID)`. Assign `sellFrame.listDisplayedItemKey = exactKey` and call `sellFrame:GetAuctionHouseFrame():QueryItem(sellFrame:GetSearchContext(), exactKey, true)`.

Do this only when the frame's current `listDisplayedItemKey` is not already that exact key, so the hook does not query twice for the same item.

When `ITEM_SEARCH_RESULTS_UPDATED` fires, or the sell frame is shown:

- Same item and `TabuAucUserEdited` means do nothing.
- Equipment: `searchReady = C_AuctionHouse.HasFullItemSearchResults(exactKey)`. Collect `buyoutAmount` from `GetItemSearchResultInfo(exactKey, index)` for `1..GetNumItemSearchResults(exactKey)` into a plain array and pass it to `ns.Price.MinimumBuyout`. `exactPrice` is that minimum. `blizzardPrice` is nil.
- Non-equipment: `searchReady` is commodity `HasFullCommoditySearchResults(itemID)` when `GetPrice` is absent, otherwise `HasFullItemSearchResults` for the frame's `listDisplayedItemKey`. `blizzardPrice` is `sellFrame:GetUnitPrice()` when that value is greater than 0. `exactPrice` is nil.
- `rememberedPrice` comes from `ns.Settings.Remembered`. `multiplier` comes from `ns.Settings.Multiplier(classID)`. `vendorPrice` is the same vendor unit price `Core.lua` already reads with `select(11, C_Item.GetItemInfo(itemLink))`, and a nil info result means `vendorPrice` nil.
- `choice = ns.Price.Choose(query)`. Nil choice means return without writing the field.
- Set `PriceInput.TabuAucApplying = true`, call `PriceInput:SetAmount(choice.amount)`, then clear the flag. Set `sellFrame.TabuAucShownItem = memoryKey` and `sellFrame.TabuAucShownSource = choice.source`.
- Color the digits. Store the tooltip text on the input.

Changing `TabuAucShownItem` clears `TabuAucUserEdited`.

Watch user edits without treating Blizzard's own `SetAmount` as an edit:

```lua
local function WatchBox(editBox, sellFrame)
	if editBox == nil or editBox.TabuAucWatch then
		return
	end
	editBox.TabuAucWatch = true
	editBox:HookScript("OnTextChanged", function(_, userInput)
		if userInput and not sellFrame.PriceInput.TabuAucApplying then
			sellFrame.TabuAucUserEdited = true
		end
	end)
end
```

Watch `GoldBox`, `SilverBox`, and `CopperBox` on `PriceInput`.

Tooltip: `PriceInput:HookScript("OnEnter", ShowTooltip)` and `OnLeave` calls `GameTooltip_Hide`. `ShowTooltip` reads the stored text and does nothing when it is nil.

Remember on a successful post, before the slot is cleared:

```lua
sellFrame.PostButton:HookScript("PreClick", function()
	local item = sellFrame:GetItem()
	if item == nil or not item:IsValid() then
		sellFrame.TabuAucSnapshot = nil
		return
	end
	local key = C_AuctionHouse.GetItemKeyFromItem(item:GetItemLocation())
	sellFrame.TabuAucSnapshot = {
		itemID = key.itemID,
		itemSuffix = key.itemSuffix,
		amount = sellFrame:GetUnitPrice(),
		userEdited = sellFrame.TabuAucUserEdited == true,
	}
end)
```

On `AUCTION_HOUSE_AUCTION_CREATED`, if `sellFrame.TabuAucSnapshot` exists, call `ns.Settings.Remember(snapshot.itemID, snapshot.itemSuffix, snapshot.amount, snapshot.userEdited)` and clear the snapshot. Hook both `AuctionHouseFrame.ItemSellFrame` and `AuctionHouseFrame.CommoditiesSellFrame`. Register the event on the addon's existing listener pattern: a frame in `SellPrice.lua` is enough. Also run the first hook from `ADDON_LOADED` when `Blizzard_AuctionHouseUI` is already loaded, matching `Core.lua`.

A programmatic fill must not leave `TabuAucUserEdited` true from the previous item. Clear it when `TabuAucShownItem` changes.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `node --test test/Price.test.js test/Core.test.js`

Expected: PASS for both files.

- [ ] **Step 5: Commit**

```bash
git add SellPrice.lua tabu-auc-ext.toc test/Price.test.js
git commit -m "Price equipment from its affix and keep a hand-entered price."
```

## Self-review

- Spec coverage: Task 1 is the source order and unfinished search. Task 2 is class buckets, memory key, and the remember predicate. Task 3 is both tooltip languages and the seven labels. Task 4 is the native category, defaults, and account storage. Task 5 is the exact query, colors, tooltip, edit lock, and post snapshot.
- Placeholders: none. Slider bounds, class ids, colors, and strings are written out.
- Signatures: `Choose`, `MinimumBuyout`, `FallbackCopper`, `MultiplierKey`, `MemoryKey`, `FormatMultiplier`, `ShouldRemember`, `Settings.Multiplier`, `Settings.Remembered`, and `Settings.Remember` use the same names in Tasks 1 through 5.
