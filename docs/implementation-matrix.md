# tabu-auc-ext implementation matrix

- Updated: 2026-11-21
- Requirements: `docs/requirements.md`

| Slice | REQ | Files | Status | Validation |
|---|---|---|---|---|
| Строка комиссии 5% / 15% от количества × цены | REQ-001 … REQ-007 | `Core.lua` | implemented | Хук перенесён на `ItemSellFrame` и `CommoditiesSellFrame`. `node --test test/Core.test.js`. В клиенте после правки не запускалось. |
| Французские подписи | REQ-007 | `Locales/frFR.lua`, `tabu-auc-ext.toc` | implemented | `node --test test/Core.test.js`. В клиенте frFR не запускалось. Перевод черновой. |
| Немецкие подписи | REQ-007 | `Locales/deDE.lua`, `tabu-auc-ext.toc` | implemented | `node --test test/Core.test.js`. В клиенте deDE не запускалось. Перевод черновой. |
| Испанские и португальская подписи | REQ-007 | `Locales/esES.lua`, `Locales/esMX.lua`, `Locales/ptBR.lua`, `tabu-auc-ext.toc` | implemented | `node --test test/Core.test.js`. В клиентах esES, esMX и ptBR не запускалось. Перевод черновой. |
| Две строки под штатным итогом | REQ-003, REQ-008, REQ-011 | `Core.lua` | implemented | `node --test test/Core.test.js`. В клиенте после правки не запускалось. |
| Нейтральный гоблин без тега фракции | REQ-004, REQ-005 | `Core.lua` | implemented | `node --test test/Core.test.js`. В клиенте после правки не переоткрывалось. |

## Checkpoint

- Revision: патч 1.1.1. Нейтральный аукционист без тега фракции читается по реакции и по текущей цели.
- Last verified: пользователь подтвердил, что у гоблина строки появляются. `node --test test/Core.test.js`.
- Next: нет.
- Open: точный возврат `UnitFactionGroup` у гоблина по-прежнему не снят. Сверка суммы 15% по медякам в клиенте не записана.
