# tabu-auc-ext requirements

- Project: `D:\dev\wow\forever\tabu-auc-ext`
- Game copy: `F:\GAMES\World of Warcraft\_forever_\Interface\AddOns\tabu-auc-ext` — только `.toc`, `Core.lua` и `Locales`.
- Updated: 2026-11-15
- Implementation matrix: `docs/implementation-matrix.md`
- Original request: аддон `tabu-auc-ext` дописывает в окно продажи аукциона строку комиссии по формуле 5% от полной цены лота. Затем: определять, какой это аукцион, чтобы брать 5% или 15%.
- Goal: на панели продажи, между залогом и итогом, показывать комиссию `floor(полная цена × процент / 100)`. Фракционный аукционист — 5%. Нейтральный — 15%.
- Scope: Forever, Interface 16001. Настроек нет: процент выбирается по фракции открытого аукциониста.

## Requirements

| ID | Required behavior or constraint | Origin and source | Priority | Targets | Observable acceptance criteria | State |
|---|---|---|---|---|---|---|
| REQ-001 | Имя аддона и папки — `tabu-auc-ext`. | User: «сделай аддон tabu-auc-ext». | 1 | forever | Папка и TOC называются `tabu-auc-ext`. | active |
| REQ-002 | Клиент — Forever, Interface 16001, рядом с `tabu-ai-agent`. | Тот же набор tabu-аддонов. Нейтральные 15% есть на Forever, не на современном Retail. | 1 | forever | TOC содержит `## Interface: 16001` и лежит в `_forever_\Interface\AddOns`. | active |
| REQ-003 | В окне продажи строка комиссии: `floor(количество × цена за штуку × процент / 100)` меди. Пересчёт на каждое изменение цены и количества. | User: вывести комиссию по формуле. Затем: «чтобы количество учитывалось и считалось правильно». Первая версия считала один раз от цены по умолчанию в 1 серебро и показывала 5 меди. | 1 | forever | 20 штук по 1з00с дают 1з00с комиссии на фракционном доме и 3з00с на нейтральном. Смена количества или цены сразу меняет строку. | active |
| REQ-008 | Строка «На руки» показывает сумму к получению: количество × цена − комиссия. Справа от этой суммы — дельта к цене торговцу за то же количество. Надпись и дельта зелёные, если торговцу сдавать дешевле, и красные, если на руки столько же или меньше, чем у торговца. Если поле количества скрыто, количество равно 1. | User: дельту справа от цены «на руки»; надпись тоже красить; у нестакающихся предметов «на руки» считается неправильно, потому что скрытое поле количества даёт 0. | 1 | forever | Один меч за 1з при комиссии 5% и цене торговцу 50с: «На руки» 95с, справа с отступом зелёные +45с, надпись зелёная. Если торговец платит 2з, надпись красная и справа красные −1з05с. Поле ввода цены лота не меняется. | active |
| REQ-004 | Процент 15, если `UnitFactionGroup("npc")` равен `Neutral`, и 5, если `Alliance` или `Horde`. | User: «надо определять еще какой это аук чтобы понимать 5 или 15 проц». | 1 | forever | У нейтрального аукциониста 15%. У аукциониста Орды или Альянса 5%. | active |
| REQ-005 | Если фракцию аукциониста прочитать нельзя, строка комиссии скрыта. | Не подставлять 5%, когда дом не определён. | 1 | forever | Без юнита `npc` и без уже снятой фракции строка не видна. | active |
| REQ-006 | Нет настроек. | Процент задаётся домом, а не опцией. | 2 | forever | Нет категории в меню настроек и нет SavedVariables. | active |
| REQ-007 | Подпись строки локализована. Английский fallback и ruRU. | Localization baseline. Пользователь называет сумму комиссией. | 2 | forever | В en-клиенте подпись `House cut`. В ruRU — `Комиссия`. | active |
| REQ-009 | Если в ячейке продажи нет предмета, комиссия, «На руки» и дельта показывают 0. Так бывает после объявления аукциона, когда лот снят с ячейки, и когда предмет забрали из ячейки вручную. Поле ввода цены не меняется. | User: «после того как аукцион объявляется или когда предмет изымается из аукционной ячейки — цифры должны превратиться в 0». | 1 | forever | После объявления одного предмета и после снятия предмета с ячейки комиссия 0, «На руки» 0, дельта 0 без знака, надпись и дельта красные. | active |
| REQ-010 | При смене предмета цифры перерисовываются один раз, уже по собранному лоту: новый предмет, видимость количества и известная цена торговцу. Промежуточные сбросы ячейки на экран не выводятся. Повтор с теми же суммой и цветом не трогает поля. | User: при смене продающихся предметов цифры выставляются больше одного раза, промежуточные некорректны по сумме и по цвету. Окно продажи сначала снимает предмет, затем сбрасывает количество и меняет цену отдельными пересчётами. | 1 | forever | Выбор предмета не мигает зелёной дельтой от автоматической цены. Цифры появляются один раз, уже по цене из списка аукциона. | active |

## Target and API evidence

| Target | Intended client/build/interface | Source commit and evidence | Related REQ IDs | Loading/access/runtime uncertainty |
|---|---|---|---|---|
| forever | WoW Forever 1.60.1, Interface 16001. Пин источника `9dc84f0d3bbae1768ac3405b3716000bd93eda06`. | `AuctionHouseSellFrameMixin:GetTotalPrice` / `UpdateTotalPrice` есть в Shared sell frame этого коммита. `UnitFactionGroup(unit) -> factionGroupTag` объявлен в `UnitDocumentation.lua` того же коммита; тег `Neutral` в документации не перечислен. `AUCTION_HOUSE_SHOW` и `AUCTION_HOUSE_CLOSED` есть в индексе. `C_AddOns.IsAddOnLoaded` и `issecretvalue` есть в индексе. | REQ-003, REQ-004 | Что `UnitFactionGroup("npc")` у гоблинского аукциониста возвращает именно `Neutral`, в игре не проверено. Шаблон `AuctionHouseAlignedPriceDisplayTemplate` доступен только после загрузки `Blizzard_AuctionHouseUI`. |

## UI and accepted design

- Mock-up choice: пользователь сразу попросил аддон, отдельный макет не запрашивал. Строка повторяет шаблон залога `AuctionHouseAlignedPriceDisplayTemplate` и встаёт между залогом (`layoutIndex` 50) и итогом (`layoutIndex` 60) с индексом 55.
- Accepted design: одна денежная строка в панели продажи.
- Relevant REQ IDs: REQ-003, REQ-007
- Layout, assets and states: штатные шрифт и монеты окна продажи. Состояния: фракционный дом, нейтральный дом, дом не определён (строка скрыта), нулевая цена.
- Interaction: строка только показывает сумму. Своего ввода нет.

## Options-menu integration and localization

- Options discovery: нет настраиваемого поведения. 5% и 15% выбираются по фракции аукциониста.
- Settings lifecycle: нет SavedVariables.
- Locale architecture: `Locales/Base.lua`, затем `Locales/ruRU.lua`, затем `Core.lua`.
- Translation coverage: enUS — `House cut` и `Notes`. ruRU — `Комиссия` и `Notes-ruRU`, написано вместе с аддоном, в клиенте не проверялось. Остальные локали остаются на английском.
- Acceptance REQ IDs: REQ-006, REQ-007.

## Controller interaction assessment

| UI element or control group | Role | Controller path and visible cues | Target evidence / gaps | Acceptance or explicit user exclusion |
|---|---|---|---|---|
| Строка комиссии | passive display | Не фокус. Тот же денежный шаблон, что у залога. Клавиатура и контроллер её не активируют. | Forever, sell frame шаблон `AuctionHouseAlignedPriceDisplayTemplate`. | Отдельная проверка контроллера не применима. |

- Input modes: мышь и клавиатура остаются у штатных полей цены.
- Bindings to preserve: не меняются.

## Testing preference

- Route and source: в этом заходе в игре не проверяем. Для `tabu-ai-agent` пользователь 2026-11-15 отказался от Witchcraft и UIForever и просил не предлагать их снова, пока сам не попросит проверку.
- Remaining real-client checks: REQ-003 и REQ-004 у фракционного и нейтрального аукциониста. Статус: not run.
- Controller checks: not applicable.
