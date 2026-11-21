local _, ns = ...

if GetLocale() ~= "esES" then
	return
end

-- Same column as Depósito. "Comisión" is the sale cut, not the listing deposit.
ns.L.CUT_LABEL = "Comisión"
-- Replaces the Precio total label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "Recibes"
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
ns.L.MULTIPLIER_HEADING = "Multiplicador del precio al vendedor. 2 es el doble."
ns.L.MULTIPLIER_TOOLTIP = "Se usa cuando el objeto no tiene precio de subasta ni un precio que hayas escrito."
