local _, ns = ...

if GetLocale() ~= "esES" then
	return
end

-- Same column as Depósito. "Comisión" is the sale cut, not the listing deposit.
ns.L.CUT_LABEL = "Comisión"
-- Replaces the Precio total label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "Recibes"
