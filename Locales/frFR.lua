local _, ns = ...

if GetLocale() ~= "frFR" then
	return
end

-- Same column as Dépôt. "Commission" is the sale cut, not the listing deposit.
ns.L.CUT_LABEL = "Commission"
-- Replaces the Prix total label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "Vous recevez"
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
ns.L.MULTIPLIER_HEADING = "Multiplicateur du prix marchand. 2 = le double."
ns.L.MULTIPLIER_TOOLTIP = "Utilisé quand l'objet n'a ni prix d'enchère ni prix saisi par vous."
