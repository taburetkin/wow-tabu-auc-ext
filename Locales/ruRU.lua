local _, ns = ...

if GetLocale() ~= "ruRU" then
	return
end

-- Same column as Deposit. "Комиссия" is the sale cut, not the listing deposit.
ns.L.CUT_LABEL = "Комиссия"
-- Replaces the Total Price label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "На руки"
ns.L.PRICE_BLIZZARD = "Минимум аукциона."
ns.L.PRICE_EXACT = "Минимальная цена этого аффикса."
ns.L.PRICE_TYPE = "Лотов этого аффикса нет, поэтому это минимум по умолчанию для этого предмета."
ns.L.PRICE_SUGGESTED = "Этого предмета нет в продаже. Аукцион подставляет свой минимум."
ns.L.UNIT_PRICE = "Цена за штуку"
ns.L.UNIT_PRICE_OPTION = "Цена за штуку в подсказке"
ns.L.UNIT_PRICE_OPTION_TIP = "Если в стопке больше одной штуки, показать цену торговцу за одну штуку так же, как цену продажи."
ns.L.OPTIONS_UNAVAILABLE = "Не удалось открыть настройку цены за штуку."
