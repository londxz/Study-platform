"use client";

import { FormEvent, useEffect, useMemo, useRef, useState } from "react";
import CodeEditorImport from "react-simple-code-editor";
import Prism from "prismjs";
import "prismjs/components/prism-go";
import "prismjs/components/prism-swift";

// vinext keeps CommonJS default exports wrapped in the browser bundle.
// Unwrap the editor component so React receives the actual forwardRef value.
const CodeEditor = (
  (CodeEditorImport as unknown as { default?: typeof CodeEditorImport }).default
  ?? CodeEditorImport
) as typeof CodeEditorImport;

type TrackId = "ios" | "go";
type PathId = "learning" | "interview";
type MockMode = "theory" | "livecoding";
type Screen = "home" | "track" | "practice" | "mock" | "progress";

type CustomSection = {
  id: string;
  track: TrackId;
  title: string;
  description: string;
};

type RunResult = {
  ok: boolean;
  stdout: string;
  stderr: string;
  compiler: string;
};

function highlightCode(source: string, track: TrackId) {
  const language = track === "ios" ? "swift" : "go";
  const grammar = Prism.languages[language] || Prism.languages.clike;
  return Prism.highlight(source, grammar, language);
}

const TRACKS = {
  ios: {
    short: "iOS",
    name: "iOS Development",
    kicker: "INTERVIEW TRACK",
    description: "Глубокая подготовка к техническим интервью и разбор задач на Swift.",
    color: "orange",
    total: 64,
    baseDone: 18,
  },
  go: {
    short: "Go",
    name: "Go Development",
    kicker: "FROM ZERO TO BACKEND",
    description: "Пошаговый путь от синтаксиса и основ языка до конкурентного backend.",
    color: "cyan",
    total: 82,
    baseDone: 7,
  },
} as const;

const TRACK_PATHS = {
  ios: [
    {
      id: "interview" as const,
      index: "01",
      kicker: "ИНТЕРВЬЮ",
      title: "Подготовка к собеседованиям iOS",
      description: "Теоретические вопросы и практические задачи с технических интервью.",
      total: 64,
      done: 19,
    },
    {
      id: "learning" as const,
      index: "02",
      kicker: "УЧЕБНЫЙ ПЛАН",
      title: "Изучение iOS",
      description: "Материал, темы, практические задачи и проекты для системного изучения iOS.",
      total: 48,
      done: 0,
    },
  ],
  go: [
    {
      id: "interview" as const,
      index: "01",
      kicker: "ИНТЕРВЬЮ",
      title: "Подготовка к собеседованиям Go",
      description: "Теория, вопросы по runtime и практические backend-задачи с интервью.",
      total: 36,
      done: 0,
    },
    {
      id: "learning" as const,
      index: "02",
      kicker: "УЧЕБНЫЙ ПЛАН",
      title: "Изучение Go",
      description: "Последовательный путь от синтаксиса до конкурентного backend и баз данных.",
      total: 58,
      done: 7,
    },
  ],
} as const;

const PATH_MODULES = {
  ios: {
    learning: [
      { title: "Swift: основы", topics: 10, done: 0, icon: "{ }", description: "Типы, функции, коллекции, optional и обработка ошибок" },
      { title: "ООП и протоколы", topics: 8, done: 0, icon: "◇", description: "Структуры, классы, протоколы, generics и композиция" },
      { title: "UIKit", topics: 9, done: 0, icon: "▦", description: "Lifecycle, layout, navigation и переиспользуемые экраны" },
      { title: "SwiftUI", topics: 8, done: 0, icon: "◫", description: "State, bindings, environment, navigation и rendering" },
      { title: "Сеть и данные", topics: 7, done: 0, icon: "◎", description: "URLSession, Codable, кэш, Core Data и offline-first" },
      { title: "Тесты и проект", topics: 6, done: 0, icon: "✓", description: "Unit/UI tests и итоговое приложение с API" },
    ],
    interview: [
      { title: "Swift Core", topics: 12, done: 8, icon: "{ }", description: "Value/reference types, generics, protocols и dispatch" },
      { title: "ARC и память", topics: 8, done: 5, icon: "∞", description: "Strong, weak, unowned, capture lists и retain cycles" },
      { title: "Concurrency", topics: 10, done: 2, icon: "⇄", description: "GCD, async/await, actors и Sendable" },
      { title: "UIKit & SwiftUI", topics: 9, done: 1, icon: "▦", description: "Lifecycle, layout, state и rendering" },
      { title: "Архитектура", topics: 8, done: 2, icon: "◇", description: "MVC, MVVM, Coordinator и dependency injection" },
      { title: "System Design", topics: 7, done: 0, icon: "⌘", description: "Сеть, кэш, офлайн-режим и наблюдаемость" },
    ],
  },
  go: {
    learning: [
      { title: "Основы языка", topics: 12, done: 5, icon: "{ }", description: "Типы, функции, структуры, интерфейсы и ошибки" },
      { title: "Коллекции и память", topics: 10, done: 1, icon: "[]", description: "Slices, maps, pointers, escape analysis и GC" },
      { title: "Горутины", topics: 12, done: 1, icon: "⇄", description: "Channels, select, context и sync primitives" },
      { title: "Backend", topics: 11, done: 0, icon: "◎", description: "HTTP, middleware, REST, gRPC и конфигурация" },
      { title: "Хранение данных", topics: 8, done: 0, icon: "▤", description: "SQL, транзакции, индексы, Redis и миграции" },
      { title: "Тесты и проект", topics: 5, done: 0, icon: "✓", description: "Table tests, race detector, benchmarks и итоговый сервис" },
    ],
    interview: [
      { title: "Язык и интерфейсы", topics: 7, done: 0, icon: "{ }", description: "Методы, embedding, nil, errors и tricky-вопросы" },
      { title: "Runtime и память", topics: 6, done: 0, icon: "∞", description: "Scheduler, stack growth, escape analysis и GC" },
      { title: "Конкурентность", topics: 7, done: 0, icon: "⇄", description: "Channels, select, context, mutex и race conditions" },
      { title: "Backend и сети", topics: 6, done: 0, icon: "◎", description: "HTTP, TCP, middleware, gRPC и graceful shutdown" },
      { title: "Базы данных", topics: 5, done: 0, icon: "▤", description: "SQL, транзакции, индексы и конкурентный доступ" },
      { title: "System Design", topics: 5, done: 0, icon: "◇", description: "Очереди, кэш, масштабирование и отказоустойчивость" },
    ],
  },
} as const;

const PRACTICE = {
  ios: {
    learning: {
      title: "Коллекции и преобразование данных",
      category: "iOS · Изучение iOS",
      language: "swift" as const,
      compiler: "Swift 5.2.3",
      task: "Получите названия всех непрочитанных статей через filter и map, затем выведите их по одной строке.",
      hint: "Сначала отфильтруйте элементы по isRead, затем преобразуйте результат в массив строк.",
      code: `struct Article {
    let title: String
    let isRead: Bool
}

let articles = [
    Article(title: "Value types", isRead: true),
    Article(title: "Protocols", isRead: false),
    Article(title: "Concurrency", isRead: false)
]

let unreadTitles = articles
    .filter { !$0.isRead }
    .map { $0.title }

unreadTitles.forEach { print($0) }`,
    },
    interview: {
      title: "Управление памятью и capture list",
      category: "iOS · Подготовка к собеседованиям",
      language: "swift" as const,
      compiler: "Swift 5.2.3",
      task: "Исправьте замыкание так, чтобы объект DownloadService освобождался после выполнения. Затем запустите код и проверьте deinit в консоли.",
      hint: "Замыкание хранится внутри самого объекта. Используйте capture list и не оставляйте обработчик висеть после вызова.",
      code: `final class DownloadService {
    var onComplete: (() -> Void)?

    deinit {
        print("service released")
    }

    func start() {
        onComplete = { [weak self] in
            print("download complete")
            self?.onComplete = nil
        }
    }
}

var service: DownloadService? = DownloadService()
service?.start()
service?.onComplete?()
service = nil`,
    },
  },
  go: {
    learning: {
      title: "Передача результата через channel",
      category: "Go · Изучение Go",
      language: "go" as const,
      compiler: "Go 1.23.5",
      task: "Запустите worker в отдельной горутине, безопасно получите число из канала и выведите result: 42 без sleep и глобальных переменных.",
      hint: "Небуферизованный канал синхронизирует отправителя и получателя. Чтение можно выполнить прямо внутри fmt.Printf.",
      code: `package main

import "fmt"

func worker(result chan<- int) {
	result <- 42
}

func main() {
	result := make(chan int)
	go worker(result)
	fmt.Printf("result: %d\\n", <-result)
}`,
    },
    interview: {
      title: "Гонки данных и синхронизация",
      category: "Go · Подготовка к собеседованиям",
      language: "go" as const,
      compiler: "Go 1.23.5",
      task: "Объясните, почему инкремент counter небезопасен, и исправьте код с помощью sync.Mutex или atomic.",
      hint: "Операция counter++ состоит из чтения, изменения и записи. Эти действия должны быть синхронизированы.",
      code: `package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	counter := 0

	for i := 0; i < 1000; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			counter++
		}()
	}

	wg.Wait()
	fmt.Println(counter)
}`,
    },
  },
};

const MOCK_QUESTIONS = {
  ios: [
    "В чём практическая разница между value type и reference type в Swift?",
    "Как ARC освобождает память и из-за чего возникает retain cycle?",
    "Когда использовать weak, а когда unowned ссылку?",
    "Чем Task, async let и TaskGroup отличаются друг от друга?",
    "Опишите жизненный цикл UIViewController и типичные ошибки в нём.",
    "Как бы вы спроектировали кэширование изображений для большой ленты?",
    "Чем protocol witness table отличается от dynamic dispatch через Objective-C runtime?",
    "Как Copy-on-Write работает в стандартных коллекциях Swift?",
    "Почему escaping-замыкание может потребовать явного self?",
    "Чем actor отличается от serial DispatchQueue?",
    "Что такое Sendable и какие проблемы он помогает обнаружить?",
    "Как устроена обработка ошибок через throws, Result и async throws?",
    "Какие этапы проходит Auto Layout при вычислении и применении размеров?",
    "Как SwiftUI определяет, какую часть дерева представлений нужно обновить?",
    "Когда выбрать struct, final class или actor для новой модели?",
    "Как организовать dependency injection без глобального service locator?",
    "Какие уровни тестирования нужны iOS-приложению и что проверять на каждом?",
    "Как сделать сетевой слой устойчивым к отмене, повторным запросам и потере сети?",
    "Что происходит с приложением при переходе между active, inactive и background?",
    "Как спроектировать офлайн-синхронизацию с разрешением конфликтов?",
  ],
  go: [
    "Как устроен interface в Go и почему interface с nil-указателем может быть не nil?",
    "Как планировщик Go распределяет goroutine между системными потоками?",
    "Кто должен закрывать channel и что произойдёт при записи в закрытый channel?",
    "Как правильно распространять отмену операции через context?",
    "Чем длина slice отличается от capacity и когда происходит перевыделение массива?",
    "Как бы вы спроектировали graceful shutdown для HTTP-сервиса?",
    "Чем value receiver отличается от pointer receiver и как это влияет на method set?",
    "Как работает defer и в каком порядке вычисляются его аргументы?",
    "Когда использовать errors.Is, errors.As и оборачивание через %w?",
    "Из-за чего возникает data race и почему mutex не всегда лучший вариант?",
    "Как избежать утечки goroutine в конвейере с несколькими стадиями?",
    "Чем unbuffered channel отличается от buffered channel с точки зрения синхронизации?",
    "Как map ведёт себя при конкурентном чтении и записи?",
    "Что такое escape analysis и как он связан с аллокациями в heap?",
    "Как garbage collector Go влияет на latency сервиса?",
    "Как правильно ограничить параллелизм обработки большого потока задач?",
    "Какие гарантии дают транзакции и уровни изоляции базы данных?",
    "Как организовать retries, timeout и idempotency для внешнего API?",
    "Как профилировать CPU, память и блокировки в Go-сервисе?",
    "Как спроектировать сервис, который корректно переживает частичные отказы?",
  ],
} as const;

const LIVE_CODING_PROMPTS = {
  ios: [
    ["Управление памятью", "Исправьте замыкание так, чтобы объект освобождался после выполнения.", "Используйте capture list и очистите обработчик после вызова."],
    ["Уникальные элементы", "Удалите дубликаты из массива Int, сохранив исходный порядок.", "Храните уже встреченные значения в Set."],
    ["Первый уникальный символ", "Найдите первый символ строки, который встречается ровно один раз.", "Посчитайте частоты, затем пройдите строку повторно."],
    ["Группировка моделей", "Сгруппируйте пользователей по городу и отсортируйте имена внутри групп.", "Используйте Dictionary(grouping:by:) и mapValues."],
    ["Безопасный декодинг", "Декодируйте массив JSON так, чтобы одна повреждённая запись не ломала остальные.", "Обрабатывайте ошибку каждой записи отдельно."],
    ["Debounce поиска", "Реализуйте debounce: предыдущий запланированный поиск должен отменяться.", "Храните и отменяйте текущую отложенную работу."],
    ["Потокобезопасный счётчик", "Защитите счётчик от одновременного изменения из нескольких очередей.", "Изолируйте состояние очередью или блокировкой."],
    ["LRU-кэш", "Реализуйте get и put для LRU-кэша за O(1).", "Соедините словарь с двусвязным списком."],
    ["Параллельная загрузка", "Соберите результаты независимых загрузок, сохранив исходный порядок.", "Свяжите каждый результат с индексом запроса."],
    ["Diff коллекций", "Найдите добавленные, удалённые и общие идентификаторы двух массивов.", "Используйте Set и операции difference и intersection."],
  ],
  go: [
    ["Гонки данных", "Найдите data race в счётчике и исправьте её с помощью Mutex или atomic.", "Операция инкремента должна быть синхронизирована."],
    ["Worker pool", "Реализуйте worker pool с фиксированным числом воркеров.", "Закройте канал задач и дождитесь воркеров через WaitGroup."],
    ["Отмена через context", "Остановите долгую операцию при отмене context без утечки goroutine.", "Проверяйте ctx.Done() в select."],
    ["Безопасный кэш", "Реализуйте конкурентно безопасный in-memory кэш с Get и Set.", "Используйте RWMutex."],
    ["Merge channels", "Объедините несколько каналов в один и корректно закройте результат.", "По goroutine на вход и WaitGroup для закрытия."],
    ["Дедупликация", "Удалите дубликаты строк, сохранив порядок первого появления.", "Используйте map[string]struct{} как множество."],
    ["HTTP middleware", "Добавьте request ID и измерение времени обработки запроса.", "Оберните http.Handler через http.HandlerFunc."],
    ["Лимит параллелизма", "Обработайте URL параллельно, но не более трёх одновременно.", "Используйте buffered channel как семафор."],
    ["Graceful shutdown", "Завершите HTTP-сервер по сигналу ОС без обрыва активных запросов.", "Используйте signal.NotifyContext и Server.Shutdown."],
    ["LRU-кэш", "Реализуйте Get и Put для LRU-кэша за O(1).", "Используйте map и container/list."],
  ],
} as const;

const SEARCH_ITEMS = [
  ...PATH_MODULES.ios.learning.map((item) => ({ ...item, track: "ios" as TrackId })),
  ...PATH_MODULES.ios.interview.map((item) => ({ ...item, track: "ios" as TrackId })),
  ...PATH_MODULES.go.learning.map((item) => ({ ...item, track: "go" as TrackId })),
  ...PATH_MODULES.go.interview.map((item) => ({ ...item, track: "go" as TrackId })),
];

function Brand() {
  return (
    <span className="brand">
      <span className="brand-mark" aria-hidden="true">L</span>
      <span>Learny</span>
    </span>
  );
}

export function StudyPlatform() {
  const [screen, setScreen] = useState<Screen>("home");
  const [track, setTrack] = useState<TrackId>("ios");
  const [path, setPath] = useState<PathId>("learning");
  const [mockMode, setMockMode] = useState<MockMode>("theory");
  const [interviewTaskCount, setInterviewTaskCount] = useState(1);
  const [customSections, setCustomSections] = useState<CustomSection[]>([]);
  const [completed, setCompleted] = useState<string[]>([]);
  const [sectionModal, setSectionModal] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [mobileNav, setMobileNav] = useState(false);
  const [hydrated, setHydrated] = useState(false);
  const searchRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      try {
        setCustomSections(JSON.parse(localStorage.getItem("learny-sections") || "[]"));
        setCompleted(JSON.parse(localStorage.getItem("learny-completed") || "[]"));
      } catch {
        setCustomSections([]);
        setCompleted([]);
      }
      setHydrated(true);
    }, 0);
    return () => window.clearTimeout(timer);
  }, []);

  useEffect(() => {
    if (!hydrated) return;
    localStorage.setItem("learny-sections", JSON.stringify(customSections));
    localStorage.setItem("learny-completed", JSON.stringify(completed));
  }, [customSections, completed, hydrated]);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        setSearchOpen(true);
      }
      if (event.key === "Escape") {
        setSearchOpen(false);
        setSectionModal(false);
        setMobileNav(false);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  useEffect(() => {
    if (searchOpen) window.setTimeout(() => searchRef.current?.focus(), 20);
  }, [searchOpen]);

  const navigate = (next: Screen, selectedTrack?: TrackId) => {
    if (selectedTrack) setTrack(selectedTrack);
    setScreen(next);
    setMobileNav(false);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const addSection = (title: string, description: string, targetTrack: TrackId) => {
    setCustomSections((items) => [
      ...items,
      { id: `custom-${Date.now()}`, title, description, track: targetTrack },
    ]);
    setTrack(targetTrack);
    setSectionModal(false);
    setScreen("track");
  };

  return (
    <main className={`app-shell screen-${screen}`}>
      <div className="noise" aria-hidden="true" />
      <div className="ambient ambient-one" aria-hidden="true" />
      <div className="ambient ambient-two" aria-hidden="true" />
      <div className="ambient ambient-three" aria-hidden="true" />

      <header className="topbar">
        <button className="brand-button" onClick={() => navigate("home")} aria-label="Learny — на главную">
          <Brand />
        </button>
        <nav className={`main-nav ${mobileNav ? "mobile-open" : ""}`} aria-label="Основная навигация">
          <button className={["home", "track", "practice", "mock"].includes(screen) ? "active" : ""} onClick={() => navigate("home")}>Обучение</button>
          <button className={screen === "progress" ? "active" : ""} onClick={() => navigate("progress")}>Прогресс</button>
        </nav>
        <div className="header-actions">
          <button className="search-button" type="button" aria-label="Открыть поиск" onClick={() => setSearchOpen(true)}>
            <span aria-hidden="true">⌕</span>
            <span>Найти тему</span>
            <kbd>⌘ K</kbd>
          </button>
          <div className="profile" aria-label="Профиль пользователя">L</div>
          <button className="menu-button" type="button" aria-label="Открыть меню" aria-expanded={mobileNav} onClick={() => setMobileNav((open) => !open)}>
            <span /><span />
          </button>
        </div>
      </header>

      {screen === "home" && (
        <Dashboard
          completed={completed}
          onOpenTrack={(id) => navigate("track", id)}
          onPractice={(id, selectedPath = "interview") => {
            setPath(selectedPath);
            setInterviewTaskCount(1);
            navigate("practice", id);
          }}
        />
      )}
      {screen === "track" && (
        <TrackView
          key={track}
          track={track}
          onBack={() => navigate("home")}
          onPractice={(selectedPath) => {
            setPath(selectedPath);
            setInterviewTaskCount(1);
            navigate("practice", track);
          }}
          onMockInterview={(mode) => {
            setMockMode(mode);
            setPath("interview");
            navigate("mock", track);
          }}
        />
      )}
      {screen === "practice" && (
        <PracticeView
          key={`${track}-${path}-${interviewTaskCount}`}
          track={track}
          path={path}
          completed={completed.includes(`${track}-${path}-practice`)}
          sessionCount={path === "interview" ? interviewTaskCount : 1}
          onTrackChange={setTrack}
          onBack={() => navigate("track", track)}
          onComplete={() => setCompleted((items) => items.includes(`${track}-${path}-practice`) ? items : [...items, `${track}-${path}-practice`])}
        />
      )}
      {screen === "mock" && (
        <MockInterviewView
          key={`${track}-${mockMode}`}
          track={track}
          mode={mockMode}
          onBack={() => navigate("track", track)}
          onStartLivecoding={(count) => {
            setPath("interview");
            setInterviewTaskCount(count);
            navigate("practice", track);
          }}
        />
      )}
      {screen === "progress" && <ProgressView completed={completed} onOpenTrack={(id) => navigate("track", id)} />}

      {sectionModal && <AddSectionModal defaultTrack={track} onClose={() => setSectionModal(false)} onSubmit={addSection} />}
      {searchOpen && (
        <SearchModal
          query={search}
          inputRef={searchRef}
          onQuery={setSearch}
          onClose={() => setSearchOpen(false)}
          onSelect={(id) => {
            setSearchOpen(false);
            navigate("track", id);
          }}
        />
      )}
    </main>
  );
}

function Dashboard({ completed, onOpenTrack, onPractice }: {
  completed: string[];
  onOpenTrack: (id: TrackId) => void;
  onPractice: (id: TrackId, path?: PathId) => void;
}) {
  return (
    <div className="page-wrap" id="top">
      <section className="hero" aria-labelledby="hero-title">
        <div>
          <p className="eyebrow">ЛИЧНАЯ БОТАЛКА</p>
          <h1 id="hero-title">С возвращением, londxz</h1>
          <p className="hero-copy">Продолжайте учиться в своём темпе. Помни, зачем ты всё начал.</p>
        </div>
        <div className="streak-card glass-panel" aria-label="Серия занятий: 4 дня">
          <span className="streak-avatar" aria-hidden="true" />
          <div><strong>4 дня</strong><span>серия занятий</span></div>
        </div>
      </section>

      <section className="tracks-section" aria-labelledby="tracks-title">
        <div className="section-heading">
          <div><p className="eyebrow">НАПРАВЛЕНИЯ</p><h2 id="tracks-title">Что изучаем сегодня?</h2></div>
        </div>
        <div className="track-grid">
          {(Object.keys(TRACKS) as TrackId[]).map((id) => {
            const item = TRACKS[id];
            const done = item.baseDone + (completed.some((entry) => entry.startsWith(`${id}-`)) ? 1 : 0);
            const percent = Math.round((done / item.total) * 100);
            return (
              <button className={`track-card ${id}-card glass-panel`} type="button" onClick={() => onOpenTrack(id)} key={id} aria-label={`Открыть направление ${item.name}`}>
                <span className="track-card-top">
                  <span className={`track-logo ${id}-logo`} aria-hidden="true">{item.short}</span>
                  <span className={`language-logo ${id === "ios" ? "swift" : "go"}`} aria-hidden="true" />
                </span>
                <span className="track-copy">
                  <span className="track-title">{item.name}</span>
                </span>
                <span className="progress-row"><span>Пройдено {done} из {item.total} тем</span><strong>{percent}%</strong></span>
                <span className="progress-bar" aria-label={`Прогресс ${item.short}: ${percent}%`}><span style={{ width: `${percent}%` }} /></span>
                <span className="track-link">Открыть направление <span aria-hidden="true">↗</span></span>
              </button>
            );
          })}
        </div>
      </section>

      <section className="resume-section" aria-labelledby="last-task-title">
        <div className="section-heading compact">
          <div><p className="eyebrow">ПРОДОЛЖИТЬ</p><h2 id="last-task-title">Последняя задача</h2></div>
        </div>
        <div className="resume-panel glass-panel">
          <div className="resume-label"><span aria-hidden="true">▶</span> ПРОДОЛЖИТЬ</div>
          <div className="resume-body">
            <span className="lesson-index">07</span>
            <div><p>iOS · Подготовка к интервью</p><h2 id="resume-title">ARC и управление памятью</h2><span>12 минут · 3 вопроса · 1 задача с кодом</span></div>
          </div>
          <button className="primary-button" type="button" onClick={() => onPractice("ios", "interview")}>Открыть урок <span aria-hidden="true">→</span></button>
        </div>
      </section>
    </div>
  );
}

function TrackView({ track, onBack, onPractice, onMockInterview }: {
  track: TrackId;
  onBack: () => void;
  onPractice: (path: PathId) => void;
  onMockInterview: (mode: MockMode) => void;
}) {
  const [selectedPath, setSelectedPath] = useState<PathId | null>(null);
  const details = TRACKS[track];
  const paths = TRACK_PATHS[track];

  if (!selectedPath) {
    return (
      <div className="page-wrap track-page">
        <button className="back-link" onClick={onBack}><span aria-hidden="true">←</span> Все направления</button>
        <header className="path-picker-head">
          <p className="eyebrow">{details.short} · НАПРАВЛЕНИЕ</p>
          <h1>Выберите формат</h1>
          <p>Обучение и подготовка к интервью разделены, чтобы не смешивать материал с проверкой знаний.</p>
        </header>

        <section className="path-grid" aria-label={`Форматы обучения ${details.short}`}>
          {paths.map((item) => {
            const percent = Math.round((item.done / item.total) * 100);
            return (
              <button className={`path-card ${track}-path glass-panel`} type="button" onClick={() => setSelectedPath(item.id)} key={item.id}>
                <span className="path-card-top">
                  <span className="path-number" aria-hidden="true">{item.index}</span>
                  <span className="path-kicker">{item.kicker}</span>
                </span>
                <span className="path-card-copy">
                  <strong>{item.title}</strong>
                  <span>{item.description}</span>
                </span>
                <span className="progress-row"><span>Пройдено {item.done} из {item.total} тем</span><strong>{percent}%</strong></span>
                <span className="progress-bar" aria-label={`Прогресс: ${percent}%`}><span style={{ width: `${percent}%` }} /></span>
                <span className="path-link">Открыть раздел <span aria-hidden="true">↗</span></span>
              </button>
            );
          })}
        </section>
      </div>
    );
  }

  const selected = paths.find((item) => item.id === selectedPath) ?? paths[0];
  const modules = PATH_MODULES[track][selectedPath];

  return (
    <div className="page-wrap track-page">
      <button className="back-link" onClick={() => setSelectedPath(null)}><span aria-hidden="true">←</span> К выбору формата</button>
      <header className="path-detail-head">
        <div>
          <p className="eyebrow">{details.short} · {selected.kicker}</p>
          <h1>{selected.title}</h1>
          <p>{selected.description}</p>
        </div>
        <span className={`track-logo large ${track}-logo`} aria-hidden="true">{details.short}</span>
      </header>

      {selectedPath === "interview" && (
        <section className="mock-section" aria-labelledby="mock-title">
          <div className="section-heading compact">
            <div>
              <p className="eyebrow">МОК-ИНТЕРВЬЮ</p>
              <h2 id="mock-title">Проверь себя в боевом формате</h2>
            </div>
          </div>
          <div className="mock-grid">
            <button className="mock-choice glass-panel" type="button" onClick={() => onMockInterview("theory")}>
              <span className="mock-choice-icon" aria-hidden="true">?</span>
              <span className="mock-choice-copy"><strong>Теория</strong></span>
              <span className="mock-choice-meta"><b aria-hidden="true">→</b></span>
            </button>
            <button className="mock-choice glass-panel" type="button" onClick={() => onMockInterview("livecoding")}>
              <span className="mock-choice-icon code" aria-hidden="true">{`{ }`}</span>
              <span className="mock-choice-copy"><strong>Лайвкодинг</strong></span>
              <span className="mock-choice-meta"><b aria-hidden="true">→</b></span>
            </button>
          </div>
        </section>
      )}

      <section className="modules-section path-modules" aria-labelledby="modules-title">
        <div className="section-heading compact">
          <div>
            <p className="eyebrow">{selectedPath === "learning" ? "УЧЕБНЫЙ ПЛАН" : "БАЗА ИНТЕРВЬЮ"}</p>
            <h2 id="modules-title">{selectedPath === "learning" ? "Темы и задачи" : "Вопросы и практика"}</h2>
          </div>
        </div>
        <div className="module-grid">
          {modules.map((module, index) => {
            const pct = Math.round((module.done / module.topics) * 100);
            return (
              <button className="module-card glass-panel" onClick={() => onPractice(selectedPath)} key={module.title} aria-label={`Открыть ${module.title}`}>
                <span className="module-icon" aria-hidden="true">{module.icon}</span>
                <span className="module-order">{String(index + 1).padStart(2, "0")}</span>
                <strong>{module.title}</strong>
                <small>{module.description}</small>
                <span className="module-progress"><i><b style={{ width: `${pct}%` }} /></i><em>{module.done}/{module.topics}</em></span>
              </button>
            );
          })}
        </div>
      </section>
    </div>
  );
}

function MockInterviewView({ track, mode, onBack, onStartLivecoding }: {
  track: TrackId;
  mode: MockMode;
  onBack: () => void;
  onStartLivecoding: (count: number) => void;
}) {
  const maxCount = mode === "theory" ? 20 : 10;
  const [count, setCount] = useState(mode === "theory" ? 6 : 3);
  const [started, setStarted] = useState(false);
  const questions = useMemo(() => MOCK_QUESTIONS[track].slice(0, count), [count, track]);
  const [current, setCurrent] = useState(0);
  const [answers, setAnswers] = useState<string[]>([]);
  const [finished, setFinished] = useState(false);
  const progress = Math.round(((current + 1) / questions.length) * 100);

  const setSafeCount = (value: number) => {
    const normalized = Number.isFinite(value) ? Math.floor(value) : 1;
    setCount(Math.min(maxCount, Math.max(1, normalized)));
  };

  const start = (event: FormEvent) => {
    event.preventDefault();
    if (mode === "livecoding") {
      onStartLivecoding(count);
      return;
    }
    setAnswers(questions.map(() => ""));
    setCurrent(0);
    setFinished(false);
    setStarted(true);
  };

  const updateAnswer = (value: string) => {
    setAnswers((items) => items.map((answer, index) => index === current ? value : answer));
  };

  const moveNext = () => {
    if (current === questions.length - 1) {
      setFinished(true);
      return;
    }
    setCurrent((index) => index + 1);
  };

  const restart = () => {
    setAnswers(questions.map(() => ""));
    setCurrent(0);
    setFinished(false);
  };

  if (!started) {
    return (
      <div className="page-wrap mock-page">
        <button className="back-link" onClick={onBack}><span aria-hidden="true">←</span> К подготовке</button>
        <form className="mock-setup glass-panel" onSubmit={start} aria-labelledby="mock-setup-title">
          <div className="mock-setup-icon" aria-hidden="true">{mode === "theory" ? "?" : "{ }"}</div>
          <p className="eyebrow">МОК-ИНТЕРВЬЮ · {TRACKS[track].short}</p>
          <h1 id="mock-setup-title">{mode === "theory" ? "Теория" : "Лайвкодинг"}</h1>
          <p>{mode === "theory"
            ? "Выберите количество вопросов. Отвечайте последовательно, как на настоящем техническом интервью."
            : "Выберите количество задач. Каждая откроется в редакторе с компиляцией Swift или Go."}</p>
          <label htmlFor="interview-count">Количество {mode === "theory" ? "вопросов" : "задач"}</label>
          <div className="count-stepper">
            <button type="button" onClick={() => setSafeCount(count - 1)} disabled={count <= 1} aria-label="Уменьшить количество">−</button>
            <input id="interview-count" type="number" min="1" max={maxCount} value={count} onChange={(event) => setSafeCount(Number(event.target.value))} />
            <button type="button" onClick={() => setSafeCount(count + 1)} disabled={count >= maxCount} aria-label="Увеличить количество">+</button>
          </div>
          <span className="count-limit">Минимум 1 · максимум {maxCount}</span>
          <button className="primary-button mock-start-button" type="submit">Начать <span aria-hidden="true">→</span></button>
        </form>
      </div>
    );
  }

  return (
    <div className="page-wrap mock-page">
      <button className="back-link" onClick={onBack}><span aria-hidden="true">←</span> К подготовке</button>
      <section className="mock-session glass-panel" aria-labelledby="mock-session-title">
        {!finished ? (
          <>
            <header className="mock-session-head">
              <div><p className="eyebrow">МОК-ИНТЕРВЬЮ · {TRACKS[track].short}</p><span>Вопрос {current + 1} из {questions.length}</span></div>
              <strong>{progress}%</strong>
            </header>
            <div className="mock-session-progress" aria-label={`Прогресс интервью: ${progress}%`}><span style={{ width: `${progress}%` }} /></div>
            <div className="mock-question">
              <span className="mock-question-number">{String(current + 1).padStart(2, "0")}</span>
              <h1 id="mock-session-title">{questions[current]}</h1>
              <p>Отвечайте так, как говорили бы интервьюеру: сначала короткий тезис, затем объяснение и пример.</p>
              <label htmlFor="mock-answer">Ваш ответ</label>
              <textarea id="mock-answer" value={answers[current]} onChange={(event) => updateAnswer(event.target.value)} placeholder="Запишите свой ответ здесь…" />
            </div>
            <footer className="mock-session-actions">
              <button className="secondary-button" type="button" onClick={moveNext}>Пропустить</button>
              <button className="primary-button" type="button" onClick={moveNext}>{current === questions.length - 1 ? "Завершить интервью" : "Следующий вопрос"} <span aria-hidden="true">→</span></button>
            </footer>
          </>
        ) : (
          <div className="mock-finished">
            <p className="eyebrow">ИНТЕРВЬЮ ЗАВЕРШЕНО</p>
            <h1 id="mock-session-title">Ответы собраны</h1>
            <p>Вы ответили на {answers.filter((answer) => answer.trim()).length} из {questions.length} вопросов. Просмотрите пробелы и повторите интервью ещё раз.</p>
            <div className="mock-answer-list">
              {questions.map((question, index) => (
                <article key={question}>
                  <span>{String(index + 1).padStart(2, "0")}</span>
                  <div><strong>{question}</strong><p>{answers[index].trim() || "Ответ пропущен"}</p></div>
                </article>
              ))}
            </div>
            <div className="mock-session-actions finished-actions">
              <button className="secondary-button" type="button" onClick={onBack}>Вернуться к базе</button>
              <button className="primary-button" type="button" onClick={restart}>Пройти ещё раз <span aria-hidden="true">↻</span></button>
            </div>
          </div>
        )}
      </section>
    </div>
  );
}

function PracticeView({ track, path, completed, sessionCount, onTrackChange, onBack, onComplete }: {
  track: TrackId;
  path: PathId;
  completed: boolean;
  sessionCount: number;
  onTrackChange: (track: TrackId) => void;
  onBack: () => void;
  onComplete: () => void;
}) {
  const sessionTasks = useMemo(() => {
    const base = PRACTICE[track][path];
    if (path !== "interview") return [base];
    return LIVE_CODING_PROMPTS[track].slice(0, Math.min(10, Math.max(1, sessionCount))).map(([title, task, hint], index) => ({
      ...base,
      title,
      task,
      hint,
      code: index === 0 ? base.code : track === "ios"
        ? `import Foundation

// Напишите решение здесь
`
        : `package main

import "fmt"

func main() {
	fmt.Println("write your solution")
}
`,
    }));
  }, [path, sessionCount, track]);
  const [currentTask, setCurrentTask] = useState(0);
  const lesson = sessionTasks[currentTask];
  const [code, setCode] = useState(lesson.code);
  const [result, setResult] = useState<RunResult | null>(null);
  const [running, setRunning] = useState(false);
  const [hintOpen, setHintOpen] = useState(false);
  const hasNextTask = currentTask < sessionTasks.length - 1;
  const isLivecoding = path === "interview";

  const advanceTask = () => {
    if (!hasNextTask) {
      onBack();
      return;
    }
    const nextTask = currentTask + 1;
    setCurrentTask(nextTask);
    setCode(sessionTasks[nextTask].code);
    setResult(null);
    setHintOpen(false);
  };

  const run = async () => {
    setRunning(true);
    setResult(null);
    try {
      const response = await fetch("/api/run", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ language: lesson.language, code }),
      });
      const data = await response.json() as RunResult & { error?: string };
      if (!response.ok) throw new Error(data.error || "Компилятор недоступен");
      setResult(data);
      if (data.ok) onComplete();
    } catch (error) {
      setResult({ ok: false, stdout: "", stderr: error instanceof Error ? error.message : "Не удалось запустить код", compiler: lesson.compiler });
    } finally {
      setRunning(false);
    }
  };

  return (
    <div className={`practice-page ${isLivecoding ? "livecoding-page" : ""}`}>
      {!isLivecoding && <aside className="practice-sidebar glass-panel">
        <button className="back-link light" onClick={onBack}><span aria-hidden="true">←</span> К разделам</button>
        <p className="sidebar-eyebrow">КОДОВАЯ ПРАКТИКА</p>
        <h2>{TRACKS[track].name}</h2>
        <div className="language-switch" role="group" aria-label="Язык практики">
          <button className={track === "ios" ? "active" : ""} onClick={() => onTrackChange("ios")}>Swift</button>
          <button className={track === "go" ? "active" : ""} onClick={() => onTrackChange("go")}>Go</button>
        </div>
        <ol className="task-list">
          {sessionTasks.map((task, index) => (
            <li className={index < currentTask ? "done" : index === currentTask ? "current" : ""} key={`${task.title}-${index}`}>
              <span>{index < currentTask ? "✓" : String(index + 1).padStart(2, "0")}</span>
              <div><strong>{task.title}</strong><small>{task.compiler}</small></div>
            </li>
          ))}
        </ol>
        <div className="sidebar-note"><span aria-hidden="true">⌁</span><p>Код отправляется в изолированный внешний компилятор. Не вставляйте секреты и токены.</p></div>
      </aside>}

      <section className="workspace">
        {isLivecoding ? <header className="livecoding-head">
          <button className="livecoding-back" type="button" onClick={onBack} aria-label="Вернуться к подготовке">←</button>
          <h1>{lesson.title}</h1>
          <span>{currentTask + 1} / {sessionTasks.length}</span>
        </header> : <header className="workspace-head">
          <div><p>{lesson.category}</p><h1>{lesson.title}</h1></div>
          <span className={`completion-badge ${completed ? "done" : ""}`}>{completed ? "✓ Выполнено" : "Практика"}</span>
        </header>}
        {isLivecoding ? <div className="livecoding-prompt">
          <p>{lesson.task}</p>
          <button type="button" onClick={() => setHintOpen((open) => !open)}>{hintOpen ? "Скрыть подсказку" : "Подсказка"}</button>
        </div> : <div className="task-brief glass-panel">
          <div className="task-brief-number">01</div>
          <div><p className="eyebrow">ЗАДАЧА</p><p>{lesson.task}</p></div>
          <button onClick={() => setHintOpen((open) => !open)}>{hintOpen ? "Скрыть" : "Подсказка"}</button>
        </div>}
        {hintOpen && <div className="hint-panel glass-panel"><span aria-hidden="true">✦</span><p>{lesson.hint}</p></div>}

        <div className="code-lab">
          <div className="editor-panel">
            <div className="panel-toolbar"><span className="file-name">{isLivecoding ? "main" : <><i className={track} />{track === "ios" ? "main.swift" : "main.go"}</>}</span><button onClick={() => setCode(lesson.code)}>Сбросить</button></div>
            <div className="editor-wrap">
              <div className="line-numbers" aria-hidden="true">{code.split("\n").map((_, i) => <span key={i}>{i + 1}</span>)}</div>
              <CodeEditor
                value={code}
                onValueChange={setCode}
                highlight={(source) => highlightCode(source, track)}
                padding={{ top: 17, right: 19, bottom: 30, left: 19 }}
                tabSize={4}
                insertSpaces
                className="xcode-editor"
                preClassName="xcode-highlight"
                textareaClassName="xcode-editor-input"
                textareaId="practice-code-editor"
                aria-label={`Редактор кода ${lesson.compiler}`}
              />
            </div>
          </div>
          <div className="output-panel">
            <div className="panel-toolbar"><span>Консоль</span>{!isLivecoding && <span className="runtime-dot">{lesson.compiler}</span>}</div>
            <div className={`console-output ${result ? (result.ok ? "success" : "error") : ""}`} aria-live="polite">
              {!result && <div className="console-empty"><span>›_</span><p>Результат запуска появится здесь.</p></div>}
              {result && <><p className="console-status">{result.ok ? "✓ Выполнено успешно" : "× Ошибка выполнения"}</p>{result.stdout && <pre>{result.stdout}</pre>}{result.stderr && <pre className="stderr">{result.stderr}</pre>}{!isLivecoding && <small>{result.compiler}</small>}</>}
            </div>
          </div>
        </div>
        <div className={`runner-bar ${isLivecoding ? "livecoding-runner" : "glass-panel"}`}>
          {!isLivecoding && <div><span className="live-dot" />Изолированный запуск · лимит 10 КБ</div>}
          <div className="runner-actions">
            {result?.ok && isLivecoding && <button className="secondary-button" type="button" onClick={advanceTask}>{hasNextTask ? "Следующая задача" : "Завершить"} <span aria-hidden="true">→</span></button>}
            <button className="run-button" onClick={run} disabled={running || !code.trim()}>{running ? <><i className="spinner" /> Компилирую…</> : <><span aria-hidden="true">▶</span> Запустить код</>}</button>
          </div>
        </div>
      </section>
    </div>
  );
}

function ProgressView({ completed, onOpenTrack }: { completed: string[]; onOpenTrack: (id: TrackId) => void }) {
  const week = [42, 58, 30, 76, 54, 84, 66];
  return (
    <div className="page-wrap progress-page">
      <section className="progress-hero">
        <p className="eyebrow">ВАШ ПРОГРЕСС</p><h1>Движение видно в деталях</h1><p>Спокойный обзор тем, практики и ритма занятий.</p>
      </section>
      <div className="stats-grid">
        <article className="stat-card glass-panel"><span>Пройдено тем</span><strong>{25 + completed.length}</strong><small>из 146 в двух направлениях</small></article>
        <article className="stat-card glass-panel"><span>Задачи с кодом</span><strong>{6 + completed.length}</strong><small>{completed.length ? "+1 за сегодня" : "следующая уже готова"}</small></article>
        <article className="stat-card glass-panel"><span>Серия</span><strong>4 <em>дня</em></strong><small>лучший результат: 9 дней</small></article>
      </div>
      <section className="activity-card glass-panel">
        <div><p className="eyebrow">АКТИВНОСТЬ</p><h2>Последние 7 дней</h2></div>
        <div className="activity-chart" aria-label="График активности за неделю">
          {week.map((value, index) => <div key={index}><span style={{ height: `${value}%` }} /><small>{["Пн","Вт","Ср","Чт","Пт","Сб","Вс"][index]}</small></div>)}
        </div>
      </section>
      <section className="progress-tracks">
        {(Object.keys(TRACKS) as TrackId[]).map((id) => {
          const item = TRACKS[id]; const done = item.baseDone + (completed.includes(`${id}-practice`) ? 1 : 0); const percent = Math.round(done/item.total*100);
          return <button className={`progress-track glass-panel ${id}`} key={id} onClick={() => onOpenTrack(id)}><span className={`track-logo ${id}-logo`}>{item.short}</span><div><strong>{item.name}</strong><small>{done} из {item.total} тем</small><i><b style={{ width: `${percent}%` }} /></i></div><em>{percent}%</em></button>;
        })}
      </section>
    </div>
  );
}

function AddSectionModal({ defaultTrack, onClose, onSubmit }: { defaultTrack: TrackId; onClose: () => void; onSubmit: (title: string, description: string, track: TrackId) => void }) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [track, setTrack] = useState<TrackId>(defaultTrack);
  const submit = (event: FormEvent) => { event.preventDefault(); if (title.trim()) onSubmit(title.trim(), description.trim(), track); };
  return (
    <div className="modal-layer" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
      <form className="modal-card glass-panel" onSubmit={submit} role="dialog" aria-modal="true" aria-labelledby="section-modal-title">
        <div className="modal-head"><div><p className="eyebrow">НОВЫЙ РАЗДЕЛ</p><h2 id="section-modal-title">Добавить направление обучения</h2></div><button type="button" onClick={onClose} aria-label="Закрыть">×</button></div>
        <fieldset><legend>К какому треку</legend><div className="segmented"><button type="button" className={track === "ios" ? "active" : ""} onClick={() => setTrack("ios")}>iOS</button><button type="button" className={track === "go" ? "active" : ""} onClick={() => setTrack("go")}>Go</button></div></fieldset>
        <label><span>Название</span><input value={title} onChange={(event) => setTitle(event.target.value)} placeholder="Например, System Design" maxLength={60} /></label>
        <label><span>Короткое описание</span><textarea value={description} onChange={(event) => setDescription(event.target.value)} placeholder="Что вы хотите изучить в этом разделе?" maxLength={180} /></label>
        <div className="modal-actions"><button type="button" className="secondary-button" onClick={onClose}>Отмена</button><button className="primary-button" disabled={!title.trim()}>Добавить раздел <span>→</span></button></div>
      </form>
    </div>
  );
}

function SearchModal({ query, inputRef, onQuery, onClose, onSelect }: { query: string; inputRef: React.RefObject<HTMLInputElement | null>; onQuery: (value: string) => void; onClose: () => void; onSelect: (track: TrackId) => void }) {
  const results = useMemo(() => {
    const normalized = query.toLowerCase().trim();
    return normalized ? SEARCH_ITEMS.filter((item) => `${item.title} ${item.description}`.toLowerCase().includes(normalized)) : SEARCH_ITEMS.slice(0, 5);
  }, [query]);
  return (
    <div className="modal-layer search-layer" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
      <div className="search-modal glass-panel" role="dialog" aria-modal="true" aria-label="Поиск по темам">
        <div className="search-input-wrap"><span aria-hidden="true">⌕</span><input ref={inputRef} value={query} onChange={(event) => onQuery(event.target.value)} placeholder="Тема, модуль или технология…" /><kbd>ESC</kbd></div>
        <div className="search-results">
          <p>{query ? `Найдено: ${results.length}` : "Популярные темы"}</p>
          {results.map((item) => <button key={`${item.track}-${item.title}`} onClick={() => onSelect(item.track)}><span className={`search-track ${item.track}`}>{TRACKS[item.track].short}</span><div><strong>{item.title}</strong><small>{item.description}</small></div><em>→</em></button>)}
          {!results.length && <div className="no-results"><span>⌁</span><p>Ничего не найдено. Попробуйте другое слово.</p></div>}
        </div>
      </div>
    </div>
  );
}
