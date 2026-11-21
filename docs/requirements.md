# tabu-auc-ext requirements

- Project: `D:\dev\wow\forever\tabu-auc-ext`
- Game copy: `F:\GAMES\World of Warcraft\_forever_\Interface\AddOns\tabu-auc-ext` — только `.toc`, `Core.lua` и `Locales`.
- Updated: 2026-11-22
- Implementation matrix: `docs/implementation-matrix.md`
- Original request: аддон `tabu-auc-ext` дописывает в окно продажи аукциона строку комиссии по формуле 5% от полной цены лота. Затем: определять, какой это аукцион, чтобы брать 5% или 15%.
- Goal: штатные поля выше итога не меняются. Под итогом с обычным шагом идут комиссия и сумма к получению. Чекбокс выкупа закреплён в левом нижнем углу, кнопка объявления — в правом. Фракционный аукционист — 5%. Нейтральный — 15%.
- Scope: Forever, Interface 16001.

## Requirements

| ID | Required behavior or constraint | Origin and source | Priority | Targets | Observable acceptance criteria | State |
|---|---|---|---|---|---|---|
| REQ-001 | Имя аддона и папки — `tabu-auc-ext`. | User: «сделай аддон tabu-auc-ext». | 1 | forever | Папка и TOC называются `tabu-auc-ext`. | active |
| REQ-002 | Клиент — Forever, Interface 16001, рядом с `tabu-ai-agent`. | Тот же набор tabu-аддонов. Нейтральные 15% есть на Forever, не на современном Retail. | 1 | forever | TOC содержит `## Interface: 16001` и лежит в `_forever_\Interface\AddOns`. | active |
| REQ-003 | Сразу под итогом строка комиссии: `floor(количество × цена за штуку × процент / 100)` меди. Пересчёт на каждое изменение цены и количества. | User: вывести комиссию по формуле. Затем: «чтобы количество учитывалось и считалось правильно». Затем: порядок «итог, комиссия, на руки, кнопка, чекбокс». | 1 | forever | 20 штук по 1з00с дают 1з00с комиссии на фракционном доме и 3з00с на нейтральном. Смена количества или цены сразу меняет строку. Комиссия между итогом и «На руки». | active |
| REQ-008 | Самая нижняя строка, ниже комиссии, показывает сумму к получению: количество × цена − комиссия. Справа от этой суммы — дельта к цене торговцу за то же количество. Надпись и дельта зелёные, если торговцу сдавать дешевле, и красные, если на руки столько же или меньше, чем у торговца. Если поле количества скрыто, количество равно 1. Если модуль дельты не меньше 1 золота, серебро и медь дельты скрыты, а наведение показывает точную сумму. | User: дельту справа от цены «на руки»; надпись тоже красить; у нестакающихся предметов «на руки» считается неправильно, потому что скрытое поле количества даёт 0. Затем: при трёх знаках золота выгода уезжает за фрейм — с 1з прятать серебро и медь выгоды и дать тултип точной суммы. | 1 | forever | Один меч за 1з при комиссии 5% и цене торговцу 50с: «На руки» 95с, справа зелёные +45с. Дельта 1з50с рисуется как 1з, тултип показывает 1з50с. Поле ввода цены лота и штатный итог не меняются. | active |
| REQ-004 | Процент 15 у нейтрального аукциониста и 5 у аукциониста Орды или Альянса. Тег `Alliance` или `Horde` — 5%, `Neutral` — 15%. Если тега нет, реакция к игроку от 4 и выше — нейтральный дом. Сначала читается `npc`, а если этого юнита нет — текущая цель. | User: «надо определять еще какой это аук чтобы понимать 5 или 15 проц». Затем: у гоблина в Пиратской бухте строк нет, в том числе после копии с проверкой только `npc`. | 1 | forever | У нейтрального аукциониста 15%. У аукциониста Орды или Альянса 5%. | active |
| REQ-005 | Если фракцию аукциониста прочитать нельзя, строка комиссии скрыта. | Не подставлять 5%, когда дом не определён. | 1 | forever | Без юнита `npc` и без уже снятой фракции строка не видна. | active |
| REQ-006 | Seven multipliers in the native addon category, default 2, account `TabuAucExtDB`. | Vendor fallback is a per-type multiplier stored for the account. | 2 | forever | Native category `tabu-auc-ext` has seven multipliers, default 2, in account `TabuAucExtDB`. | active |
| REQ-007 | Подписи строк локализованы. Английский fallback, ruRU, frFR, deDE, esES, esMX и ptBR. | Localization baseline. Пользователь называет сумму комиссией. Затем просил французский, немецкий, испанский и португальский. | 2 | forever | В en-клиенте подписи `House cut` и `You receive`. В ruRU — `Комиссия` и `На руки`. В frFR — `Commission` и `Vous recevez`. В deDE — `Provision` и `Ihr erhaltet`. В esES и esMX — `Comisión` и `Recibes`. В ptBR — `Comissão` и `Você recebe`. | active |
| REQ-009 | Если в ячейке продажи нет предмета, комиссия, «На руки» и дельта показывают 0. Так бывает после объявления аукциона, когда лот снят с ячейки, и когда предмет забрали из ячейки вручную. Поле ввода цены не меняется. | User: «после того как аукцион объявляется или когда предмет изымается из аукционной ячейки — цифры должны превратиться в 0». | 1 | forever | После объявления одного предмета и после снятия предмета с ячейки комиссия 0, «На руки» 0, дельта 0 без знака, надпись и дельта красные. | active |
| REQ-010 | При смене предмета цифры перерисовываются один раз, уже по собранному лоту: новый предмет, видимость количества и известная цена торговцу. Промежуточные сбросы ячейки на экран не выводятся. Повтор с теми же суммой и цветом не трогает поля. | User: при смене продающихся предметов цифры выставляются больше одного раза, промежуточные некорректны по сумме и по цвету. Окно продажи сначала снимает предмет, затем сбрасывает количество и меняет цену отдельными пересчётами. | 1 | forever | Выбор предмета не мигает зелёной дельтой от автоматической цены. Цифры появляются один раз, уже по цене из списка аукциона. | active |
| REQ-011 | Строки идут с обычным шагом: итог, комиссия, «На руки». Чекбокс выкупа закреплён в левом нижнем углу фрейма. Кнопка объявления закреплена в правом нижнем углу напротив него. Выбор предмета не сдвигает ни кнопку, ни чекбокс. | User: при выборе предмета всё разъезжается и чекбокс уплывает. Закрепить чекбокс слева снизу, кнопку справа снизу, строки оставить с обычными отступами. | 1 | forever | До выбора предмета и после него чекбокс в левом нижнем углу, кнопка в правом. Строки комиссии и «На руки» не толкают их вниз. | active |

## Target and API evidence

| Target | Intended client/build/interface | Source commit and evidence | Related REQ IDs | Loading/access/runtime uncertainty |
|---|---|---|---|---|
| forever | WoW Forever 1.60.1, Interface 16001. Пин источника `9dc84f0d3bbae1768ac3405b3716000bd93eda06`. | `AuctionHouseSellFrameMixin:GetTotalPrice` / `UpdateTotalPrice` есть в Shared sell frame этого коммита. `UnitFactionGroup(unitName) -> factionGroupTag, localized` объявлен в `UnitDocumentation.lua` того же коммита; тег `Neutral` в документации не перечислен. `UnitReaction(unit, otherUnit) -> result` там же, `luaIndex`, может быть nil. `AUCTION_HOUSE_SHOW` и `AUCTION_HOUSE_CLOSED` есть в индексе. `C_AddOns.IsAddOnLoaded` и `issecretvalue` есть в индексе. | REQ-003, REQ-004 | 2026-11-21: у Auctioneer O'reely в Пиратской бухте окно продажи открыто, в ячейке Heavy Leather, строк комиссии и «На руки» нет. Имя аукциониста жёлтое. Число, которое вернул `UnitFactionGroup("npc")`, из клиента не снималось. Шаблон `AuctionHouseAlignedPriceDisplayTemplate` доступен только после загрузки `Blizzard_AuctionHouseUI`. |

## UI and accepted design

- Mock-up choice: пользователь сразу попросил аддон, отдельный макет не запрашивал. Затем описал раскладку сам: классический фрейм остаётся, две свои строки самые нижние.
- Accepted design: залог 50, итог 60, комиссия 64, «На руки» 65. Штатный шаг 15. Кнопка объявления снята с раскладки и закреплена в правом нижнем углу. Чекбокс выкупа закреплён в левом нижнем углу, как в исходном окне.
- Relevant REQ IDs: REQ-003, REQ-007
- Layout, assets and states: штатные шрифт и монеты окна продажи. Состояния: фракционный дом, нейтральный дом, дом не определён (строка скрыта), нулевая цена.
- Interaction: строка только показывает сумму. Своего ввода нет.

## Options-menu integration and localization

- Options discovery: native category `tabu-auc-ext` with seven multipliers (weapon, armor, consumable, reagent, recipe, bag, other), min 0, max 100, step 0.1, default 2. The category title stays `tabu-auc-ext` in every locale. Setting names stay English. The 5% and 15% house cut is still chosen by the auctioneer's faction.
- Settings lifecycle: account-wide `SavedVariables` `TabuAucExtDB`. A stored `false` is kept. A missing or out-of-range multiplier becomes 2.
- Locale architecture: `Locales/Base.lua`, затем `ruRU`, `frFR`, `deDE`, `esES`, `esMX`, `ptBR`, затем `Core.lua`. Неизвестная локаль остаётся на английском. esMX не подменяет esES: у каждой локали свой файл, даже когда подписи совпадают.
- Translation coverage: enUS — `House cut`, `You receive` и `Notes`. ruRU — `Комиссия`, `На руки` и `Notes-ruRU`. frFR — `Commission`, `Vous recevez` и `Notes-frFR`. deDE — `Provision`, `Ihr erhaltet` и `Notes-deDE`. esES и esMX — `Comisión`, `Recibes` и соответствующие `Notes`. ptBR — `Comissão`, `Você recebe` и `Notes-ptBR`. Отдельной локали ptPT в клиенте нет. Формулировки кроме enUS и ruRU черновые, носителем и в клиенте не проверялись. Остальные локали остаются на английском.
- Acceptance REQ IDs: REQ-006, REQ-007.

## Controller interaction assessment

| UI element or control group | Role | Controller path and visible cues | Target evidence / gaps | Acceptance or explicit user exclusion |
|---|---|---|---|---|
| Строки комиссии и «На руки» | passive display | Не фокус. Тот же денежный шаблон, что у залога и итога. Клавиатура и контроллер их не активируют. | Forever, sell frame: итог 60, свои строки 64 и 65. Кнопка объявления и чекбокс выкупа закреплены по нижним углам и в раскладку не входят. | Отдельная проверка контроллера не применима. |

- Input modes: мышь и клавиатура остаются у штатных полей цены.
- Bindings to preserve: не меняются.

## Testing preference

- Route and source: в этом заходе в игре не проверяем. Для `tabu-ai-agent` пользователь 2026-11-15 отказался от Witchcraft и UIForever и просил не предлагать их снова, пока сам не попросит проверку.
- Remaining real-client checks: REQ-003 и REQ-004 у фракционного и нейтрального аукциониста. Статус: not run.
- Controller checks: not applicable.
