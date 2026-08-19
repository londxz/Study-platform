-- +goose Up
-- Big Tech iOS interview curriculum: deep theory, realistic questions and
-- deterministic Swift live-coding tasks. Content is original and grounded in
-- the current Swift 6 / Apple platform model.

WITH lesson_data(section_slug, slug, title, body_markdown, duration_minutes, position) AS (VALUES
('swift-core','swift-semantics-runtime','Swift semantics и runtime-модель',
$md$# Swift semantics и runtime-модель

Цель блока — уметь объяснить не синтаксис, а стоимость и поведение кода. Разберите value и reference semantics, identity, mutability, stack и heap как оптимизационные детали, Copy-on-Write и exclusivity of access.

## Что нужно уметь на интервью

Объяснить, почему Array остаётся value type, хотя использует разделяемый буфер. Показать момент, когда мутация вызывает копирование. Сравнить struct, final class и actor по семантике владения, изоляции и стоимости dispatch.

Отдельно разберите layout enum с associated values, Optional как enum, inline storage, boxing и влияние generic specialization. Не привязывайте корректность программы к предположению, что любой struct всегда находится на стеке.

## Практика

Возьмите модель ленты, сделайте её сначала классом, затем структурой. Найдите места, где identity действительно нужна, измерьте копирования больших коллекций и сформулируйте инварианты мутации.

Официальная база: The Swift Programming Language — Types, Memory Safety и Performance.$md$,35,10),
('swift-core','protocols-generics-existentials','Protocols, generics, any и some',
$md$# Protocol-oriented design без магии

На сильном интервью недостаточно сказать, что protocol — это контракт. Нужно различать generic constraints, existential containers, opaque result types, associated types, witness tables и dynamic dispatch.

## Ключевые развилки

Generic T: Protocol сохраняет конкретный тип и позволяет specialization. any Protocol стирает конкретный тип и даёт единый runtime-контейнер. some Protocol скрывает тип от вызывающего кода, но сохраняет одну конкретную реализацию для компилятора.

Объясните, почему protocol с associated type нельзя бездумно использовать как тип коллекции, когда type erasure оправдан, и какую цену создают boxing, heap allocation и indirect calls.

## Практика

Спроектируйте API аналитики с несколькими sink-реализациями. Сравните generic pipeline, массив existential-значений и ручной type erasure. Защитите выбор измеримыми требованиями, а не стилем.$md$,40,20),
('swift-core','api-errors-testing','API design, ошибки и тестируемость',
$md$# API design уровня production

Хороший Swift API выражает допустимые состояния типами. Разберите Result, throws, async throws, typed domain errors, cancellation и границы преобразования инфраструктурной ошибки в пользовательскую.

## Интервью-фокус

Умейте объяснить, где optional скрывает важную причину отказа, почему catch без классификации ошибок ломает retry, как сохранить underlying error для диагностики и не протащить URLSession или NSError через весь домен.

Проектируйте зависимости через маленькие интерфейсы, часы и генераторы ID передавайте извне. Это делает retry, кеш, дедупликацию и гонки воспроизводимыми в тестах.

## Практика

Напишите API загрузки страницы с явными состояниями success, empty, unauthorized, transient и permanent failure. Добавьте table-driven тесты, отмену и проверку повторной попытки.$md$,30,30),

('arc-memory','arc-object-graphs','ARC и графы владения',
$md$# ARC как граф владения

ARC считает strong references, но интервью проверяет умение увидеть весь граф: controller, view model, task, closure, delegate, timer, notification token и cache.

## Strong, weak, unowned

weak всегда optional и обнуляется после deinit. unowned не удерживает объект, но обещает более длинное время жизни ссылки и может упасть при нарушении обещания. Выбор делается по модели lifetime, а не по желанию убрать warning.

Capture list вычисляется при создании closure. Слабый self не обязан использоваться в каждом escaping closure: иногда задача должна продлить lifetime операции. Важен владелец closure и момент её освобождения.

## Практика

Нарисуйте граф экран → view model → service → callback. Для каждого ребра укажите семантику владения и событие, которое разрывает связь. Проверьте deinit и Memory Graph.$md$,35,10),
('arc-memory','closure-task-lifetimes','Closure, Task и lifetime',
$md$# Lifetime асинхронной работы

Task может удерживать захваченные значения до завершения. weak self в начале долгой задачи часто превращается в strong self на весь период после guard let. Это не всегда leak, но может быть нежелательным продлением lifetime.

## Что обсуждают на senior-интервью

Кто владеет Task handle, кто вызывает cancel, где проверяется cancellation, что происходит при исчезновении экрана и может ли callback записать устаревший результат.

Разберите stored closures, lazy closures, Timer, CADisplayLink, NotificationCenter и Combine subscriptions. Для каждого механизма назовите симметричную точку cleanup.

## Практика

Сделайте экран поиска с debounce и отменой предыдущего запроса. Докажите, что старый результат не перезапишет новый, а view model освобождается после закрытия экрана.$md$,35,20),
('arc-memory','memory-diagnostics','Диагностика памяти и производительности',
$md$# Диагностика вместо догадок

Memory Graph помогает увидеть циклы и пути владения. Allocations показывает создание и lifetime объектов. Leaks ищет недостижимую память, но рост памяти не всегда является leak: это может быть cache, fragmentation или слишком большой working set.

## План расследования

Сначала зафиксируйте воспроизводимый сценарий и baseline на устройстве. Затем разделите постоянный рост, пиковое потребление и удержание объектов. Проверьте autorelease pools, изображения, decoded bitmap size, коллекции, mmap и системные кеши.

Сильный ответ включает метрики до и после исправления, а не только скриншот Instruments.

## Практика

Профилируйте бесконечный scroll feed. Измерьте число живых view models, decoded images и размер cache. Добавьте ограничение стоимости и повторите замер.$md$,35,30),

('concurrency','structured-concurrency','Structured concurrency и cancellation',
$md$# Structured concurrency

async let и TaskGroup связывают lifetime дочерней работы с родителем. Unstructured Task нужен, когда lifetime намеренно выходит за текущий scope, но тогда приложению нужен явный владелец и политика отмены.

## На интервью

Объясните cooperative cancellation: cancel не убивает код немедленно. Операция должна проверять Task.isCancelled, Task.checkCancellation или вызывать API, которое реагирует на отмену.

Сравните async let, task group, Task, detached task и continuation. Укажите наследование priority, task-local values и actor context. Detached task — не универсальный способ уйти с main thread.

## Практика

Параллельно загрузите десять ресурсов, ограничив concurrency тремя, сохранив исходный порядок и отменив оставшуюся работу после первой фатальной ошибки.$md$,45,10),
('concurrency','swift6-isolation-sendable','Swift 6 isolation и Sendable',
$md$# Swift 6 data-race safety

Swift 6 проверяет пересечение isolation boundaries. Sendable — семантическое обещание, что значение безопасно передавать между concurrency domains. Actor защищает своё mutable state, но не делает составную операцию атомарной через await.

## Обязательные темы

MainActor, actor isolation, global actors, nonisolated, Sendable, @Sendable closures, region-based isolation, sending parameters и риск @unchecked Sendable.

После каждого await перепроверяйте предположения: actor reentrancy позволяет другой задаче изменить состояние, пока текущая suspended.

## Практика

Спроектируйте token refresh actor. Параллельные запросы должны разделять один refresh, cancellation одного клиента не должна ломать остальных, а устаревший refresh не должен перезаписать новый token.

Официальная база: Swift 6 Concurrency Migration Guide — Data Race Safety.$md$,50,20),
('concurrency','backpressure-priority','Backpressure, priority и синхронизация',
$md$# Когда async недостаточно

Производитель может быть быстрее потребителя. Без backpressure очередь растёт, память увеличивается, а latency становится неограниченной. Нужны bounded buffers, batching, dropping/coalescing policy или ограничение concurrency.

## Priority и блокировки

Task priority — сигнал планировщику, а не гарантия порядка. Избегайте priority inversion и блокировки потоков, от которых зависит Swift concurrency runtime. Для коротких синхронных critical sections могут быть уместны lock или serial executor; для изолированного async state — actor.

## Практика

Разработайте pipeline обработки кадров камеры: максимум два кадра в очереди, устаревшие кадры можно выбрасывать, UI получает только последний завершённый результат.$md$,40,30),

('uikit-swiftui','uikit-lifecycle-layout','UIKit lifecycle, layout и reuse',
$md$# UIKit под нагрузкой

Разберите UIViewController lifecycle, view loading, containment, appearance callbacks и scene lifecycle. Объясните, почему viewDidLoad не означает появление на экране и почему повторная конфигурация должна быть идемпотентной.

## Layout

Auto Layout решает систему ограничений. Важны intrinsicContentSize, content hugging, compression resistance, ambiguous и unsatisfiable layouts, updateConstraints, layoutSubviews и offscreen sizing.

## Lists

Cell reuse требует отмены image task, сброса transient state и защиты от устаревшего результата. Diffable data source решает identity и snapshot updates, но не отменяет правильную модель данных.

## Практика

Спроектируйте feed cell с изображением, prefetch, отменой, placeholder и защитой от отображения картинки предыдущей модели.$md$,45,10),
('uikit-swiftui','swiftui-identity-observation','SwiftUI identity, state и Observation',
$md$# Как SwiftUI понимает изменения

SwiftUI пересчитывает body из state dependencies и сопоставляет элементы дерева по structural и explicit identity. Ошибочная identity уничтожает локальное состояние, ломает анимации или заставляет интерфейс обновляться слишком широко.

## Data flow

Разберите State, Binding, Environment, Observable macro и владение reference model. Observable отслеживает реально прочитанные свойства, но архитектурные границы и MainActor всё равно остаются ответственностью приложения.

## Частые ловушки

Создание model object внутри body, нестабильный id, AnyView без необходимости, тяжёлая работа в body, глобальный environment как service locator и side effects в вычислении представления.

## Практика

Объясните, почему список теряет состояние строки после сортировки. Исправьте identity и измерьте частоту обновлений через SwiftUI Instruments.$md$,45,20),
('uikit-swiftui','ui-performance-accessibility','Rendering, hitches и accessibility',
$md$# Производительность интерфейса

Кадр должен быть подготовлен до следующего display deadline. Hitches появляются, когда main thread занят, заблокирован или rendering pipeline получает слишком много работы.

## Инструменты

Используйте Time Profiler, Hitches, SwiftUI template, Core Animation и signposts. Профилируйте на устройстве. Отделяйте CPU, layout, image decoding, I/O, excessive updates и GPU overdraw.

Accessibility — часть качества: Dynamic Type, VoiceOver order, meaningful labels, contrast, touch targets и Reduce Motion должны учитываться в компоненте, а не добавляться после релиза.

## Практика

Исследуйте подвисание списка при первом scroll. Снимите trace, вынесите decoding и formatting из main actor, ограничьте prefetch и сравните метрики.$md$,40,30),

('architecture','modularity-dependencies','Модульность и направление зависимостей',
$md$# Архитектура для большой команды

Архитектура должна ускорять изменения. Начните с ownership, границ модулей, стабильных контрактов и направлений зависимостей. Название MVVM не решает циклические зависимости, shared mutable state и медленную сборку.

## Big Tech-фокус

Объясните feature modules, core/platform layers, dependency inversion, composition root, API/implementation targets и стратегию миграции без переписывания всего приложения.

У каждого модуля должны быть понятные публичные API, владелец, тестовая стратегия и правила observability.

## Практика

Разрежьте монолитный shopping app на модули так, чтобы checkout не зависел от конкретной аналитики, сети и UI корзины. Покажите composition root.$md$,45,10),
('architecture','state-navigation','State management и navigation',
$md$# Состояние как конечный автомат

Экран лучше моделировать конечным набором допустимых состояний, чем россыпью boolean-флагов. Loading вместе с error и content часто создаёт невозможные комбинации.

## Navigation

Coordinator, Router и NavigationStack решают разные уровни задачи. Deep link должен превращаться в валидный маршрут после авторизации и загрузки зависимостей. Restoration требует сериализуемой модели состояния.

## Практика

Спроектируйте flow login → catalog → product → checkout с deep link на product, требованием авторизации и восстановлением после termination.$md$,40,20),
('architecture','testing-observability','Тестирование и observability',
$md$# Проверяем не проценты покрытия

Unit tests защищают доменные инварианты. Integration tests проверяют реальные границы: сеть, база, сериализация и модули. UI tests оставляют для критических пользовательских цепочек. Contract tests защищают согласованность клиента и backend.

## Современный стек

Swift Testing подходит для новых unit tests, XCTest остаётся важным для UI и performance tests. Async-код тестируйте управляемыми clocks, fakes и явной cancellation, а не sleep.

Observability связывает логи, метрики, traces, signposts и crash reports общим request или operation ID. Не логируйте персональные данные и токены.

## Практика

Составьте test pyramid для offline checkout и определите, какие сбои должны ловиться до merge, на canary и после релиза.$md$,40,30),

('system-design','network-cache-offline','Networking, cache и offline-first',
$md$# Мобильный networking

URLSession поддерживает async/await, HTTP/2 и HTTP/3, cache policies и background transfers. Клиент обязан различать transport, HTTP, decoding и domain errors.

## Cache

Определите key, value, freshness, validation, capacity и eviction. Используйте HTTP validators, когда сервер поддерживает ETag и Last-Modified. Не превращайте retry в шторм: учитывайте idempotency, exponential backoff, jitter и Retry-After.

## Offline

Source of truth обычно находится в локальном хранилище, а сеть синхронизирует изменения. Нужны operation log, client IDs, conflict policy, tombstones и повторяемые операции.

## Практика

Спроектируйте offline редактирование заметок на двух устройствах. Опишите merge, удаление, конфликт и восстановление после частичной синхронизации.$md$,50,10),
('system-design','feed-media-pipeline','Feed, изображения и prefetch',
$md$# System design бесконечной ленты

Обсудите cursor pagination, deduplication, stable ordering, refresh, insertion новых элементов и поведение при offline. UI должен читать консистентный snapshot, а не склеивать страницы случайными append.

## Изображения

Разделите memory cache, disk cache, transport cache и decoded image cache. Учитывайте размер bitmap, downsampling, request coalescing, cancellation, prefetch budget и memory warning.

## Практика

Спроектируйте ленту на миллион пользователей: API contract, локальное хранилище, cache keys, pagination, обновление visible items, метрики latency и memory.$md$,50,20),
('system-design','reliability-release-metrics','Надёжность, релизы и метрики',
$md$# Production-мышление

Мобильный клиент живёт в мире старых версий, плохой сети, ограниченной батареи и необновляемого бинарника. Контракты backend должны быть backward compatible, миграции — поэтапными, а опасные функции — управляться server-driven flags.

## Метрики

Следите за crash-free users, hangs, launch time, frame hitches, memory termination, network success, p95/p99 latency и бизнес-конверсией. Среднее значение скрывает хвосты.

## Rollout

Используйте staged rollout, kill switch, schema compatibility и наблюдение по версии приложения. Любой remote config требует безопасных defaults и TTL.

## Практика

Опишите выпуск нового checkout: совместимость API, миграция локальных данных, эксперимент, rollback и критерии остановки rollout.$md$,45,30)
)
INSERT INTO lessons (topic_id,slug,title,body_markdown,duration_minutes,position,status)
SELECT tp.id,l.slug,l.title,l.body_markdown,l.duration_minutes,l.position,'published'
FROM lesson_data l
JOIN sections s ON s.slug=l.section_slug
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
JOIN topics tp ON tp.section_id=s.id AND tp.slug='main'
ON CONFLICT (topic_id,slug) DO UPDATE SET
 title=EXCLUDED.title,body_markdown=EXCLUDED.body_markdown,
 duration_minutes=EXCLUDED.duration_minutes,position=EXCLUDED.position,status='published',updated_at=now();

-- Enrich the original core/memory/concurrency questions instead of leaving
-- their explanations and reviewer answers empty.
WITH answer_data(prompt, explanation, reference_answer) AS (VALUES
($q$В чём практическая разница между value type и reference type в Swift?$q$,
$e$Проверьте семантику копирования, identity, shared mutable state и осознанный выбор модели, а не миф про stack и heap.$e$,
$a$Value type передаётся по значению: логически получатель получает независимое значение. Struct, enum, tuple и стандартные коллекции имеют value semantics; коллекции оптимизируют копирование через Copy-on-Write. Reference type имеет identity, несколько ссылок наблюдают один объект, а lifetime управляется ARC. Stack и heap — детали размещения, которые оптимизатор может менять, поэтому на них нельзя строить семантический ответ. Struct выбирают для данных и локальной мутации, final class — когда нужна общая identity или интеграция с reference API, actor — когда общей изменяемой state нужна concurrency isolation.$a$),
($q$Как ARC освобождает память и из-за чего возникает retain cycle?$q$,
$e$Сильный ответ должен построить граф strong-ссылок и назвать конкретное событие, которое разрывает каждое ребро.$e$,
$a$ARC вставляет retain и release на основе времени жизни strong references. Экземпляр класса деинициализируется, когда число strong references становится нулём. Cycle возникает, когда группа объектов или объект и сохранённое closure удерживают друг друга, поэтому ни один счётчик не достигает нуля. Исправление начинается с модели владения: обратную не-владеющую связь делают weak либо unowned при строгой гарантии lifetime, stored callback очищают после использования, Task и subscription отменяют владельцем. Проверка — deinit, Memory Graph и воспроизводимый lifecycle-сценарий.$a$),
($q$Когда использовать weak, а когда unowned ссылку?$q$,
$e$Кандидат должен рассуждать о lifetime и последствиях нарушения инварианта.$e$,
$a$weak используют, когда связанный объект может исчезнуть раньше: ссылка optional и автоматически становится nil. unowned используют, когда объект гарантированно живёт не меньше владельца ссылки; ссылка обычно non-optional, но обращение после deallocation завершится runtime error. Для delegate типично weak. Для объекта, который по доменной модели всегда принадлежит более долгоживущему parent, возможен unowned. Если гарантию сложно доказать или она меняется при асинхронной работе, безопаснее weak с явной обработкой отсутствия.$a$),
($q$Чем Task, async let и TaskGroup отличаются друг от друга?$q$,
$e$Ищем понимание structured lifetime, отмены, динамического fan-out и порядка результатов.$e$,
$a$async let создаёт фиксированное число child tasks в lexical scope; результат нужно await, а при выходе незавершённая работа отменяется и ожидается. TaskGroup создаёт динамическое число child tasks, позволяет получать результаты в порядке завершения и реализовывать bounded parallelism. Task создаёт unstructured task: её lifetime не связан автоматически с текущим scope, поэтому handle, cancellation и ошибки должен контролировать явный владелец. Все три наследуют контекст по-разному; detached Task дополнительно отрывается от actor context и task-local values и нужен редко.$a$),
($q$Чем protocol witness table отличается от dynamic dispatch через Objective-C runtime?$q$,
$e$Важны разные механизмы dispatch и последствия для оптимизации, а не только терминология.$e$,
$a$Для generic или existential-вызова требования Swift protocol реализация находится через witness table, связанную с конкретным conforming type. Компилятор может специализировать generic-код и устранить indirect call. Objective-C message dispatch отправляет selector объекту и ищет IMP через runtime class metadata и caches; он поддерживает swizzling и optional Objective-C requirements, но слабее оптимизируется. Вызов concrete final method может быть static dispatch, class method — vtable dispatch, а @objc dynamic принудительно использует Objective-C messaging.$a$),
($q$Как Copy-on-Write работает в стандартных коллекциях Swift?$q$,
$e$Нужно описать observable semantics, проверку уникальности буфера и границы потокобезопасности.$e$,
$a$Две копии Array могут временно разделять reference-counted storage. Чтение не требует копии. Перед мутацией коллекция проверяет уникальность владения буфером; если buffer разделяется, создаётся копия, после чего изменяется уникальный storage. Поэтому присваивание обычно дёшево, а первая мутация одной из копий может быть O(n). CoW сохраняет value semantics, но не делает одновременную мутацию одной переменной из разных задач безопасной. Slice может удерживать большой исходный buffer, что важно для памяти.$a$),
($q$Почему escaping-замыкание может потребовать явного self?$q$,
$e$Проверяем связь синтаксиса с lifetime, а не знание правила компилятора наизусть.$e$,
$a$Escaping closure может выполниться после возврата функции и сохранить захваченные объекты. Явный self делает потенциальное удержание экземпляра заметным и заставляет выбрать capture semantics. По умолчанию self захватывается strongly. Если объект хранит это closure, может возникнуть cycle. Но weak self не является универсальным решением: операция иногда должна удерживать владельца до завершения. Нужно определить владельца closure, срок его хранения, cancellation и момент очистки.$a$),
($q$Чем actor отличается от serial DispatchQueue?$q$,
$e$Хороший ответ сравнивает isolation model, suspension и reentrancy.$e$,
$a$Actor — языковая граница изоляции: компилятор проверяет доступ к actor-isolated state, переход требует await, а значения на границе должны удовлетворять правилам Sendable. Serial queue — runtime-механизм последовательного выполнения блоков без статической проверки владения данными. Actor reentrant: во время await другая задача может войти и изменить состояние, поэтому последовательность до и после await не атомарна. Queue sync может блокировать поток и создать deadlock; actor suspension освобождает поток. Для короткой синхронной защиты legacy state queue может быть уместна, но для async domain state actor выражает инварианты лучше.$a$),
($q$Что такое Sendable и какие проблемы он помогает обнаружить?$q$,
$e$Нужно сформулировать semantic contract и границу concurrency domains.$e$,
$a$Sendable означает, что значение безопасно передавать между concurrency domains без риска конкурентного доступа к незащищённому mutable state. Value types могут быть Sendable, если их поля Sendable. Immutable final class также может соответствовать требованиям; actor Sendable по своей модели изоляции. @unchecked Sendable отключает проверку и перекладывает доказательство на разработчика, поэтому требует реальной синхронизации и документации. Swift 6 использует Sendable вместе с actor isolation и анализом transfer, чтобы превращать потенциальные data races в compile-time diagnostics.$a$),
($q$Как устроена обработка ошибок через throws, Result и async throws?$q$,
$e$Оцениваем моделирование доменных причин, cancellation и границы API.$e$,
$a$throws даёт линейный control flow и автоматически сочетается с async. Result полезен как сохраняемое значение, для callback API или композиции результата вне текущего стека вызова. async throws — основной контракт асинхронной операции, а CancellationError нельзя бездумно превращать в обычную network error. На инфраструктурной границе URL, HTTP, decoding и transport errors классифицируют, затем переводят в небольшой доменный набор. Retry допустим только для transient и безопасных или идемпотентных операций. Ошибка должна сохранить диагностическую причину, но публичный API не обязан раскрывать детали транспорта.$a$)
)
UPDATE questions q SET explanation=a.explanation,reference_answer=a.reference_answer,updated_at=now()
FROM answer_data a
WHERE q.prompt=a.prompt
  AND EXISTS (
    SELECT 1 FROM topics tp
    JOIN sections s ON s.id=tp.section_id
    JOIN tracks tr ON tr.id=s.track_id
    JOIN directions d ON d.id=tr.direction_id
    WHERE tp.id=q.topic_id AND d.slug='ios' AND tr.slug='interview'
  );

-- New Swift Core and ARC questions. Positions start at 101 so the original
-- baseline remains first while the advanced bank can grow independently.
WITH question_data(section_slug, position, difficulty, prompt, explanation, reference_answer) AS (VALUES
('swift-core',101,3,
$q$Как Optional может представляться без дополнительного байта и когда это невозможно?$q$,
$e$Вопрос проверяет понимание enum layout и spare bits без требования помнить ABI-таблицы.$e$,
$a$Optional — enum из none и some(Wrapped). Для многих типов runtime использует недопустимые или свободные bit patterns Wrapped как discriminator: nil object pointer, spare bits выровненного указателя или неиспользуемые значения payload. Тогда размер Optional может совпадать с Wrapped. Если у payload нет свободных представлений, нужен дополнительный discriminator и padding с учётом alignment. Конкретный layout зависит от ABI и resilience, поэтому приложение не должно полагаться на него без документированного interop-контракта.$a$),
('swift-core',102,3,
$q$Сравните any Protocol, some Protocol и generic-параметр T: Protocol.$q$,
$e$Нужно объяснить сохранение concrete type, возможности API и runtime-cost.$e$,
$a$Generic T сохраняет concrete type на каждом вызове, поддерживает связи между типами и может специализироваться. some Protocol скрывает concrete type от клиента, но производитель возвращает один конкретный тип, что сохраняет static identity и оптимизацию. any Protocol — existential box, который может хранить значения разных conforming types; вызов требований идёт через witness table и иногда требует boxing. Existential удобен для heterogeneous storage и runtime composition, generic — для алгоритмов и type relationships, opaque — для сокрытия реализации без стирания типа.$a$),
('swift-core',103,4,
$q$Когда generic specialization не произойдёт и почему это важно для производительности?$q$,
$e$Проверяем способность обсуждать границы модулей, resilience и измерения.$e$,
$a$Специализация зависит от видимости реализации и concrete type, режима оптимизации, resilience boundary и решения optimizer. Код из другого модуля без подходящей сериализации body может остаться shared generic implementation с metadata и witness-table arguments. @inlinable расширяет доступную optimizer информацию, но становится частью ABI-контракта и ограничивает внутренние ссылки. Специализация увеличивает code size, поэтому не всегда выгодна. Вывод подтверждают SIL, binary size и profiling, а не предположение, что любой generic всегда быстрее existential.$a$),
('swift-core',104,4,
$q$Как реализовать type erasure для протокола с associated type и какую цену это создаёт?$q$,
$e$Ожидается box или closure-based стирание и честный анализ компромиссов.$e$,
$a$Создают concrete wrapper, который фиксирует нужные associated types и хранит либо абстрактный box с virtual methods, либо closures для операций. Wrapper скрывает исходный conforming type и даёт единый тип коллекции. Цена — дополнительный слой indirection, возможный heap allocation, потеря части static relationships и сложнее diagnostics. В современном Swift сначала проверяют, достаточно ли any Protocol с primary associated types или generic composition. Type erasure оправдан на API boundary или для heterogeneous storage, но не должен быть рефлексом.$a$),
('swift-core',105,4,
$q$Что гарантирует exclusivity of access и почему два inout к одному значению опасны?$q$,
$e$Кандидат должен связать inout с временным эксклюзивным доступом и overlapping access.$e$,
$a$Во время modifying access к памяти не должен пересекаться другой read или modify access, если он конфликтует. inout концептуально даёт функции временный эксклюзивный доступ; реализация может использовать copy-in/copy-out, но семантика запрещает overlapping mutation. Передача одной переменной в два inout-параметра или чтение свойства self во время mutating access может быть диагностировано compile-time или runtime. Это правило защищает value semantics и позволяет оптимизации, но не заменяет synchronization между concurrency domains.$a$),
('swift-core',106,3,
$q$Какие требования Hashable нельзя нарушать при использовании модели как ключа Dictionary?$q$,
$e$Проверяется invariant equality/hash и опасность мутации ключа.$e$,
$a$Если a == b, их hash(into:) обязан дать одинаковый результат в рамках одного процесса. Обратное не требуется: collisions допустимы. Поля, участвующие в equality, должны согласованно участвовать в hash. Нельзя менять identity-поля объекта, пока он логически используется как ключ: bucket был выбран по старому hash, и lookup станет некорректным. Hasher намеренно рандомизирован между запусками, поэтому hashValue нельзя сохранять на диск или передавать по сети.$a$),
('swift-core',107,3,
$q$Как выбрать между enum с associated values, protocol hierarchy и class hierarchy для state machine?$q$,
$e$Нужен анализ closed/open world, exhaustive switching и shared implementation.$e$,
$a$Enum хорош для закрытого конечного множества состояний: compiler проверяет exhaustive switch, associated values хранят данные конкретного состояния и исключают невозможные комбинации. Protocol hierarchy подходит для открытого набора реализаций и независимого расширения, но exhaustive анализ теряется. Class hierarchy добавляет identity, inheritance и shared mutable state, поэтому оправдана только при таких требованиях. Для feature state обычно enum плюс чистый reducer яснее; на framework boundary может понадобиться protocol.$a$),
('swift-core',108,4,
$q$Чем escaping, non-escaping, autoclosure и @Sendable closure отличаются по контракту?$q$,
$e$Проверяем четыре независимых измерения closure type.$e$,
$a$Non-escaping closure не переживает вызов и даёт optimizer больше свободы; escaping может сохраняться и требует явного lifetime/capture анализа. autoclosure автоматически заворачивает выражение и нужен для ленивой ergonomics, но чрезмерное использование скрывает control flow. @Sendable обещает, что closure можно безопасно выполнять в другом concurrency domain, и ограничивает захваты правилами Sendable. Эти атрибуты комбинируются: closure может быть escaping и @Sendable, а autoclosure не означает асинхронность или потокобезопасность.$a$),
('swift-core',109,4,
$q$Как эволюционировать Codable-модель, когда backend добавляет, переименовывает и удаляет поля?$q$,
$e$Ответ должен учитывать backward/forward compatibility и domain mapping.$e$,
$a$Неизвестные поля Decodable обычно игнорирует, поэтому добавление server fields безопасно. Новое обязательное client field ломает старые payloads — нужен default, optional или custom decoding. Переименование поддерживают чтением старого и нового key на переходный период. DTO отделяют от domain model, чтобы wire compatibility не заражала бизнес-логику. Dates, numbers и polymorphic payloads требуют явной стратегии. Encode и decode версии тестируют fixtures разных поколений, а удаление поля согласуют с минимально поддерживаемой версией клиента.$a$),
('swift-core',110,5,
$q$Что такое library evolution в Swift и как resilience влияет на public struct и enum?$q$,
$e$Это уровень сильного senior/staff-кандидата: ABI, @frozen и future cases.$e$,
$a$При library evolution клиент не должен зависеть от текущего layout public non-frozen struct или полного набора cases non-frozen enum, потому что библиотека может измениться без перекомпиляции клиента. Доступ к полям идёт через resilient metadata/accessors, а switch из внешнего модуля должен учитывать unknown default. @frozen фиксирует layout или cases как ABI contract и улучшает оптимизацию, но навсегда ограничивает совместимую эволюцию. Для app-internal модулей это обычно не нужно; для binary framework решение принимают осознанно.$a$),

('arc-memory',101,3,
$q$Зачем нужен autoreleasepool в Swift-приложении, если память управляется ARC?$q$,
$e$Проверяем interop с Objective-C и управление временными пиками.$e$,
$a$ARC управляет Swift strong references, но Objective-C/Cocoa API могут возвращать autoreleased objects, живущие до drain текущего pool. В длинном цикле обработки изображений или файлов временные объекты могут накопиться и создать высокий peak memory. Внутренний autoreleasepool вокруг одной итерации сокращает lifetime таких temporaries. Это не лечение retain cycle и не должно использоваться вслепую: сначала profiling, затем локальная граница там, где виден autorelease growth.$a$),
('arc-memory',102,4,
$q$Как zeroing weak reference работает концептуально и почему weak-доступ не бесплатный?$q$,
$e$Не требуется реализация runtime, но нужна корректная модель side table и синхронизации.$e$,
$a$Runtime должен знать все weak references на объект и атомарно обнулить их при deinitialization. Концептуально это требует дополнительной metadata или side table и синхронизированного weak load/store, чтобы чтение не получило уже уничтоженный объект. Поэтому weak access может быть дороже обычного strong access и не является performance-neutral контейнером. Детали runtime меняются; для архитектуры важны optional semantics, отсутствие владения и корректный lifetime.$a$),
('arc-memory',103,3,
$q$Почему delegate обычно объявляют weak и когда это решение будет неправильным?$q$,
$e$Оцениваем ownership, а не следование шаблону.$e$,
$a$Обычно владелец компонента создаёт его и назначает себя delegate, поэтому component не должен владеть владельцем — иначе возникает cycle. weak выражает эту модель и допускает исчезновение delegate. Но если delegate является отдельным объектом без другого strong owner, он немедленно деинициализируется и callbacks пропадут. Тогда нужен явный владелец или другая семантика composition. Protocol для weak property должен быть class-bound, а callbacks обязаны корректно переживать nil.$a$),
('arc-memory',104,4,
$q$Какие retain cycle типичны для Timer, CADisplayLink и NotificationCenter?$q$,
$e$Нужно назвать владельцев и симметричный cleanup.$e$,
$a$Scheduled Timer удерживается run loop и часто strongly удерживает target или closure; если controller удерживает timer, получается cycle. CADisplayLink имеет похожую target-модель и должен invalidated. Block-based NotificationCenter возвращает token, center удерживает observer closure, а closure может удержать self; token нужно удалить или связать с корректным lifetime. Selector-based observers в современных системах безопаснее при deallocation, но бизнес-lifecycle всё равно может требовать remove. Решение: explicit owner, weak proxy/capture при верной семантике и invalidate/remove в предсказуемой точке.$a$),
('arc-memory',105,4,
$q$Почему guard let self внутри Task может неожиданно продлить жизнь экрана?$q$,
$e$Проверяем lifetime захвата через suspension points.$e$,
$a$Task closure сначала может захватить self weakly, но guard let self создаёт strong local reference. Если эта переменная живёт через долгие await, экран удерживается до завершения Task. Это не cycle, если Task когда-нибудь завершится, но нежелательный lifetime и side effects после закрытия возможны. Лучше определить owner Task handle, отменять в lifecycle, проверять cancellation и захватывать только необходимые Sendable values. Иногда self должен жить до атомарного короткого шага — решение зависит от операции.$a$),
('arc-memory',106,4,
$q$Чем capture [value] отличается от обращения к value внутри closure без capture list?$q$,
$e$Ищем момент вычисления capture и различие value/reference semantics.$e$,
$a$Элемент capture list value = expression вычисляется в момент создания closure и сохраняет полученное значение. Для value type это snapshot по value semantics, хотя внутренний CoW storage может разделяться до мутации. Обычный capture локальной var использует общий capture box, чтобы closure видел последующие изменения, если переменная мутируется. Для reference type capture list копирует ссылку, а не объект, поэтому состояние объекта остаётся общим. weak и unowned применяются только к class references и меняют владение.$a$),
('arc-memory',107,5,
$q$Как отличить memory leak, memory growth, cache growth и fragmentation?$q$,
$e$Сильный ответ строит эксперимент и использует несколько инструментов.$e$,
$a$Leak — память, которая больше не нужна, но остаётся достижимой из-за владения, либо недостижимая native allocation. Growth может быть ожидаемым working set или накоплением состояния. Cache должен иметь измеримый hit rate, cost limit и eviction; если после pressure не уменьшается, это дефект политики. Fragmentation означает, что allocator не может вернуть или переиспользовать разбросанные blocks несмотря на освобождения. Сравнивают repeated scenario, live object counts, allocation backtraces, dirty/resident memory, VM regions и поведение после cleanup/memory warning. Один граф общего footprint причину не доказывает.$a$),
('arc-memory',108,4,
$q$Почему Substring может удерживать память большой исходной String?$q$,
$e$Проверяем slice semantics и hidden retention.$e$,
$a$Substring — представление диапазона исходной String и может разделять её storage, чтобы slicing был дешёвым. Если сохранить короткий Substring надолго, большой исходный buffer может остаться жив. На долговременной границе, например в model или cache, создают самостоятельную String(substring). Аналогичная мысль применима к ArraySlice и другим views. Нужно измерять реальную retention, но помнить, что маленькое логическое значение не гарантирует маленький retained storage.$a$),
('arc-memory',109,4,
$q$Как спроектировать image memory cache с NSCache и не получить memory spike?$q$,
$e$Нужны cost, downsampling, in-flight deduplication и pressure policy.$e$,
$a$В NSCache задают totalCostLimit и передают cost decoded bitmap примерно width × height × bytesPerPixel, а не размер JPEG. Изображение downsample до target display size до помещения в cache. Request key включает URL и transform. Одновременные запросы coalesce, prefetch ограничен, cell cancellation удаляет waiter. NSCache может сам evict values и не является persistent source of truth. При memory warning можно сбросить всё; hit rate, decode latency и footprint измеряют на устройстве.$a$),
('arc-memory',110,5,
$q$Как ownership Core Foundation объектов связан с ARC при bridging?$q$,
$e$Проверяем Create/Copy rule и transferred ownership.$e$,
$a$Core Foundation следует Create/Copy rule: функции с Create или Copy обычно возвращают owned reference, которую нужно release или передать ARC. Unmanaged и bridging annotations выражают transfer. takeRetainedValue принимает уже принадлежащее вызывающему владение и передаёт его ARC; takeUnretainedValue не добавляет владение и требует, чтобы объект жил достаточно долго. Ошибка выбора даёт leak или use-after-free. В обычном toll-free bridge компилятор часто знает annotations, но для C API контракт нужно читать точно.$a$)
)
INSERT INTO questions (topic_id,prompt,explanation,reference_answer,difficulty,position,status)
SELECT tp.id,q.prompt,q.explanation,q.reference_answer,q.difficulty,q.position,'published'
FROM question_data q
JOIN sections s ON s.slug=q.section_slug
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
JOIN topics tp ON tp.section_id=s.id AND tp.slug='main'
WHERE NOT EXISTS (SELECT 1 FROM questions existing WHERE existing.topic_id=tp.id AND existing.prompt=q.prompt);

-- Live coding: Swift Core and ARC. Each program has a deterministic console
-- contract so the backend can verify behavior with hidden tests.
WITH task_data(section_slug,slug,title,statement_markdown,hint,starter_code,reference_solution,difficulty,position) AS (VALUES
('swift-core','merge-overlapping-intervals','Объединение интервалов',
$md$Первая строка содержит интервалы start end через точку с запятой. Объедините все пересекающиеся и соприкасающиеся интервалы за O(n log n). Выведите результат в том же формате, отсортированным по start.

Пример: 1 3;2 6;8 10 → 1 6;8 10.$md$,
$md$Сначала отсортируйте по start, затем расширяйте последний добавленный интервал.$md$,
$swift$import Foundation

struct Interval {
    var start: Int
    var end: Int
}

func merge(_ intervals: [Interval]) -> [Interval] {
    // Реализуйте алгоритм
    return []
}

let line = readLine() ?? ""
let intervals = line.split(separator: ";").compactMap { part -> Interval? in
    let values = part.split(separator: " ").compactMap { Int($0) }
    guard values.count == 2 else { return nil }
    return Interval(start: values[0], end: values[1])
}
let answer = merge(intervals)
print(answer.map { "\($0.start) \($0.end)" }.joined(separator: ";"))$swift$,
$solution$import Foundation

struct Interval {
    var start: Int
    var end: Int
}

func merge(_ intervals: [Interval]) -> [Interval] {
    let sorted = intervals.sorted {
        $0.start == $1.start ? $0.end < $1.end : $0.start < $1.start
    }
    var result: [Interval] = []
    for item in sorted {
        guard let last = result.last else {
            result.append(item)
            continue
        }
        if item.start <= last.end {
            result[result.count - 1].end = max(last.end, item.end)
        } else {
            result.append(item)
        }
    }
    return result
}

let line = readLine() ?? ""
let intervals = line.split(separator: ";").compactMap { part -> Interval? in
    let values = part.split(separator: " ").compactMap { Int($0) }
    guard values.count == 2 else { return nil }
    return Interval(start: values[0], end: values[1])
}
let answer = merge(intervals)
print(answer.map { "\($0.start) \($0.end)" }.joined(separator: ";"))$solution$,3,201),

('swift-core','top-k-frequent-deterministic','Top K частых элементов',
$md$В первой строке даны целые числа через пробел, во второй — k. Верните k наиболее частых значений. При одинаковой частоте меньшее число должно идти раньше.

Требуемая сложность — лучше полной сортировки исходного массива.$md$,
$md$Сначала постройте частоты. Сортировать можно только уникальные значения.$md$,
$swift$import Foundation

func topKFrequent(_ values: [Int], k: Int) -> [Int] {
    // Реализуйте функцию
    return []
}

let values = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let k = Int(readLine() ?? "") ?? 0
print(topKFrequent(values, k: k).map(String.init).joined(separator: " "))$swift$,
$solution$import Foundation

func topKFrequent(_ values: [Int], k: Int) -> [Int] {
    var frequency: [Int: Int] = [:]
    for value in values {
        frequency[value, default: 0] += 1
    }
    return frequency.keys.sorted {
        let left = frequency[$0] ?? 0
        let right = frequency[$1] ?? 0
        return left == right ? $0 < $1 : left > right
    }.prefix(max(0, k)).map { $0 }
}

let values = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let k = Int(readLine() ?? "") ?? 0
print(topKFrequent(values, k: k).map(String.init).joined(separator: " "))$solution$,3,202),

('swift-core','longest-unique-substring','Самая длинная подстрока без повторов',
$md$Прочитайте строку и выведите длину самой длинной непрерывной подстроки без повторяющихся Character. Решение должно работать за O(n) и корректно обрабатывать Unicode Character.$md$,
$md$Храните последний индекс каждого Character и левую границу sliding window.$md$,
$swift$import Foundation

func longestUniqueLength(_ text: String) -> Int {
    // Реализуйте sliding window
    return 0
}

print(longestUniqueLength(readLine() ?? ""))$swift$,
$solution$import Foundation

func longestUniqueLength(_ text: String) -> Int {
    var lastIndex: [Character: Int] = [:]
    var left = 0
    var best = 0
    for (right, character) in text.enumerated() {
        if let previous = lastIndex[character], previous >= left {
            left = previous + 1
        }
        lastIndex[character] = right
        best = max(best, right - left + 1)
    }
    return best
}

print(longestUniqueLength(readLine() ?? ""))$solution$,3,203),

('arc-memory','weak-observer-store','Хранилище weak-наблюдателей',
$md$ObserverStore не должен продлевать lifetime подписчиков. Исправьте реализацию так, чтобы после освобождения первого observer событие получил только второй. Хранилище также должно удалять пустые weak slots.$md$,
$md$Массив protocol-значений удерживает observers strongly. Нужен class-bound protocol и weak box.$md$,
$swift$import Foundation

protocol EventObserver: AnyObject {
    func receive()
}

final class Observer: EventObserver {
    let name: String
    init(_ name: String) { self.name = name }
    func receive() { print(name) }
}

final class ObserverStore {
    private var observers: [EventObserver] = []

    func add(_ observer: EventObserver) {
        observers.append(observer)
    }

    func notify() {
        observers.forEach { $0.receive() }
    }
}

let store = ObserverStore()
var first: Observer? = Observer("first")
var second: Observer? = Observer("second")
store.add(first!)
store.add(second!)
first = nil
store.notify()
second = nil$swift$,
$solution$import Foundation

protocol EventObserver: AnyObject {
    func receive()
}

final class Observer: EventObserver {
    let name: String
    init(_ name: String) { self.name = name }
    func receive() { print(name) }
}

private final class WeakObserver {
    weak var value: EventObserver?
    init(_ value: EventObserver) { self.value = value }
}

final class ObserverStore {
    private var observers: [WeakObserver] = []

    func add(_ observer: EventObserver) {
        observers.append(WeakObserver(observer))
    }

    func notify() {
        observers = observers.filter { $0.value != nil }
        observers.forEach { $0.value?.receive() }
    }
}

let store = ObserverStore()
var first: Observer? = Observer("first")
var second: Observer? = Observer("second")
store.add(first!)
store.add(second!)
first = nil
store.notify()
second = nil$solution$,3,201),

('arc-memory','break-stored-closure-cycle','Разрыв цикла stored closure',
$md$Worker сохраняет completion, а completion захватывает Worker. Исправьте lifetime так, чтобы после выполнения работы объект освобождался и программа печатала released.$md$,
$md$Определите, должен ли callback владеть Worker. После одноразового вызова callback можно очистить.$md$,
$swift$import Foundation

final class Worker {
    var completion: (() -> Void)?
    private var finished = false

    func start() {
        completion = {
            self.finished = true
        }
        completion?()
    }

    deinit { print("released") }
}

func run() {
    var worker: Worker? = Worker()
    worker?.start()
    worker = nil
}

run()$swift$,
$solution$import Foundation

final class Worker {
    var completion: (() -> Void)?
    private var finished = false

    func start() {
        completion = { [weak self] in
            self?.finished = true
            self?.completion = nil
        }
        completion?()
    }

    deinit { print("released") }
}

func run() {
    var worker: Worker? = Worker()
    worker?.start()
    worker = nil
}

run()$solution$,3,202),

('arc-memory','custom-copy-on-write','Собственный Copy-on-Write буфер',
$md$ValueBuffer должен иметь value semantics, но две копии сейчас меняют общий Storage. Реализуйте ensureUnique через isKnownUniquelyReferenced и вызывайте его перед мутацией.

Ожидаемый вывод: 1 9.$md$,
$md$Проверяйте уникальность ссылки на Storage до записи и копируйте values только при необходимости.$md$,
$swift$import Foundation

final class Storage {
    var values: [Int]
    init(_ values: [Int]) { self.values = values }
}

struct ValueBuffer {
    private var storage: Storage
    init(_ values: [Int]) { storage = Storage(values) }

    subscript(index: Int) -> Int {
        get { storage.values[index] }
        set {
            // Обеспечьте уникальный Storage перед мутацией
            storage.values[index] = newValue
        }
    }
}

var first = ValueBuffer([1, 2, 3])
var second = first
second[0] = 9
print(first[0], second[0])$swift$,
$solution$import Foundation

final class Storage {
    var values: [Int]
    init(_ values: [Int]) { self.values = values }
}

struct ValueBuffer {
    private var storage: Storage
    init(_ values: [Int]) { storage = Storage(values) }

    private mutating func ensureUnique() {
        if !isKnownUniquelyReferenced(&storage) {
            storage = Storage(storage.values)
        }
    }

    subscript(index: Int) -> Int {
        get { storage.values[index] }
        set {
            ensureUnique()
            storage.values[index] = newValue
        }
    }
}

var first = ValueBuffer([1, 2, 3])
var second = first
second[0] = 9
print(first[0], second[0])$solution$,4,203)
)
INSERT INTO coding_tasks
(topic_id,slug,title,statement_markdown,hint,language,starter_code,reference_solution,time_limit_ms,memory_limit_kb,difficulty,position,status)
SELECT tp.id,t.slug,t.title,t.statement_markdown,t.hint,'swift',t.starter_code,t.reference_solution,
       3000,128000,t.difficulty,t.position,'published'
FROM task_data t
JOIN sections s ON s.slug=t.section_slug
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
JOIN topics tp ON tp.section_id=s.id AND tp.slug='main'
ON CONFLICT (topic_id,slug) DO UPDATE SET
 title=EXCLUDED.title,statement_markdown=EXCLUDED.statement_markdown,hint=EXCLUDED.hint,
 starter_code=EXCLUDED.starter_code,reference_solution=EXCLUDED.reference_solution,
 difficulty=EXCLUDED.difficulty,position=EXCLUDED.position,status='published',updated_at=now();

WITH test_data(task_slug,stdin,expected_stdout,position) AS (VALUES
('merge-overlapping-intervals',$in$1 3;2 6;8 10;15 18
$in$,$out$1 6;8 10;15 18
$out$,1),
('merge-overlapping-intervals',$in$1 4;4 5;10 12;11 15
$in$,$out$1 5;10 15
$out$,2),
('top-k-frequent-deterministic',$in$1 1 1 2 2 3
2
$in$,$out$1 2
$out$,1),
('top-k-frequent-deterministic',$in$4 4 5 5 6 6 7
3
$in$,$out$4 5 6
$out$,2),
('longest-unique-substring',$in$abcabcbb
$in$,$out$3
$out$,1),
('longest-unique-substring',$in$абвгба
$in$,$out$4
$out$,2),
('weak-observer-store',$in$$in$,$out$second
$out$,1),
('break-stored-closure-cycle',$in$$in$,$out$released
$out$,1),
('custom-copy-on-write',$in$$in$,$out$1 9
$out$,1)
)
INSERT INTO coding_task_tests (coding_task_id,stdin,expected_stdout,hidden,position)
SELECT ct.id,t.stdin,t.expected_stdout,true,t.position
FROM test_data t
JOIN coding_tasks ct ON ct.slug=t.task_slug
JOIN topics tp ON tp.id=ct.topic_id
JOIN sections s ON s.id=tp.section_id
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
WHERE NOT EXISTS (
 SELECT 1 FROM coding_task_tests existing
 WHERE existing.coding_task_id=ct.id AND existing.position=t.position
);

-- Live coding: architecture and mobile system design.
WITH task_data(section_slug,slug,title,statement_markdown,hint,starter_code,reference_solution,difficulty,position) AS (VALUES
('architecture','module-build-order','Порядок сборки модулей',
$md$Модули перечислены как Module:Dependency1,Dependency2 через точку с запятой. Выведите лексикографически минимальный корректный порядок сборки, в котором dependency идёт раньше consumer. Если есть цикл, выведите CYCLE.

Оцените сложность через V и E.$md$,
$md$Постройте indegree consumer и adjacency dependency → consumers, затем примените алгоритм Кана.$md$,
$swift$import Foundation

func buildOrder(_ specification: String) -> [String]? {
    // Верните nil при цикле
    return []
}

if let order = buildOrder(readLine() ?? "") {
    print(order.joined(separator: " "))
} else {
    print("CYCLE")
}$swift$,
$solution$import Foundation

func buildOrder(_ specification: String) -> [String]? {
    var dependencies: [String: Set<String>] = [:]
    for segment in specification.split(separator: ";", omittingEmptySubsequences: false) {
        let parts = segment.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard let modulePart = parts.first else { continue }
        let module = String(modulePart)
        guard !module.isEmpty else { continue }
        let deps = parts.count == 2
            ? Set(parts[1].split(separator: ",").map(String.init).filter { !$0.isEmpty })
            : []
        dependencies[module, default: []].formUnion(deps)
        for dep in deps { dependencies[dep, default: []] = dependencies[dep, default: []] }
    }

    var indegree = Dictionary(uniqueKeysWithValues: dependencies.map { ($0.key, $0.value.count) })
    var consumers: [String: [String]] = [:]
    for (module, deps) in dependencies {
        for dep in deps { consumers[dep, default: []].append(module) }
    }
    var ready = indegree.filter { $0.value == 0 }.map { $0.key }.sorted()
    var result: [String] = []
    while !ready.isEmpty {
        let module = ready.removeFirst()
        result.append(module)
        for consumer in (consumers[module] ?? []).sorted() {
            indegree[consumer, default: 0] -= 1
            if indegree[consumer] == 0 {
                ready.append(consumer)
                ready.sort()
            }
        }
    }
    return result.count == dependencies.count ? result : nil
}

if let order = buildOrder(readLine() ?? "") {
    print(order.joined(separator: " "))
} else {
    print("CYCLE")
}$solution$,4,201),

('architecture','authenticated-deep-link','Deep link через авторизацию',
$md$Первая строка — authenticated или anonymous. Вторая — /product/ID либо /product/ID/checkout. Третья строка для anonymous — login-success или login-cancel.

Сначала выведите каждый реально показанный экран: login, product ID, checkout ID или home. Pending destination после успешного login должна восстановиться.$md$,
$md$Парсите URL в типизированный Route и храните pending route, а не произвольную строку действия.$md$,
$swift$import Foundation

enum Route {
    case product(String)
    case checkout(String)
}

func parseRoute(_ path: String) -> Route? {
    // Реализуйте безопасный parser
    return nil
}

func screens(authenticated: Bool, route: Route, loginResult: String?) -> [String] {
    // Реализуйте auth gate и pending destination
    return []
}

let authenticated = (readLine() ?? "") == "authenticated"
let path = readLine() ?? ""
let loginResult = authenticated ? nil : readLine()
if let route = parseRoute(path) {
    screens(authenticated: authenticated, route: route, loginResult: loginResult).forEach { print($0) }
} else {
    print("home")
}$swift$,
$solution$import Foundation

enum Route {
    case product(String)
    case checkout(String)
}

func parseRoute(_ path: String) -> Route? {
    let parts = path.split(separator: "/").map(String.init)
    guard parts.count >= 2, parts[0] == "product", !parts[1].isEmpty else { return nil }
    if parts.count == 2 { return .product(parts[1]) }
    if parts.count == 3, parts[2] == "checkout" { return .checkout(parts[1]) }
    return nil
}

func description(_ route: Route) -> String {
    switch route {
    case .product(let id): return "product \(id)"
    case .checkout(let id): return "checkout \(id)"
    }
}

func screens(authenticated: Bool, route: Route, loginResult: String?) -> [String] {
    if authenticated { return [description(route)] }
    guard case .checkout = route else { return [description(route)] }
    if loginResult == "login-success" { return ["login", description(route)] }
    return ["login", "home"]
}

let authenticated = (readLine() ?? "") == "authenticated"
let path = readLine() ?? ""
let loginResult = authenticated ? nil : readLine()
if let route = parseRoute(path) {
    screens(authenticated: authenticated, route: route, loginResult: loginResult).forEach { print($0) }
} else {
    print("home")
}$solution$,4,202),

('architecture','retry-policy-state-machine','Retry policy как state machine',
$md$В строке перечислены outcomes попыток: timeout, 500, 502, 429:N, 400 или 200. Максимум четыре попытки.

После transient error выведите retry DELAY, где delay начинается с 1 и удваивается; 429:N использует N. Для 200 выведите success, для permanent ошибки — stop CODE, после исчерпания — failed.$md$,
$md$Не повторяйте 4xx, кроме явно поддержанного 429. Retry-After важнее локального backoff.$md$,
$swift$import Foundation

func evaluate(_ outcomes: [String], maxAttempts: Int) -> [String] {
    // Реализуйте policy
    return []
}

let outcomes = (readLine() ?? "").split(separator: " ").map(String.init)
evaluate(outcomes, maxAttempts: 4).forEach { print($0) }$swift$,
$solution$import Foundation

func evaluate(_ outcomes: [String], maxAttempts: Int) -> [String] {
    var log: [String] = []
    var backoff = 1
    for (index, outcome) in outcomes.prefix(maxAttempts).enumerated() {
        if outcome == "200" {
            log.append("success")
            return log
        }
        if outcome.hasPrefix("429:") {
            let delay = Int(outcome.split(separator: ":").last ?? "") ?? backoff
            if index + 1 < maxAttempts {
                log.append("retry \(delay)")
                continue
            }
            break
        }
        if outcome == "timeout" || outcome.hasPrefix("5") {
            if index + 1 < maxAttempts {
                log.append("retry \(backoff)")
                backoff *= 2
                continue
            }
            break
        }
        log.append("stop \(outcome)")
        return log
    }
    log.append("failed")
    return log
}

let outcomes = (readLine() ?? "").split(separator: " ").map(String.init)
evaluate(outcomes, maxAttempts: 4).forEach { print($0) }$solution$,4,203),

('system-design','merge-cursor-pages','Слияние cursor-страниц',
$md$Страницы ID разделены символом |, элементы внутри страницы — пробелами. Объедините страницы, сохранив первое появление каждого ID и глобальный порядок. Выведите итоговую последовательность.

Решение должно быть O(n) по числу элементов.$md$,
$md$Используйте Set для уже добавленных ID и массив для стабильного порядка.$md$,
$swift$import Foundation

func mergePages(_ pages: [[String]]) -> [String] {
    // Реализуйте стабильную дедупликацию
    return []
}

let pages = (readLine() ?? "").split(separator: "|").map {
    $0.split(separator: " ").map(String.init)
}
print(mergePages(pages).joined(separator: " "))$swift$,
$solution$import Foundation

func mergePages(_ pages: [[String]]) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []
    for page in pages {
        for id in page where seen.insert(id).inserted {
            result.append(id)
        }
    }
    return result
}

let pages = (readLine() ?? "").split(separator: "|").map {
    $0.split(separator: " ").map(String.init)
}
print(mergePages(pages).joined(separator: " "))$solution$,3,201),

('system-design','ttl-lru-cache','LRU-кэш с TTL',
$md$Первая строка — capacity. Вторая содержит команды через точку с запятой:

PUT key value now ttl
GET key now

GET печатает value либо MISS. Просроченная запись считается отсутствующей. Операции должны быть O(1), eviction удаляет least recently used запись.$md$,
$md$Соедините Dictionary с двусвязным списком. Expiry проверяйте до move-to-front.$md$,
$swift$import Foundation

final class LRUCache {
    init(capacity: Int) {
        // Инициализация
    }

    func put(key: String, value: String, now: Int, ttl: Int) {
        // Добавление и eviction
    }

    func get(key: String, now: Int) -> String? {
        // TTL и LRU
        return nil
    }
}

let capacity = Int(readLine() ?? "") ?? 0
let cache = LRUCache(capacity: capacity)
let commands = (readLine() ?? "").split(separator: ";").map {
    $0.split(separator: " ").map(String.init)
}
for command in commands {
    if command.first == "PUT", command.count == 5 {
        cache.put(key: command[1], value: command[2], now: Int(command[3]) ?? 0, ttl: Int(command[4]) ?? 0)
    } else if command.first == "GET", command.count == 3 {
        print(cache.get(key: command[1], now: Int(command[2]) ?? 0) ?? "MISS")
    }
}$swift$,
$solution$import Foundation

private final class Node {
    let key: String
    var value: String
    var expiry: Int
    weak var previous: Node?
    var next: Node?

    init(key: String, value: String, expiry: Int) {
        self.key = key
        self.value = value
        self.expiry = expiry
    }
}

final class LRUCache {
    private let capacity: Int
    private var nodes: [String: Node] = [:]
    private var head: Node?
    private var tail: Node?

    init(capacity: Int) {
        self.capacity = max(0, capacity)
    }

    private func remove(_ node: Node) {
        if let previous = node.previous { previous.next = node.next } else { head = node.next }
        if let next = node.next { next.previous = node.previous } else { tail = node.previous }
        node.previous = nil
        node.next = nil
    }

    private func insertAtHead(_ node: Node) {
        node.next = head
        node.previous = nil
        head?.previous = node
        head = node
        if tail == nil { tail = node }
    }

    private func touch(_ node: Node) {
        remove(node)
        insertAtHead(node)
    }

    func put(key: String, value: String, now: Int, ttl: Int) {
        guard capacity > 0 else { return }
        if let node = nodes[key] {
            node.value = value
            node.expiry = now + ttl
            touch(node)
        } else {
            let node = Node(key: key, value: value, expiry: now + ttl)
            nodes[key] = node
            insertAtHead(node)
        }
        while nodes.count > capacity, let victim = tail {
            remove(victim)
            nodes[victim.key] = nil
        }
    }

    func get(key: String, now: Int) -> String? {
        guard let node = nodes[key] else { return nil }
        if now >= node.expiry {
            remove(node)
            nodes[key] = nil
            return nil
        }
        touch(node)
        return node.value
    }
}

let capacity = Int(readLine() ?? "") ?? 0
let cache = LRUCache(capacity: capacity)
let commands = (readLine() ?? "").split(separator: ";").map {
    $0.split(separator: " ").map(String.init)
}
for command in commands {
    if command.first == "PUT", command.count == 5 {
        cache.put(key: command[1], value: command[2], now: Int(command[3]) ?? 0, ttl: Int(command[4]) ?? 0)
    } else if command.first == "GET", command.count == 3 {
        print(cache.get(key: command[1], now: Int(command[2]) ?? 0) ?? "MISS")
    }
}$solution$,5,202),

('system-design','idempotent-outbox-replay','Идемпотентный replay outbox',
$md$В строке перечислены попытки доставки id=payload, включая повторы после потерянного ACK. Сервер должен применить side effect ровно один раз на id.

Для первой доставки выведите applied id=payload, для повторной — duplicate id. Если тот же id пришёл с другим payload, выведите conflict id.$md$,
$md$Храните результат первой операции по idempotency key и сравнивайте повторный payload.$md$,
$swift$import Foundation

func replay(_ deliveries: [(id: String, payload: String)]) -> [String] {
    // Реализуйте idempotent consumer
    return []
}

let deliveries = (readLine() ?? "").split(separator: " ").compactMap { token -> (String, String)? in
    let parts = token.split(separator: "=", maxSplits: 1).map(String.init)
    return parts.count == 2 ? (parts[0], parts[1]) : nil
}
replay(deliveries).forEach { print($0) }$swift$,
$solution$import Foundation

func replay(_ deliveries: [(id: String, payload: String)]) -> [String] {
    var applied: [String: String] = [:]
    var log: [String] = []
    for delivery in deliveries {
        if let previous = applied[delivery.id] {
            log.append(previous == delivery.payload ? "duplicate \(delivery.id)" : "conflict \(delivery.id)")
        } else {
            applied[delivery.id] = delivery.payload
            log.append("applied \(delivery.id)=\(delivery.payload)")
        }
    }
    return log
}

let deliveries = (readLine() ?? "").split(separator: " ").compactMap { token -> (String, String)? in
    let parts = token.split(separator: "=", maxSplits: 1).map(String.init)
    return parts.count == 2 ? (parts[0], parts[1]) : nil
}
replay(deliveries).forEach { print($0) }$solution$,4,203)
)
INSERT INTO coding_tasks
(topic_id,slug,title,statement_markdown,hint,language,starter_code,reference_solution,time_limit_ms,memory_limit_kb,difficulty,position,status)
SELECT tp.id,t.slug,t.title,t.statement_markdown,t.hint,'swift',t.starter_code,t.reference_solution,
       4000,128000,t.difficulty,t.position,'published'
FROM task_data t
JOIN sections s ON s.slug=t.section_slug
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
JOIN topics tp ON tp.section_id=s.id AND tp.slug='main'
ON CONFLICT (topic_id,slug) DO UPDATE SET
 title=EXCLUDED.title,statement_markdown=EXCLUDED.statement_markdown,hint=EXCLUDED.hint,
 starter_code=EXCLUDED.starter_code,reference_solution=EXCLUDED.reference_solution,
 time_limit_ms=EXCLUDED.time_limit_ms,difficulty=EXCLUDED.difficulty,
 position=EXCLUDED.position,status='published',updated_at=now();

WITH test_data(task_slug,stdin,expected_stdout,position) AS (VALUES
('module-build-order',$in$App:Feed,Auth;Feed:Core;Auth:Core;Core:
$in$,$out$Core Auth Feed App
$out$,1),
('module-build-order',$in$A:B;B:C;C:A
$in$,$out$CYCLE
$out$,2),
('authenticated-deep-link',$in$anonymous
/product/42/checkout
login-success
$in$,$out$login
checkout 42
$out$,1),
('authenticated-deep-link',$in$anonymous
/product/42/checkout
login-cancel
$in$,$out$login
home
$out$,2),
('authenticated-deep-link',$in$authenticated
/product/7
$in$,$out$product 7
$out$,3),
('retry-policy-state-machine',$in$timeout 500 200
$in$,$out$retry 1
retry 2
success
$out$,1),
('retry-policy-state-machine',$in$429:5 502 400
$in$,$out$retry 5
retry 1
stop 400
$out$,2),
('retry-policy-state-machine',$in$500 500 500 500
$in$,$out$retry 1
retry 2
retry 4
failed
$out$,3),
('merge-cursor-pages',$in$a b c|c d e|e f a
$in$,$out$a b c d e f
$out$,1),
('merge-cursor-pages',$in$1 2|3 4|5
$in$,$out$1 2 3 4 5
$out$,2),
('ttl-lru-cache',$in$2
PUT a 1 0 5;PUT b 2 0 10;GET a 3;PUT c 3 4 10;GET b 5;GET a 6;GET c 6
$in$,$out$1
MISS
MISS
3
$out$,1),
('ttl-lru-cache',$in$1
PUT x one 0 2;GET x 1;GET x 2;PUT y two 3 5;GET y 7
$in$,$out$one
MISS
two
$out$,2),
('idempotent-outbox-replay',$in$m1=pay m2=mail m1=pay m3=push m2=mail
$in$,$out$applied m1=pay
applied m2=mail
duplicate m1
applied m3=push
duplicate m2
$out$,1),
('idempotent-outbox-replay',$in$x=v1 x=v2 x=v1
$in$,$out$applied x=v1
conflict x
duplicate x
$out$,2)
)
INSERT INTO coding_task_tests (coding_task_id,stdin,expected_stdout,hidden,position)
SELECT ct.id,t.stdin,t.expected_stdout,true,t.position
FROM test_data t
JOIN coding_tasks ct ON ct.slug=t.task_slug
JOIN topics tp ON tp.id=ct.topic_id
JOIN sections s ON s.id=tp.section_id
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
WHERE NOT EXISTS (
 SELECT 1 FROM coding_task_tests existing
 WHERE existing.coding_task_id=ct.id AND existing.position=t.position
);

-- Live coding: concurrency and UI state. These tasks stay console-based so
-- they run on the Linux Swift sandbox while exercising production iOS ideas.
WITH task_data(section_slug,slug,title,statement_markdown,hint,starter_code,reference_solution,difficulty,position) AS (VALUES
('concurrency','ordered-parallel-map','Параллельный map с сохранением порядка',
$md$Прочитайте целые числа, вычислите их квадраты параллельно и выведите в исходном порядке. Решение не должно содержать data race и должно дождаться всех операций.$md$,
$md$Свяжите результат с исходным index. Защитите общий массив короткой критической секцией.$md$,
$swift$import Foundation

func parallelSquares(_ values: [Int]) -> [Int] {
    // Реализуйте параллельное вычисление
    return []
}

let values = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
print(parallelSquares(values).map(String.init).joined(separator: " "))$swift$,
$solution$import Foundation

func parallelSquares(_ values: [Int]) -> [Int] {
    let queue = DispatchQueue(label: "squares", attributes: .concurrent)
    let group = DispatchGroup()
    let lock = NSLock()
    var result = Array(repeating: 0, count: values.count)

    for (index, value) in values.enumerated() {
        group.enter()
        queue.async {
            let square = value * value
            lock.lock()
            result[index] = square
            lock.unlock()
            group.leave()
        }
    }
    group.wait()
    return result
}

let values = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
print(parallelSquares(values).map(String.init).joined(separator: " "))$solution$,4,201),

('concurrency','bounded-parallelism','Ограничение параллелизма',
$md$Обработайте числа параллельно, но держите не более трёх активных работ. Каждая работа возвращает value × 2. Выведите результаты в исходном порядке.

Нельзя создавать отдельную serial queue, которая фактически уберёт параллелизм.$md$,
$md$Используйте semaphore как bounded permit, DispatchGroup для ожидания и index для порядка.$md$,
$swift$import Foundation

func boundedDouble(_ values: [Int], limit: Int) -> [Int] {
    // Реализуйте bounded parallelism
    return []
}

let values = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
print(boundedDouble(values, limit: 3).map(String.init).joined(separator: " "))$swift$,
$solution$import Foundation

func boundedDouble(_ values: [Int], limit: Int) -> [Int] {
    guard !values.isEmpty else { return [] }
    let queue = DispatchQueue(label: "bounded", attributes: .concurrent)
    let group = DispatchGroup()
    let semaphore = DispatchSemaphore(value: max(1, limit))
    let lock = NSLock()
    var result = Array(repeating: 0, count: values.count)

    for (index, value) in values.enumerated() {
        group.enter()
        queue.async {
            semaphore.wait()
            let output = value * 2
            lock.lock()
            result[index] = output
            lock.unlock()
            semaphore.signal()
            group.leave()
        }
    }
    group.wait()
    return result
}

let values = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
print(boundedDouble(values, limit: 3).map(String.init).joined(separator: " "))$solution$,4,202),

('concurrency','single-flight-loader','Single-flight загрузчик',
$md$В строке перечислены ключи запросов. Параллельные запросы одного ключа должны разделять одно вычисление. Для каждого входа выведите key:data в исходном порядке, затем строку fetches N — число реально начатых вычислений.$md$,
$md$Под lock храните массив waiters для каждого in-flight key. Completion вызывайте уже после выхода из lock.$md$,
$swift$import Foundation

final class SingleFlightLoader {
    // Реализуйте хранение in-flight запросов
    private(set) var fetchCount = 0

    func load(_ key: String, completion: @escaping (String) -> Void) {
        // Одинаковый key должен запускать вычисление один раз
    }
}

let keys = (readLine() ?? "").split(separator: " ").map(String.init)
let loader = SingleFlightLoader()
let group = DispatchGroup()
let lock = NSLock()
var output = Array(repeating: "", count: keys.count)
for (index, key) in keys.enumerated() {
    group.enter()
    loader.load(key) { value in
        lock.lock(); output[index] = value; lock.unlock()
        group.leave()
    }
}
group.wait()
print(output.joined(separator: " "))
print("fetches \(loader.fetchCount)")$swift$,
$solution$import Foundation

final class SingleFlightLoader {
    private let lock = NSLock()
    private var waiters: [String: [(String) -> Void]] = [:]
    private var count = 0

    var fetchCount: Int {
        lock.lock(); defer { lock.unlock() }
        return count
    }

    func load(_ key: String, completion: @escaping (String) -> Void) {
        lock.lock()
        if waiters[key] != nil {
            waiters[key]?.append(completion)
            lock.unlock()
            return
        }
        waiters[key] = [completion]
        count += 1
        lock.unlock()

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) { [weak self] in
            guard let self = self else { return }
            let value = "\(key):data"
            self.lock.lock()
            let callbacks = self.waiters.removeValue(forKey: key) ?? []
            self.lock.unlock()
            callbacks.forEach { $0(value) }
        }
    }
}

let keys = (readLine() ?? "").split(separator: " ").map(String.init)
let loader = SingleFlightLoader()
let group = DispatchGroup()
let outputLock = NSLock()
var output = Array(repeating: "", count: keys.count)
for (index, key) in keys.enumerated() {
    group.enter()
    loader.load(key) { value in
        outputLock.lock(); output[index] = value; outputLock.unlock()
        group.leave()
    }
}
group.wait()
print(output.joined(separator: " "))
print("fetches \(loader.fetchCount)")$solution$,5,203),

('uikit-swiftui','stable-list-diff','Diff списка со стабильными ID',
$md$Первая строка — старые ID, вторая — новые. Выведите удалённые ID, вставленные ID и перемещения общих элементов в формате id:old>new.

Порядок deleted следует старому списку, inserted и moved — новому.$md$,
$md$Постройте словари ID → index для обоих снимков.$md$,
$swift$import Foundation

struct ListDiff {
    let deleted: [String]
    let inserted: [String]
    let moved: [String]
}

func diff(old: [String], new: [String]) -> ListDiff {
    // Реализуйте diff по стабильным ID
    return ListDiff(deleted: [], inserted: [], moved: [])
}

let old = (readLine() ?? "").split(separator: " ").map(String.init)
let new = (readLine() ?? "").split(separator: " ").map(String.init)
let result = diff(old: old, new: new)
print("deleted " + result.deleted.joined(separator: " "))
print("inserted " + result.inserted.joined(separator: " "))
print("moved " + result.moved.joined(separator: " "))$swift$,
$solution$import Foundation

struct ListDiff {
    let deleted: [String]
    let inserted: [String]
    let moved: [String]
}

func diff(old: [String], new: [String]) -> ListDiff {
    let oldIndex = Dictionary(uniqueKeysWithValues: old.enumerated().map { ($0.element, $0.offset) })
    let newIndex = Dictionary(uniqueKeysWithValues: new.enumerated().map { ($0.element, $0.offset) })
    let deleted = old.filter { newIndex[$0] == nil }
    let inserted = new.filter { oldIndex[$0] == nil }
    let moved = new.compactMap { id -> String? in
        guard let from = oldIndex[id], let to = newIndex[id], from != to else { return nil }
        return "\(id):\(from)>\(to)"
    }
    return ListDiff(deleted: deleted, inserted: inserted, moved: moved)
}

let old = (readLine() ?? "").split(separator: " ").map(String.init)
let new = (readLine() ?? "").split(separator: " ").map(String.init)
let result = diff(old: old, new: new)
print("deleted " + result.deleted.joined(separator: " "))
print("inserted " + result.inserted.joined(separator: " "))
print("moved " + result.moved.joined(separator: " "))$solution$,4,201),

('uikit-swiftui','reusable-cell-generation','Защита reusable cell от старого ответа',
$md$События разделены точкой с запятой. bind ID привязывает cell к модели, complete ID IMAGE завершает загрузку. Применяйте изображение только если ID всё ещё текущий. Выведите каждое реально применённое значение как ID=IMAGE.$md$,
$md$Храните representedID и проверяйте его в completion перед изменением UI.$md$,
$swift$import Foundation

final class CellModel {
    private var representedID: String?

    func handle(_ event: [String]) -> String? {
        // Реализуйте bind и complete с generation guard
        return nil
    }
}

let events = (readLine() ?? "").split(separator: ";").map {
    $0.split(separator: " ").map(String.init)
}
let cell = CellModel()
for event in events {
    if let applied = cell.handle(event) {
        print(applied)
    }
}$swift$,
$solution$import Foundation

final class CellModel {
    private var representedID: String?

    func handle(_ event: [String]) -> String? {
        guard let kind = event.first else { return nil }
        if kind == "bind", event.count == 2 {
            representedID = event[1]
            return nil
        }
        if kind == "complete", event.count == 3, representedID == event[1] {
            return "\(event[1])=\(event[2])"
        }
        return nil
    }
}

let events = (readLine() ?? "").split(separator: ";").map {
    $0.split(separator: " ").map(String.init)
}
let cell = CellModel()
for event in events {
    if let applied = cell.handle(event) {
        print(applied)
    }
}$solution$,3,202),

('uikit-swiftui','screen-state-reducer','Reducer состояния экрана',
$md$Обработайте события через точку с запятой: load, success N, refresh, failure MESSAGE. После каждого события состояние должно оставаться допустимым.

Если refresh существующего content завершился ошибкой, сохраните content и пометьте его stale. Выведите финал: loaded N, loaded N stale MESSAGE, loading или failed MESSAGE.$md$,
$md$Используйте enum с associated values вместо независимых boolean-флагов.$md$,
$swift$import Foundation

enum State {
    case idle
    case loading
    case loaded(count: Int, staleError: String?)
    case failed(String)
}

func reduce(state: State, event: [String]) -> State {
    // Реализуйте переходы
    return state
}

func describe(_ state: State) -> String {
    // Верните строковое представление
    return ""
}

let events = (readLine() ?? "").split(separator: ";").map {
    $0.split(separator: " ").map(String.init)
}
var state: State = .idle
for event in events { state = reduce(state: state, event: event) }
print(describe(state))$swift$,
$solution$import Foundation

enum State {
    case idle
    case loading
    case loaded(count: Int, staleError: String?)
    case failed(String)
}

func reduce(state: State, event: [String]) -> State {
    guard let kind = event.first else { return state }
    switch kind {
    case "load":
        return .loading
    case "refresh":
        if case .loaded(let count, _) = state {
            return .loaded(count: count, staleError: nil)
        }
        return .loading
    case "success":
        return .loaded(count: event.count > 1 ? Int(event[1]) ?? 0 : 0, staleError: nil)
    case "failure":
        let message = event.dropFirst().joined(separator: " ")
        if case .loaded(let count, _) = state {
            return .loaded(count: count, staleError: message)
        }
        return .failed(message)
    default:
        return state
    }
}

func describe(_ state: State) -> String {
    switch state {
    case .idle: return "idle"
    case .loading: return "loading"
    case .failed(let message): return "failed \(message)"
    case .loaded(let count, let error):
        if let error = error { return "loaded \(count) stale \(error)" }
        return "loaded \(count)"
    }
}

let events = (readLine() ?? "").split(separator: ";").map {
    $0.split(separator: " ").map(String.init)
}
var state: State = .idle
for event in events { state = reduce(state: state, event: event) }
print(describe(state))$solution$,4,203)
)
INSERT INTO coding_tasks
(topic_id,slug,title,statement_markdown,hint,language,starter_code,reference_solution,time_limit_ms,memory_limit_kb,difficulty,position,status)
SELECT tp.id,t.slug,t.title,t.statement_markdown,t.hint,'swift',t.starter_code,t.reference_solution,
       4000,128000,t.difficulty,t.position,'published'
FROM task_data t
JOIN sections s ON s.slug=t.section_slug
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
JOIN topics tp ON tp.section_id=s.id AND tp.slug='main'
ON CONFLICT (topic_id,slug) DO UPDATE SET
 title=EXCLUDED.title,statement_markdown=EXCLUDED.statement_markdown,hint=EXCLUDED.hint,
 starter_code=EXCLUDED.starter_code,reference_solution=EXCLUDED.reference_solution,
 time_limit_ms=EXCLUDED.time_limit_ms,difficulty=EXCLUDED.difficulty,
 position=EXCLUDED.position,status='published',updated_at=now();

WITH test_data(task_slug,stdin,expected_stdout,position) AS (VALUES
('ordered-parallel-map',$in$1 2 3 4 5
$in$,$out$1 4 9 16 25
$out$,1),
('ordered-parallel-map',$in$-3 0 8
$in$,$out$9 0 64
$out$,2),
('bounded-parallelism',$in$1 2 3 4 5 6
$in$,$out$2 4 6 8 10 12
$out$,1),
('bounded-parallelism',$in$-2 0 9
$in$,$out$-4 0 18
$out$,2),
('single-flight-loader',$in$a a b a b
$in$,$out$a:data a:data b:data a:data b:data
fetches 2
$out$,1),
('single-flight-loader',$in$avatar feed config avatar
$in$,$out$avatar:data feed:data config:data avatar:data
fetches 3
$out$,2),
('stable-list-diff',$in$a b c
b d a
$in$,$out$deleted c
inserted d
moved b:1>0 a:0>2
$out$,1),
('stable-list-diff',$in$1 2 3
1 2 3
$in$,$out$deleted 
inserted 
moved 
$out$,2),
('reusable-cell-generation',$in$bind A;bind B;complete A old;complete B new
$in$,$out$B=new
$out$,1),
('reusable-cell-generation',$in$bind X;complete X first;bind Y;complete X stale;complete Y second
$in$,$out$X=first
Y=second
$out$,2),
('screen-state-reducer',$in$load;success 3;refresh;failure timeout
$in$,$out$loaded 3 stale timeout
$out$,1),
('screen-state-reducer',$in$load;failure offline
$in$,$out$failed offline
$out$,2)
)
INSERT INTO coding_task_tests (coding_task_id,stdin,expected_stdout,hidden,position)
SELECT ct.id,t.stdin,t.expected_stdout,true,t.position
FROM test_data t
JOIN coding_tasks ct ON ct.slug=t.task_slug
JOIN topics tp ON tp.id=ct.topic_id
JOIN sections s ON s.id=tp.section_id
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
WHERE NOT EXISTS (
 SELECT 1 FROM coding_task_tests existing
 WHERE existing.coding_task_id=ct.id AND existing.position=t.position
);



WITH question_data(section_slug, position, difficulty, prompt, explanation, reference_answer) AS (VALUES
('architecture',101,3,
$q$Почему MVVM сам по себе не является архитектурой приложения?$q$,
$e$Проверяем границы ответственности и системное мышление поверх названий паттернов.$e$,
$a$MVVM описывает в основном взаимодействие presentation state, view и view model. Он не определяет модульные границы, навигацию, ownership, data source of truth, networking/persistence contracts, dependency direction, observability и release strategy. Massive ViewModel так же плох, как Massive ViewController. Полная архитектура задаёт слои и feature boundaries, composition root, state model, error/cancellation policy и тестовые seams. MVVM может быть локальным presentation pattern внутри такой системы.$a$),
('architecture',102,4,
$q$Как разделить iOS-монолит на feature-модули без большого переписывания?$q$,
$e$Нужна эволюционная стратегия с измеримыми границами.$e$,
$a$Сначала строят dependency graph и выбирают feature с ясным ownership и небольшим числом входов. Выделяют contract target отдельно от implementation, ставят facade перед legacy-кодом и собирают всё в composition root. Переносят вертикальный slice вместе с тестами, запрещают новые обратные зависимости и измеряют build time/cycles. Shared-модули появляются только после нескольких реальных consumers. Миграция идёт strangler-подходом, а не созданием огромного Core, от которого зависит всё.$a$),
('architecture',103,4,
$q$Как моделировать экран, чтобы исключить комбинацию loading=true, error!=nil и content!=nil?$q$,
$e$Ожидается algebraic state machine вместо независимых flags.$e$,
$a$Используют enum State: idle, loading(previous?), loaded(Content), empty, failed(Error, previous?). Associated values хранят данные, допустимые только в этом состоянии. Events проходят через reducer или явные transition methods, где можно проверить generation и cancellation. Так compiler помогает exhaustive rendering и тестированию переходов. Отдельные orthogonal dimensions, например connectivity banner, можно композиционно хранить рядом, но не смешивать в один бесконечный enum.$a$),
('architecture',104,4,
$q$Как обработать deep link на checkout, если пользователь не авторизован?$q$,
$e$Проверяем route state machine, отложенное намерение и безопасность.$e$,
$a$URL сначала парсится в типизированный Route и валидируется. Router видит prerequisite auth и сохраняет pending destination как безопасные domain parameters, затем открывает login. После успеха повторно проверяет доступность товара/корзины и строит checkout flow; после отмены очищает pending route. Нельзя хранить произвольный URL и слепо исполнять. Navigation state должен поддерживать cold start, уже открытое приложение и несколько scenes. Analytics связывает исходный deep link с финальным outcome.$a$),
('architecture',105,5,
$q$Как выбрать scope зависимостей в DI-контейнере?$q$,
$e$Ищем lifetime, ownership и concurrency, а не singleton по умолчанию.$e$,
$a$App scope подходит stateless clients, shared database coordinator и configuration, если их thread safety доказана. Session scope хранит auth-bound state и уничтожается при logout. Feature scope владеет coordinator, state и tasks конкретного flow. Transient создаётся для одной операции. Scope не должен быть дольше данных, которые он удерживает. Composition root создаёт child scopes и явно завершает их. Глобальный singleton усложняет logout, multi-account, tests и parallel scenes.$a$),
('architecture',106,4,
$q$Когда Repository становится вредной абстракцией?$q$,
$e$Проверяем утечку lowest-common-denominator API и неправильное сокрытие возможностей хранилища.$e$,
$a$Generic CRUD Repository часто стирает важные semantics: transaction, pagination, observation, cache freshness и query capabilities. В результате interface разрастается или возвращает transport entities. Лучше определять use-case-oriented ports: ObserveCart, LoadFeedPage, CommitCheckout. Абстракция оправдана, если защищает domain от изменчивой инфраструктуры и даёт тестовый seam, но не обязана скрывать различия network и local store, которые влияют на correctness.$a$),
('architecture',107,5,
$q$Как гарантировать, что старый сетевой ответ не перезапишет новый state?$q$,
$e$Это практический вопрос на cancellation и logical ordering.$e$,
$a$Отмена предыдущего Task снижает работу, но response всё равно может завершиться. State owner хранит monotonically increasing generation, request ID или query key. Перед commit результата проверяет, что token совпадает с текущим запросом и feature ещё активна. Для actor проверка и запись выполняются в одном synchronous isolated segment. Если server даёт version/ETag, дополнительно соблюдают causal version. UI identity и cache также используют тот же normalized key.$a$),
('architecture',108,4,
$q$Как тестировать debounce, retry и timeout без sleep?$q$,
$e$Ожидаются инъецируемые Clock/Scheduler и детерминированное управление временем.$e$,
$a$Код зависит от минимального Clock или Scheduler contract, а production использует continuous clock. Test clock хранит scheduled sleeps и продвигается тестом вручную. Network fake возвращает запрограммированную последовательность ошибок. Тест проверяет число вызовов, delays, cancellation и итоговый state мгновенно и без flaky wall time. Random jitter получает seeded generator или injected strategy. Важно дать задачам выполнить queued continuation после advance.$a$),
('architecture',109,4,
$q$Какие данные нельзя писать в мобильные логи и как сохранить диагностичность?$q$,
$e$Проверяем privacy by design и structured observability.$e$,
$a$Не логируют access/refresh tokens, cookies, пароли, payment data, полные personal payloads и содержимое скрытых пользовательских документов. URL query и headers редактируют allowlist-подходом. Используют structured event names, operation/request ID, error category, latency, retry count и безопасные dimensions. User ID при необходимости pseudonymized и ограничен retention. Debug payload включается только контролируемо и не в production. Политика согласуется с privacy requirements и поддерживает удаление данных.$a$),
('architecture',110,5,
$q$Как внедрить новую архитектуру состояния, не останавливая разработку feature-команд?$q$,
$e$Staff-level вопрос на миграцию, совместимость и организационный rollout.$e$,
$a$Фиксируют target principles и anti-corruption adapter между legacy и new state. Выбирают один vertical slice, создают reference implementation и automated boundary checks. Старые features продолжают через compatibility facade, новые пишутся по новому пути. Метрики: lead time, defects, build time, test duration и количество обратных dependencies. Миграция имеет owner, RFC, examples и sunset criteria; нельзя одновременно переписать UI, network и persistence без промежуточно работающих состояний.$a$),

('system-design',101,4,
$q$Спроектируйте cursor pagination для ленты, в которую постоянно добавляются новые элементы.$q$,
$e$Нужны stable order, opaque cursor, refresh и deduplication.$e$,
$a$Server задаёт стабильный порядок, например rank plus immutable ID, и возвращает opaque cursor, кодирующий позицию snapshot. Клиент хранит page boundaries и deduplicates по item ID, но не сортирует несогласованно с server. Pull-to-refresh создаёт новый head snapshot; новые элементы можно показать banner, не сдвигая чтение пользователя. Удалённые элементы приходят tombstone или исчезают по version policy. Cursor может expire, тогда клиент делает controlled refresh. Метрики включают duplicates, gaps, page latency и stale age.$a$),
('system-design',102,4,
$q$Как использовать ETag и Cache-Control в iOS-клиенте?$q$,
$e$Проверяем HTTP semantics и роль URLCache.$e$,
$a$Cache-Control задаёт freshness и допустимость хранения. URLCache может обслужить свежий response без сети. Для stale entry клиент отправляет If-None-Match с ETag; 304 позволяет использовать cached body и обновить metadata, а 200 приносит новую representation. Cache policy не должна без причины игнорировать server headers. Authenticated или user-specific data требует корректных Vary/private directives и раздельных keys. App-level cache нужен для domain/offline semantics, которые transport cache не решает.$a$),
('system-design',103,5,
$q$Как построить offline outbox, устойчивый к crash между отправкой и сохранением ответа?$q$,
$e$Ожидается at-least-once delivery плюс idempotency на сервере.$e$,
$a$Локальная транзакция сохраняет domain change и operation с client-generated idempotency key. Worker отправляет operation; если приложение падает после server commit, но до local ack, повторит её. Сервер хранит key и возвращает прежний result без повторного side effect. Клиент применяет ack и удаляет/помечает operation транзакционно. Ordering задаётся только там, где домен требует; poison operation имеет retry budget и видимый failed state. Exactly-once transport недостижим, поэтому correctness строится на idempotency.$a$),
('system-design',104,4,
$q$Спроектируйте pipeline загрузки и отображения изображений в ленте.$q$,
$e$Проверяем полный путь: request, cache, decode, display, cancel.$e$,
$a$Normalized request key ищется в decoded memory cache, затем disk/URL cache. In-flight registry объединяет одинаковые запросы. Network task поддерживает priority и cancellation отдельных subscribers. Полученные bytes валидируются, сохраняются по policy и downsample/decode вне main actor до target pixel size. UI применяет image только при совпадении model ID. Prefetch ограничен видимым горизонтом и общим budget. Memory warning очищает decoded cache. Нужны hit-rate, download/decode latency, bytes, cancellation ratio и hitch metrics.$a$),
('system-design',105,5,
$q$Как загружать большое видео в фоне с возобновлением и прогрессом?$q$,
$e$Нужны background URLSession, multipart strategy и durable state.$e$,
$a$Файл сначала стабилизируют в app-owned location. Backend создаёт upload session и части с idempotent part IDs. Background URLSession выполняет file uploads, а приложение сохраняет session/task mapping и подтверждённые parts. После relaunch восстанавливает tasks через identifier и reconcile с server. Progress агрегируется по bytes, но UI учитывает неизвестный этап server processing. Retry ограничен и уважает connectivity/power policy. Финализация upload идемпотентна, checksum проверяет целостность, expired session безопасно пересоздаётся.$a$),
('system-design',106,4,
$q$Как предотвратить retry storm после массового восстановления сети?$q$,
$e$Проверяем exponential backoff, jitter, budgets и server signals.$e$,
$a$Каждая операция использует capped exponential backoff с full jitter, чтобы клиенты не синхронизировались. Retry budget ограничивает попытки и общую длительность. Клиент уважает Retry-After, app lifecycle и network cost. Очереди имеют priority и bounded concurrency, одинаковые refresh coalesce. Server может использовать token bucket и shed load. Неидемпотентные requests повторяются только с idempotency key. Метрики retries per success и herd events показывают проблему.$a$),
('system-design',107,5,
$q$Как сохранить совместимость API с приложениями, которые пользователи не обновляли год?$q$,
$e$Нужна additive evolution и план deprecation.$e$,
$a$Изменения делают additive: новые optional fields и endpoints, старые semantics не переиспользуют. Server поддерживает минимальные версии по наблюдаемой install base, а destructive change проходит новый version/contract. Клиент tolerant к неизвестным fields и enum cases там, где это предусмотрено. Remote config имеет safe defaults. Миграция: dual read/write или adapter, metrics по версиям, уведомление, затем sunset после явного порога. Auth/security fixes могут требовать forced update, но flow должен быть управляемым.$a$),
('system-design',108,5,
$q$Какие данные хранить в Keychain, базе и UserDefaults?$q$,
$e$Проверяем threat model и назначение каждого storage.$e$,
$a$Keychain — небольшие secrets и credentials с выбранной accessibility policy; это не база общего назначения. Database — структурированные domain data, offline cache и outbox, при необходимости с file/data protection и дополнительным шифрованием по threat model. UserDefaults — маленькие не-секретные preferences и feature flags, не токены и не большие blobs. Files — медиа и documents с correct protection class. Logout удаляет account-scoped secrets/data, а backup/migration policy определяется отдельно. Ни одно локальное хранилище не защищает от полностью скомпрометированного разблокированного устройства.$a$),
('system-design',109,4,
$q$Какие метрики вы поставите для cold launch и scrolling?$q$,
$e$Нужны user-perceived stages, percentiles и device segmentation.$e$,
$a$Cold launch разделяют pre-main, app initialization, first frame и time-to-interactive с signposts. Смотрят p50/p95/p99 по device class, OS и app version, а не только average. Для scrolling — hitch time ratio, long frames, main-thread utilization, image decode latency и memory footprint. MetricKit/Xcode Organizer дают production signal, Instruments — локальную причинность. Regression gate использует стабильный сценарий на реальном устройстве и сравнивает baseline.$a$),
('system-design',110,5,
$q$Спроектируйте мобильный чат с offline-отправкой, порядком сообщений и несколькими устройствами.$q$,
$e$Комплексный вопрос на IDs, sync cursor, optimistic UI и conflict policy.$e$,
$a$Клиент создаёт message ID и local sequence, атомарно пишет сообщение и outbox, сразу показывает pending state. Server idempotently принимает ID, назначает conversation sequence/server timestamp и рассылает событие. Клиент синхронизируется cursor-ом, deduplicates по ID и переставляет optimistic item по canonical order без потери identity. WebSocket даёт low latency, но после reconnect всегда нужен gap sync через HTTP. Edit/delete — versioned operations и tombstones. Attachments имеют отдельный upload lifecycle. Read receipts монотонны, encryption и push privacy проектируются отдельно.$a$)
)
INSERT INTO questions (topic_id,prompt,explanation,reference_answer,difficulty,position,status)
SELECT tp.id,q.prompt,q.explanation,q.reference_answer,q.difficulty,q.position,'published'
FROM question_data q
JOIN sections s ON s.slug=q.section_slug
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
JOIN topics tp ON tp.section_id=s.id AND tp.slug='main'
WHERE NOT EXISTS (SELECT 1 FROM questions existing WHERE existing.topic_id=tp.id AND existing.prompt=q.prompt);


WITH question_data(section_slug, position, difficulty, prompt, explanation, reference_answer) AS (VALUES
('concurrency',101,4,
$q$Почему actor не гарантирует атомарность операции, содержащей await?$q$,
$e$Ключевое слово — reentrancy: состояние может измениться в точке suspension.$e$,
$a$Actor сериализует синхронные участки actor-isolated code, но await может приостановить текущую задачу и освободить actor executor для другой. Когда исходная задача продолжится, состояние уже может быть другим. Поэтому read → await → write не является транзакцией. Инвариант сохраняют, выполняя критическое изменение без suspension, резервируя state до await, используя version/token и проверяя его после возврата, либо перенося внешний I/O за границу actor. Блокировать actor thread нельзя — это нарушает forward progress.$a$),
('concurrency',102,4,
$q$Как реализовать single-flight token refresh без дублирующих запросов?$q$,
$e$Проверяем actor state machine, shared task и cancellation semantics.$e$,
$a$Actor хранит current token и optional refresh Task. Первый caller создаёт Task и сохраняет handle; остальные получают тот же value через await. После завершения actor очищает handle только если он всё ещё относится к текущему generation, и атомарно обновляет token. Cancellation одного waiter не должна автоматически отменять shared refresh, если он нужен другим; для общей отмены нужен reference count или отдельная policy. Ошибку refresh классифицируют, а повторный 401 ограничивают, чтобы не получить бесконечный loop.$a$),
('concurrency',103,5,
$q$Когда @unchecked Sendable допустим и какое доказательство вы потребуете на code review?$q$,
$e$Ответ «когда компилятор ругается» является провалом.$e$,
$a$Допустим только когда тип действительно потокобезопасен, но compiler не способен проверить механизм: immutable state за C/Objective-C boundary, lock-protected fields или безопасный framework type без annotations. Review требует перечислить все mutable fields, единый synchronization domain, отсутствие утечки небезопасных references, правила callback и тесты под contention. Lock должен защищать составной invariant, а не отдельные properties. Annotation документируют рядом с доказательством. Для нового кода чаще лучше actor, immutable value type или global-actor isolation.$a$),
('concurrency',104,4,
$q$Чем Task.detached отличается от Task и почему detached редко нужен в приложении?$q$,
$e$Проверяем наследование actor context, priority и task-local values.$e$,
$a$Task наследует текущий priority, task-local values и actor isolation контекст создания. Task.detached создаёт unstructured task без этого контекста, поэтому захваты обязаны безопасно пересекать isolation boundary. Detached не означает «выполни на отдельном потоке» и не является способом исправить тяжёлую работу на MainActor. Он уместен для действительно независимой top-level работы с явным lifetime и Sendable inputs. В большинстве feature-flow правильнее child task, TaskGroup или отдельный actor/service.$a$),
('concurrency',105,4,
$q$Как корректно обернуть callback API через withCheckedContinuation?$q$,
$e$Нужно назвать exactly-once resume, cancellation и race между completion/cancel.$e$,
$a$Continuation должна resume ровно один раз на всех путях; отсутствие resume зависнет, двойной resume является ошибкой. Синхронный callback тоже должен поддерживаться. Checked variant помогает диагностировать misuse, но не решает cancellation. Для cancellable API используют withTaskCancellationHandler, хранят underlying token и синхронизируют race: completion и cancel не должны оба resume. Возвращаемые значения должны безопасно пересекать isolation. Если callback может выдавать много событий, continuation не подходит — нужен AsyncSequence.$a$),
('concurrency',106,4,
$q$Как ограничить TaskGroup до четырёх одновременных операций?$q$,
$e$Ожидается bounded scheduling, а не создание тысячи tasks и semaphore внутри.$e$,
$a$Сначала добавляют min(limit, input.count) child tasks. Каждый раз после получения next completed result добавляют следующую работу, пока input не закончится. Так число активных child tasks ограничено и нет тысячи suspended tasks, ожидающих semaphore. Результаты при необходимости складывают по исходному index. При первой fatal error group отменяет оставшихся, а child operations должны cooperative реагировать на cancellation. Для stream можно использовать actor/AsyncSequence с bounded buffer.$a$),
('concurrency',107,5,
$q$Что такое priority inversion в iOS и как её обнаружить?$q$,
$e$Нужны причина, инструменты и исправление без ручного повышения всего до high.$e$,
$a$Высокоприоритетная работа ждёт resource или lock, удерживаемый низкоприоритетной, которая не получает CPU из-за другой средней работы. Симптом — UI hang при вроде бы небольшой загрузке. Thread Performance Checker, Time Profiler, Hangs и signposts помогают увидеть wait chain. Исправления: сократить critical section, не делать I/O под lock, убрать синхронное ожидание main thread, правильно наследовать priority и применять priority donation поддерживаемыми primitives. Массовое userInitiated повышает contention и не лечит архитектуру.$a$),
('concurrency',108,5,
$q$Как избежать data race при callback из Objective-C API в Swift 6 strict concurrency?$q$,
$e$Проверяем isolation hop и работу с non-Sendable framework objects.$e$,
$a$Сначала определить, на какой queue приходит callback и какой domain должен владеть результатом. UI state изолируют MainActor и делают явный hop через Task { @MainActor in ... }. Mutable non-Sendable object нельзя просто захватить в @Sendable closure; его преобразуют в immutable Sendable snapshot на исходной границе либо оборачивают проверенным actor/lock adapter. Для framework API используют корректные annotations или @preconcurrency как временную миграционную меру, но не скрывают реальную гонку. Lifetime и cancellation callback token остаются явными.$a$),
('concurrency',109,4,
$q$Как спроектировать AsyncSequence с backpressure для частых событий?$q$,
$e$Нужно выбрать buffering policy исходя из смысла данных.$e$,
$a$Сначала определить, допустима ли потеря. Для sensor latest-value можно bufferingNewest(1); для audit events потеря недопустима и нужен bounded durable queue или замедление producer. Unbounded buffer опасен памятью и latency. onTermination обязан отменить subscription и освободить resources. Producer и continuation access синхронизируют по контракту API. Consumer cancellation должна закрыть pipeline. Метрики queue depth, dropped events и processing latency подтверждают policy.$a$),
('concurrency',110,5,
$q$Почему actor с одним огромным состоянием может стать bottleneck и как его декомпозировать?$q$,
$e$Ищем contention domains, sharding и сохранение инвариантов.$e$,
$a$Все actor-isolated операции конкурируют за один executor, даже если касаются независимых keys. Длинный synchronous work блокирует остальные messages. State делят по независимым инвариантам: actor per account/document, sharded actors по key, immutable snapshots для read-heavy data, внешние pure computations вне actor. Нельзя дробить invariant, который требует атомарного обновления нескольких частей, без coordinator или transaction protocol. Решение подтверждают queueing latency и profiling, а не количеством actors.$a$),

('uikit-swiftui',101,3,
$q$В каком порядке использовать viewDidLoad, viewWillAppear и viewDidAppear?$q$,
$e$Проверяем повторяемость lifecycle и разделение setup от side effects.$e$,
$a$viewDidLoad вызывается после загрузки view и подходит для одноразовой сборки hierarchy, bindings и статической конфигурации. viewWillAppear вызывается перед каждым появлением и подходит для синхронизации отображаемого state и navigation UI. viewDidAppear — после завершения появления; здесь запускают работу, требующую реально видимого экрана, аналитику impression или presentation. Все appearance callbacks могут повторяться. Долгую работу не блокируют на main thread, а subscriptions и tasks имеют явный lifetime.$a$),
('uikit-swiftui',102,4,
$q$Почему reusable cell иногда показывает изображение предыдущей модели и как это исправить?$q$,
$e$Нужны cancellation, identity check и cache strategy.$e$,
$a$Асинхронный запрос, начатый для старой модели, завершается после reuse и записывает результат в ту же cell. В prepareForReuse отменяют cell-owned task, сбрасывают image и transient state. При configure сохраняют representedID; перед применением результата проверяют ID. Лучше image loader coalesces requests и возвращает cancellable token, а cache key учитывает transform. Prefetch также отменяется. Сам indexPath не является стабильной identity после diff.$a$),
('uikit-swiftui',103,4,
$q$Что происходит при конфликте Auto Layout priorities 1000, 999 и intrinsic size?$q$,
$e$Проверяем solver priorities и роль hugging/compression resistance.$e$,
$a$Required constraints priority 1000 должны быть совместимы; при конфликте система логирует unsatisfiable layout и ломает одно constraint, но выбор не следует считать стабильным. Optional 999 может быть нарушено, чтобы удовлетворить required. Intrinsic size добавляет не одно обязательное равенство, а ограничения через content hugging и compression resistance priorities. Поэтому label может растянуться или сжаться в зависимости от этих значений. Priority 999 часто используют как controlled failure point, но layout всё равно нужно тестировать для локализаций и Dynamic Type.$a$),
('uikit-swiftui',104,4,
$q$Чем diffable data source улучшает обновление списка и какие проблемы не решает?$q$,
$e$Нужно отделить identity snapshot от загрузки данных и производительности cell.$e$,
$a$Diffable data source принимает snapshot стабильных item identifiers, вычисляет изменения и избегает неконсистентных ручных batch updates. Он упрощает insert/delete/move и анимации. Но не решает неправильную identity, thread safety модели, image cancellation, тяжёлый cell configuration, pagination merge или слишком большой snapshot. Snapshot строят из консистентного state, применяют на требуемом executor и измеряют стоимость для больших наборов. Reconfigure/reload выбирают по характеру изменения.$a$),
('uikit-swiftui',105,4,
$q$Почему ForEach по индексам ломает состояние SwiftUI-строк после удаления?$q$,
$e$Проверяется explicit identity и reconciliation.$e$,
$a$Индекс описывает позицию, а не сущность. После удаления все последующие индексы сдвигаются, SwiftUI сопоставляет local state, focus или animation с другой моделью. Нужно использовать стабильный domain ID, который не меняется при сортировке и не генерируется заново в body. Если равные value могут представлять разные сущности, self как ID тоже неверен. Index допустим для действительно статической позиционной коллекции без независимого состояния элементов.$a$),
('uikit-swiftui',106,4,
$q$Когда использовать State, Binding, Environment и Observable model?$q$,
$e$Ответ должен начинаться с ownership и source of truth.$e$,
$a$State — локальный source of truth, которым владеет view identity. Binding даёт дочернему view чтение и запись чужого state без владения. Environment передаёт ambient dependency или model по иерархии, но чрезмерное использование скрывает requirements. Observable reference model подходит для разделяемого mutable feature state; владелец создаёт его в стабильной точке и учитывает actor isolation. Derived values не дублируют в state. Выбор wrapper следует ownership и lifetime, а не желанию заставить UI обновиться.$a$),
('uikit-swiftui',107,5,
$q$Как Observation macro меняет invalidation по сравнению с ObservableObject?$q$,
$e$Ищем property access tracking и ограничения модели.$e$,
$a$Observable macro добавляет observation instrumentation, а SwiftUI формирует dependencies на properties, прочитанные во время body. Изменение непрочитанного свойства не обязано invalidated этот view, что может сузить updates по сравнению с objectWillChange ObservableObject. Модель всё равно должна создаваться и передаваться с правильным ownership; Observation не делает её Sendable и не выбирает actor. Для iOS до 17 нужна стратегия совместимости. Частоту updates подтверждают SwiftUI Instruments.$a$),
('uikit-swiftui',108,5,
$q$Как диагностировать scroll hitches в SwiftUI или UICollectionView?$q$,
$e$Ожидается измеримый план: device, Instruments, signposts, decomposition.$e$,
$a$Воспроизводят на целевом устройстве и записывают Hitches/Time Profiler, SwiftUI или Core Animation trace. Смотрят main-thread stacks в длинном frame, layout, body updates, image decode, formatting, I/O и GPU overdraw. Добавляют signposts вокруг model mapping, image pipeline и snapshot apply. Затем выносят pure CPU/I/O с main actor, downsample images, уменьшают invalidation scope, кешируют дорогие вычисления и ограничивают prefetch. Сравнивают hitch count и frame duration до/после.$a$),
('uikit-swiftui',109,4,
$q$Как спроектировать Dynamic Type без сломанного layout?$q$,
$e$Проверяется accessibility-first layout, а не только UIFontMetrics.$e$,
$a$Используют semantic text styles и scalable custom fonts через UIFontMetrics. Не фиксируют высоту текстовых контейнеров, допускают multiline, корректно задают compression resistance и перестраивают horizontal layout в vertical на accessibility sizes. Проверяют локализации, bold text, VoiceOver order и minimum touch targets. Изображения и controls сохраняют смысл при увеличении. Snapshot/UI tests прогоняют несколько content size categories, но финальная проверка проводится на устройстве.$a$),
('uikit-swiftui',110,5,
$q$Что происходит между изменением state и появлением нового кадра на экране?$q$,
$e$Это вопрос на целостное понимание UI pipeline.$e$,
$a$State change invalidates зависимые представления. Framework планирует update в run loop, вычисляет новое описание UI, reconciles identity и применяет изменения к platform view/layout/render tree. Auto Layout или SwiftUI layout вычисляют geometry, затем слои commit в render server; GPU compositing выдаёт frame к display deadline. Main-thread work, layout, decoding или слишком поздний commit создают hitch. Точный pipeline различается по framework и версии, поэтому кандидат должен показать причинную цепочку и инструменты, а не обещать конкретный приватный порядок.$a$)
)
INSERT INTO questions (topic_id,prompt,explanation,reference_answer,difficulty,position,status)
SELECT tp.id,q.prompt,q.explanation,q.reference_answer,q.difficulty,q.position,'published'
FROM question_data q
JOIN sections s ON s.slug=q.section_slug
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
JOIN topics tp ON tp.section_id=s.id AND tp.slug='main'
WHERE NOT EXISTS (SELECT 1 FROM questions existing WHERE existing.topic_id=tp.id AND existing.prompt=q.prompt);



WITH answer_data(prompt, explanation, reference_answer) AS (VALUES
($q$Какие этапы проходит Auto Layout при вычислении и применении размеров?$q$,
$e$Проверьте понимание constraint solving, intrinsic size и layout pass, а не перечень callback.$e$,
$a$Ограничения и intrinsicContentSize формируют систему уравнений и неравенств с priorities. UIKit вызывает updateConstraints для обновления constraints, затем layout pass вычисляет frames и вызывает layoutSubviews по иерархии. Intrinsic size участвует через content hugging и compression resistance. Изменение, влияющее на constraints, требует setNeedsUpdateConstraints; геометрия — setNeedsLayout; layoutIfNeeded синхронно выполняет отложенный layout в нужной иерархии. Ambiguous layout имеет несколько решений, unsatisfiable — конфликт обязательных constraints, после чего система ломает одно и логирует проблему.$a$),
($q$Как SwiftUI определяет, какую часть дерева представлений нужно обновить?$q$,
$e$Ищем связь dependencies, identity, body evaluation и rendering, без мифа про полный redraw.$e$,
$a$При вычислении body SwiftUI регистрирует зависимости от State, Environment и observable data. После изменения соответствующей зависимости invalidated view пересчитывает body. Новое value-дерево сопоставляется с предыдущим по structural и explicit identity, после чего framework обновляет только нужные platform views и rendering state. Пересчёт body не равен перерисовке всего экрана. Нестабильный id может уничтожить local state и вызвать лишние операции. Тяжёлую работу нельзя делать в body; частоту и длительность updates измеряют SwiftUI Instruments и Hitches.$a$),
($q$Когда выбрать struct, final class или actor для новой модели?$q$,
$e$Ответ должен исходить из semantics, ownership и concurrency requirements.$e$,
$a$Struct выбирают для value semantics, независимых снимков и локальной мутации. final class нужен для shared identity, lifecycle, интеграции с reference-only framework или когда копирование значения концептуально неверно. actor нужен, когда нескольким задачам требуется общий mutable state и его инварианты можно изолировать одним executor. Actor не нужен для immutable service без state, а class с @MainActor уместен для UI-owned state. Решение также учитывает API ergonomics, Sendable, тестируемость и стоимость копирования, но не должно строиться на упрощении «struct на stack, class на heap».$a$),
($q$Как организовать dependency injection без глобального service locator?$q$,
$e$Проверяем composition root, явные зависимости и scope объектов.$e$,
$a$Зависимости передаются через init или фабрики, а concrete implementations собираются в composition root приложения или feature. Модуль публикует минимальные contracts, не зная контейнер и соседние реализации. Долгоживущие зависимости создаются на app scope, feature state — на feature scope, transient objects — по запросу. Closure-based dependencies удобны для маленьких capabilities. Service locator скрывает requirements, переносит ошибки в runtime и усложняет параллельные тесты. DI-контейнер допустим в composition layer, если разрешение не просачивается в бизнес-код.$a$),
($q$Какие уровни тестирования нужны iOS-приложению и что проверять на каждом?$q$,
$e$Сильный кандидат привязывает уровни к рискам и стоимости обратной связи.$e$,
$a$Unit tests быстро проверяют доменные инварианты, reducers, mapping и error policy. Component или integration tests проверяют несколько реальных слоёв: persistence, serialization, networking adapter и feature module. Contract tests фиксируют согласованность API. Snapshot tests полезны для контролируемых visual states, но не заменяют behavior tests. UI tests покрывают небольшое число критических пользовательских путей и accessibility identifiers. Performance tests защищают launch, scrolling и алгоритмические бюджеты. Async tests используют controllable clock и fakes вместо sleep. На production добавляются staged rollout, metrics и crash/hang monitoring.$a$),
($q$Как сделать сетевой слой устойчивым к отмене, повторным запросам и потере сети?$q$,
$e$Ищем полный lifecycle запроса, а не один retry interceptor.$e$,
$a$API принимает cancellation через structured concurrency и не маскирует CancellationError. Retry применяется только к transient failures, уважает Retry-After, использует exponential backoff с jitter и ограниченный budget. Неидемпотентная операция требует idempotency key или не повторяется автоматически. Одинаковые GET можно coalesce, но cancellation одного waiter не должна отменить shared request для остальных. Cache и локальная база дают last known state; reachability используется как сигнал для UI, а не как доказательство доступности сервера. Ответы защищаются request generation или version, чтобы устаревший запрос не перезаписал новый.$a$),
($q$Что происходит с приложением при переходе между active, inactive и background?$q$,
$e$Проверяем современную scene-based модель и ограничения background execution.$e$,
$a$Active scene получает события и обновляет UI. Inactive — переходное состояние, например системное перекрытие; интерактивную работу обычно приостанавливают. В background приложение получает короткое время на завершение, затем может быть suspended без выполнения кода. Процесс может быть terminated без дополнительного callback, поэтому важное состояние сохраняют заранее. Scene lifecycle отделён от process lifecycle: несколько scenes могут иметь разные состояния. Долгие transfers поручают background URLSession, запланированную работу — BackgroundTasks при допустимых условиях. Нельзя рассчитывать на постоянный timer или произвольный network loop в фоне.$a$),
($q$Как бы вы спроектировали кэширование изображений для большой ленты?$q$,
$e$Проверяем уровни cache, memory cost, cancellation и stampede protection.$e$,
$a$Cache key включает нормализованный URL и параметры трансформации. URLCache может хранить transport response по HTTP headers; отдельный disk cache — оригинал или подготовленный файл; memory cache хранит decoded/downsampled image с cost по числу байт, а не числу объектов. Перед декодированием изображение downsample под размер показа. Одинаковые in-flight requests coalesce, cell reuse отменяет waiter и защищается identity token. Prefetch имеет ограниченный budget и низший priority. При memory warning memory cache очищается. Политика eviction обычно LRU с лимитом стоимости и TTL/validation. Метрики: hit rate каждого уровня, decode time, memory и scroll hitches.$a$),
($q$Как спроектировать офлайн-синхронизацию с разрешением конфликтов?$q$,
$e$Сначала зафиксируйте доменный инвариант и только потом выбирайте CRDT или timestamp.$e$,
$a$Клиент хранит materialized local state и durable журнал неподтверждённых операций. Каждая операция имеет стабильный ID, base version и повторяемый server contract. Сервер возвращает cursor и canonical versions; клиент применяет пакет транзакционно и повторяет безопасно после crash. Для независимых полей возможен merge, для денежных и inventory операций нужен server authority, для совместного текста — специализированная модель вроде OT или CRDT. Tombstones и retention предотвращают воскрешение удалённых записей. Пользователь должен видеть конфликт, если автоматический merge может потерять смысл.$a$)
)
UPDATE questions q SET explanation=a.explanation,reference_answer=a.reference_answer,updated_at=now()
FROM answer_data a
WHERE q.prompt=a.prompt
  AND EXISTS (
    SELECT 1 FROM topics tp
    JOIN sections s ON s.id=tp.section_id
    JOIN tracks tr ON tr.id=s.track_id
    JOIN directions d ON d.id=tr.direction_id
    WHERE tp.id=q.topic_id AND d.slug='ios' AND tr.slug='interview'
  );

UPDATE questions q SET
 explanation=$e$Проверьте не только порядок callbacks, но и повторяемость appearance, containment, scene lifecycle и владение асинхронной работой.$e$,
 reference_answer=$a$viewDidLoad вызывается после загрузки view и подходит для одноразовой сборки hierarchy и bindings. viewWillAppear и viewDidAppear могут вызываться много раз при каждом появлении; первый синхронизирует отображаемое состояние, второй фиксирует факт видимости и запускает только работу, которой это действительно нужно. viewWillDisappear/viewDidDisappear не гарантируют deinit. Child containment требует addChild, добавления view и didMove. Scene lifecycle отделён от controller lifecycle. Типичные ошибки: повторные subscriptions, тяжёлая работа на main thread, запуск Task без owner/cancellation, использование viewDidLoad как impression и предположение, что закрытие экрана немедленно освобождает controller.$a$,
 updated_at=now()
WHERE q.prompt='Опишите жизненный цикл UIViewController и типичные ошибки в нём.'
  AND EXISTS (
   SELECT 1 FROM topics tp
   JOIN sections s ON s.id=tp.section_id
   JOIN tracks tr ON tr.id=s.track_id
   JOIN directions d ON d.id=tr.direction_id
   WHERE tp.id=q.topic_id AND d.slug='ios' AND tr.slug='interview'
  );

-- +goose Down
DELETE FROM coding_task_tests
WHERE coding_task_id IN (
 SELECT ct.id FROM coding_tasks ct
 JOIN topics tp ON tp.id=ct.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND ct.slug IN (
  'merge-overlapping-intervals','top-k-frequent-deterministic','longest-unique-substring',
  'weak-observer-store','break-stored-closure-cycle','custom-copy-on-write',
  'ordered-parallel-map','bounded-parallelism','single-flight-loader',
  'stable-list-diff','reusable-cell-generation','screen-state-reducer',
  'module-build-order','authenticated-deep-link','retry-policy-state-machine',
  'merge-cursor-pages','ttl-lru-cache','idempotent-outbox-replay'
 )
);
DELETE FROM coding_tasks
WHERE id IN (
 SELECT ct.id FROM coding_tasks ct
 JOIN topics tp ON tp.id=ct.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND ct.slug IN (
  'merge-overlapping-intervals','top-k-frequent-deterministic','longest-unique-substring',
  'weak-observer-store','break-stored-closure-cycle','custom-copy-on-write',
  'ordered-parallel-map','bounded-parallelism','single-flight-loader',
  'stable-list-diff','reusable-cell-generation','screen-state-reducer',
  'module-build-order','authenticated-deep-link','retry-policy-state-machine',
  'merge-cursor-pages','ttl-lru-cache','idempotent-outbox-replay'
 )
);
DELETE FROM questions
WHERE id IN (
 SELECT q.id FROM questions q
 JOIN topics tp ON tp.id=q.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND q.position BETWEEN 101 AND 110
);
UPDATE questions q SET explanation='',reference_answer='',updated_at=now()
WHERE EXISTS (
 SELECT 1 FROM topics tp
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE tp.id=q.topic_id AND d.slug='ios' AND tr.slug='interview'
) AND q.position < 101;
DELETE FROM lessons
WHERE id IN (
 SELECT l.id FROM lessons l
 JOIN topics tp ON tp.id=l.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND l.slug IN (
  'swift-semantics-runtime','protocols-generics-existentials','api-errors-testing',
  'arc-object-graphs','closure-task-lifetimes','memory-diagnostics',
  'structured-concurrency','swift6-isolation-sendable','backpressure-priority',
  'uikit-lifecycle-layout','swiftui-identity-observation','ui-performance-accessibility',
  'modularity-dependencies','state-navigation','testing-observability',
  'network-cache-offline','feed-media-pipeline','reliability-release-metrics'
 )
);
