# tabu-auc-ext

## 1.3.0

- A listing of this affix is purple. The cheapest listing of the same item, when this affix is absent, is blue. Vendor times 1.5 is red.
- Item tooltips can show a unit vendor price, drawn like Sell Price, when the stack is larger than one. The option is off until turned on in the tabu-auc-ext category.
- An item with no listings at all takes the auction house's suggested price: vendor price times 1.5, rounded up to the next silver. The digits are red, and the tooltip says the item is not listed.
- The multiplier options and remembered prices are gone.

## 1.2.1

- Using an item outside the auction house no longer reports an addon error. The sell price updates only while the auction window is open.

## 1.2.0

- Gear with an affix is priced from that affix. A Nobles Brand of the Sorcerer takes the cheapest Sorcerer listing, not the cheapest Nobles Brand of any other suffix.
- The unit-price digits show where the number came from. Blue is the lowest buyout for this affix. White is the auction house minimum. Purple is the last price you typed for this item. Orange is the vendor price times your multiplier. Hover the digits for the same note.
- A price is remembered only after you change the field yourself and the auction is created.
- Options, category tabu-auc-ext, sets that multiplier for weapons, armor, consumables, reagents, recipes, bags, and everything else. The default is 2, twice the vendor price. Type the number or use the slider. Herbs, cloth, and ore count as reagents.

## 1.1.1

- Goblin and other neutral auctioneers show the house cut and the amount you receive. The cut at those houses is 15%.

## 1.1.0

- The auction total stays the auction total. House cut and the amount you receive are separate rows under it, and the vendor comparison stays beside the amount you receive.
- French, German, Spanish, and Portuguese labels are included.
- The buyout checkbox stays in the bottom-left corner of the sell frame, and the post button stays in the bottom-right. Choosing an item no longer moves them.
- When the vendor difference is at least 1 gold, only the gold is shown, so the row stays inside the frame. Hover the difference for the exact amount.
