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

## Checkpoint

- Revision: новые файлы, без коммита.
- Last verified: статический тест формулы и TOC. Игровой клиент не открывался.
- Next: открыть фракционный и нейтральный аукцион в Forever и сверить строку с 5% и 15% от полной цены.
- Open: `UnitFactionGroup("npc")` у нейтрального аукциониста в Forever не снят.
