local _, ns = ...

if GetLocale() ~= "frFR" then
	return
end

-- Same column as Dépôt. "Commission" is the sale cut, not the listing deposit.
ns.L.CUT_LABEL = "Commission"
-- Replaces the Prix total label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "Vous recevez"
