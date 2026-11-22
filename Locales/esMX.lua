local _, ns = ...

if GetLocale() ~= "esMX" then
	return
end

-- Same column as Depósito. "Comisión" is the sale cut, not the listing deposit.
-- These two labels match esES; the wording is the same in both Spanish clients.
ns.L.CUT_LABEL = "Comisión"
-- Replaces the Precio total label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "Recibes"
ns.L.PRICE_BLIZZARD = "Mínimo de la casa de subastas."
ns.L.PRICE_EXACT = "Precio más bajo de este afijo."
ns.L.PRICE_TYPE = "No hay subastas de este afijo, así que este es el mínimo predeterminado de este objeto."
ns.L.PRICE_SUGGESTED = "Este objeto no está a la venta. La casa de subastas propone su propio mínimo."
ns.L.UNIT_PRICE = "Precio por unidad"
ns.L.UNIT_PRICE_OPTION = "Precio por unidad en la descripción"
ns.L.UNIT_PRICE_OPTION_TIP = "Si la pila tiene más de un objeto, mostrar el precio del vendedor de uno solo, igual que el precio de venta."
ns.L.OPTIONS_UNAVAILABLE = "No se pudo registrar el ajuste del precio por unidad."
