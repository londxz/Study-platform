-- +goose Up

-- A second interview-oriented Swift practice pack. The tasks deliberately mix
-- algorithms with lifecycle, concurrency, UI infrastructure and mobile systems
-- problems that commonly appear in senior iOS interview loops.
WITH task_data(section_slug,slug,title,statement_markdown,hint,starter_code,reference_solution,difficulty,position) AS (VALUES
('swift-core','binary-search-target-range','Диапазон элемента бинарным поиском',
$md$В первой строке дан отсортированный массив целых чисел, во второй — target. Выведите индексы первого и последнего вхождения target. Если элемента нет, выведите `-1 -1`.

Ожидаемая сложность: O(log n), без линейного прохода после первого совпадения.$md$,
$md$Найдите отдельно lower bound — первый индекс `>= target`, и upper bound — первый индекс `> target`.$md$,
$swift$import Foundation

func targetRange(_ values: [Int], target: Int) -> (Int, Int) {
    // Реализуйте два бинарных поиска
    return (-1, -1)
}

let values = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let target = Int(readLine() ?? "") ?? 0
let answer = targetRange(values, target: target)
print(answer.0, answer.1)$swift$,
$solution$import Foundation

func targetRange(_ values: [Int], target: Int) -> (Int, Int) {
    func lowerBound(_ predicate: (Int) -> Bool) -> Int {
        var left = 0
        var right = values.count
        while left < right {
            let middle = left + (right - left) / 2
            if predicate(values[middle]) {
                right = middle
            } else {
                left = middle + 1
            }
        }
        return left
    }

    let first = lowerBound { $0 >= target }
    guard first < values.count, values[first] == target else {
        return (-1, -1)
    }
    let afterLast = lowerBound { $0 > target }
    return (first, afterLast - 1)
}

let values = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let target = Int(readLine() ?? "") ?? 0
let answer = targetRange(values, target: target)
print(answer.0, answer.1)$solution$,3,301),

('swift-core','stable-anagram-groups','Стабильная группировка анаграмм',
$md$В одной строке даны слова через запятую. Сгруппируйте анаграммы без изменения порядка слов внутри группы. Сами группы должны идти в порядке первого появления их представителя.

Регистр не учитывается. Группы выводятся через `|`, слова внутри группы — через запятую.$md$,
$md$Ключ группы — отсортированные Character нормализованного слова. Отдельно храните индекс уже созданной группы.$md$,
$swift$import Foundation

func groupAnagramsStable(_ words: [String]) -> [[String]] {
    // Сохраните стабильный порядок групп и элементов
    return []
}

let words = (readLine() ?? "")
    .split(separator: ",", omittingEmptySubsequences: true)
    .map { String($0).trimmingCharacters(in: .whitespaces) }
let groups = groupAnagramsStable(words)
print(groups.map { $0.joined(separator: ",") }.joined(separator: "|"))$swift$,
$solution$import Foundation

func groupAnagramsStable(_ words: [String]) -> [[String]] {
    var groups: [[String]] = []
    var groupIndex: [String: Int] = [:]
    for word in words {
        let key = String(word.lowercased().sorted())
        if let index = groupIndex[key] {
            groups[index].append(word)
        } else {
            groupIndex[key] = groups.count
            groups.append([word])
        }
    }
    return groups
}

let words = (readLine() ?? "")
    .split(separator: ",", omittingEmptySubsequences: true)
    .map { String($0).trimmingCharacters(in: .whitespaces) }
let groups = groupAnagramsStable(words)
print(groups.map { $0.joined(separator: ",") }.joined(separator: "|"))$solution$,3,302),

('arc-memory','one-shot-callback-release','One-shot callback без retain cycle',
$md$`OneShotOperation` хранит completion до завершения операции. Исправьте `finish()`, чтобы callback выполнился ровно один раз и все захваченные им объекты освободились сразу после выполнения, а не только вместе с operation.

Программа должна вывести `done`, затем `released`.$md$,
$md$Сначала перенесите callback в локальную strong-переменную, затем обнулите хранимое свойство и только после этого вызывайте callback.$md$,
$swift$import Foundation

final class Owner {
    let name = "done"
}

final class WeakBox<T: AnyObject> {
    weak var value: T?
    init(_ value: T) { self.value = value }
}

final class OneShotOperation {
    var completion: (() -> Void)?

    func finish() {
        // Исправьте lifetime callback
        completion?()
    }
}

let operation = OneShotOperation()
var owner: Owner? = Owner()
let ownerBox = WeakBox(owner!)
operation.completion = { [captured = owner!] in print(captured.name) }
owner = nil
operation.finish()
print(ownerBox.value == nil ? "released" : "retained")$swift$,
$solution$import Foundation

final class Owner {
    let name = "done"
}

final class WeakBox<T: AnyObject> {
    weak var value: T?
    init(_ value: T) { self.value = value }
}

final class OneShotOperation {
    var completion: (() -> Void)?

    func finish() {
        let callback = completion
        completion = nil
        callback?()
    }
}

let operation = OneShotOperation()
var owner: Owner? = Owner()
let ownerBox = WeakBox(owner!)
operation.completion = { [captured = owner!] in print(captured.name) }
owner = nil
operation.finish()
print(ownerBox.value == nil ? "released" : "retained")$solution$,3,301),

('arc-memory','idempotent-cancellation-token','Идемпотентный CancellationToken',
$md$Реализуйте RAII-токен отмены. `cancel()` может быть вызван несколько раз, но cleanup должен выполниться только однажды. Если токен освобождается без явной отмены, cleanup также должен выполниться из `deinit`.

Тест дважды вызывает `cancel()`, затем освобождает токен. Итоговый счётчик должен быть равен 1.$md$,
$md$Заберите closure в локальную переменную и обнулите свойство до вызова. `deinit` может безопасно делегировать в `cancel()`.$md$,
$swift$import Foundation

final class CancellationToken {
    private var cleanup: (() -> Void)?

    init(cleanup: @escaping () -> Void) {
        self.cleanup = cleanup
    }

    func cancel() {
        // Сделайте отмену идемпотентной
    }

    deinit {
        // Выполните cleanup, если явной отмены не было
    }
}

var cleanupCount = 0
var token: CancellationToken? = CancellationToken { cleanupCount += 1 }
token?.cancel()
token?.cancel()
token = nil
print(cleanupCount)$swift$,
$solution$import Foundation

final class CancellationToken {
    private var cleanup: (() -> Void)?

    init(cleanup: @escaping () -> Void) {
        self.cleanup = cleanup
    }

    func cancel() {
        let action = cleanup
        cleanup = nil
        action?()
    }

    deinit {
        cancel()
    }
}

var cleanupCount = 0
var token: CancellationToken? = CancellationToken { cleanupCount += 1 }
token?.cancel()
token?.cancel()
token = nil
print(cleanupCount)$solution$,3,302),

('concurrency','latest-search-wins','Latest wins для поиска',
$md$Пользователь быстро меняет поисковый запрос. Медленный старый ответ не должен перезаписать быстрый новый.

Первая строка содержит старый query и задержку в миллисекундах, вторая — новый query и задержку. Реализуйте actor с generation token. Выведите принятый новый результат и `STALE` для отклонённого старого.$md$,
$md$Actor выдаёт монотонный token при старте. После await результат принимается только если token всё ещё последний.$md$,
$swift$import Foundation

actor SearchState {
    // Реализуйте generation token
    func begin() -> Int { 0 }
    func commit(token: Int, value: String) -> String? { nil }
}

func perform(query: String, delay: Int, state: SearchState) async -> String? {
    let token = await state.begin()
    try? await Task.sleep(nanoseconds: UInt64(max(0, delay)) * 1_000_000)
    return await state.commit(token: token, value: query)
}

let first = (readLine() ?? "slow 100").split(separator: " ")
let second = (readLine() ?? "fast 10").split(separator: " ")
let firstQuery = String(first.first ?? "slow")
let secondQuery = String(second.first ?? "fast")
let firstDelay = Int(first.last ?? "100") ?? 100
let secondDelay = Int(second.last ?? "10") ?? 10

Task {
    let state = SearchState()
    let oldTask = Task { await perform(query: firstQuery, delay: firstDelay, state: state) }
    try? await Task.sleep(nanoseconds: 2_000_000)
    let newTask = Task { await perform(query: secondQuery, delay: secondDelay, state: state) }
    print(await newTask.value ?? "STALE")
    print(await oldTask.value ?? "STALE")
    exit(0)
}
dispatchMain()$swift$,
$solution$import Foundation

actor SearchState {
    private var generation = 0

    func begin() -> Int {
        generation += 1
        return generation
    }

    func commit(token: Int, value: String) -> String? {
        token == generation ? value : nil
    }
}

func perform(query: String, delay: Int, state: SearchState) async -> String? {
    let token = await state.begin()
    try? await Task.sleep(nanoseconds: UInt64(max(0, delay)) * 1_000_000)
    return await state.commit(token: token, value: query)
}

let first = (readLine() ?? "slow 100").split(separator: " ")
let second = (readLine() ?? "fast 10").split(separator: " ")
let firstQuery = String(first.first ?? "slow")
let secondQuery = String(second.first ?? "fast")
let firstDelay = Int(first.last ?? "100") ?? 100
let secondDelay = Int(second.last ?? "10") ?? 10

Task {
    let state = SearchState()
    let oldTask = Task { await perform(query: firstQuery, delay: firstDelay, state: state) }
    try? await Task.sleep(nanoseconds: 2_000_000)
    let newTask = Task { await perform(query: secondQuery, delay: secondDelay, state: state) }
    print(await newTask.value ?? "STALE")
    print(await oldTask.value ?? "STALE")
    exit(0)
}
dispatchMain()$solution$,4,301),

('concurrency','async-operation-timeout','Timeout для async-операции',
$md$Реализуйте `withTimeout`: операция и таймер участвуют в structured race. Побеждает первый результат, проигравшая задача отменяется.

Во входе указаны задержка операции и timeout в миллисекундах. Выведите `VALUE`, если операция успела, иначе `TIMEOUT`. Нельзя использовать busy waiting.$md$,
$md$Используйте throwing task group из двух child tasks и `group.next()`. Перед выходом вызовите `cancelAll()`.$md$,
$swift$import Foundation

enum TimeoutError: Error { case expired }

func withTimeout<T: Sendable>(
    milliseconds: Int,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    // Реализуйте structured race
    throw TimeoutError.expired
}

let values = (readLine() ?? "20 100").split(separator: " ").compactMap { Int($0) }
let operationDelay = values.first ?? 20
let timeout = values.last ?? 100

Task {
    do {
        let result: String = try await withTimeout(milliseconds: timeout) {
            try await Task.sleep(nanoseconds: UInt64(max(0, operationDelay)) * 1_000_000)
            return "VALUE"
        }
        print(result)
    } catch TimeoutError.expired {
        print("TIMEOUT")
    } catch {
        print("ERROR")
    }
    exit(0)
}
dispatchMain()$swift$,
$solution$import Foundation

enum TimeoutError: Error { case expired }

func withTimeout<T: Sendable>(
    milliseconds: Int,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(max(0, milliseconds)) * 1_000_000)
            throw TimeoutError.expired
        }
        defer { group.cancelAll() }
        guard let result = try await group.next() else {
            throw CancellationError()
        }
        return result
    }
}

let values = (readLine() ?? "20 100").split(separator: " ").compactMap { Int($0) }
let operationDelay = values.first ?? 20
let timeout = values.last ?? 100

Task {
    do {
        let result: String = try await withTimeout(milliseconds: timeout) {
            try await Task.sleep(nanoseconds: UInt64(max(0, operationDelay)) * 1_000_000)
            return "VALUE"
        }
        print(result)
    } catch TimeoutError.expired {
        print("TIMEOUT")
    } catch {
        print("ERROR")
    }
    exit(0)
}
dispatchMain()$solution$,4,302),

('uikit-swiftui','prefetch-window-delta','Планировщик prefetch для ленты',
$md$Рассчитайте, какие индексы нужно начать prefetch и какие отменить при изменении видимого диапазона.

Вход: количество элементов; предыдущий видимый диапазон `start end`; новый диапазон; margin. Desired window — видимый диапазон, расширенный на margin в обе стороны и ограниченный массивом. Выведите новые индексы и отменённые индексы на отдельных строках, либо `-`.$md$,
$md$Постройте два Set индексов. Start = new − old, cancel = old − new. Перед выводом отсортируйте.$md$,
$swift$import Foundation

func prefetchDelta(
    itemCount: Int,
    previous: ClosedRange<Int>,
    next: ClosedRange<Int>,
    margin: Int
) -> (start: [Int], cancel: [Int]) {
    // Реализуйте расчёт двух множеств
    return ([], [])
}

let itemCount = Int(readLine() ?? "") ?? 0
let old = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let new = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let margin = Int(readLine() ?? "") ?? 0
let result = prefetchDelta(
    itemCount: itemCount,
    previous: (old.first ?? 0)...(old.last ?? 0),
    next: (new.first ?? 0)...(new.last ?? 0),
    margin: margin
)
print(result.start.isEmpty ? "-" : result.start.map(String.init).joined(separator: " "))
print(result.cancel.isEmpty ? "-" : result.cancel.map(String.init).joined(separator: " "))$swift$,
$solution$import Foundation

func prefetchDelta(
    itemCount: Int,
    previous: ClosedRange<Int>,
    next: ClosedRange<Int>,
    margin: Int
) -> (start: [Int], cancel: [Int]) {
    func window(for range: ClosedRange<Int>) -> Set<Int> {
        guard itemCount > 0 else { return [] }
        let lower = max(0, range.lowerBound - max(0, margin))
        let upper = min(itemCount - 1, range.upperBound + max(0, margin))
        guard lower <= upper else { return [] }
        return Set(lower...upper)
    }

    let oldWindow = window(for: previous)
    let newWindow = window(for: next)
    return (
        start: newWindow.subtracting(oldWindow).sorted(),
        cancel: oldWindow.subtracting(newWindow).sorted()
    )
}

let itemCount = Int(readLine() ?? "") ?? 0
let old = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let new = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let margin = Int(readLine() ?? "") ?? 0
let result = prefetchDelta(
    itemCount: itemCount,
    previous: (old.first ?? 0)...(old.last ?? 0),
    next: (new.first ?? 0)...(new.last ?? 0),
    margin: margin
)
print(result.start.isEmpty ? "-" : result.start.map(String.init).joined(separator: " "))
print(result.cancel.isEmpty ? "-" : result.cancel.map(String.init).joined(separator: " "))$solution$,3,301),

('uikit-swiftui','cell-reuse-generation-gate','Защита ячейки от устаревшего изображения',
$md$При переиспользовании ячейки старый image request может завершиться позже нового. Реализуйте generation gate: `begin(slot:)` выдаёт новый token, а `accept` возвращает value только для текущего token этого slot.

Тест сначала завершает старый запрос, затем новый. Вывод должен быть `STALE` и `new-image`.$md$,
$md$Для каждого slot храните последний generation. Любой новый `begin` инвалидирует предыдущий token.$md$,
$swift$import Foundation

final class ReuseGenerationGate {
    func begin(slot: String) -> Int {
        // Верните новый token
        return 0
    }

    func accept(slot: String, token: Int, value: String) -> String? {
        // Пропустите только актуальный результат
        return nil
    }
}

let gate = ReuseGenerationGate()
let old = gate.begin(slot: "feed-cell")
let current = gate.begin(slot: "feed-cell")
print(gate.accept(slot: "feed-cell", token: old, value: "old-image") ?? "STALE")
print(gate.accept(slot: "feed-cell", token: current, value: "new-image") ?? "STALE")$swift$,
$solution$import Foundation

final class ReuseGenerationGate {
    private var generation = 0
    private var currentBySlot: [String: Int] = [:]

    func begin(slot: String) -> Int {
        generation += 1
        currentBySlot[slot] = generation
        return generation
    }

    func accept(slot: String, token: Int, value: String) -> String? {
        currentBySlot[slot] == token ? value : nil
    }
}

let gate = ReuseGenerationGate()
let old = gate.begin(slot: "feed-cell")
let current = gate.begin(slot: "feed-cell")
print(gate.accept(slot: "feed-cell", token: old, value: "old-image") ?? "STALE")
print(gate.accept(slot: "feed-cell", token: current, value: "new-image") ?? "STALE")$solution$,3,302),

('architecture','analytics-event-batcher','Батчер аналитических событий',
$md$События приходят как `name@timestamp` через `;`. Соберите их в батчи, сохраняя порядок. Новый батч начинается, если текущий уже достиг `maxCount` либо разница timestamp нового события и первого события текущего батча больше `maxAge`.

Во второй строке `maxCount`, в третьей `maxAge`. Выведите батчи через `|`, имена внутри — через запятую.$md$,
$md$Храните timestamp первого элемента текущего батча. Перед добавлением следующего события проверяйте обе причины flush.$md$,
$swift$import Foundation

struct Event {
    let name: String
    let timestamp: Int
}

func makeBatches(_ events: [Event], maxCount: Int, maxAge: Int) -> [[Event]] {
    // Реализуйте предсказуемую batching policy
    return []
}

let events = (readLine() ?? "").split(separator: ";").compactMap { raw -> Event? in
    let parts = raw.split(separator: "@", maxSplits: 1)
    guard parts.count == 2, let timestamp = Int(parts[1]) else { return nil }
    return Event(name: String(parts[0]), timestamp: timestamp)
}
let maxCount = Int(readLine() ?? "") ?? 1
let maxAge = Int(readLine() ?? "") ?? 0
print(makeBatches(events, maxCount: maxCount, maxAge: maxAge)
    .map { $0.map(\.name).joined(separator: ",") }
    .joined(separator: "|"))$swift$,
$solution$import Foundation

struct Event {
    let name: String
    let timestamp: Int
}

func makeBatches(_ events: [Event], maxCount: Int, maxAge: Int) -> [[Event]] {
    guard !events.isEmpty else { return [] }
    let countLimit = max(1, maxCount)
    let ageLimit = max(0, maxAge)
    var result: [[Event]] = []
    var current: [Event] = []

    for event in events {
        if let first = current.first,
           current.count >= countLimit || event.timestamp - first.timestamp > ageLimit {
            result.append(current)
            current = []
        }
        current.append(event)
    }
    if !current.isEmpty { result.append(current) }
    return result
}

let events = (readLine() ?? "").split(separator: ";").compactMap { raw -> Event? in
    let parts = raw.split(separator: "@", maxSplits: 1)
    guard parts.count == 2, let timestamp = Int(parts[1]) else { return nil }
    return Event(name: String(parts[0]), timestamp: timestamp)
}
let maxCount = Int(readLine() ?? "") ?? 1
let maxAge = Int(readLine() ?? "") ?? 0
print(makeBatches(events, maxCount: maxCount, maxAge: maxAge)
    .map { $0.map(\.name).joined(separator: ",") }
    .joined(separator: "|"))$solution$,3,301),

('architecture','deterministic-feature-rollout','Детерминированный rollout feature flag',
$md$Реализуйте стабильный percentage rollout без `hashValue`, потому что Swift не гарантирует одинаковый hash между процессами.

Первая строка содержит user IDs, вторая — процент от 0 до 100. Используйте FNV-1a 64-bit по UTF-8, bucket = hash % 100. Выведите IDs с bucket меньше процента, сохраняя порядок, или `-`.$md$,
$md$Начальное значение FNV-1a: 14695981039346656037, множитель: 1099511628211. Для умножения используйте overflow operator `&*`.$md$,
$swift$import Foundation

func rolloutBucket(_ identifier: String) -> Int {
    // Реализуйте стабильный FNV-1a hash
    return 0
}

func enabledUsers(_ identifiers: [String], percentage: Int) -> [String] {
    // Отфильтруйте пользователей по bucket
    return []
}

let identifiers = (readLine() ?? "").split(separator: " ").map(String.init)
let percentage = Int(readLine() ?? "") ?? 0
let result = enabledUsers(identifiers, percentage: percentage)
print(result.isEmpty ? "-" : result.joined(separator: " "))$swift$,
$solution$import Foundation

func rolloutBucket(_ identifier: String) -> Int {
    var hash: UInt64 = 14_695_981_039_346_656_037
    for byte in identifier.utf8 {
        hash ^= UInt64(byte)
        hash &*= 1_099_511_628_211
    }
    return Int(hash % 100)
}

func enabledUsers(_ identifiers: [String], percentage: Int) -> [String] {
    let threshold = min(100, max(0, percentage))
    return identifiers.filter { rolloutBucket($0) < threshold }
}

let identifiers = (readLine() ?? "").split(separator: " ").map(String.init)
let percentage = Int(readLine() ?? "") ?? 0
let result = enabledUsers(identifiers, percentage: percentage)
print(result.isEmpty ? "-" : result.joined(separator: " "))$solution$,3,302),

('system-design','offline-mutation-compaction','Компактация offline mutation queue',
$md$Очередь содержит операции `S:key:value` и `D:key`, разделённые `;`. Перед синхронизацией оставьте только последнюю операцию для каждого key. Порядок результата определяется позициями оставшихся последних операций.

Например, `S:a:1;S:b:2;S:a:3;D:b` превращается в `S:a:3;D:b`.$md$,
$md$Первым проходом запомните последний индекс каждого key, вторым оставьте операции, индекс которых совпал с сохранённым.$md$,
$swift$import Foundation

struct Mutation {
    let raw: String
    let key: String
}

func compact(_ mutations: [Mutation]) -> [Mutation] {
    // Оставьте последнюю mutation каждого key
    return []
}

let mutations = (readLine() ?? "").split(separator: ";").compactMap { part -> Mutation? in
    let pieces = part.split(separator: ":", omittingEmptySubsequences: false)
    guard pieces.count >= 2 else { return nil }
    return Mutation(raw: String(part), key: String(pieces[1]))
}
print(compact(mutations).map(\.raw).joined(separator: ";"))$swift$,
$solution$import Foundation

struct Mutation {
    let raw: String
    let key: String
}

func compact(_ mutations: [Mutation]) -> [Mutation] {
    var lastIndex: [String: Int] = [:]
    for (index, mutation) in mutations.enumerated() {
        lastIndex[mutation.key] = index
    }
    return mutations.enumerated().compactMap { index, mutation in
        lastIndex[mutation.key] == index ? mutation : nil
    }
}

let mutations = (readLine() ?? "").split(separator: ";").compactMap { part -> Mutation? in
    let pieces = part.split(separator: ":", omittingEmptySubsequences: false)
    guard pieces.count >= 2 else { return nil }
    return Mutation(raw: String(part), key: String(pieces[1]))
}
print(compact(mutations).map(\.raw).joined(separator: ";"))$solution$,3,301),

('system-design','retry-delay-schedule','Retry schedule с Retry-After',
$md$Постройте задержки повторов сетевого запроса. Первая строка: `attempts baseDelay maxDelay`. Вторая строка содержит Retry-After для каждой попытки; `-1` означает отсутствие заголовка.

Без Retry-After используйте exponential backoff `baseDelay * 2^attempt`. С Retry-After используйте его значение. Любая задержка ограничивается maxDelay. Выведите schedule через пробел.$md$,
$md$Отдельно нормализуйте отрицательные значения и ограничьте степень, чтобы избежать переполнения Int.$md$,
$swift$import Foundation

func retrySchedule(
    attempts: Int,
    baseDelay: Int,
    maxDelay: Int,
    retryAfter: [Int]
) -> [Int] {
    // Реализуйте retry policy
    return []
}

let configuration = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let overrides = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let result = retrySchedule(
    attempts: configuration.first ?? 0,
    baseDelay: configuration.count > 1 ? configuration[1] : 0,
    maxDelay: configuration.last ?? 0,
    retryAfter: overrides
)
print(result.map(String.init).joined(separator: " "))$swift$,
$solution$import Foundation

func retrySchedule(
    attempts: Int,
    baseDelay: Int,
    maxDelay: Int,
    retryAfter: [Int]
) -> [Int] {
    let count = max(0, attempts)
    let base = max(0, baseDelay)
    let ceiling = max(0, maxDelay)
    return (0..<count).map { attempt in
        if attempt < retryAfter.count, retryAfter[attempt] >= 0 {
            return min(ceiling, retryAfter[attempt])
        }
        let exponent = min(attempt, 30)
        let multiplier = 1 << exponent
        let delay = base > Int.max / max(1, multiplier) ? Int.max : base * multiplier
        return min(ceiling, delay)
    }
}

let configuration = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let overrides = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
let result = retrySchedule(
    attempts: configuration.first ?? 0,
    baseDelay: configuration.count > 1 ? configuration[1] : 0,
    maxDelay: configuration.last ?? 0,
    retryAfter: overrides
)
print(result.map(String.init).joined(separator: " "))$solution$,3,302)
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
('binary-search-target-range',$in$1 2 2 2 3 4
2
$in$,$out$1 3
$out$,1),
('binary-search-target-range',$in$1 3 5 7
4
$in$,$out$-1 -1
$out$,2),
('stable-anagram-groups',$in$eat,tea,tan,ate,nat,bat
$in$,$out$eat,tea,ate|tan,nat|bat
$out$,1),
('stable-anagram-groups',$in$Tea,Eat,ate,foo,oof
$in$,$out$Tea,Eat,ate|foo,oof
$out$,2),
('one-shot-callback-release',$in$$in$,$out$done
released
$out$,1),
('idempotent-cancellation-token',$in$$in$,$out$1
$out$,1),
('latest-search-wins',$in$old 80
new 5
$in$,$out$new
STALE
$out$,1),
('async-operation-timeout',$in$10 80
$in$,$out$VALUE
$out$,1),
('async-operation-timeout',$in$80 10
$in$,$out$TIMEOUT
$out$,2),
('prefetch-window-delta',$in$20
2 5
5 8
2
$in$,$out$8 9 10
0 1 2
$out$,1),
('prefetch-window-delta',$in$6
0 2
1 3
2
$in$,$out$5
-
$out$,2),
('cell-reuse-generation-gate',$in$$in$,$out$STALE
new-image
$out$,1),
('analytics-event-batcher',$in$a@0;b@1;c@2;d@10;e@11
2
5
$in$,$out$a,b|c|d,e
$out$,1),
('analytics-event-batcher',$in$a@0;b@5;c@6
3
5
$in$,$out$a,b|c
$out$,2),
('deterministic-feature-rollout',$in$alice bob carol dave
70
$in$,$out$carol dave
$out$,1),
('deterministic-feature-rollout',$in$alice bob carol
0
$in$,$out$-
$out$,2),
('offline-mutation-compaction',$in$S:a:1;S:b:2;S:a:3;D:b;S:c:4
$in$,$out$S:a:3;D:b;S:c:4
$out$,1),
('offline-mutation-compaction',$in$S:x:1;D:x;S:x:2
$in$,$out$S:x:2
$out$,2),
('retry-delay-schedule',$in$5 100 1000
-1 -1 700 -1 -1
$in$,$out$100 200 700 800 1000
$out$,1),
('retry-delay-schedule',$in$3 250 400
50 -1 900
$in$,$out$50 400 400
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

-- +goose Down
DELETE FROM coding_task_tests
WHERE coding_task_id IN (
 SELECT ct.id FROM coding_tasks ct
 JOIN topics tp ON tp.id=ct.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND ct.slug IN (
  'binary-search-target-range','stable-anagram-groups',
  'one-shot-callback-release','idempotent-cancellation-token',
  'latest-search-wins','async-operation-timeout',
  'prefetch-window-delta','cell-reuse-generation-gate',
  'analytics-event-batcher','deterministic-feature-rollout',
  'offline-mutation-compaction','retry-delay-schedule'
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
  'binary-search-target-range','stable-anagram-groups',
  'one-shot-callback-release','idempotent-cancellation-token',
  'latest-search-wins','async-operation-timeout',
  'prefetch-window-delta','cell-reuse-generation-gate',
  'analytics-event-batcher','deterministic-feature-rollout',
  'offline-mutation-compaction','retry-delay-schedule'
 )
);
