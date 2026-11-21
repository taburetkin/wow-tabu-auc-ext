local _, ns = ...

if GetLocale() ~= "ptBR" then
	return
end

-- Same column as Depósito. "Comissão" is the sale cut, not the listing deposit.
ns.L.CUT_LABEL = "Comissão"
-- Replaces the Preço total label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "Você recebe"
