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
ns.L.PRICE_TYPE = "Aucune annonce pour ce suffixe, donc ceci est le minimum par défaut de cet objet."
ns.L.PRICE_SUGGESTED = "Cet objet n'est pas en vente. L'hôtel des ventes propose son propre minimum."
ns.L.UNIT_PRICE = "Prix unitaire"
ns.L.UNIT_PRICE_OPTION = "Prix unitaire dans l'infobulle"
ns.L.UNIT_PRICE_OPTION_TIP = "Si la pile contient plus d'un objet, afficher le prix marchand d'un seul objet, comme le prix de vente."
ns.L.OPTIONS_UNAVAILABLE = "Impossible d'enregistrer le réglage du prix unitaire."
