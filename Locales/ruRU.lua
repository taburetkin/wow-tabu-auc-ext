local _, ns = ...

if GetLocale() ~= "ruRU" then
	return
end

-- Same column as Deposit. "Комиссия" is the sale cut, not the listing deposit.
ns.L.CUT_LABEL = "Комиссия"
-- Replaces the Total Price label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "На руки"
