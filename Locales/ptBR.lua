local _, ns = ...

if GetLocale() ~= "ptBR" then
	return
end

-- Same column as Depósito. "Comissão" is the sale cut, not the listing deposit.
ns.L.CUT_LABEL = "Comissão"
-- Replaces the Preço total label. This is the gold left after the cut.
ns.L.RECEIVE_LABEL = "Você recebe"
ns.L.PRICE_BLIZZARD = "Mínimo da casa de leilões."
ns.L.PRICE_EXACT = "Menor preço deste afixo."
ns.L.PRICE_REMEMBERED = "Último preço que você digitou para este item."
ns.L.PRICE_MULTIPLIER = "Preço do comerciante × %s (%s)."
ns.L.TYPE_WEAPON = "Armas"
ns.L.TYPE_ARMOR = "Armadura"
ns.L.TYPE_CONSUMABLE = "Consumíveis"
ns.L.TYPE_REAGENT = "Reagentes"
ns.L.TYPE_RECIPE = "Receitas"
ns.L.TYPE_BAG = "Bolsas"
ns.L.TYPE_OTHER = "Outros"
ns.L.OPTIONS_UNAVAILABLE = "Não foi possível registrar as opções de preço."
ns.L.MULTIPLIER_HEADING = "Multiplicador do preço do comerciante. 2 é o dobro."
ns.L.MULTIPLIER_TOOLTIP = "Usado quando o item não tem preço de leilão nem um preço que você digitou."
