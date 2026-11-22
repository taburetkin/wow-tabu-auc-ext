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
ns.L.PRICE_TYPE = "Keine Angebote für diese Eigenschaft, daher ist dies der Standardmindestpreis für diesen Gegenstand."
ns.L.PRICE_SUGGESTED = "Dieser Gegenstand ist nicht gelistet. Das Auktionshaus schlägt sein eigenes Minimum vor."
ns.L.UNIT_PRICE = "Stückpreis"
ns.L.UNIT_PRICE_OPTION = "Stückpreis im Tooltip"
ns.L.UNIT_PRICE_OPTION_TIP = "Wenn ein Stapel mehr als einen Gegenstand enthält, den Händlerpreis für einen Gegenstand anzeigen, wie den Verkaufspreis."
ns.L.OPTIONS_UNAVAILABLE = "Die Stückpreis-Einstellung konnte nicht registriert werden."
