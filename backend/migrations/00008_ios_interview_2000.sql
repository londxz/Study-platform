-- +goose Up

-- A deliberately broad iOS interview drill bank.
--
-- Theory is generated from 100 high-signal competencies and 14 interview
-- angles. This produces 1,400 distinct prompts with a concept-specific answer
-- foundation and an angle-specific evaluation rubric.
--
-- Live coding is generated from the 30 fully verified Swift archetypes that
-- existed before this migration. Each archetype is rehearsed in 20 interview
-- modes,
-- producing 600 runnable tasks while preserving starter code, reference
-- solutions and hidden tests.

WITH concept_data(section_slug, concept_no, concept, foundation, pitfalls, base_difficulty) AS (VALUES
-- Swift Core: 20
('swift-core',1,$c$Value и reference semantics$c$,$c$Struct и enum выражают независимые значения, class добавляет identity и разделяемое состояние. Выбор определяется семантикой модели, а не мифом про stack и heap.$c$,$c$Не путать value semantics с отсутствием heap allocation; отдельно обсуждать identity, mutation и thread safety.$c$,2),
('swift-core',2,$c$Copy-on-Write$c$,$c$CoW позволяет value type разделять storage до мутации; перед записью уникальность буфера проверяется и при необходимости создаётся копия.$c$,$c$Учитывать slices, escaped storage, isKnownUniquelyReferenced и то, что CoW не делает mutable reference потокобезопасным.$c$,3),
('swift-core',3,$c$String, Unicode и Character$c$,$c$Swift String — коллекция расширенных grapheme clusters с variable-width encoding; индексирование не обязано быть O(1).$c$,$c$Не индексировать строку Int-индексом, различать scalar, grapheme и UTF code unit, тестировать normalization и emoji.$c$,3),
('swift-core',4,$c$Array, Dictionary и Set complexity$c$,$c$Сложность операций зависит от contiguous storage, hashing, collisions, capacity growth и CoW. Dictionary и Set дают амортизированное O(1), но не гарантируют его для плохого hash.$c$,$c$Не сохранять hashValue, не мутировать identity ключа и учитывать амортизированную, а не абсолютную стоимость.$c$,3),
('swift-core',5,$c$Optional и моделирование ошибок$c$,$c$Optional выражает отсутствие значения, throws и Result сохраняют причину отказа, а domain enum ограничивает допустимые состояния.$c$,$c$Не превращать все ошибки в nil и не протаскивать NSError или транспортные детали через доменный слой.$c$,2),
('swift-core',6,$c$Generics и specialization$c$,$c$Generic constraint сохраняет concrete type и связи между типами; optimizer может специализировать код при достаточной видимости реализации.$c$,$c$Специализация не гарантирована, @inlinable расширяет ABI-контракт, а рост code size нужно измерять.$c$,4),
('swift-core',7,$c$Existential any и opaque some$c$,$c$any стирает concrete type для heterogeneous storage, some скрывает один конкретный тип, generic parameter передаёт тип вызывающей стороне.$c$,$c$Обсуждать witness tables, boxing, associated types и не считать existential просто другим синтаксисом generic.$c$,4),
('swift-core',8,$c$Protocols с associated types и type erasure$c$,$c$Associated types описывают отношения типов; type erasure фиксирует нужные типы и скрывает реализацию через box или closures.$c$,$c$Сначала проверить constrained existential или generic; учитывать allocation, indirection и потерю static guarantees.$c$,4),
('swift-core',9,$c$Dispatch в protocol extensions$c$,$c$Protocol requirements используют witness-table dispatch, а методы только из extension выбираются статически по известному compile-time типу.$c$,$c$Одинаково названный метод без requirement может вызвать неожиданную реализацию после стирания к protocol type.$c$,4),
('swift-core',10,$c$Static, dynamic и Objective-C dispatch$c$,$c$final и whole-module optimization помогают direct dispatch; class vtable, witness table и Objective-C message dispatch имеют разные возможности и стоимость.$c$,$c$Не обещать конкретную оптимизацию без измерения; dynamic и @objc меняют контракт и interop.$c$,4),
('swift-core',11,$c$Enum с associated values и state machine$c$,$c$Enum задаёт закрытое множество состояний, associated values хранят данные конкретного case, exhaustive switch защищает от невозможных комбинаций.$c$,$c$Не заменять state enum набором независимых boolean и не использовать class hierarchy без требования открытого расширения или identity.$c$,3),
('swift-core',12,$c$Codable и эволюция wire-моделей$c$,$c$DTO отделяется от domain model; custom decoding поддерживает defaults, старые ключи, версии, нестандартные даты и polymorphic payload.$c$,$c$Новое обязательное поле ломает старые payload, silent defaults могут скрыть повреждение, fixtures разных версий обязательны.$c$,3),
('swift-core',13,$c$KeyPath и dynamic member lookup$c$,$c$KeyPath типобезопасно описывает доступ к свойству и поддерживает composition; dynamic member lookup строит DSL, но переносит часть ошибок в менее очевидные места.$c$,$c$Не скрывать сложный control flow за магией и различать WritableKeyPath, ReferenceWritableKeyPath и runtime KVC.$c$,4),
('swift-core',14,$c$Property wrappers и macros$c$,$c$Wrapper переиспользует storage/access policy, macro генерирует синтаксис на compile time. Оба механизма должны сохранять понятный API и diagnostics.$c$,$c$Не прятать I/O и глобальное состояние в property access; generated code должен быть тестируемым и обозримым.$c$,4),
('swift-core',15,$c$Result builders и DSL$c$,$c$Result builder трансформирует последовательность выражений в итоговое значение через buildBlock, buildEither и другие операции.$c$,$c$Ошибки типов могут стать сложнее; DSL должен иметь ограниченную область и предсказуемую семантику evaluation.$c$,4),
('swift-core',16,$c$Exclusivity of access и inout$c$,$c$Modify-access должен быть эксклюзивным относительно конфликтующих read/modify; inout задаёт временный доступ, а не обычную reference передачу.$c$,$c$Опасны overlapping accesses, captured inout и чтение self во время mutating access.$c$,4),
('swift-core',17,$c$Hashable, Equatable и Comparable invariants$c$,$c$Равные значения обязаны иметь одинаковый hash; Comparable должен задавать согласованный строгий порядок; identity-поля ключа стабильны во время хранения.$c$,$c$Коллизии допустимы, hashValue не стабилен между процессами, несогласованные equality и ordering ломают коллекции.$c$,3),
('swift-core',18,$c$ABI, API stability и resilience$c$,$c$Resilient public type может менять layout между версиями библиотеки; @frozen фиксирует ABI ради оптимизации и ограничивает эволюцию.$c$,$c$Не применять library-evolution атрибуты к app-модулям автоматически и учитывать unknown enum cases.$c$,5),
('swift-core',19,$c$Objective-C interoperability$c$,$c$@objc, NSObject, selectors, KVO/KVC, nullability и bridging соединяют разные runtime-модели и ограничения типов.$c$,$c$Не терять nullability, generic information и ownership annotations; динамические возможности имеют цену и ограничения.$c$,4),
('swift-core',20,$c$Unsafe pointers и memory binding$c$,$c$Pointer API требует корректных lifetime, alignment, initialization, binding и bounds; withUnsafePointer ограничивает время жизни адреса closure-областью.$c$,$c$Нельзя сохранять временный pointer, делать неверный assumingMemoryBound или нарушать aliasing и initialization rules.$c$,5),

-- ARC and memory: 12
('arc-memory',21,$c$Граф strong ownership$c$,$c$ARC освобождает объект, когда исчезает последний strong owner; анализ начинается с полного графа controller, model, task, callback, timer и cache.$c$,$c$Leak ищут по пути владения, а не механически добавляют weak во все closures.$c$,3),
('arc-memory',22,$c$weak и unowned references$c$,$c$weak — zeroing optional для ссылки, которая может исчезнуть; unowned — обещание более длинного lifetime и crash при нарушении.$c$,$c$Выбор основан на lifetime invariant; unowned не является просто более быстрой версией weak.$c$,3),
('arc-memory',23,$c$Closure capture lists$c$,$c$Capture list вычисляется при создании closure; value capture даёт snapshot значения, weak/unowned меняют владение class reference.$c$,$c$Вложенная closure может неявно strongly захватить self; capture reference type не копирует сам объект.$c$,4),
('arc-memory',24,$c$Stored callback lifecycle$c$,$c$Владелец callback должен иметь явную точку сброса; one-shot callback безопасно переносится в local strong variable и удаляется до вызова.$c$,$c$Не обнулять callback во время выполнения без гарантии lifetime и не оставлять multi-shot подписку без cancellation.$c$,4),
('arc-memory',25,$c$Timer, display link и notifications$c$,$c$Run loop или center может удерживать callback/target; token, timer и display link требуют симметричного invalidate или remove по бизнес-lifecycle.$c$,$c$deinit не наступит, если цикл уже удерживает owner; selector и block API имеют разную ownership-модель.$c$,4),
('arc-memory',26,$c$Task и lifetime экрана$c$,$c$Task удерживает захваченные значения до завершения; guard let self может создать strong lifetime через несколько suspension points.$c$,$c$Отличать leak от намеренного продления жизни, хранить handle, отменять работу и защищаться от stale result.$c$,4),
('arc-memory',27,$c$Delegate ownership$c$,$c$Delegate обычно weak, когда владелец компонента одновременно владеет delegate; отдельному delegate нужен другой strong owner.$c$,$c$Слабая ссылка без владельца мгновенно обнулится, а protocol должен быть class-bound.$c$,3),
('arc-memory',28,$c$Autorelease pools$c$,$c$Objective-C temporaries могут жить до drain pool; локальный autoreleasepool уменьшает memory peak в длинных циклах обработки.$c$,$c$Pool не исправляет retain cycle; сначала подтверждать autorelease growth профилированием.$c$,4),
('arc-memory',29,$c$Slices и скрытое удержание storage$c$,$c$Substring и ArraySlice могут разделять большой исходный buffer; долгоживущая маленькая slice способна удерживать весь storage.$c$,$c$На storage boundary создавать самостоятельную String или Array, но не копировать вслепую в hot path.$c$,3),
('arc-memory',30,$c$Core Foundation ownership bridging$c$,$c$Create/Copy rule и annotations определяют transfer; takeRetainedValue и takeUnretainedValue имеют противоположные ownership-ожидания.$c$,$c$Неверный bridge даёт leak или use-after-free; контракт C API нужно читать точно.$c$,5),
('arc-memory',31,$c$Image memory cache$c$,$c$Decoded image cost зависит от пикселей, а не размера JPEG; cache ограничивается cost, downsampling и pressure eviction.$c$,$c$Нужны in-flight deduplication, target-size key, cancellation и измеримый hit rate.$c$,4),
('arc-memory',32,$c$Instruments и memory diagnostics$c$,$c$Memory Graph показывает ownership paths, Allocations — lifetime и backtrace, VM/footprint отделяет heap от mapped и decoded memory.$c$,$c$Рост memory не равен leak; нужен воспроизводимый сценарий, baseline и метрики после cleanup.$c$,4),

-- Swift Concurrency: 18
('concurrency',33,$c$Structured concurrency$c$,$c$async let и task group связывают child lifetime с scope родителя и обеспечивают ожидание или отмену перед выходом.$c$,$c$Не создавать unstructured Task без владельца и не использовать detached как универсальный background queue.$c$,3),
('concurrency',34,$c$TaskGroup ordering и failure$c$,$c$Task group возвращает результаты в порядке завершения; исходный порядок восстанавливают индексом, throwing group отменяет siblings после ошибки.$c$,$c$Cancellation cooperative, уже завершённые side effects не откатываются, число одновременно добавленных задач может требовать ограничения.$c$,4),
('concurrency',35,$c$Cooperative cancellation$c$,$c$cancel устанавливает флаг; код проверяет Task.checkCancellation, Task.isCancelled или вызывает cancellation-aware API.$c$,$c$Не проглатывать CancellationError как retryable failure и очищать ресурсы независимо от точки отмены.$c$,3),
('concurrency',36,$c$Actor isolation$c$,$c$Actor сериализует доступ к isolated mutable state; cross-actor вызов требует await, immutable Sendable value можно безопасно передать.$c$,$c$Actor не делает несколько await атомарной транзакцией и не защищает внешнее shared state.$c$,3),
('concurrency',37,$c$Actor reentrancy$c$,$c$Во время await actor допускает другую работу, поэтому состояние после suspension нужно перепроверить через token, generation или state machine.$c$,$c$Нельзя держать логический invariant через await без явного протокола commit.$c$,4),
('concurrency',38,$c$MainActor и UI isolation$c$,$c$MainActor выражает сериализацию UI state; наследование actor context не равно гарантии конкретного thread во всех низкоуровневых деталях.$c$,$c$Не выполнять blocking I/O на MainActor и не добавлять MainActor ко всему feature ради устранения warnings.$c$,3),
('concurrency',39,$c$Sendable и sending$c$,$c$Sendable обещает безопасную передачу между isolation domains; immutable value types обычно естественны, mutable classes требуют изоляции.$c$,$c$@unchecked Sendable переносит ответственность на автора и должен иметь доказуемый synchronization invariant.$c$,4),
('concurrency',40,$c$Checked continuations$c$,$c$Continuation адаптирует callback API и должна resume ровно один раз на всех путях; cancellation и callback race требуют отдельного state.$c$,$c$Double resume и забытый resume — ошибки; continuation сама не делает legacy API cancellation-aware.$c$,4),
('concurrency',41,$c$AsyncSequence и backpressure$c$,$c$AsyncSequence выдаёт элементы по pull-модели, но producer bridge всё равно нуждается в bounded buffer и policy drop/coalesce/suspend.$c$,$c$Unbounded continuation buffer создаёт memory growth, termination handler должен освобождать producer.$c$,4),
('concurrency',42,$c$Task priority и inversion$c$,$c$Priority — сигнал scheduler; structured dependencies могут эскалировать priority, но порядок выполнения не гарантирован.$c$,$c$Не строить correctness на priority и не блокировать threads, необходимые higher-priority work.$c$,4),
('concurrency',43,$c$Task.detached$c$,$c$Detached task не наследует actor context, task-local values и structured lifetime; нужен для действительно независимой работы с Sendable inputs.$c$,$c$Потеря cancellation, priority и isolation часто делает detached неправильным выбором.$c$,4),
('concurrency',44,$c$Single-flight async loading$c$,$c$Параллельные клиенты делят один in-flight Task, результат кешируется, а lifecycle task не должен зависеть от отмены одного waiter.$c$,$c$Нужно определить политику ошибок, invalidation, token refresh и когда отменять shared operation.$c$,4),
('concurrency',45,$c$Debounce, throttle и latest-wins$c$,$c$Debounce ждёт паузу, throttle ограничивает частоту, latest-wins отменяет или отвергает stale generation.$c$,$c$Отмена сети может прийти поздно, поэтому commit результата также проверяет generation.$c$,3),
('concurrency',46,$c$Bounded parallelism$c$,$c$Concurrency limit реализуют window/task group, semaphore с async-safe ожиданием или worker pool, сохраняя cancellation и порядок при необходимости.$c$,$c$Не запускать тысячи child tasks одновременно и не блокировать cooperative executor обычным semaphore wait.$c$,4),
('concurrency',47,$c$Locks, atomics и actors$c$,$c$Lock подходит для короткой synchronous critical section, atomics — для узкого lock-free invariant, actor — для async isolated state.$c$,$c$Нельзя await под обычным lock; выбирать примитив по модели доступа, contention и доказуемости.$c$,5),
('concurrency',48,$c$Deterministic async testing$c$,$c$Clock, scheduler, UUID generator и transport передаются как dependencies; тест управляет временем и событиями без sleep.$c$,$c$Sleep создаёт flaky и медленные тесты, а ожидание без timeout зависает навсегда.$c$,4),
('concurrency',49,$c$Task-local values$c$,$c$TaskLocal распространяет контекст по structured child tasks и полезен для tracing, но не является общим mutable storage.$c$,$c$Detached work не наследует контекст; бизнес-зависимости лучше передавать явно.$c$,4),
('concurrency',50,$c$Swift 6 concurrency migration$c$,$c$Миграция начинается с границ isolation и data ownership, затем Sendable diagnostics исправляются архитектурно, а не массовым @unchecked.$c$,$c$Preconcurrency и unsafe escape hatches должны быть локальными и иметь план удаления.$c$,5),

-- UIKit and SwiftUI: 18
('uikit-swiftui',51,$c$UIViewController lifecycle$c$,$c$viewDidLoad означает загрузку view, appearance callbacks отражают показ, deinit — реальное освобождение; повторная конфигурация должна быть идемпотентной.$c$,$c$Не начинать неотменяемую работу без owner и не считать viewDidDisappear гарантией уничтожения.$c$,2),
('uikit-swiftui',52,$c$View controller containment$c$,$c$Корректный containment вызывает addChild, добавляет view/layout и didMove; удаление зеркально вызывает willMove, remove view и removeFromParent.$c$,$c$Нарушенный порядок ломает appearance forwarding и lifecycle.$c$,4),
('uikit-swiftui',53,$c$Auto Layout solver$c$,$c$Constraints образуют систему уравнений с priorities; intrinsic size, hugging и compression resistance разрешают неоднозначность.$c$,$c$Различать ambiguous и unsatisfiable layout, не обновлять constraints хаотично в layoutSubviews.$c$,3),
('uikit-swiftui',54,$c$Self-sizing cells и reuse$c$,$c$Cell должна полностью конфигурироваться из model, сбрасывать transient state, отменять work и защищаться от stale async result.$c$,$c$prepareForReuse не заменяет корректную конфигурацию; identity и generation обязательны.$c$,3),
('uikit-swiftui',55,$c$Diffable data source identity$c$,$c$Snapshot описывает section/item identifiers; identifiers уникальны и стабильны, content changes не должны менять identity.$c$,$c$Duplicate IDs приводят к crash, неправильный hash ломает updates, слишком частые snapshots дают hitches.$c$,3),
('uikit-swiftui',56,$c$Compositional layout$c$,$c$Layout строится из item, group, section и environment; orthogonal scrolling и estimated sizes требуют измерения.$c$,$c$Сложная иерархия может увеличить layout cost; decoration и supplementary identity должны быть стабильны.$c$,4),
('uikit-swiftui',57,$c$Prefetching и cancellation$c$,$c$Prefetch — hint, а не гарантия; requests coalesce, concurrency ограничен, cancellation удаляет waiter или отменяет ненужную операцию.$c$,$c$Не считать indexPath стабильной identity и не давать fast scroll раздувать очередь.$c$,3),
('uikit-swiftui',58,$c$SwiftUI structural identity$c$,$c$SwiftUI сопоставляет дерево по structural и explicit identity; стабильный id сохраняет local state и корректные transitions.$c$,$c$UUID в body, смена ветвей и AnyView без нужды уничтожают identity или ухудшают diffing.$c$,3),
('uikit-swiftui',59,$c$State, Binding и ownership$c$,$c$State хранит локальное owned value, Binding даёт контролируемый доступ владельцу, reference model должна иметь ясного owner.$c$,$c$Не дублировать source of truth и не создавать observable model заново внутри body.$c$,3),
('uikit-swiftui',60,$c$Observation framework$c$,$c$Observation отслеживает прочитанные свойства и уменьшает лишние invalidations; actor isolation и dependency boundaries остаются явными.$c$,$c$Не превращать global Environment в service locator и не мутировать UI state вне MainActor.$c$,4),
('uikit-swiftui',61,$c$NavigationStack и restoration$c$,$c$Navigation path — сериализуемая модель маршрута; deep link проходит validation, auth gates и восстановление зависимостей.$c$,$c$View не должна быть единственным source of truth navigation, path с нестабильными values не восстановится.$c$,4),
('uikit-swiftui',62,$c$SwiftUI Layout protocol$c$,$c$Layout измеряет subviews через proposals, может кешировать результаты и размещает их в bounds без побочных эффектов.$c$,$c$Не предполагать один measurement pass, учитывать unspecified/infinite proposal и invalidation cache.$c$,4),
('uikit-swiftui',63,$c$Transactions и animations$c$,$c$Transaction несёт animation context, withAnimation анимирует изменения state, transition требует insert/remove identity.$c$,$c$Не путать animation modifier scope, тестировать Reduce Motion и interruption.$c$,4),
('uikit-swiftui',64,$c$Rendering performance и hitches$c$,$c$Main-thread work, layout, decoding, excessive state updates и GPU overdraw анализируют Time Profiler, Hitches и SwiftUI instruments.$c$,$c$Оптимизация без trace часто переносит bottleneck; профилировать на устройстве и измерять frame deadlines.$c$,4),
('uikit-swiftui',65,$c$Accessibility$c$,$c$Semantic labels, traits, reading order, Dynamic Type, contrast, touch targets и Reduce Motion входят в контракт компонента.$c$,$c$Не объединять элементы так, чтобы потерять действия, и не фиксировать размеры, ломающие large text.$c$,3),
('uikit-swiftui',66,$c$App и Scene lifecycle$c$,$c$Scene lifecycle отделяет UI sessions от process lifetime; background/foreground события не гарантируют termination callback.$c$,$c$Сохранять критичные данные заранее, поддерживать несколько scenes и не связывать global state с одним window.$c$,3),
('uikit-swiftui',67,$c$Keyboard, focus и input$c$,$c$Focus model, safe area, keyboard layout guide и responder chain должны работать с hardware keyboard, rotation и accessibility.$c$,$c$Не двигать весь экран по raw notification frame и не перехватывать system gestures без необходимости.$c$,3),
('uikit-swiftui',68,$c$UIKit и SwiftUI interoperability$c$,$c$Representable/hosting boundaries синхронизируют state идемпотентно; coordinator связывает delegate callbacks без циклов.$c$,$c$update может вызываться часто, coordinator не должен владеть parent бесконтрольно, lifecycle двух миров различается.$c$,4),

-- Architecture and engineering: 15
('architecture',69,$c$Feature modularization$c$,$c$Модули следуют ownership и change boundaries; public API мал, зависимости направлены к стабильным abstractions.$c$,$c$Слишком мелкие модули увеличивают build graph и boilerplate, shared модуль легко превращается в свалку.$c$,4),
('architecture',70,$c$Dependency injection и composition root$c$,$c$Dependencies создаются в composition root и передаются через initializer или environment с явным lifetime.$c$,$c$Service locator скрывает граф, optional dependencies маскируют ошибки сборки, singleton усложняет тесты.$c$,3),
('architecture',71,$c$MVVM, reducer и unidirectional flow$c$,$c$Pattern выбирают по state complexity и team needs; reducer делает transition чистым, effects явными, view model адаптирует presentation.$c$,$c$Название MVVM не предотвращает massive view model, races и неявные dependencies.$c$,4),
('architecture',72,$c$Finite state machines$c$,$c$State enum и actions задают допустимые transitions, side effects отделены, impossible states исключаются типами.$c$,$c$Несколько boolean создают противоречия; transition должен учитывать stale response и cancellation.$c$,3),
('architecture',73,$c$Navigation, coordinator и deep links$c$,$c$Router превращает intent в route, coordinator управляет flow, deep link проходит auth, data loading и validation.$c$,$c$Не связывать domain со UIViewController и не выполнять deep link до готовности зависимостей.$c$,4),
('architecture',74,$c$Repository и data-source boundaries$c$,$c$Repository предоставляет доменный контракт и координирует remote/local sources, caching и mapping.$c$,$c$Не делать generic CRUD repository ради шаблона и не скрывать важные consistency semantics.$c$,3),
('architecture',75,$c$Domain error mapping$c$,$c$Transport, decoding, auth, cancellation и business errors преобразуются на границе в actionable domain outcomes.$c$,$c$Не retry permanent failure, не показывать raw backend message, сохранять diagnostic cause безопасно.$c$,3),
('architecture',76,$c$Testing pyramid и Swift Testing$c$,$c$Unit tests защищают invariants, integration — реальные boundaries, UI — критические flows, contract tests — client/server agreement.$c$,$c$Coverage не равно качеству; clocks/fakes лучше sleep, mocks не должны повторять реализацию.$c$,3),
('architecture',77,$c$Observability$c$,$c$Logs, metrics, traces, signposts и crash context связываются operation ID и измеряют latency, errors, saturation и user impact.$c$,$c$Не логировать PII и tokens, не создавать high-cardinality labels, alerts должны быть actionable.$c$,4),
('architecture',78,$c$Feature flags$c$,$c$Flag имеет owner, default, targeting, exposure event, kill switch и дату удаления; evaluation должна быть deterministic.$c$,$c$Комбинаторный взрыв состояний, stale flags и разная логика клиента/сервера создают риск.$c$,3),
('architecture',79,$c$Analytics event design$c$,$c$Event schema версионируется, имеет stable semantics, consent и batching; продуктовые метрики отделены от diagnostic telemetry.$c$,$c$Не отправлять PII, не менять смысл старого event, не блокировать UI на delivery.$c$,3),
('architecture',80,$c$Swift API design и code review$c$,$c$API выражает ownership, mutability, failure и concurrency в типах, имеет понятные names и минимальную поверхность.$c$,$c$Не принимать boolean soup, не скрывать expensive work в property, документировать preconditions.$c$,4),
('architecture',81,$c$Incremental legacy migration$c$,$c$Strangler approach вводит boundary, adapters и измеримый slice; старый и новый путь сосуществуют под flag до доказанного parity.$c$,$c$Big-bang rewrite теряет behavior knowledge, двойная запись требует reconciliation и rollback.$c$,4),
('architecture',82,$c$Build performance и SwiftPM graph$c$,$c$Измеряют frontend/backend compilation, type checking и dependency fan-out; API/implementation targets и stable boundaries улучшают incremental builds.$c$,$c$Модули не бесплатны, @_implementationOnly и generated code требуют осторожности, CI cache должен быть воспроизводимым.$c$,4),
('architecture',83,$c$Mobile security и privacy architecture$c$,$c$Threat model определяет assets, trust boundaries и abuse cases; secrets не хранят в app binary, чувствительные данные минимизируются.$c$,$c$Keychain не исправляет insecure protocol, certificate pinning имеет операционный риск, logs и analytics тоже data boundary.$c$,5),

-- Mobile system design: 17
('system-design',84,$c$URLSession networking stack$c$,$c$Client разделяет request building, transport, decoding, auth и domain mapping; session configuration задаёт timeout, cache и connectivity policy.$c$,$c$Не создавать session на каждый запрос, учитывать cancellation, redirect, metrics и background configuration.$c$,3),
('system-design',85,$c$HTTP caching и ETag$c$,$c$Cache-Control определяет freshness, ETag/If-None-Match валидирует representation, 304 обновляет metadata без body.$c$,$c$Не кешировать private data общим ключом, учитывать Vary, auth scope и offline stale policy.$c$,4),
('system-design',86,$c$Retry, backoff и jitter$c$,$c$Retry разрешён для transient и идемпотентных операций, использует exponential backoff, jitter, Retry-After и общий deadline.$c$,$c$Не повторять auth/business errors и non-idempotent mutation без idempotency key.$c$,3),
('system-design',87,$c$Authentication и token refresh$c$,$c$Single-flight refresh делит одну операцию, запросы ждут новый token, rotation и logout атомарно очищают credentials.$c$,$c$401 loop, отмена одного waiter, clock skew и refresh token theft должны быть учтены.$c$,4),
('system-design',88,$c$Offline-first data flow$c$,$c$UI читает local source of truth, sync обновляет его транзакционно, mutations входят в durable outbox с idempotency.$c$,$c$Нужны conflict policy, tombstones, ordering, retry budget и состояние partial sync.$c$,4),
('system-design',89,$c$Pagination и cursor consistency$c$,$c$Cursor устойчивее offset при изменениях; merge дедуплицирует identity, сохраняет order и защищается от stale page.$c$,$c$Refresh и load-more race, duplicate/missing items, end detection и filter version требуют state machine.$c$,3),
('system-design',90,$c$Image loading pipeline$c$,$c$Pipeline coalesce requests, использует memory/disk cache, downsampling, priority, prefetch и cancellation.$c$,$c$Cache key включает transform/scale, decoded cost ограничен, disk writes атомарны.$c$,4),
('system-design',91,$c$Local persistence$c$,$c$Schema, transactions, indexes и migrations выбираются по access patterns; repository не скрывает consistency и threading model.$c$,$c$Не мигрировать огромную базу на main thread, проверять rollback/backup и corruption recovery.$c$,4),
('system-design',92,$c$Synchronization и conflict resolution$c$,$c$Server version, vector/lamport metadata или domain merge определяют conflict; policy может быть LWW, merge или user resolution.$c$,$c$Clock skew ломает naive timestamps, delete нуждается в tombstone, повторная доставка обязательна.$c$,5),
('system-design',93,$c$Idempotency и outbox$c$,$c$Mutation получает stable operation ID, durable outbox повторяет delivery, server возвращает прежний result для duplicate key.$c$,$c$Idempotency scope и retention должны быть определены, local success до durability теряет операцию.$c$,4),
('system-design',94,$c$Client rate limiting$c$,$c$Token bucket или leaky bucket ограничивает burst и sustained rate; server hints и priority classes управляют fairness.$c$,$c$Глобальный limiter может душить критичные запросы, clock и background transitions требуют корректной модели.$c$,4),
('system-design',95,$c$Realtime updates и WebSocket$c$,$c$Connection state machine покрывает connect, auth, heartbeat, reconnect, resubscribe и sequence gap recovery.$c$,$c$Сеть меняется, messages дублируются/теряются, background suspension требует fallback sync.$c$,4),
('system-design',96,$c$Push notifications$c$,$c$Push — hint, payload минимален, app fetches authoritative state; token lifecycle, permission и routing разделены.$c$,$c$Delivery не гарантирована, duplicate и stale push возможны, sensitive data нельзя класть в payload.$c$,3),
('system-design',97,$c$Background execution$c$,$c$BGTaskScheduler и background URLSession работают в системных budget; task сохраняет durable checkpoint и быстро обрабатывает expiration.$c$,$c$Нельзя обещать точное время запуска, infinite work или зависимость UI от background completion.$c$,4),
('system-design',98,$c$App startup performance$c$,$c$Cold start budget защищают lazy initialization, dependency graph staging и перенос I/O после первого meaningful frame.$c$,$c$Статические initializers, database migration, SDK startup и synchronous Keychain/network блокируют launch.$c$,4),
('system-design',99,$c$Release reliability и monitoring$c$,$c$Canary/phased release, crash-free sessions, hang rate, latency и business guardrails связаны с rollback/kill switch.$c$,$c$Среднее скрывает tails, alerts без ownership бесполезны, symbolication и version dimensions обязательны.$c$,4),
('system-design',100,$c$Эксперименты и масштабирование mobile feature$c$,$c$Assignment стабилен по user/unit, exposure логируется при фактическом показе, server/client contracts поддерживают mixed versions.$c$,$c$Sample ratio mismatch, cross-device identity, offline exposure и incompatible cohorts искажают результат.$c$,5)
),
frame_data(frame_no, frame_slug, lead, expectation, difficulty_delta) AS (VALUES
(1,'mechanics',$f$Объясните «$f$,$f$»: дайте точную модель, минимальный пример и гарантии, на которые может опираться приложение.$f$,0),
(2,'example',$f$Напишите минимальный Swift-пример для «$f$,$f$». Предскажите результат до запуска и объясните каждую существенную строку.$f$,0),
(3,'compare',$f$Сравните «$f$,$f$» с ближайшей альтернативой. Назовите критерии выбора, стоимость и случай, когда каждый вариант проигрывает.$f$,1),
(4,'diagnose',$f$Диагностируйте production-баг, связанный с «$f$,$f$». Постройте гипотезы, воспроизведение и способ доказать root cause.$f$,1),
(5,'review',$f$Вы ревьюите код, использующий «$f$,$f$». Какие вопросы зададите и какие скрытые ошибки будете искать?$f$,1),
(6,'design',$f$Спроектируйте небольшой API вокруг «$f$,$f$». Покажите типы, допустимые состояния, failure model и границы зависимостей.$f$,1),
(7,'invariants',$f$Назовите edge cases и инварианты «$f$,$f$». Какие входы и переходы особенно часто ломают решение?$f$,1),
(8,'tradeoffs',$f$Когда «$f$,$f$» является правильным выбором, а когда создаёт лишнюю сложность? Защитите решение требованиями.$f$,1),
(9,'testing',$f$Составьте стратегию тестирования «$f$,$f$». Какие unit, integration, stress и regression cases обязательны?$f$,1),
(10,'performance',$f$Разберите стоимость «$f$,$f$». Какие CPU, memory, allocation или latency effects возможны и чем их измерить?$f$,1),
(11,'failure',$f$Опишите наиболее опасный failure mode для «$f$,$f$». Как его предотвратить, обнаружить и безопасно восстановиться?$f$,2),
(12,'migration',$f$Спланируйте переход legacy-кода к корректному использованию «$f$,$f$». Нужны этапы, совместимость и rollback.$f$,2),
(13,'scale',$f$Как изменится решение с «$f$,$f$» при росте команды, данных и числа параллельных сценариев?$f$,2),
(14,'defend',$f$Защитите решение по теме «$f$,$f$» на senior follow-up. Назовите альтернативу, ограничения, метрики успеха и триггер пересмотра.$f$,2)
),
generated_questions AS (
 SELECT c.section_slug,c.concept_no,f.frame_no,
        f.lead || c.concept || f.expectation AS prompt,
        'Компетенция: ' || c.concept || '. Формат: ' || f.frame_slug || '.' AS explanation,
        c.foundation || E'\n\nСильный ответ должен: ' || f.expectation || E'\n\nКритические риски: ' || c.pitfalls AS reference_answer,
        LEAST(5,c.base_difficulty+f.difficulty_delta) AS difficulty,
        10000 + c.concept_no*20 + f.frame_no AS position
 FROM concept_data c CROSS JOIN frame_data f
)
INSERT INTO questions (topic_id,prompt,explanation,reference_answer,difficulty,position,status)
SELECT tp.id,g.prompt,g.explanation,g.reference_answer,g.difficulty,g.position,'published'
FROM generated_questions g
JOIN sections s ON s.slug=g.section_slug
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
JOIN topics tp ON tp.section_id=s.id AND tp.slug='main'
WHERE NOT EXISTS (
 SELECT 1 FROM questions existing WHERE existing.topic_id=tp.id AND existing.prompt=g.prompt
);

-- Fifteen interview modes turn every verified archetype into a focused drill.
WITH base_tasks AS (
 SELECT source.*,row_number() OVER (ORDER BY source.section_position,source.task_position,source.slug) AS base_no
 FROM (
  SELECT ct.*,s.position AS section_position,ct.position AS task_position
  FROM coding_tasks ct
  JOIN topics tp ON tp.id=ct.topic_id
  JOIN sections s ON s.id=tp.section_id
  JOIN tracks tr ON tr.id=s.track_id
  JOIN directions d ON d.id=tr.direction_id
  WHERE d.slug='ios' AND tr.slug='interview' AND ct.status='published'
    AND ct.slug NOT LIKE 'ios-drill-%' AND ct.reference_solution <> ''
    AND EXISTS (SELECT 1 FROM coding_task_tests verified_test WHERE verified_test.coding_task_id=ct.id)
  ORDER BY s.position,ct.position,ct.slug
  LIMIT 30
 ) source
),
drill_frames(drill_no,label,instruction,difficulty_delta) AS (VALUES
(1,'Корректность',$d$Сначала сформулируйте инварианты и докажите корректность до запуска кода.$d$,0),
(2,'Границы',$d$Перечислите пустой, минимальный, максимальный и патологический входы; затем реализуйте решение.$d$,0),
(3,'Сложность',$d$Перед кодом назовите time и space complexity, после кода защитите её по каждой операции.$d$,1),
(4,'API design',$d$Сделайте сигнатуры и типы такими, чтобы неверное использование было заметно на этапе компиляции.$d$,1),
(5,'Читаемость',$d$Решите задачу production-стилем: ясные имена, короткие функции и никаких скрытых side effects.$d$,0),
(6,'Тестирование',$d$Сначала предложите таблицу тестов и только затем пишите реализацию, проходящую эти случаи.$d$,1),
(7,'Память',$d$Отдельно разберите allocations, ownership и возможность уменьшить peak memory.$d$,1),
(8,'Concurrency',$d$Объясните, что изменится при параллельных вызовах, где нужна isolation и как распространяется cancellation.$d$,2),
(9,'Ошибки',$d$Определите invalid input и failure model без silent fallback, затем реализуйте happy path.$d$,1),
(10,'Производительность',$d$Определите bottleneck, предложите измерение и оптимизируйте только критический путь.$d$,1),
(11,'Production',$d$Добавьте reasoning про logging, limits, backward compatibility и безопасное поведение при сбое.$d$,2),
(12,'Think aloud',$d$Решайте вслух: уточните контракт, предложите brute force, улучшите его и проверьте результат.$d$,0),
(13,'Альтернатива',$d$После основного решения предложите второй подход и объясните границу, где он становится выгоднее.$d$,1),
(14,'Code review',$d$Считайте starter code pull request: сначала найдите риски и только затем внесите минимальное исправление.$d$,1),
(15,'Senior follow-up',$d$Защитите решение при изменении требований: больше данных, отмена, повторный вызов и частичный отказ.$d$,2),
(16,'Рефакторинг',$d$Сначала получите корректный результат, затем отделите policy от mechanism без изменения поведения.$d$,1),
(17,'Whiteboard',$d$Решите без запуска кода: вручную пройдите алгоритм на двух примерах и найдите ошибку до компиляции.$d$,1),
(18,'Adversarial',$d$Интервьюер подаёт неудобные входы и меняет порядок событий. Решение должно сохранить инварианты.$d$,2),
(19,'Масштабирование',$d$Объясните, что сломается при росте входа в тысячу раз и какое изменение внесёте первым.$d$,2),
(20,'Обучение',$d$После решения объясните его junior-разработчику: модель, типичная ошибка и способ самопроверки.$d$,0)
),
generated_tasks AS (
 SELECT b.topic_id,b.id AS base_task_id,b.base_no,f.drill_no,
        'ios-drill-' || lpad((((b.base_no-1)*20)+f.drill_no)::text,4,'0') || '-' || b.slug AS slug,
        b.title || ' · ' || f.label AS title,
        b.statement_markdown || E'\n\n## Режим интервью\n' || f.instruction AS statement_markdown,
        b.hint,b.language,b.starter_code,b.reference_solution,b.time_limit_ms,b.memory_limit_kb,
        LEAST(5,b.difficulty+f.difficulty_delta) AS difficulty,
        20000 + ((b.base_no-1)*20)+f.drill_no AS position
 FROM base_tasks b CROSS JOIN drill_frames f
)
INSERT INTO coding_tasks
(topic_id,slug,title,statement_markdown,hint,language,starter_code,reference_solution,time_limit_ms,memory_limit_kb,difficulty,position,status)
SELECT topic_id,slug,title,statement_markdown,hint,language,starter_code,reference_solution,
       time_limit_ms,memory_limit_kb,difficulty,position,'published'
FROM generated_tasks
ON CONFLICT (topic_id,slug) DO NOTHING;

-- Every generated live-coding task inherits the hidden fixtures of its
-- verified archetype.
WITH base_tasks AS (
 SELECT source.*,row_number() OVER (ORDER BY source.section_position,source.task_position,source.slug) AS base_no
 FROM (
  SELECT ct.*,s.position AS section_position,ct.position AS task_position
  FROM coding_tasks ct
  JOIN topics tp ON tp.id=ct.topic_id
  JOIN sections s ON s.id=tp.section_id
  JOIN tracks tr ON tr.id=s.track_id
  JOIN directions d ON d.id=tr.direction_id
  WHERE d.slug='ios' AND tr.slug='interview' AND ct.status='published'
    AND ct.slug NOT LIKE 'ios-drill-%' AND ct.reference_solution <> ''
    AND EXISTS (SELECT 1 FROM coding_task_tests verified_test WHERE verified_test.coding_task_id=ct.id)
  ORDER BY s.position,ct.position,ct.slug
  LIMIT 30
 ) source
),
drill_numbers AS (SELECT generate_series(1,20) AS drill_no),
generated AS (
 SELECT b.id AS base_task_id,b.topic_id,
        'ios-drill-' || lpad((((b.base_no-1)*20)+n.drill_no)::text,4,'0') || '-' || b.slug AS slug
 FROM base_tasks b CROSS JOIN drill_numbers n
)
INSERT INTO coding_task_tests (coding_task_id,stdin,expected_stdout,hidden,position)
SELECT target.id,source_test.stdin,source_test.expected_stdout,true,source_test.position
FROM generated g
JOIN coding_tasks target ON target.topic_id=g.topic_id AND target.slug=g.slug
JOIN coding_task_tests source_test ON source_test.coding_task_id=g.base_task_id
WHERE NOT EXISTS (
 SELECT 1 FROM coding_task_tests existing
 WHERE existing.coding_task_id=target.id AND existing.position=source_test.position
);

-- +goose Down
DELETE FROM coding_task_tests
WHERE coding_task_id IN (
 SELECT ct.id FROM coding_tasks ct
 JOIN topics tp ON tp.id=ct.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND ct.slug LIKE 'ios-drill-%'
);
DELETE FROM coding_tasks
WHERE id IN (
 SELECT ct.id FROM coding_tasks ct
 JOIN topics tp ON tp.id=ct.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND ct.slug LIKE 'ios-drill-%'
);
DELETE FROM questions
WHERE id IN (
 SELECT q.id FROM questions q
 JOIN topics tp ON tp.id=q.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND q.position BETWEEN 10000 AND 12020
);
