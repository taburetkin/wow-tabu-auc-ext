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
ns.L.PRICE_TYPE = "Não há anúncios deste afixo, então este é o mínimo padrão deste item."
ns.L.PRICE_SUGGESTED = "Este item não está à venda. A casa de leilões sugere o próprio mínimo."
ns.L.UNIT_PRICE = "Preço unitário"
ns.L.UNIT_PRICE_OPTION = "Preço unitário na dica"
ns.L.UNIT_PRICE_OPTION_TIP = "Se a pilha tiver mais de um item, mostrar o preço do comerciante de um item, como o preço de venda."
ns.L.OPTIONS_UNAVAILABLE = "Não foi possível registrar a opção de preço unitário."
