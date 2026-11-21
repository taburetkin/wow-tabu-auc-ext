local _, ns = ...

if GetLocale() ~= "deDE" then
	return
end

-- Same column as Anzahlung. "Provision" is the sale cut, not the listing deposit.
ns.L.CUT_LABEL = "Provision"
-- Replaces the Gesamtpreis label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "Ihr erhaltet"
