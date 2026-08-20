-- +goose Up

-- Thirty new, independently runnable Swift interview archetypes: five for
-- every iOS interview section. Unlike the drill cards from migration 00008,
-- each task below has a new implementation problem, reference solution and
-- deterministic hidden fixtures.

WITH task_data(section_slug,slug,title,statement_markdown,hint,starter_code,reference_solution,difficulty,position) AS (VALUES

-- Swift Core -----------------------------------------------------------------
('swift-core','ios-advanced-lossy-decodable-array','Lossy-декодирование массива',
$md$В stdin приходит JSON-массив объектов `{"id": Int, "name": String}`. Повреждённые элементы не должны ломать весь ответ. Выведите только валидные элементы в исходном порядке как `id:name`, разделив их запятыми.$md$,
$md$Декодируйте каждый элемент через generic-обёртку, которая превращает локальную ошибку Decodable в nil.$md$,
$swift$import Foundation

struct User: Decodable { let id: Int; let name: String }

func decodeValidUsers(_ data: Data) -> [User] {
    // Верните только корректно декодированные элементы
    return []
}

let data = Data((readLine() ?? "[]").utf8)
let users = decodeValidUsers(data)
print(users.map { "\($0.id):\($0.name)" }.joined(separator: ","))$swift$,
$solution$import Foundation

struct User: Decodable { let id: Int; let name: String }
struct Failable<Value: Decodable>: Decodable {
    let value: Value?
    init(from decoder: Decoder) throws { value = try? Value(from: decoder) }
}

func decodeValidUsers(_ data: Data) -> [User] {
    (try? JSONDecoder().decode([Failable<User>].self, from: data))?.compactMap(\.value) ?? []
}

let data = Data((readLine() ?? "[]").utf8)
let users = decodeValidUsers(data)
print(users.map { "\($0.id):\($0.name)" }.joined(separator: ","))$solution$,3,501),

('swift-core','ios-advanced-semver-sort','Сортировка Semantic Version',
$md$В строке даны версии через пробел. Отсортируйте их по SemVer: major, minor, patch; release новее prerelease, числовой prerelease identifier меньше текстового, более короткий равный префикс меньше длинного. Выведите версии по возрастанию.$md$,
$md$Разберите core и prerelease отдельно. Build metadata после `+` не участвует в сравнении.$md$,
$swift$import Foundation

struct Version: Comparable {
    let raw: String
    init(_ raw: String) { self.raw = raw }
    static func < (lhs: Version, rhs: Version) -> Bool {
        // Реализуйте SemVer-сравнение
        return false
    }
}

let versions = (readLine() ?? "").split(separator: " ").map { Version(String($0)) }
print(versions.sorted().map(\.raw).joined(separator: " "))$swift$,
$solution$import Foundation

struct Version: Comparable {
    let raw: String
    let core: [Int]
    let pre: [String]?
    init(_ raw: String) {
        self.raw = raw
        let noBuild = raw.split(separator: "+", maxSplits: 1).first.map(String.init) ?? raw
        let parts = noBuild.split(separator: "-", maxSplits: 1).map(String.init)
        core = parts[0].split(separator: ".").map { Int($0) ?? 0 }
        pre = parts.count > 1 ? parts[1].split(separator: ".").map(String.init) : nil
    }
    static func < (lhs: Version, rhs: Version) -> Bool {
        for index in 0..<3 {
            let l = index < lhs.core.count ? lhs.core[index] : 0
            let r = index < rhs.core.count ? rhs.core[index] : 0
            if l != r { return l < r }
        }
        switch (lhs.pre, rhs.pre) {
        case (nil, nil): return false
        case (nil, _): return false
        case (_, nil): return true
        case let (l?, r?):
            for index in 0..<min(l.count, r.count) {
                if l[index] == r[index] { continue }
                let li = Int(l[index]), ri = Int(r[index])
                if let li, let ri { return li < ri }
                if li != nil { return true }
                if ri != nil { return false }
                return l[index] < r[index]
            }
            return l.count < r.count
        }
    }
}

let versions = (readLine() ?? "").split(separator: " ").map { Version(String($0)) }
print(versions.sorted().map(\.raw).joined(separator: " "))$solution$,5,502),

('swift-core','ios-advanced-unicode-rle','Unicode-safe Run-Length Encoding',
$md$Закодируйте последовательные одинаковые `Character` как `символ:количество`, группы разделите `|`. Решение должно корректно работать с emoji и grapheme clusters, а не с UTF-8 bytes.$md$,
$md$Итерируйтесь по String как по Collection<Character>.$md$,
$swift$import Foundation

func encodeRuns(_ text: String) -> String {
    // Реализуйте Character-aware RLE
    return ""
}

print(encodeRuns(readLine() ?? ""))$swift$,
$solution$import Foundation

func encodeRuns(_ text: String) -> String {
    var groups: [(Character, Int)] = []
    for character in text {
        if let last = groups.indices.last, groups[last].0 == character {
            groups[last].1 += 1
        } else {
            groups.append((character, 1))
        }
    }
    return groups.map { "\($0.0):\($0.1)" }.joined(separator: "|")
}

print(encodeRuns(readLine() ?? ""))$solution$,2,503),

('swift-core','ios-advanced-bracket-error-index','Индекс ошибки скобок',
$md$Проверьте круглые, квадратные и фигурные скобки в произвольной строке. Выведите `OK` или `ERROR index`, где index — позиция первой неверной закрывающей скобки. Если строка закончилась с незакрытой скобкой, верните индекс самой ранней незакрытой.$md$,
$md$Храните в stack пару `(Character, offset)` и в конце смотрите первый оставшийся элемент.$md$,
$swift$import Foundation

func bracketError(in text: String) -> Int? {
    // Верните offset ошибки или nil
    return nil
}

if let index = bracketError(in: readLine() ?? "") { print("ERROR", index) } else { print("OK") }$swift$,
$solution$import Foundation

func bracketError(in text: String) -> Int? {
    let pairs: [Character: Character] = [")": "(", "]": "[", "}": "{"]
    var stack: [(Character, Int)] = []
    for (index, character) in text.enumerated() {
        if "([{ ".contains(character), character != " " { stack.append((character, index)) }
        else if let opening = pairs[character] {
            guard stack.last?.0 == opening else { return index }
            stack.removeLast()
        }
    }
    return stack.first?.1
}

if let index = bracketError(in: readLine() ?? "") { print("ERROR", index) } else { print("OK") }$solution$,3,504),

('swift-core','ios-advanced-minimum-window','Минимальное покрывающее окно',
$md$В первой строке source, во второй target. Найдите самую короткую подстроку source, содержащую все `Character` target с учётом кратности. При равной длине выберите более раннее окно. Если решения нет, выведите `-`.$md$,
$md$Используйте sliding window и два словаря частот. Индексы храните в массиве Character.$md$,
$swift$import Foundation

func minimumWindow(_ source: String, target: String) -> String? {
    // O(n) sliding window
    return nil
}

print(minimumWindow(readLine() ?? "", target: readLine() ?? "") ?? "-")$swift$,
$solution$import Foundation

func minimumWindow(_ source: String, target: String) -> String? {
    let values = Array(source), targetValues = Array(target)
    if targetValues.isEmpty { return "" }
    var need: [Character: Int] = [:], have: [Character: Int] = [:]
    for value in targetValues { need[value, default: 0] += 1 }
    var formed = 0, left = 0, best: (Int, Int)?
    for right in values.indices {
        let value = values[right]
        have[value, default: 0] += 1
        if let required = need[value], have[value] == required { formed += 1 }
        while formed == need.count {
            if best == nil || right - left + 1 < best!.1 { best = (left, right - left + 1) }
            let removed = values[left]
            if let required = need[removed], have[removed] == required { formed -= 1 }
            have[removed, default: 0] -= 1
            left += 1
        }
    }
    guard let best else { return nil }
    return String(values[best.0..<(best.0 + best.1)])
}

print(minimumWindow(readLine() ?? "", target: readLine() ?? "") ?? "-")$solution$,4,505),

-- ARC and lifetime -----------------------------------------------------------
('arc-memory','ios-advanced-weak-parent-tree','Дерево с weak parent',
$md$`Node` владеет дочерними узлами, но дочерний узел не должен удерживать родителя. Исправьте ownership так, чтобы после удаления внешних ссылок оба объекта освободились. Программа должна вывести `released released`.$md$,
$md$Обратная ссылка parent выражает навигацию, а не владение.$md$,
$swift$import Foundation

final class Node {
    let name: String
    var parent: Node?
    var children: [Node] = []
    init(_ name: String) { self.name = name }
}
final class WeakBox<T: AnyObject> { weak var value: T?; init(_ value: T) { self.value = value } }

var root: Node? = Node("root")
var child: Node? = Node("child")
root?.children = [child!]; child?.parent = root
let rootBox = WeakBox(root!), childBox = WeakBox(child!)
root = nil; child = nil
print(rootBox.value == nil ? "released" : "retained", childBox.value == nil ? "released" : "retained")$swift$,
$solution$import Foundation

final class Node {
    let name: String
    weak var parent: Node?
    var children: [Node] = []
    init(_ name: String) { self.name = name }
}
final class WeakBox<T: AnyObject> { weak var value: T?; init(_ value: T) { self.value = value } }

var root: Node? = Node("root")
var child: Node? = Node("child")
root?.children = [child!]; child?.parent = root
let rootBox = WeakBox(root!), childBox = WeakBox(child!)
root = nil; child = nil
print(rootBox.value == nil ? "released" : "retained", childBox.value == nil ? "released" : "retained")$solution$,2,501),

('arc-memory','ios-advanced-cancellation-bag','CancellationBag с cleanup',
$md$Реализуйте bag для cancellation tokens. `cancelAll()` можно вызывать многократно, каждый cleanup выполняется ровно один раз. При deinit bag должен отменить оставшиеся tokens. Ввод — число tokens; вывод — итоговое число cleanup после двух cancelAll и освобождения bag.$md$,
$md$Token забирает closure перед вызовом, bag забирает массив перед обходом.$md$,
$swift$import Foundation

final class Token {
    private var cleanup: (() -> Void)?
    init(_ cleanup: @escaping () -> Void) { self.cleanup = cleanup }
    func cancel() { /* TODO */ }
    deinit { cancel() }
}
final class CancellationBag {
    private var tokens: [Token] = []
    func insert(_ token: Token) { tokens.append(token) }
    func cancelAll() { /* TODO */ }
    deinit { cancelAll() }
}

let count = Int(readLine() ?? "0") ?? 0
var cleaned = 0
var bag: CancellationBag? = CancellationBag()
for _ in 0..<count { bag?.insert(Token { cleaned += 1 }) }
bag?.cancelAll(); bag?.cancelAll(); bag = nil
print(cleaned)$swift$,
$solution$import Foundation

final class Token {
    private var cleanup: (() -> Void)?
    init(_ cleanup: @escaping () -> Void) { self.cleanup = cleanup }
    func cancel() { let action = cleanup; cleanup = nil; action?() }
    deinit { cancel() }
}
final class CancellationBag {
    private var tokens: [Token] = []
    func insert(_ token: Token) { tokens.append(token) }
    func cancelAll() { let pending = tokens; tokens.removeAll(); pending.forEach { $0.cancel() } }
    deinit { cancelAll() }
}

let count = Int(readLine() ?? "0") ?? 0
var cleaned = 0
var bag: CancellationBag? = CancellationBag()
for _ in 0..<count { bag?.insert(Token { cleaned += 1 }) }
bag?.cancelAll(); bag?.cancelAll(); bag = nil
print(cleaned)$solution$,3,502),

('arc-memory','ios-advanced-capture-snapshot','Snapshot и shared capture',
$md$В первой строке initial, во второй updated. Верните две closures: первая должна навсегда сохранить initial как value snapshot, вторая — читать актуальное значение reference box. После обновления box программа выводит `initial updated`.$md$,
$md$Для snapshot используйте capture list, для live-значения захватите сам Box.$md$,
$swift$import Foundation

final class Box { var value: String; init(_ value: String) { self.value = value } }

func callbacks(value: String, box: Box) -> (() -> String, () -> String) {
    // Верните snapshot и live callback
    return ({ "" }, { "" })
}

let initial = readLine() ?? ""
let box = Box(initial)
let pair = callbacks(value: initial, box: box)
box.value = readLine() ?? ""
print(pair.0(), pair.1())$swift$,
$solution$import Foundation

final class Box { var value: String; init(_ value: String) { self.value = value } }

func callbacks(value: String, box: Box) -> (() -> String, () -> String) {
    let snapshot = { [value] in value }
    let live = { box.value }
    return (snapshot, live)
}

let initial = readLine() ?? ""
let box = Box(initial)
let pair = callbacks(value: initial, box: box)
box.value = readLine() ?? ""
print(pair.0(), pair.1())$solution$,2,503),

('arc-memory','ios-advanced-weak-value-cache','Weak-value cache',
$md$Реализуйте cache, который не продлевает lifetime значений. После освобождения внешней strong-ссылки `value(for:)` возвращает nil, а `purge()` удаляет мёртвые entries. Программа выводит существующие ключи по алфавиту.$md$,
$md$Dictionary хранит WeakBox, а чтение может лениво удалить обнулённую запись.$md$,
$swift$import Foundation

final class Value { let name: String; init(_ name: String) { self.name = name } }
final class WeakBox { weak var value: Value?; init(_ value: Value) { self.value = value } }
final class WeakCache {
    private var storage: [String: WeakBox] = [:]
    func set(_ value: Value, for key: String) { /* TODO */ }
    func value(for key: String) -> Value? { nil }
    func purge() { /* TODO */ }
    var keys: [String] { storage.keys.sorted() }
}

let names = (readLine() ?? "").split(separator: " ").map(String.init)
let cache = WeakCache(); var first: Value?; var second: Value?
first = names.indices.contains(0) ? Value(names[0]) : nil
second = names.indices.contains(1) ? Value(names[1]) : nil
if let first { cache.set(first, for: "a") }; if let second { cache.set(second, for: "b") }
first = nil; cache.purge(); _ = second
print(cache.keys.joined(separator: ","))$swift$,
$solution$import Foundation

final class Value { let name: String; init(_ name: String) { self.name = name } }
final class WeakBox { weak var value: Value?; init(_ value: Value) { self.value = value } }
final class WeakCache {
    private var storage: [String: WeakBox] = [:]
    func set(_ value: Value, for key: String) { storage[key] = WeakBox(value) }
    func value(for key: String) -> Value? {
        guard let value = storage[key]?.value else { storage[key] = nil; return nil }
        return value
    }
    func purge() { storage = storage.filter { $0.value.value != nil } }
    var keys: [String] { storage.keys.sorted() }
}

let names = (readLine() ?? "").split(separator: " ").map(String.init)
let cache = WeakCache(); var first: Value?; var second: Value?
first = names.indices.contains(0) ? Value(names[0]) : nil
second = names.indices.contains(1) ? Value(names[1]) : nil
if let first { cache.set(first, for: "a") }; if let second { cache.set(second, for: "b") }
first = nil; cache.purge(); _ = second
print(cache.keys.joined(separator: ","))$solution$,3,504),

('arc-memory','ios-advanced-observation-token','Observation token без цикла',
$md$`Subject` хранит callbacks, `Owner` хранит observation token. Реализуйте подписку так, чтобы Owner освобождался без ручного cancel, callback не удерживал его, а token при deinit удалял callback из Subject. Выведите `released 0`.$md$,
$md$Callback захватывает Owner weakly, token cleanup — Subject weakly.$md$,
$swift$import Foundation

final class Token {
    private var cleanup: (() -> Void)?
    init(_ cleanup: @escaping () -> Void) { self.cleanup = cleanup }
    deinit { cleanup?() }
}
final class Subject {
    private var callbacks: [Int: () -> Void] = [:]; private var next = 0
    var count: Int { callbacks.count }
    func observe(_ callback: @escaping () -> Void) -> Token {
        // Сохраните callback и верните token удаления
        fatalError()
    }
}
final class Owner { var token: Token?; var value = 0 }
final class WeakBox<T: AnyObject> { weak var value: T?; init(_ value: T) { self.value = value } }

let subject = Subject(); var owner: Owner? = Owner(); let box = WeakBox(owner!)
owner?.token = subject.observe { owner?.value += 1 }
owner = nil
print(box.value == nil ? "released" : "retained", subject.count)$swift$,
$solution$import Foundation

final class Token {
    private var cleanup: (() -> Void)?
    init(_ cleanup: @escaping () -> Void) { self.cleanup = cleanup }
    deinit { let action = cleanup; cleanup = nil; action?() }
}
final class Subject {
    private var callbacks: [Int: () -> Void] = [:]; private var next = 0
    var count: Int { callbacks.count }
    func observe(_ callback: @escaping () -> Void) -> Token {
        let id = next; next += 1; callbacks[id] = callback
        return Token { [weak self] in self?.callbacks[id] = nil }
    }
}
final class Owner { var token: Token?; var value = 0 }
final class WeakBox<T: AnyObject> { weak var value: T?; init(_ value: T) { self.value = value } }

let subject = Subject(); var owner: Owner? = Owner(); let box = WeakBox(owner!)
owner?.token = subject.observe { [weak owner] in owner?.value += 1 }
owner = nil
print(box.value == nil ? "released" : "retained", subject.count)$solution$,4,505),

-- Swift Concurrency ---------------------------------------------------------
('concurrency','ios-advanced-first-success-race','Первый успешный async-результат',
$md$В строке заданы кандидаты `value:delayMs`. Отрицательный `value` означает ошибку. Параллельно запустите все операции, верните первый успешный результат по фактическому времени завершения и отмените остальные. Если успешных результатов нет, выведите `NONE`.$md$,
$md$Task group отдаёт результаты в порядке завершения. После первого успеха вызовите `cancelAll()` и проверяйте отмену внутри child task.$md$,
$swift$import Foundation

struct Candidate: Sendable { let value: Int; let delay: UInt64 }

func firstSuccess(_ candidates: [Candidate]) async -> Int? {
    // Запустите кандидатов конкурентно и отмените проигравших
    return nil
}

let items = (readLine() ?? "").split(separator: " ").compactMap { token -> Candidate? in
    let parts = token.split(separator: ":"); guard parts.count == 2,
        let value = Int(parts[0]), let delay = UInt64(parts[1]) else { return nil }
    return Candidate(value: value, delay: delay)
}
let done = DispatchSemaphore(value: 0)
Task { print(await firstSuccess(items).map(String.init) ?? "NONE"); done.signal() }
done.wait()$swift$,
$solution$import Foundation

struct Candidate: Sendable { let value: Int; let delay: UInt64 }

func firstSuccess(_ candidates: [Candidate]) async -> Int? {
    await withTaskGroup(of: Int?.self) { group in
        for candidate in candidates {
            group.addTask {
                do {
                    try await Task.sleep(nanoseconds: candidate.delay * 1_000_000)
                    try Task.checkCancellation()
                    return candidate.value >= 0 ? candidate.value : nil
                } catch { return nil }
            }
        }
        for await result in group {
            if let result { group.cancelAll(); return result }
        }
        return nil
    }
}

let items = (readLine() ?? "").split(separator: " ").compactMap { token -> Candidate? in
    let parts = token.split(separator: ":"); guard parts.count == 2,
        let value = Int(parts[0]), let delay = UInt64(parts[1]) else { return nil }
    return Candidate(value: value, delay: delay)
}
let done = DispatchSemaphore(value: 0)
Task { print(await firstSuccess(items).map(String.init) ?? "NONE"); done.signal() }
done.wait()$solution$,4,501),

('concurrency','ios-advanced-quorum-task-group','Кворум параллельных запросов',
$md$В первой строке задан размер кворума `k`, во второй — операции `value:delayMs`; отрицательное значение означает ошибку. Соберите первые `k` успешных результатов в порядке завершения и отмените остаток. Если кворум недостижим, выведите `IMPOSSIBLE`.$md$,
$md$Не ждите результаты в исходном порядке. Task group сам предоставляет completion order.$md$,
$swift$import Foundation

struct Candidate: Sendable { let value: Int; let delay: UInt64 }

func quorum(_ candidates: [Candidate], required: Int) async -> [Int]? {
    // Верните первые required успехов или nil
    return nil
}

let required = Int(readLine() ?? "") ?? 1
let items = (readLine() ?? "").split(separator: " ").compactMap { token -> Candidate? in
    let parts = token.split(separator: ":"); guard parts.count == 2,
        let value = Int(parts[0]), let delay = UInt64(parts[1]) else { return nil }
    return Candidate(value: value, delay: delay)
}
let done = DispatchSemaphore(value: 0)
Task {
    if let values = await quorum(items, required: required) { print(values.map(String.init).joined(separator: ",")) }
    else { print("IMPOSSIBLE") }
    done.signal()
}
done.wait()$swift$,
$solution$import Foundation

struct Candidate: Sendable { let value: Int; let delay: UInt64 }

func quorum(_ candidates: [Candidate], required: Int) async -> [Int]? {
    guard required > 0 else { return [] }
    return await withTaskGroup(of: Int?.self) { group in
        for candidate in candidates {
            group.addTask {
                do {
                    try await Task.sleep(nanoseconds: candidate.delay * 1_000_000)
                    try Task.checkCancellation()
                    return candidate.value >= 0 ? candidate.value : nil
                } catch { return nil }
            }
        }
        var successes: [Int] = []
        for await result in group {
            if let result { successes.append(result) }
            if successes.count == required { group.cancelAll(); return successes }
        }
        return nil
    }
}

let required = Int(readLine() ?? "") ?? 1
let items = (readLine() ?? "").split(separator: " ").compactMap { token -> Candidate? in
    let parts = token.split(separator: ":"); guard parts.count == 2,
        let value = Int(parts[0]), let delay = UInt64(parts[1]) else { return nil }
    return Candidate(value: value, delay: delay)
}
let done = DispatchSemaphore(value: 0)
Task {
    if let values = await quorum(items, required: required) { print(values.map(String.init).joined(separator: ",")) }
    else { print("IMPOSSIBLE") }
    done.signal()
}
done.wait()$solution$,4,502),

('concurrency','ios-advanced-actor-token-bucket','Actor token bucket',
$md$Первая строка содержит `capacity refillPerSecond`, вторая — монотонные timestamps запросов в секундах. Реализуйте actor token bucket: каждый разрешённый запрос тратит один токен, между запросами токены восстанавливаются, но не выше capacity. Выведите для запросов `1` или `0`.$md$,
$md$Храните дробное число токенов и время последнего обновления внутри actor isolation.$md$,
$swift$import Foundation

actor TokenBucket {
    init(capacity: Int, refillPerSecond: Double) {}
    func allow(at time: Double) -> Bool {
        // Обновите bucket и примите решение
        return false
    }
}

let config = (readLine() ?? "").split(separator: " ")
let bucket = TokenBucket(capacity: Int(config.first ?? "0") ?? 0,
                         refillPerSecond: Double(config.dropFirst().first ?? "0") ?? 0)
let times = (readLine() ?? "").split(separator: " ").compactMap { Double($0) }
let done = DispatchSemaphore(value: 0)
Task {
    var result: [String] = []
    for time in times { result.append(await bucket.allow(at: time) ? "1" : "0") }
    print(result.joined(separator: " ")); done.signal()
}
done.wait()$swift$,
$solution$import Foundation

actor TokenBucket {
    private let capacity: Double
    private let refillPerSecond: Double
    private var tokens: Double
    private var lastTime: Double?

    init(capacity: Int, refillPerSecond: Double) {
        self.capacity = Double(max(0, capacity)); self.refillPerSecond = max(0, refillPerSecond)
        self.tokens = Double(max(0, capacity))
    }
    func allow(at time: Double) -> Bool {
        if let lastTime { tokens = min(capacity, tokens + max(0, time - lastTime) * refillPerSecond) }
        lastTime = time
        guard tokens >= 1 else { return false }
        tokens -= 1; return true
    }
}

let config = (readLine() ?? "").split(separator: " ")
let bucket = TokenBucket(capacity: Int(config.first ?? "0") ?? 0,
                         refillPerSecond: Double(config.dropFirst().first ?? "0") ?? 0)
let times = (readLine() ?? "").split(separator: " ").compactMap { Double($0) }
let done = DispatchSemaphore(value: 0)
Task {
    var result: [String] = []
    for time in times { result.append(await bucket.allow(at: time) ? "1" : "0") }
    print(result.joined(separator: " ")); done.signal()
}
done.wait()$solution$,4,503),

('concurrency','ios-advanced-cancellation-cutoff','Отмена по общему deadline',
$md$В первой строке задан общий deadline в миллисекундах, во второй — длительности операций. Запустите операции параллельно, по deadline отмените незавершённые и выведите отсортированные индексы успевших операций. Если не успела ни одна — `NONE`.$md$,
$md$Добавьте в task group отдельную deadline-задачу. Результаты отменённых children нельзя считать завершёнными.$md$,
$swift$import Foundation

enum Event: Sendable { case finished(Int), timeout, cancelled }

func completedBeforeDeadline(delays: [UInt64], deadline: UInt64) async -> [Int] {
    // Верните индексы завершившихся до deadline
    return []
}

let deadline = UInt64(readLine() ?? "") ?? 0
let delays = (readLine() ?? "").split(separator: " ").compactMap { UInt64($0) }
let done = DispatchSemaphore(value: 0)
Task {
    let result = await completedBeforeDeadline(delays: delays, deadline: deadline)
    print(result.isEmpty ? "NONE" : result.map(String.init).joined(separator: ",")); done.signal()
}
done.wait()$swift$,
$solution$import Foundation

enum Event: Sendable { case finished(Int), timeout, cancelled }

func completedBeforeDeadline(delays: [UInt64], deadline: UInt64) async -> [Int] {
    await withTaskGroup(of: Event.self) { group in
        for (index, delay) in delays.enumerated() {
            group.addTask {
                do {
                    try await Task.sleep(nanoseconds: delay * 1_000_000)
                    try Task.checkCancellation(); return .finished(index)
                } catch { return .cancelled }
            }
        }
        group.addTask {
            do { try await Task.sleep(nanoseconds: deadline * 1_000_000); return .timeout }
            catch { return .cancelled }
        }
        var completed: [Int] = []
        for await event in group {
            switch event {
            case .finished(let index): completed.append(index)
            case .timeout: group.cancelAll()
            case .cancelled: break
            }
        }
        return completed.sorted()
    }
}

let deadline = UInt64(readLine() ?? "") ?? 0
let delays = (readLine() ?? "").split(separator: " ").compactMap { UInt64($0) }
let done = DispatchSemaphore(value: 0)
Task {
    let result = await completedBeforeDeadline(delays: delays, deadline: deadline)
    print(result.isEmpty ? "NONE" : result.map(String.init).joined(separator: ",")); done.signal()
}
done.wait()$solution$,5,504),

('concurrency','ios-advanced-actor-event-deduplicator','Actor-дедупликация событий',
$md$В строке даны event ID. Отправьте каждый ID отдельной child task в actor, который атомарно принимает только первое появление ID. Выведите уникальные ID в сортированном порядке.$md$,
$md$Операцию contains+insert нужно целиком изолировать внутри одного actor method.$md$,
$swift$import Foundation

actor Deduplicator {
    func accept(_ id: String) -> Bool {
        // Атомарно примите только новый ID
        return false
    }
}

func uniqueEvents(_ ids: [String]) async -> [String] {
    return []
}

let ids = (readLine() ?? "").split(separator: " ").map(String.init)
let done = DispatchSemaphore(value: 0)
Task { print((await uniqueEvents(ids)).joined(separator: ",")); done.signal() }
done.wait()$swift$,
$solution$import Foundation

actor Deduplicator {
    private var seen: Set<String> = []
    func accept(_ id: String) -> Bool {
        if seen.contains(id) { return false }
        seen.insert(id); return true
    }
}

func uniqueEvents(_ ids: [String]) async -> [String] {
    let deduplicator = Deduplicator()
    return await withTaskGroup(of: String?.self) { group in
        for id in ids { group.addTask { await deduplicator.accept(id) ? id : nil } }
        var accepted: [String] = []
        for await id in group { if let id { accepted.append(id) } }
        return accepted.sorted()
    }
}

let ids = (readLine() ?? "").split(separator: " ").map(String.init)
let done = DispatchSemaphore(value: 0)
Task { print((await uniqueEvents(ids)).joined(separator: ",")); done.signal() }
done.wait()$solution$,4,505),

-- UIKit and SwiftUI ---------------------------------------------------------
('uikit-swiftui','ios-advanced-snapshot-duplicate-validator','Валидация diffable snapshot',
$md$В строке задан snapshot как `section:item,item;section:item`. Найдите item identifiers, встречающиеся более одного раза во всём snapshot, и выведите их без повторов в сортированном порядке. Если дубликатов нет — `OK`.$md$,
$md$Diffable data source требует глобальной уникальности item identifier, а не только уникальности внутри секции.$md$,
$swift$import Foundation

func duplicateItems(in snapshot: String) -> [String] {
    // Проверьте identifiers во всех секциях
    return []
}

let input = readLine() ?? ""
let duplicates = duplicateItems(in: input)
print(duplicates.isEmpty ? "OK" : duplicates.joined(separator: ","))$swift$,
$solution$import Foundation

func duplicateItems(in snapshot: String) -> [String] {
    var seen: Set<String> = []; var duplicates: Set<String> = []
    for section in snapshot.split(separator: ";") {
        let parts = section.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { continue }
        for item in parts[1].split(separator: ",").map(String.init) {
            if !seen.insert(item).inserted { duplicates.insert(item) }
        }
    }
    return duplicates.sorted()
}

let input = readLine() ?? ""
let duplicates = duplicateItems(in: input)
print(duplicates.isEmpty ? "OK" : duplicates.joined(separator: ","))$solution$,3,501),

('uikit-swiftui','ios-advanced-navigation-path-diff','Минимальное изменение NavigationPath',
$md$В двух строках заданы текущий и целевой route path через запятую. Найдите общий префикс и выведите минимальные операции `pop N;push route,route`. Если push-часть пуста, используйте `push -`.$md$,
$md$Оставьте longest common prefix, удалите только хвост текущего path и добавьте только хвост целевого.$md$,
$swift$import Foundation

struct PathChange { let popCount: Int; let pushed: [String] }

func change(from current: [String], to target: [String]) -> PathChange {
    // Вычислите минимальную замену хвоста
    return PathChange(popCount: 0, pushed: [])
}

func path(_ line: String) -> [String] { line.isEmpty ? [] : line.split(separator: ",").map(String.init) }
let result = change(from: path(readLine() ?? ""), to: path(readLine() ?? ""))
print("pop \(result.popCount);push \(result.pushed.isEmpty ? "-" : result.pushed.joined(separator: ","))")$swift$,
$solution$import Foundation

struct PathChange { let popCount: Int; let pushed: [String] }

func change(from current: [String], to target: [String]) -> PathChange {
    var common = 0
    while common < current.count && common < target.count && current[common] == target[common] { common += 1 }
    return PathChange(popCount: current.count - common, pushed: Array(target.dropFirst(common)))
}

func path(_ line: String) -> [String] { line.isEmpty ? [] : line.split(separator: ",").map(String.init) }
let result = change(from: path(readLine() ?? ""), to: path(readLine() ?? ""))
print("pop \(result.popCount);push \(result.pushed.isEmpty ? "-" : result.pushed.joined(separator: ","))")$solution$,3,502),

('uikit-swiftui','ios-advanced-layout-size-cache','Кэш layout по width bucket',
$md$Обработайте операции через `;`: `S:id:width:height` сохраняет высоту, `G:id:width` читает, `I:id` инвалидирует все размеры элемента. Ширина нормализуется вниз до bucket, кратного 10. Выведите результаты `G` через запятую (`MISS` при промахе).$md$,
$md$Ключ layout cache должен учитывать identity элемента и нормализованное constraint, а invalidation — удалять все варианты identity.$md$,
$swift$import Foundation

struct SizeKey: Hashable { let id: String; let widthBucket: Int }
struct LayoutCache {
    mutating func set(id: String, width: Int, height: Int) {}
    func get(id: String, width: Int) -> Int? { nil }
    mutating func invalidate(id: String) {}
}

var cache = LayoutCache(); var output: [String] = []
for operation in (readLine() ?? "").split(separator: ";").map(String.init) {
    let p = operation.split(separator: ":").map(String.init)
    if p.first == "S", p.count == 4 { cache.set(id: p[1], width: Int(p[2]) ?? 0, height: Int(p[3]) ?? 0) }
    if p.first == "G", p.count == 3 { output.append(cache.get(id: p[1], width: Int(p[2]) ?? 0).map(String.init) ?? "MISS") }
    if p.first == "I", p.count == 2 { cache.invalidate(id: p[1]) }
}
print(output.joined(separator: ","))$swift$,
$solution$import Foundation

struct SizeKey: Hashable { let id: String; let widthBucket: Int }
struct LayoutCache {
    private var values: [SizeKey: Int] = [:]
    private func key(id: String, width: Int) -> SizeKey { SizeKey(id: id, widthBucket: width / 10 * 10) }
    mutating func set(id: String, width: Int, height: Int) { values[key(id: id, width: width)] = height }
    func get(id: String, width: Int) -> Int? { values[key(id: id, width: width)] }
    mutating func invalidate(id: String) { values = values.filter { $0.key.id != id } }
}

var cache = LayoutCache(); var output: [String] = []
for operation in (readLine() ?? "").split(separator: ";").map(String.init) {
    let p = operation.split(separator: ":").map(String.init)
    if p.first == "S", p.count == 4 { cache.set(id: p[1], width: Int(p[2]) ?? 0, height: Int(p[3]) ?? 0) }
    if p.first == "G", p.count == 3 { output.append(cache.get(id: p[1], width: Int(p[2]) ?? 0).map(String.init) ?? "MISS") }
    if p.first == "I", p.count == 2 { cache.invalidate(id: p[1]) }
}
print(output.joined(separator: ","))$solution$,3,503),

('uikit-swiftui','ios-advanced-list-update-coalescer','Коалесинг обновлений списка',
$md$В строке заданы mutations `I:id`, `U:id`, `D:id` через `;`. Сожмите операции каждого ID: insert+update → insert, insert+delete → ничего, update+delete → delete, delete+insert → update. Порядок результата определяется первым появлением ID. Выведите итоговые mutations через запятую или `NONE`.$md$,
$md$Храните первую позицию ID отдельно от текущего сжатого состояния.$md$,
$swift$import Foundation

enum Mutation: String { case insert = "I", update = "U", delete = "D" }

func coalesce(_ input: [(Mutation, String)]) -> [(Mutation, String)] {
    // Сожмите последовательность без изменения порядка identity
    return []
}

let operations = (readLine() ?? "").split(separator: ";").compactMap { raw -> (Mutation, String)? in
    let p = raw.split(separator: ":"); guard p.count == 2, let kind = Mutation(rawValue: String(p[0])) else { return nil }
    return (kind, String(p[1]))
}
let result = coalesce(operations).map { "\($0.0.rawValue):\($0.1)" }
print(result.isEmpty ? "NONE" : result.joined(separator: ","))$swift$,
$solution$import Foundation

enum Mutation: String { case insert = "I", update = "U", delete = "D" }

func coalesce(_ input: [(Mutation, String)]) -> [(Mutation, String)] {
    var order: [String] = []; var state: [String: Mutation] = [:]
    for (next, id) in input {
        if !order.contains(id) { order.append(id) }
        switch (state[id], next) {
        case (nil, _): state[id] = next
        case (.insert?, .update), (.insert?, .insert): state[id] = .insert
        case (.insert?, .delete): state[id] = nil
        case (.update?, .insert), (.update?, .update): state[id] = .update
        case (.update?, .delete): state[id] = .delete
        case (.delete?, .insert): state[id] = .update
        case (.delete?, _): state[id] = .delete
        }
    }
    return order.compactMap { id in state[id].map { ($0, id) } }
}

let operations = (readLine() ?? "").split(separator: ";").compactMap { raw -> (Mutation, String)? in
    let p = raw.split(separator: ":"); guard p.count == 2, let kind = Mutation(rawValue: String(p[0])) else { return nil }
    return (kind, String(p[1]))
}
let result = coalesce(operations).map { "\($0.0.rawValue):\($0.1)" }
print(result.isEmpty ? "NONE" : result.joined(separator: ","))$solution$,4,504),

('uikit-swiftui','ios-advanced-scroll-anchor-delta','Сохранение scroll anchor',
$md$Первая и вторая строки содержат список `id:height` до и после обновления, третья — anchor ID. Посчитайте изменение Y-координаты начала anchor (`after - before`), чтобы UI мог скорректировать contentOffset. Если anchor отсутствует в одном из списков — `MISSING`.$md$,
$md$Положение anchor равно сумме высот всех элементов перед ним.$md$,
$swift$import Foundation

struct Item { let id: String; let height: Int }
func offset(of anchor: String, in items: [Item]) -> Int? { nil }
func parse(_ line: String) -> [Item] {
    line.split(separator: " ").compactMap { raw in
        let p = raw.split(separator: ":"); guard p.count == 2, let height = Int(p[1]) else { return nil }
        return Item(id: String(p[0]), height: height)
    }
}

let before = parse(readLine() ?? ""), after = parse(readLine() ?? ""), anchor = readLine() ?? ""
if let old = offset(of: anchor, in: before), let new = offset(of: anchor, in: after) { print(new - old) }
else { print("MISSING") }$swift$,
$solution$import Foundation

struct Item { let id: String; let height: Int }
func offset(of anchor: String, in items: [Item]) -> Int? {
    var result = 0
    for item in items {
        if item.id == anchor { return result }
        result += item.height
    }
    return nil
}
func parse(_ line: String) -> [Item] {
    line.split(separator: " ").compactMap { raw in
        let p = raw.split(separator: ":"); guard p.count == 2, let height = Int(p[1]) else { return nil }
        return Item(id: String(p[0]), height: height)
    }
}

let before = parse(readLine() ?? ""), after = parse(readLine() ?? ""), anchor = readLine() ?? ""
if let old = offset(of: anchor, in: before), let new = offset(of: anchor, in: after) { print(new - old) }
else { print("MISSING") }$solution$,3,505),

-- Architecture --------------------------------------------------------------
('architecture','ios-advanced-reducer-effects','Reducer с явными effects',
$md$В строке даны actions `ADD`, `REMOVE`, `CHECKOUT`. Reducer хранит количество товаров: REMOVE не уходит ниже нуля, CHECKOUT при непустой корзине сбрасывает count и создаёт effect `checkout:N`. Выведите `count=X;effects=...` или `effects=NONE`.$md$,
$md$Reducer должен быть детерминированным: state меняется синхронно, а side effect только описывается значением.$md$,
$swift$import Foundation

enum Action: String { case add = "ADD", remove = "REMOVE", checkout = "CHECKOUT" }
enum Effect { case checkout(Int) }
struct State { var count = 0 }

func reduce(state: inout State, action: Action) -> Effect? {
    // Измените state и верните описание effect
    return nil
}

var state = State(); var effects: [String] = []
for action in (readLine() ?? "").split(separator: " ").compactMap({ Action(rawValue: String($0)) }) {
    if case .checkout(let count)? = reduce(state: &state, action: action) { effects.append("checkout:\(count)") }
}
print("count=\(state.count);effects=\(effects.isEmpty ? "NONE" : effects.joined(separator: ","))")$swift$,
$solution$import Foundation

enum Action: String { case add = "ADD", remove = "REMOVE", checkout = "CHECKOUT" }
enum Effect { case checkout(Int) }
struct State { var count = 0 }

func reduce(state: inout State, action: Action) -> Effect? {
    switch action {
    case .add: state.count += 1; return nil
    case .remove: state.count = max(0, state.count - 1); return nil
    case .checkout:
        guard state.count > 0 else { return nil }
        let count = state.count; state.count = 0; return .checkout(count)
    }
}

var state = State(); var effects: [String] = []
for action in (readLine() ?? "").split(separator: " ").compactMap({ Action(rawValue: String($0)) }) {
    if case .checkout(let count)? = reduce(state: &state, action: action) { effects.append("checkout:\(count)") }
}
print("count=\(state.count);effects=\(effects.isEmpty ? "NONE" : effects.joined(separator: ","))")$solution$,3,501),

('architecture','ios-advanced-circuit-breaker','Circuit breaker state machine',
$md$Первая строка содержит `failureThreshold cooldown`, вторая — попытки `time:S` или `time:F`. В CLOSED запросы разрешены; после threshold подряд ошибок breaker открывается. В OPEN запрос до cooldown запрещён, после cooldown разрешена одна проба: S закрывает breaker, F снова открывает. Выведите решения `A/D` и финальный state.$md$,
$md$Смоделируйте CLOSED/OPEN явно; запрещённая попытка не должна менять состояние.$md$,
$swift$import Foundation

enum BreakerState { case closed(failures: Int), open(since: Int) }
struct CircuitBreaker {
    var state: BreakerState = .closed(failures: 0)
    let threshold: Int; let cooldown: Int
    mutating func record(time: Int, success: Bool) -> Bool {
        // Верните false, если запрос запрещён
        return false
    }
}

let config = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
var breaker = CircuitBreaker(threshold: config.first ?? 1, cooldown: config.dropFirst().first ?? 0)
var decisions: [String] = []
for raw in (readLine() ?? "").split(separator: " ") {
    let p = raw.split(separator: ":"); guard p.count == 2, let time = Int(p[0]) else { continue }
    decisions.append(breaker.record(time: time, success: p[1] == "S") ? "A" : "D")
}
let final = { if case .closed = breaker.state { return "CLOSED" }; return "OPEN" }()
print(decisions.joined(separator: ""), final)$swift$,
$solution$import Foundation

enum BreakerState { case closed(failures: Int), open(since: Int) }
struct CircuitBreaker {
    var state: BreakerState = .closed(failures: 0)
    let threshold: Int; let cooldown: Int
    mutating func record(time: Int, success: Bool) -> Bool {
        switch state {
        case .closed(let failures):
            if success { state = .closed(failures: 0) }
            else if failures + 1 >= threshold { state = .open(since: time) }
            else { state = .closed(failures: failures + 1) }
            return true
        case .open(let since):
            guard time - since >= cooldown else { return false }
            state = success ? .closed(failures: 0) : .open(since: time)
            return true
        }
    }
}

let config = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
var breaker = CircuitBreaker(threshold: config.first ?? 1, cooldown: config.dropFirst().first ?? 0)
var decisions: [String] = []
for raw in (readLine() ?? "").split(separator: " ") {
    let p = raw.split(separator: ":"); guard p.count == 2, let time = Int(p[0]) else { continue }
    decisions.append(breaker.record(time: time, success: p[1] == "S") ? "A" : "D")
}
let final = { if case .closed = breaker.state { return "CLOSED" }; return "OPEN" }()
print(decisions.joined(separator: ""), final)$solution$,4,502),

('architecture','ios-advanced-undo-redo-history','Undo/redo без невозможных состояний',
$md$Обработайте команды через `;`: `SET:value`, `UNDO`, `REDO`. Новый SET очищает redo history. Лишние UNDO/REDO ничего не делают. Выведите текущее значение или `NONE`.$md$,
$md$Разделите прошлое, текущее и будущее. REDO удобно хранить стеком в обратном порядке восстановления.$md$,
$swift$import Foundation

struct History {
    private(set) var current: String?
    mutating func set(_ value: String) {}
    mutating func undo() {}
    mutating func redo() {}
}

var history = History()
for command in (readLine() ?? "").split(separator: ";").map(String.init) {
    if command.hasPrefix("SET:") { history.set(String(command.dropFirst(4))) }
    else if command == "UNDO" { history.undo() }
    else if command == "REDO" { history.redo() }
}
print(history.current ?? "NONE")$swift$,
$solution$import Foundation

struct History {
    private var past: [String] = []; private var future: [String] = []
    private(set) var current: String?
    mutating func set(_ value: String) {
        if let current { past.append(current) }
        current = value; future.removeAll()
    }
    mutating func undo() {
        guard let current else { return }
        future.append(current); self.current = past.popLast()
    }
    mutating func redo() {
        guard let next = future.popLast() else { return }
        if let current { past.append(current) }
        current = next
    }
}

var history = History()
for command in (readLine() ?? "").split(separator: ";").map(String.init) {
    if command.hasPrefix("SET:") { history.set(String(command.dropFirst(4))) }
    else if command == "UNDO" { history.undo() }
    else if command == "REDO" { history.redo() }
}
print(history.current ?? "NONE")$solution$,3,503),

('architecture','ios-advanced-domain-error-mapper','Маппинг transport errors в domain',
$md$В строке заданы ошибки `offline 401 403 404 429 5xx decode timeout cancelled`. Преобразуйте их в доменные категории `network`, `auth`, `forbidden`, `missing`, `rateLimited`, `server`, `invalidData`, `timeout`, `cancelled`; неизвестное — `unknown`. Выведите через запятую.$md$,
$md$Transport status и низкоуровневые ошибки должны преобразовываться один раз на boundary слоя.$md$,
$swift$import Foundation

enum DomainError: String { case network, auth, forbidden, missing, rateLimited, server, invalidData, timeout, cancelled, unknown }
func mapError(_ raw: String) -> DomainError {
    // Реализуйте исчерпывающий mapping
    return .unknown
}

print((readLine() ?? "").split(separator: " ").map { mapError(String($0)).rawValue }.joined(separator: ","))$swift$,
$solution$import Foundation

enum DomainError: String { case network, auth, forbidden, missing, rateLimited, server, invalidData, timeout, cancelled, unknown }
func mapError(_ raw: String) -> DomainError {
    switch raw {
    case "offline": return .network
    case "401": return .auth
    case "403": return .forbidden
    case "404": return .missing
    case "429": return .rateLimited
    case "5xx": return .server
    case "decode": return .invalidData
    case "timeout": return .timeout
    case "cancelled": return .cancelled
    default: return .unknown
    }
}

print((readLine() ?? "").split(separator: " ").map { mapError(String($0)).rawValue }.joined(separator: ","))$solution$,2,504),

('architecture','ios-advanced-effect-generation-registry','Защита от stale effects',
$md$Обработайте события через `;`: `START:key:generation`, `CANCEL:key`, `FINISH:key:generation`. FINISH принимается только если generation всё ещё активна для key, после чего удаляется. Выведите принятые generation через запятую или `NONE`.$md$,
$md$Проверяйте identity запущенного effect, а не только key экрана: старый ответ не должен затереть новый.$md$,
$swift$import Foundation

struct EffectRegistry {
    mutating func start(key: String, generation: String) {}
    mutating func cancel(key: String) {}
    mutating func finish(key: String, generation: String) -> Bool { false }
}

var registry = EffectRegistry(); var accepted: [String] = []
for event in (readLine() ?? "").split(separator: ";") {
    let p = event.split(separator: ":").map(String.init)
    if p.first == "START", p.count == 3 { registry.start(key: p[1], generation: p[2]) }
    if p.first == "CANCEL", p.count == 2 { registry.cancel(key: p[1]) }
    if p.first == "FINISH", p.count == 3, registry.finish(key: p[1], generation: p[2]) { accepted.append(p[2]) }
}
print(accepted.isEmpty ? "NONE" : accepted.joined(separator: ","))$swift$,
$solution$import Foundation

struct EffectRegistry {
    private var active: [String: String] = [:]
    mutating func start(key: String, generation: String) { active[key] = generation }
    mutating func cancel(key: String) { active[key] = nil }
    mutating func finish(key: String, generation: String) -> Bool {
        guard active[key] == generation else { return false }
        active[key] = nil; return true
    }
}

var registry = EffectRegistry(); var accepted: [String] = []
for event in (readLine() ?? "").split(separator: ";") {
    let p = event.split(separator: ":").map(String.init)
    if p.first == "START", p.count == 3 { registry.start(key: p[1], generation: p[2]) }
    if p.first == "CANCEL", p.count == 2 { registry.cancel(key: p[1]) }
    if p.first == "FINISH", p.count == 3, registry.finish(key: p[1], generation: p[2]) { accepted.append(p[2]) }
}
print(accepted.isEmpty ? "NONE" : accepted.joined(separator: ","))$solution$,4,505),

-- Mobile system design ------------------------------------------------------
('system-design','ios-advanced-cache-revalidation-policy','HTTP cache revalidation policy',
$md$В строке заданы `now fetchedAt maxAge hasETag online`; `fetchedAt=-1` означает отсутствие cache. Верните: свежий cache → `CACHE`; stale online с ETag → `REVALIDATE`; stale online без ETag → `FETCH`; stale offline → `STALE`; cache отсутствует online → `FETCH`, offline → `ERROR`.$md$,
$md$Сначала отделите отсутствие representation от freshness, затем применяйте network policy.$md$,
$swift$import Foundation

enum Decision: String { case cache = "CACHE", revalidate = "REVALIDATE", fetch = "FETCH", stale = "STALE", error = "ERROR" }
func decide(now: Int, fetchedAt: Int?, maxAge: Int, hasETag: Bool, online: Bool) -> Decision {
    // Реализуйте policy без сетевых side effects
    return .error
}

let p = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
guard p.count == 5 else { fatalError("expected five values") }
print(decide(now: p[0], fetchedAt: p[1] < 0 ? nil : p[1], maxAge: p[2], hasETag: p[3] == 1, online: p[4] == 1).rawValue)$swift$,
$solution$import Foundation

enum Decision: String { case cache = "CACHE", revalidate = "REVALIDATE", fetch = "FETCH", stale = "STALE", error = "ERROR" }
func decide(now: Int, fetchedAt: Int?, maxAge: Int, hasETag: Bool, online: Bool) -> Decision {
    guard let fetchedAt else { return online ? .fetch : .error }
    if max(0, now - fetchedAt) <= maxAge { return .cache }
    guard online else { return .stale }
    return hasETag ? .revalidate : .fetch
}

let p = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
guard p.count == 5 else { fatalError("expected five values") }
print(decide(now: p[0], fetchedAt: p[1] < 0 ? nil : p[1], maxAge: p[2], hasETag: p[3] == 1, online: p[4] == 1).rawValue)$solution$,3,501),

('system-design','ios-advanced-websocket-gap-detector','Sequence gap detector',
$md$В первой строке задан ожидаемый sequence, во второй приходит возрастающий поток sequence numbers с возможными дублями и пропусками. Выведите `missing=` с диапазонами и `duplicates=` со значениями; например `missing=2-4,7;duplicates=6`. Если список пуст — `NONE`.$md$,
$md$При seq больше expected фиксируйте закрытый диапазон gap; при seq меньше expected — duplicate/stale delivery.$md$,
$swift$import Foundation

struct GapReport { let missing: [String]; let duplicates: [Int] }
func inspect(expected start: Int, sequences: [Int]) -> GapReport {
    // Один проход по потоку
    return GapReport(missing: [], duplicates: [])
}

let start = Int(readLine() ?? "") ?? 0
let report = inspect(expected: start, sequences: (readLine() ?? "").split(separator: " ").compactMap { Int($0) })
print("missing=\(report.missing.isEmpty ? "NONE" : report.missing.joined(separator: ","));duplicates=\(report.duplicates.isEmpty ? "NONE" : report.duplicates.map(String.init).joined(separator: ","))")$swift$,
$solution$import Foundation

struct GapReport { let missing: [String]; let duplicates: [Int] }
func inspect(expected start: Int, sequences: [Int]) -> GapReport {
    var expected = start; var missing: [String] = []; var duplicates: [Int] = []
    for sequence in sequences {
        if sequence < expected { duplicates.append(sequence); continue }
        if sequence > expected {
            missing.append(sequence - expected == 1 ? String(expected) : "\(expected)-\(sequence - 1)")
        }
        expected = sequence + 1
    }
    return GapReport(missing: missing, duplicates: duplicates)
}

let start = Int(readLine() ?? "") ?? 0
let report = inspect(expected: start, sequences: (readLine() ?? "").split(separator: " ").compactMap { Int($0) })
print("missing=\(report.missing.isEmpty ? "NONE" : report.missing.joined(separator: ","));duplicates=\(report.duplicates.isEmpty ? "NONE" : report.duplicates.map(String.init).joined(separator: ","))")$solution$,4,502),

('system-design','ios-advanced-payload-batch-planner','Планирование payload batches',
$md$Первая строка — максимальный размер batch, вторая — элементы `id:size` в порядке отправки. Разбейте их жадно на минимальное число последовательных batches, не меняя порядок; batches разделите `|`, ID внутри — запятой. Если один элемент больше лимита — `IMPOSSIBLE`.$md$,
$md$При фиксированном порядке жадное заполнение текущего batch оптимально по числу batches.$md$,
$swift$import Foundation

struct Payload { let id: String; let size: Int }
func batches(_ items: [Payload], limit: Int) -> [[String]]? {
    // Сохраните исходный порядок
    return nil
}

let limit = Int(readLine() ?? "") ?? 0
let items = (readLine() ?? "").split(separator: " ").compactMap { raw -> Payload? in
    let p = raw.split(separator: ":"); guard p.count == 2, let size = Int(p[1]) else { return nil }
    return Payload(id: String(p[0]), size: size)
}
if let result = batches(items, limit: limit) { print(result.map { $0.joined(separator: ",") }.joined(separator: "|")) }
else { print("IMPOSSIBLE") }$swift$,
$solution$import Foundation

struct Payload { let id: String; let size: Int }
func batches(_ items: [Payload], limit: Int) -> [[String]]? {
    guard limit >= 0, items.allSatisfy({ $0.size <= limit }) else { return nil }
    var result: [[String]] = []; var current: [String] = []; var used = 0
    for item in items {
        if !current.isEmpty && used + item.size > limit { result.append(current); current = []; used = 0 }
        current.append(item.id); used += item.size
    }
    if !current.isEmpty { result.append(current) }
    return result
}

let limit = Int(readLine() ?? "") ?? 0
let items = (readLine() ?? "").split(separator: " ").compactMap { raw -> Payload? in
    let p = raw.split(separator: ":"); guard p.count == 2, let size = Int(p[1]) else { return nil }
    return Payload(id: String(p[0]), size: size)
}
if let result = batches(items, limit: limit) { print(result.map { $0.joined(separator: ",") }.joined(separator: "|")) }
else { print("IMPOSSIBLE") }$solution$,3,503),

('system-design','ios-advanced-sync-conflict-classifier','Классификация sync conflict',
$md$В строке заданы `baseVersion localVersion remoteVersion dirty(0/1)`. Верните `UNCHANGED`, если local=remote; `REMOTE`, если локальных изменений нет или local=base; `LOCAL`, если remote=base; иначе `CONFLICT`.$md$,
$md$Версии — surrogate для server revision. Порядок правил важен: равенство сторон проверяется первым.$md$,
$swift$import Foundation

enum Resolution: String { case unchanged = "UNCHANGED", remote = "REMOTE", local = "LOCAL", conflict = "CONFLICT" }
func classify(base: Int, local: Int, remote: Int, dirty: Bool) -> Resolution {
    // Реализуйте deterministic policy
    return .conflict
}

let p = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
guard p.count == 4 else { fatalError("expected four values") }
print(classify(base: p[0], local: p[1], remote: p[2], dirty: p[3] == 1).rawValue)$swift$,
$solution$import Foundation

enum Resolution: String { case unchanged = "UNCHANGED", remote = "REMOTE", local = "LOCAL", conflict = "CONFLICT" }
func classify(base: Int, local: Int, remote: Int, dirty: Bool) -> Resolution {
    if local == remote { return .unchanged }
    if !dirty || local == base { return .remote }
    if remote == base { return .local }
    return .conflict
}

let p = (readLine() ?? "").split(separator: " ").compactMap { Int($0) }
guard p.count == 4 else { fatalError("expected four values") }
print(classify(base: p[0], local: p[1], remote: p[2], dirty: p[3] == 1).rawValue)$solution$,3,504),

('system-design','ios-advanced-weighted-request-scheduler','Priority scheduler с budget',
$md$В первой строке задан token budget, во второй — запросы `id:priority:cost`. Стабильно отсортируйте запросы по убыванию priority и жадно возьмите те, чья cost помещается в остаток budget. Выведите выбранные ID через запятую или `NONE`.$md$,
$md$Для равного priority сохраните исходный порядок, добавив исходный index в sort key.$md$,
$swift$import Foundation

struct Request { let id: String; let priority: Int; let cost: Int; let index: Int }
func schedule(_ requests: [Request], budget: Int) -> [String] {
    // Верните выбранные ID в порядке исполнения
    return []
}

let budget = Int(readLine() ?? "") ?? 0
let requests = (readLine() ?? "").split(separator: " ").enumerated().compactMap { index, raw -> Request? in
    let p = raw.split(separator: ":"); guard p.count == 3, let priority = Int(p[1]), let cost = Int(p[2]) else { return nil }
    return Request(id: String(p[0]), priority: priority, cost: cost, index: index)
}
let result = schedule(requests, budget: budget)
print(result.isEmpty ? "NONE" : result.joined(separator: ","))$swift$,
$solution$import Foundation

struct Request { let id: String; let priority: Int; let cost: Int; let index: Int }
func schedule(_ requests: [Request], budget: Int) -> [String] {
    var remaining = max(0, budget); var result: [String] = []
    let ordered = requests.sorted { $0.priority == $1.priority ? $0.index < $1.index : $0.priority > $1.priority }
    for request in ordered where request.cost <= remaining {
        result.append(request.id); remaining -= request.cost
    }
    return result
}

let budget = Int(readLine() ?? "") ?? 0
let requests = (readLine() ?? "").split(separator: " ").enumerated().compactMap { index, raw -> Request? in
    let p = raw.split(separator: ":"); guard p.count == 3, let priority = Int(p[1]), let cost = Int(p[2]) else { return nil }
    return Request(id: String(p[0]), priority: priority, cost: cost, index: index)
}
let result = schedule(requests, budget: budget)
print(result.isEmpty ? "NONE" : result.joined(separator: ","))$solution$,4,505)
)
INSERT INTO coding_tasks
(topic_id,slug,title,statement_markdown,hint,language,starter_code,reference_solution,time_limit_ms,memory_limit_kb,difficulty,position,status)
SELECT tp.id,t.slug,t.title,t.statement_markdown,t.hint,'swift',t.starter_code,t.reference_solution,
       5000,262144,t.difficulty,t.position,'published'
FROM task_data t
JOIN sections s ON s.slug=t.section_slug
JOIN tracks tr ON tr.id=s.track_id AND tr.slug='interview'
JOIN directions d ON d.id=tr.direction_id AND d.slug='ios'
JOIN topics tp ON tp.section_id=s.id AND tp.slug='main'
ON CONFLICT (topic_id,slug) DO NOTHING;

WITH test_data(task_slug,stdin,expected_stdout,position) AS (VALUES
('ios-advanced-lossy-decodable-array',$in$[{"id":1,"name":"A"},{"id":"bad","name":"B"},{"id":3,"name":"C"}]
$in$,$out$1:A,3:C
$out$,1),
('ios-advanced-lossy-decodable-array',$in$[]
$in$,$out$
$out$,2),
('ios-advanced-semver-sort',$in$1.0.0 1.0.0-alpha 1.0.0-alpha.1 1.0.0-alpha.beta 2.0.0
$in$,$out$1.0.0-alpha 1.0.0-alpha.1 1.0.0-alpha.beta 1.0.0 2.0.0
$out$,1),
('ios-advanced-semver-sort',$in$1.0.0+build 1.0.0-beta.11 1.0.0-beta.2
$in$,$out$1.0.0-beta.2 1.0.0-beta.11 1.0.0+build
$out$,2),
('ios-advanced-unicode-rle',$in$aa👩‍💻👩‍💻b
$in$,$out$a:2|👩‍💻:2|b:1
$out$,1),
('ios-advanced-unicode-rle',$in$
$in$,$out$
$out$,2),
('ios-advanced-bracket-error-index',$in$func(a[0]) {}
$in$,$out$OK
$out$,1),
('ios-advanced-bracket-error-index',$in$([)]
$in$,$out$ERROR 2
$out$,2),
('ios-advanced-minimum-window',$in$ADOBECODEBANC
ABC
$in$,$out$BANC
$out$,1),
('ios-advanced-minimum-window',$in$a🙂b🙂c
🙂c
$in$,$out$🙂c
$out$,2),

('ios-advanced-weak-parent-tree',$in$$in$,$out$released released
$out$,1),
('ios-advanced-weak-parent-tree',$in$ignored
$in$,$out$released released
$out$,2),
('ios-advanced-cancellation-bag',$in$3
$in$,$out$3
$out$,1),
('ios-advanced-cancellation-bag',$in$0
$in$,$out$0
$out$,2),
('ios-advanced-capture-snapshot',$in$first
second
$in$,$out$first second
$out$,1),
('ios-advanced-capture-snapshot',$in$🙂
updated
$in$,$out$🙂 updated
$out$,2),
('ios-advanced-weak-value-cache',$in$one two
$in$,$out$b
$out$,1),
('ios-advanced-weak-value-cache',$in$one
$in$,$out$
$out$,2),
('ios-advanced-observation-token',$in$$in$,$out$released 0
$out$,1),
('ios-advanced-observation-token',$in$ignored
$in$,$out$released 0
$out$,2),

('ios-advanced-first-success-race',$in$7:80 -1:5 3:20
$in$,$out$3
$out$,1),
('ios-advanced-first-success-race',$in$-1:1 -2:2
$in$,$out$NONE
$out$,2),
('ios-advanced-quorum-task-group',$in$2
7:40 -1:1 3:10 9:20
$in$,$out$3,9
$out$,1),
('ios-advanced-quorum-task-group',$in$3
1:2 -2:1 4:3
$in$,$out$IMPOSSIBLE
$out$,2),
('ios-advanced-actor-token-bucket',$in$2 1
0 0 0.5 1 2
$in$,$out$1 1 0 1 1
$out$,1),
('ios-advanced-actor-token-bucket',$in$1 0
0 10 20
$in$,$out$1 0 0
$out$,2),
('ios-advanced-cancellation-cutoff',$in$20
2 50 4
$in$,$out$0,2
$out$,1),
('ios-advanced-cancellation-cutoff',$in$1
40 50
$in$,$out$NONE
$out$,2),
('ios-advanced-actor-event-deduplicator',$in$c a b a c d
$in$,$out$a,b,c,d
$out$,1),
('ios-advanced-actor-event-deduplicator',$in$one
$in$,$out$one
$out$,2),

('ios-advanced-snapshot-duplicate-validator',$in$A:a,b;B:c,a
$in$,$out$a
$out$,1),
('ios-advanced-snapshot-duplicate-validator',$in$A:a,b;B:c,d
$in$,$out$OK
$out$,2),
('ios-advanced-navigation-path-diff',$in$home,list,item
home,settings
$in$,$out$pop 2;push settings
$out$,1),
('ios-advanced-navigation-path-diff',$in$home,list
home,list
$in$,$out$pop 0;push -
$out$,2),
('ios-advanced-layout-size-cache',$in$S:a:101:40;G:a:109;G:a:110;S:a:115:50;G:a:119
$in$,$out$40,MISS,50
$out$,1),
('ios-advanced-layout-size-cache',$in$S:a:100:40;S:a:120:60;I:a;G:a:100;G:a:120
$in$,$out$MISS,MISS
$out$,2),
('ios-advanced-list-update-coalescer',$in$I:a;U:a;I:b;D:b;U:c;D:c
$in$,$out$I:a,D:c
$out$,1),
('ios-advanced-list-update-coalescer',$in$D:a;I:a;U:b;U:b
$in$,$out$U:a,U:b
$out$,2),
('ios-advanced-scroll-anchor-delta',$in$a:10 b:20 c:30
x:5 a:10 b:25 c:30
c
$in$,$out$10
$out$,1),
('ios-advanced-scroll-anchor-delta',$in$a:10 b:20
a:10
b
$in$,$out$MISSING
$out$,2),

('ios-advanced-reducer-effects',$in$ADD ADD REMOVE CHECKOUT ADD
$in$,$out$count=1;effects=checkout:1
$out$,1),
('ios-advanced-reducer-effects',$in$REMOVE CHECKOUT
$in$,$out$count=0;effects=NONE
$out$,2),
('ios-advanced-circuit-breaker',$in$2 10
0:F 1:F 5:S 11:S
$in$,$out$AADA CLOSED
$out$,1),
('ios-advanced-circuit-breaker',$in$1 5
0:F 3:S 5:F 9:S
$in$,$out$ADAD OPEN
$out$,2),
('ios-advanced-undo-redo-history',$in$SET:a;SET:b;SET:c;UNDO;UNDO;REDO
$in$,$out$b
$out$,1),
('ios-advanced-undo-redo-history',$in$SET:a;UNDO;SET:z;REDO
$in$,$out$z
$out$,2),
('ios-advanced-domain-error-mapper',$in$offline 401 403 404 429 5xx decode timeout cancelled what
$in$,$out$network,auth,forbidden,missing,rateLimited,server,invalidData,timeout,cancelled,unknown
$out$,1),
('ios-advanced-domain-error-mapper',$in$401 offline
$in$,$out$auth,network
$out$,2),
('ios-advanced-effect-generation-registry',$in$START:q:1;START:q:2;FINISH:q:1;FINISH:q:2
$in$,$out$2
$out$,1),
('ios-advanced-effect-generation-registry',$in$START:a:x;CANCEL:a;FINISH:a:x
$in$,$out$NONE
$out$,2),

('ios-advanced-cache-revalidation-policy',$in$100 80 30 1 1
$in$,$out$CACHE
$out$,1),
('ios-advanced-cache-revalidation-policy',$in$100 20 30 1 1
$in$,$out$REVALIDATE
$out$,2),
('ios-advanced-websocket-gap-detector',$in$1
1 4 4 6
$in$,$out$missing=2-3,5;duplicates=4
$out$,1),
('ios-advanced-websocket-gap-detector',$in$10
10 11 12
$in$,$out$missing=NONE;duplicates=NONE
$out$,2),
('ios-advanced-payload-batch-planner',$in$10
a:4 b:6 c:3 d:7
$in$,$out$a,b|c,d
$out$,1),
('ios-advanced-payload-batch-planner',$in$5
a:6 b:1
$in$,$out$IMPOSSIBLE
$out$,2),
('ios-advanced-sync-conflict-classifier',$in$1 2 1 1
$in$,$out$LOCAL
$out$,1),
('ios-advanced-sync-conflict-classifier',$in$1 2 3 1
$in$,$out$CONFLICT
$out$,2),
('ios-advanced-weighted-request-scheduler',$in$8
a:2:4 b:3:5 c:2:3 d:1:1
$in$,$out$b,c
$out$,1),
('ios-advanced-weighted-request-scheduler',$in$2
a:5:3 b:1:2
$in$,$out$b
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

-- Every new archetype is also rehearsed in twenty interview modes. The code
-- and fixtures stay executable; only the interview constraint changes.
WITH base_tasks AS (
 SELECT ct.*,s.position AS section_position,
        row_number() OVER (ORDER BY s.position,ct.position,ct.slug) AS base_no
 FROM coding_tasks ct
 JOIN topics tp ON tp.id=ct.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND ct.status='published'
   AND ct.slug LIKE 'ios-advanced-%' AND ct.slug NOT LIKE 'ios-advanced-drill-%'
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
        'ios-advanced-drill-' || lpad((((b.base_no-1)*20)+f.drill_no)::text,4,'0') || '-' || b.slug AS slug,
        b.title || ' · ' || f.label AS title,
        b.statement_markdown || E'\n\n## Режим интервью\n' || f.instruction AS statement_markdown,
        b.hint,b.language,b.starter_code,b.reference_solution,b.time_limit_ms,b.memory_limit_kb,
        LEAST(5,b.difficulty+f.difficulty_delta) AS difficulty,
        40000 + ((b.base_no-1)*20)+f.drill_no AS position
 FROM base_tasks b CROSS JOIN drill_frames f
)
INSERT INTO coding_tasks
(topic_id,slug,title,statement_markdown,hint,language,starter_code,reference_solution,time_limit_ms,memory_limit_kb,difficulty,position,status)
SELECT topic_id,slug,title,statement_markdown,hint,language,starter_code,reference_solution,
       time_limit_ms,memory_limit_kb,difficulty,position,'published'
FROM generated_tasks
ON CONFLICT (topic_id,slug) DO NOTHING;

WITH base_tasks AS (
 SELECT ct.*,s.position AS section_position,
        row_number() OVER (ORDER BY s.position,ct.position,ct.slug) AS base_no
 FROM coding_tasks ct
 JOIN topics tp ON tp.id=ct.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND ct.status='published'
   AND ct.slug LIKE 'ios-advanced-%' AND ct.slug NOT LIKE 'ios-advanced-drill-%'
),
drill_numbers AS (SELECT generate_series(1,20) AS drill_no),
generated AS (
 SELECT b.id AS base_task_id,b.topic_id,
        'ios-advanced-drill-' || lpad((((b.base_no-1)*20)+n.drill_no)::text,4,'0') || '-' || b.slug AS slug
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
 WHERE d.slug='ios' AND tr.slug='interview' AND ct.slug LIKE 'ios-advanced-%'
);
DELETE FROM coding_tasks
WHERE id IN (
 SELECT ct.id FROM coding_tasks ct
 JOIN topics tp ON tp.id=ct.topic_id
 JOIN sections s ON s.id=tp.section_id
 JOIN tracks tr ON tr.id=s.track_id
 JOIN directions d ON d.id=tr.direction_id
 WHERE d.slug='ios' AND tr.slug='interview' AND ct.slug LIKE 'ios-advanced-%'
);
