local _, ns = ...

if GetLocale() ~= "deDE" then
	return
end

-- Same column as Anzahlung. "Provision" is the sale cut, not the listing deposit.
ns.L.CUT_LABEL = "Provision"
-- Replaces the Gesamtpreis label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "Ihr erhaltet"
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
