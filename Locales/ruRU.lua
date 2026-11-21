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
ns.L.PRICE_REMEMBERED = "Последняя цена, которую вы ввели для этого предмета."
ns.L.PRICE_MULTIPLIER = "Цена торговцу × %s (%s)."
ns.L.TYPE_WEAPON = "Оружие"
ns.L.TYPE_ARMOR = "Доспехи"
ns.L.TYPE_CONSUMABLE = "Расходники"
ns.L.TYPE_REAGENT = "Реагенты"
ns.L.TYPE_RECIPE = "Рецепты"
ns.L.TYPE_BAG = "Сумки"
ns.L.TYPE_OTHER = "Прочее"
ns.L.OPTIONS_UNAVAILABLE = "Не удалось открыть настройки цены аукциона."
ns.L.MULTIPLIER_HEADING = "Множитель цены торговцу. 2 — двойная цена."
ns.L.MULTIPLIER_TOOLTIP = "Берётся, когда у предмета нет цены аукциона и нет введённой вами цены."
