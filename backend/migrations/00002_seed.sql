-- +goose Up
INSERT INTO directions (id, slug, short_name, name, position, status) VALUES
    ('10000000-0000-4000-8000-000000000001', 'ios', 'iOS', 'iOS Development', 1, 'published'),
    ('10000000-0000-4000-8000-000000000002', 'go', 'Go', 'Go Development', 2, 'published')
ON CONFLICT (slug) DO UPDATE SET short_name = EXCLUDED.short_name, name = EXCLUDED.name, position = EXCLUDED.position;

INSERT INTO tracks (id, direction_id, slug, title, description, position, status) VALUES
    ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'interview', 'Подготовка к собеседованиям iOS', 'Теоретические вопросы и практические задачи с технических интервью.', 1, 'published'),
    ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'learning', 'Изучение iOS', 'Материал, темы, практические задачи и проекты для системного изучения iOS.', 2, 'published'),
    ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'interview', 'Подготовка к собеседованиям Go', 'Теория, runtime и практические backend-задачи с интервью.', 1, 'published'),
    ('20000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000002', 'learning', 'Изучение Go', 'Последовательный путь от синтаксиса до конкурентного backend и баз данных.', 2, 'published')
ON CONFLICT (direction_id, slug) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, position = EXCLUDED.position;

INSERT INTO sections (id, track_id, slug, title, description, icon, position, status) VALUES
    ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'swift-core', 'Swift Core', 'Value/reference types, generics, protocols и dispatch', '{ }', 1, 'published'),
    ('30000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', 'arc-memory', 'ARC и память', 'Strong, weak, unowned, capture lists и retain cycles', '∞', 2, 'published'),
    ('30000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000001', 'concurrency', 'Concurrency', 'GCD, async/await, actors и Sendable', '⇄', 3, 'published'),
    ('30000000-0000-4000-8000-000000000004', '20000000-0000-4000-8000-000000000001', 'uikit-swiftui', 'UIKit & SwiftUI', 'Lifecycle, layout, state и rendering', '▦', 4, 'published'),
    ('30000000-0000-4000-8000-000000000005', '20000000-0000-4000-8000-000000000001', 'architecture', 'Архитектура', 'MVC, MVVM, Coordinator и dependency injection', '◇', 5, 'published'),
    ('30000000-0000-4000-8000-000000000006', '20000000-0000-4000-8000-000000000001', 'system-design', 'System Design', 'Сеть, кэш, офлайн-режим и наблюдаемость', '⌘', 6, 'published'),
    ('30000000-0000-4000-8000-000000000007', '20000000-0000-4000-8000-000000000002', 'swift-basics', 'Swift: основы', 'Типы, функции, коллекции, optional и обработка ошибок', '{ }', 1, 'published'),
    ('30000000-0000-4000-8000-000000000008', '20000000-0000-4000-8000-000000000002', 'oop-protocols', 'ООП и протоколы', 'Структуры, классы, протоколы, generics и композиция', '◇', 2, 'published'),
    ('30000000-0000-4000-8000-000000000009', '20000000-0000-4000-8000-000000000002', 'uikit', 'UIKit', 'Lifecycle, layout, navigation и переиспользуемые экраны', '▦', 3, 'published'),
    ('30000000-0000-4000-8000-000000000010', '20000000-0000-4000-8000-000000000002', 'swiftui', 'SwiftUI', 'State, bindings, environment, navigation и rendering', '◫', 4, 'published'),
    ('30000000-0000-4000-8000-000000000011', '20000000-0000-4000-8000-000000000002', 'network-data', 'Сеть и данные', 'URLSession, Codable, кэш, Core Data и offline-first', '◎', 5, 'published'),
    ('30000000-0000-4000-8000-000000000012', '20000000-0000-4000-8000-000000000002', 'tests-project', 'Тесты и проект', 'Unit/UI tests и итоговое приложение с API', '✓', 6, 'published'),
    ('30000000-0000-4000-8000-000000000013', '20000000-0000-4000-8000-000000000003', 'language-interfaces', 'Язык и интерфейсы', 'Методы, embedding, nil, errors и tricky-вопросы', '{ }', 1, 'published'),
    ('30000000-0000-4000-8000-000000000014', '20000000-0000-4000-8000-000000000003', 'runtime-memory', 'Runtime и память', 'Scheduler, stack growth, escape analysis и GC', '∞', 2, 'published'),
    ('30000000-0000-4000-8000-000000000015', '20000000-0000-4000-8000-000000000003', 'concurrency', 'Конкурентность', 'Channels, select, context, mutex и race conditions', '⇄', 3, 'published'),
    ('30000000-0000-4000-8000-000000000016', '20000000-0000-4000-8000-000000000003', 'backend-network', 'Backend и сети', 'HTTP, TCP, middleware, gRPC и graceful shutdown', '◎', 4, 'published'),
    ('30000000-0000-4000-8000-000000000017', '20000000-0000-4000-8000-000000000003', 'databases', 'Базы данных', 'SQL, транзакции, индексы и конкурентный доступ', '▤', 5, 'published'),
    ('30000000-0000-4000-8000-000000000018', '20000000-0000-4000-8000-000000000003', 'system-design', 'System Design', 'Очереди, кэш, масштабирование и отказоустойчивость', '◇', 6, 'published'),
    ('30000000-0000-4000-8000-000000000019', '20000000-0000-4000-8000-000000000004', 'language-basics', 'Основы языка', 'Типы, функции, структуры, интерфейсы и ошибки', '{ }', 1, 'published'),
    ('30000000-0000-4000-8000-000000000020', '20000000-0000-4000-8000-000000000004', 'collections-memory', 'Коллекции и память', 'Slices, maps, pointers, escape analysis и GC', '[]', 2, 'published'),
    ('30000000-0000-4000-8000-000000000021', '20000000-0000-4000-8000-000000000004', 'goroutines', 'Горутины', 'Channels, select, context и sync primitives', '⇄', 3, 'published'),
    ('30000000-0000-4000-8000-000000000022', '20000000-0000-4000-8000-000000000004', 'backend', 'Backend', 'HTTP, middleware, REST, gRPC и конфигурация', '◎', 4, 'published'),
    ('30000000-0000-4000-8000-000000000023', '20000000-0000-4000-8000-000000000004', 'storage', 'Хранение данных', 'SQL, транзакции, индексы, Redis и миграции', '▤', 5, 'published'),
    ('30000000-0000-4000-8000-000000000024', '20000000-0000-4000-8000-000000000004', 'tests-project', 'Тесты и проект', 'Table tests, race detector, benchmarks и итоговый сервис', '✓', 6, 'published')
ON CONFLICT (track_id, slug) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description, icon = EXCLUDED.icon, position = EXCLUDED.position;

INSERT INTO topics (id, section_id, slug, title, description, position, status)
SELECT ('40000000-0000-4000-8000-' || lpad(row_number() OVER (ORDER BY id)::text, 12, '0'))::uuid,
       id, 'main', title, description, 1, 'published'
FROM sections
ON CONFLICT (section_id, slug) DO NOTHING;

WITH question_data(direction_slug, section_slug, position, prompt) AS (VALUES
    ('ios', 'swift-core', 1, 'В чём практическая разница между value type и reference type в Swift?'),
    ('ios', 'arc-memory', 2, 'Как ARC освобождает память и из-за чего возникает retain cycle?'),
    ('ios', 'arc-memory', 3, 'Когда использовать weak, а когда unowned ссылку?'),
    ('ios', 'concurrency', 4, 'Чем Task, async let и TaskGroup отличаются друг от друга?'),
    ('ios', 'uikit-swiftui', 5, 'Опишите жизненный цикл UIViewController и типичные ошибки в нём.'),
    ('ios', 'system-design', 6, 'Как бы вы спроектировали кэширование изображений для большой ленты?'),
    ('ios', 'swift-core', 7, 'Чем protocol witness table отличается от dynamic dispatch через Objective-C runtime?'),
    ('ios', 'swift-core', 8, 'Как Copy-on-Write работает в стандартных коллекциях Swift?'),
    ('ios', 'arc-memory', 9, 'Почему escaping-замыкание может потребовать явного self?'),
    ('ios', 'concurrency', 10, 'Чем actor отличается от serial DispatchQueue?'),
    ('ios', 'concurrency', 11, 'Что такое Sendable и какие проблемы он помогает обнаружить?'),
    ('ios', 'swift-core', 12, 'Как устроена обработка ошибок через throws, Result и async throws?'),
    ('ios', 'uikit-swiftui', 13, 'Какие этапы проходит Auto Layout при вычислении и применении размеров?'),
    ('ios', 'uikit-swiftui', 14, 'Как SwiftUI определяет, какую часть дерева представлений нужно обновить?'),
    ('ios', 'architecture', 15, 'Когда выбрать struct, final class или actor для новой модели?'),
    ('ios', 'architecture', 16, 'Как организовать dependency injection без глобального service locator?'),
    ('ios', 'architecture', 17, 'Какие уровни тестирования нужны iOS-приложению и что проверять на каждом?'),
    ('ios', 'system-design', 18, 'Как сделать сетевой слой устойчивым к отмене, повторным запросам и потере сети?'),
    ('ios', 'uikit-swiftui', 19, 'Что происходит с приложением при переходе между active, inactive и background?'),
    ('ios', 'system-design', 20, 'Как спроектировать офлайн-синхронизацию с разрешением конфликтов?'),
    ('go', 'language-interfaces', 1, 'Как устроен interface в Go и почему interface с nil-указателем может быть не nil?'),
    ('go', 'runtime-memory', 2, 'Как планировщик Go распределяет goroutine между системными потоками?'),
    ('go', 'concurrency', 3, 'Кто должен закрывать channel и что произойдёт при записи в закрытый channel?'),
    ('go', 'concurrency', 4, 'Как правильно распространять отмену операции через context?'),
    ('go', 'language-interfaces', 5, 'Чем длина slice отличается от capacity и когда происходит перевыделение массива?'),
    ('go', 'backend-network', 6, 'Как бы вы спроектировали graceful shutdown для HTTP-сервиса?'),
    ('go', 'language-interfaces', 7, 'Чем value receiver отличается от pointer receiver и как это влияет на method set?'),
    ('go', 'language-interfaces', 8, 'Как работает defer и в каком порядке вычисляются его аргументы?'),
    ('go', 'language-interfaces', 9, 'Когда использовать errors.Is, errors.As и оборачивание через %w?'),
    ('go', 'concurrency', 10, 'Из-за чего возникает data race и почему mutex не всегда лучший вариант?'),
    ('go', 'concurrency', 11, 'Как избежать утечки goroutine в конвейере с несколькими стадиями?'),
    ('go', 'concurrency', 12, 'Чем unbuffered channel отличается от buffered channel с точки зрения синхронизации?'),
    ('go', 'runtime-memory', 13, 'Как map ведёт себя при конкурентном чтении и записи?'),
    ('go', 'runtime-memory', 14, 'Что такое escape analysis и как он связан с аллокациями в heap?'),
    ('go', 'runtime-memory', 15, 'Как garbage collector Go влияет на latency сервиса?'),
    ('go', 'concurrency', 16, 'Как правильно ограничить параллелизм обработки большого потока задач?'),
    ('go', 'databases', 17, 'Какие гарантии дают транзакции и уровни изоляции базы данных?'),
    ('go', 'backend-network', 18, 'Как организовать retries, timeout и idempotency для внешнего API?'),
    ('go', 'runtime-memory', 19, 'Как профилировать CPU, память и блокировки в Go-сервисе?'),
    ('go', 'system-design', 20, 'Как спроектировать сервис, который корректно переживает частичные отказы?')
)
INSERT INTO questions (topic_id, prompt, difficulty, position, status)
SELECT tp.id, q.prompt, CASE WHEN q.position > 14 THEN 3 WHEN q.position > 7 THEN 2 ELSE 1 END, q.position, 'published'
FROM question_data q
JOIN directions d ON d.slug = q.direction_slug
JOIN tracks tr ON tr.direction_id = d.id AND tr.slug = 'interview'
JOIN sections s ON s.track_id = tr.id AND s.slug = q.section_slug
JOIN topics tp ON tp.section_id = s.id AND tp.slug = 'main'
WHERE NOT EXISTS (SELECT 1 FROM questions existing WHERE existing.topic_id = tp.id AND existing.prompt = q.prompt);

WITH task_data(direction_slug, section_slug, slug, position, title, statement, hint, language) AS (VALUES
    ('ios', 'arc-memory', 'memory-management', 1, 'Управление памятью', 'Исправьте замыкание так, чтобы объект освобождался после выполнения.', 'Используйте capture list и очистите обработчик после вызова.', 'swift'),
    ('ios', 'swift-core', 'unique-items', 2, 'Уникальные элементы', 'Удалите дубликаты из массива Int, сохранив исходный порядок.', 'Храните уже встреченные значения в Set.', 'swift'),
    ('ios', 'swift-core', 'first-unique-character', 3, 'Первый уникальный символ', 'Найдите первый символ строки, который встречается ровно один раз.', 'Посчитайте частоты, затем пройдите строку повторно.', 'swift'),
    ('ios', 'swift-core', 'group-models', 4, 'Группировка моделей', 'Сгруппируйте пользователей по городу и отсортируйте имена внутри групп.', 'Используйте Dictionary(grouping:by:) и mapValues.', 'swift'),
    ('ios', 'system-design', 'safe-decoding', 5, 'Безопасный декодинг', 'Декодируйте массив JSON так, чтобы одна повреждённая запись не ломала остальные.', 'Обрабатывайте ошибку каждой записи отдельно.', 'swift'),
    ('ios', 'concurrency', 'debounce-search', 6, 'Debounce поиска', 'Реализуйте debounce: предыдущий запланированный поиск должен отменяться.', 'Храните и отменяйте текущую отложенную работу.', 'swift'),
    ('ios', 'concurrency', 'thread-safe-counter', 7, 'Потокобезопасный счётчик', 'Защитите счётчик от одновременного изменения из нескольких очередей.', 'Изолируйте состояние очередью или блокировкой.', 'swift'),
    ('ios', 'system-design', 'lru-cache', 8, 'LRU-кэш', 'Реализуйте get и put для LRU-кэша за O(1).', 'Соедините словарь с двусвязным списком.', 'swift'),
    ('ios', 'concurrency', 'parallel-loading', 9, 'Параллельная загрузка', 'Соберите результаты независимых загрузок, сохранив исходный порядок.', 'Свяжите каждый результат с индексом запроса.', 'swift'),
    ('ios', 'swift-core', 'collection-diff', 10, 'Diff коллекций', 'Найдите добавленные, удалённые и общие идентификаторы двух массивов.', 'Используйте Set и операции difference и intersection.', 'swift'),
    ('go', 'concurrency', 'data-race', 1, 'Гонки данных', 'Найдите data race в счётчике и исправьте её с помощью Mutex или atomic.', 'Операция инкремента должна быть синхронизирована.', 'go'),
    ('go', 'concurrency', 'worker-pool', 2, 'Worker pool', 'Реализуйте worker pool с фиксированным числом воркеров.', 'Закройте канал задач и дождитесь воркеров через WaitGroup.', 'go'),
    ('go', 'concurrency', 'context-cancel', 3, 'Отмена через context', 'Остановите долгую операцию при отмене context без утечки goroutine.', 'Проверяйте ctx.Done() в select.', 'go'),
    ('go', 'concurrency', 'safe-cache', 4, 'Безопасный кэш', 'Реализуйте конкурентно безопасный in-memory кэш с Get и Set.', 'Используйте RWMutex.', 'go'),
    ('go', 'concurrency', 'merge-channels', 5, 'Merge channels', 'Объедините несколько каналов в один и корректно закройте результат.', 'По goroutine на вход и WaitGroup для закрытия.', 'go'),
    ('go', 'language-interfaces', 'deduplicate', 6, 'Дедупликация', 'Удалите дубликаты строк, сохранив порядок первого появления.', 'Используйте map[string]struct{} как множество.', 'go'),
    ('go', 'backend-network', 'http-middleware', 7, 'HTTP middleware', 'Добавьте request ID и измерение времени обработки запроса.', 'Оберните http.Handler через http.HandlerFunc.', 'go'),
    ('go', 'concurrency', 'parallel-limit', 8, 'Лимит параллелизма', 'Обработайте URL параллельно, но не более трёх одновременно.', 'Используйте buffered channel как семафор.', 'go'),
    ('go', 'backend-network', 'graceful-shutdown', 9, 'Graceful shutdown', 'Завершите HTTP-сервер по сигналу ОС без обрыва активных запросов.', 'Используйте signal.NotifyContext и Server.Shutdown.', 'go'),
    ('go', 'system-design', 'lru-cache', 10, 'LRU-кэш', 'Реализуйте Get и Put для LRU-кэша за O(1).', 'Используйте map и container/list.', 'go')
)
INSERT INTO coding_tasks (topic_id, slug, title, statement_markdown, hint, language, starter_code, difficulty, position, status)
SELECT tp.id, t.slug, t.title, t.statement, t.hint, t.language,
       CASE WHEN t.language = 'swift' THEN 'import Foundation\n\n// Напишите решение здесь\n' ELSE 'package main\n\nimport "fmt"\n\nfunc main() {\n\tfmt.Println("write your solution")\n}\n' END,
       CASE WHEN t.position > 7 THEN 3 WHEN t.position > 3 THEN 2 ELSE 1 END,
       t.position, 'published'
FROM task_data t
JOIN directions d ON d.slug = t.direction_slug
JOIN tracks tr ON tr.direction_id = d.id AND tr.slug = 'interview'
JOIN sections s ON s.track_id = tr.id AND s.slug = t.section_slug
JOIN topics tp ON tp.section_id = s.id AND tp.slug = 'main'
ON CONFLICT (topic_id, slug) DO UPDATE SET title = EXCLUDED.title, statement_markdown = EXCLUDED.statement_markdown, hint = EXCLUDED.hint;

-- +goose Down
DELETE FROM coding_tasks;
DELETE FROM questions;
DELETE FROM topics;
DELETE FROM sections;
DELETE FROM tracks;
DELETE FROM directions;

