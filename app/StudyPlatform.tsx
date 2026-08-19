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
type Screen = "home" | "track" | "practice" | "progress";

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

const TRACK_SECTIONS = {
  ios: [
    {
      id: "ios-basics",
      index: "01",
      title: "iOS с нуля",
      description: "Место под базовый курс — пока без материалов.",
      meta: "0 тем",
      state: "empty",
    },
    {
      id: "ios-interview",
      index: "02",
      title: "Подготовка к интервью",
      description: "Swift, память, многопоточность, архитектура и системный дизайн.",
      meta: "8 модулей · 64 темы · 27 задач",
      state: "active",
    },
  ],
  go: [
    {
      id: "go-basics",
      index: "01",
      title: "Go с нуля",
      description: "От синтаксиса и типов до HTTP-сервисов, SQL и тестирования.",
      meta: "7 модулей · 58 тем · 34 задачи",
      state: "active",
    },
    {
      id: "go-interview",
      index: "02",
      title: "Подготовка к интервью",
      description: "Горутины, планировщик, память, сети и backend design.",
      meta: "5 модулей · 24 темы · 18 задач",
      state: "active",
    },
  ],
} as const;

const MODULES = {
  ios: [
    { title: "Swift Core", topics: 12, done: 8, icon: "{ }", description: "Value/reference types, generics, protocols и dispatch" },
    { title: "ARC и память", topics: 8, done: 5, icon: "∞", description: "Strong, weak, unowned, capture lists и retain cycles" },
    { title: "Concurrency", topics: 10, done: 2, icon: "⇄", description: "GCD, async/await, actors и Sendable" },
    { title: "UIKit & SwiftUI", topics: 9, done: 1, icon: "▦", description: "Lifecycle, layout, state и rendering" },
    { title: "Архитектура", topics: 8, done: 2, icon: "◇", description: "MVC, MVVM, Coordinator и DI" },
    { title: "System Design", topics: 7, done: 0, icon: "⌘", description: "Сеть, кэш, офлайн-режим и наблюдаемость" },
  ],
  go: [
    { title: "Основы языка", topics: 12, done: 5, icon: "{ }", description: "Типы, функции, структуры, интерфейсы и ошибки" },
    { title: "Коллекции и память", topics: 10, done: 1, icon: "[]", description: "Slices, maps, pointers, escape analysis и GC" },
    { title: "Горутины", topics: 12, done: 1, icon: "⇄", description: "Channels, select, context и sync primitives" },
    { title: "Backend", topics: 11, done: 0, icon: "◎", description: "HTTP, middleware, REST, gRPC и конфигурация" },
    { title: "Хранение данных", topics: 8, done: 0, icon: "▤", description: "SQL, транзакции, индексы, Redis и миграции" },
    { title: "Тестирование", topics: 5, done: 0, icon: "✓", description: "Table tests, mocks, race detector и benchmarks" },
  ],
} as const;

const PRACTICE = {
  ios: {
    title: "Управление памятью и capture list",
    category: "iOS · Подготовка к интервью",
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
  go: {
    title: "Передача результата через channel",
    category: "Go · Go с нуля",
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
};

const SEARCH_ITEMS = [
  ...MODULES.ios.map((item) => ({ ...item, track: "ios" as TrackId })),
  ...MODULES.go.map((item) => ({ ...item, track: "go" as TrackId })),
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
          <button className={screen === "home" || screen === "track" ? "active" : ""} onClick={() => navigate("home")}>Обучение</button>
          <button className={screen === "practice" ? "active" : ""} onClick={() => navigate("practice")}>Практика</button>
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
          onPractice={(id) => navigate("practice", id)}
          onAddSection={() => setSectionModal(true)}
        />
      )}
      {screen === "track" && (
        <TrackView
          track={track}
          customSections={customSections}
          onBack={() => navigate("home")}
          onPractice={() => navigate("practice", track)}
          onAddSection={() => setSectionModal(true)}
        />
      )}
      {screen === "practice" && (
        <PracticeView
          key={track}
          track={track}
          completed={completed.includes(`${track}-practice`)}
          onTrackChange={setTrack}
          onBack={() => navigate("track", track)}
          onComplete={() => setCompleted((items) => items.includes(`${track}-practice`) ? items : [...items, `${track}-practice`])}
        />
      )}
      {screen === "progress" && <ProgressView completed={completed} onOpenTrack={(id) => navigate("track", id)} />}

      <footer className="site-footer">
        <Brand />
        <p>Личная практика. Один маленький шаг каждый день.</p>
        <span>Данные хранятся на этом устройстве</span>
      </footer>

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

function Dashboard({ completed, onOpenTrack, onPractice, onAddSection }: {
  completed: string[];
  onOpenTrack: (id: TrackId) => void;
  onPractice: (id: TrackId) => void;
  onAddSection: () => void;
}) {
  return (
    <div className="page-wrap" id="top">
      <section className="hero" aria-labelledby="hero-title">
        <div>
          <p className="eyebrow">ЛИЧНОЕ ПРОСТРАНСТВО</p>
          <h1 id="hero-title">С возвращением, Londxz</h1>
          <p className="hero-copy">Продолжайте учиться в своём темпе. Прогресс, разделы и решения сохраняются автоматически.</p>
        </div>
        <div className="streak-card glass-panel" aria-label="Серия занятий: 4 дня">
          <span className="streak-icon" aria-hidden="true">✦</span>
          <div><strong>4 дня</strong><span>серия занятий</span></div>
        </div>
      </section>

      <section className="tracks-section" aria-labelledby="tracks-title">
        <div className="section-heading">
          <div><p className="eyebrow">НАПРАВЛЕНИЯ</p><h2 id="tracks-title">Что изучаем сегодня?</h2></div>
          <button className="quiet-button glass-control" type="button" onClick={onAddSection}>+ Добавить раздел</button>
        </div>
        <div className="track-grid">
          {(Object.keys(TRACKS) as TrackId[]).map((id) => {
            const item = TRACKS[id];
            const done = item.baseDone + (completed.includes(`${id}-practice`) ? 1 : 0);
            const percent = Math.round((done / item.total) * 100);
            return (
              <article className={`track-card ${id}-card glass-panel`} key={id}>
                <div className="track-card-top">
                  <span className={`track-logo ${id}-logo`} aria-hidden="true">{item.short}</span>
                  <span className="status-pill"><i /> В процессе</span>
                </div>
                <div className="track-copy">
                  <p className="track-kicker">{item.kicker}</p>
                  <h3>{item.name}</h3>
                  <p>{item.description}</p>
                </div>
                <div className="progress-row"><span>Пройдено {done} из {item.total} тем</span><strong>{percent}%</strong></div>
                <div className="progress-bar" aria-label={`Прогресс ${item.short}: ${percent}%`}><span style={{ width: `${percent}%` }} /></div>
                <button className="track-link" onClick={() => onOpenTrack(id)}>Открыть направление <span aria-hidden="true">↗</span></button>
              </article>
            );
          })}
        </div>
      </section>

      <section className="resume-panel glass-panel" aria-labelledby="resume-title">
        <div className="resume-label"><span aria-hidden="true">▶</span> ПРОДОЛЖИТЬ</div>
        <div className="resume-body">
          <span className="lesson-index">07</span>
          <div><p>iOS · Подготовка к интервью</p><h2 id="resume-title">ARC и управление памятью</h2><span>12 минут · 3 вопроса · 1 задача с кодом</span></div>
        </div>
        <button className="primary-button" type="button" onClick={() => onPractice("ios")}>Открыть урок <span aria-hidden="true">→</span></button>
      </section>
    </div>
  );
}

function TrackView({ track, customSections, onBack, onPractice, onAddSection }: {
  track: TrackId;
  customSections: CustomSection[];
  onBack: () => void;
  onPractice: () => void;
  onAddSection: () => void;
}) {
  const details = TRACKS[track];
  const sections = TRACK_SECTIONS[track];
  const custom = customSections.filter((item) => item.track === track);
  return (
    <div className="page-wrap track-page">
      <button className="back-link" onClick={onBack}><span aria-hidden="true">←</span> Все направления</button>
      <section className={`track-hero ${track}-hero glass-panel`}>
        <span className={`track-logo large ${track}-logo`} aria-hidden="true">{details.short}</span>
        <div className="track-hero-copy">
          <p className="eyebrow">{details.kicker}</p>
          <h1>{details.name}</h1>
          <p>{details.description}</p>
        </div>
        <div className="track-hero-stat"><strong>{details.baseDone}</strong><span>тем пройдено</span></div>
      </section>

      <section className="curriculum-section" aria-labelledby="curriculum-title">
        <div className="section-heading">
          <div><p className="eyebrow">УЧЕБНЫЙ ПЛАН</p><h2 id="curriculum-title">Разделы направления</h2></div>
          <button className="quiet-button glass-control" onClick={onAddSection}>+ Добавить раздел</button>
        </div>
        <div className="section-card-list">
          {sections.map((section) => (
            <article className={`section-card glass-panel ${section.state === "empty" ? "empty" : ""}`} key={section.id}>
              <span className="section-number">{section.index}</span>
              <div><div className="section-title-row"><h3>{section.title}</h3>{section.state === "empty" && <span className="empty-pill">Пока пусто</span>}</div><p>{section.description}</p><span className="section-meta">{section.meta}</span></div>
              <button type="button" disabled={section.state === "empty"} onClick={onPractice} aria-label={`Открыть раздел ${section.title}`}>{section.state === "empty" ? "+" : "→"}</button>
            </article>
          ))}
          {custom.map((section, index) => (
            <article className="section-card glass-panel custom" key={section.id}>
              <span className="section-number">{String(sections.length + index + 1).padStart(2, "0")}</span>
              <div><div className="section-title-row"><h3>{section.title}</h3><span className="custom-pill">Ваш раздел</span></div><p>{section.description || "Добавьте темы и материалы, когда будете готовы."}</p><span className="section-meta">0 тем · создано вами</span></div>
              <button type="button" disabled aria-label="Раздел пока пуст">+</button>
            </article>
          ))}
        </div>
      </section>

      <section className="modules-section" aria-labelledby="modules-title">
        <div className="section-heading compact"><div><p className="eyebrow">СОДЕРЖАНИЕ</p><h2 id="modules-title">Модули для практики</h2></div></div>
        <div className="module-grid">
          {MODULES[track].map((module, index) => {
            const pct = Math.round((module.done / module.topics) * 100);
            return (
              <button className="module-card glass-panel" onClick={onPractice} key={module.title}>
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

function PracticeView({ track, completed, onTrackChange, onBack, onComplete }: {
  track: TrackId;
  completed: boolean;
  onTrackChange: (track: TrackId) => void;
  onBack: () => void;
  onComplete: () => void;
}) {
  const lesson = PRACTICE[track];
  const [code, setCode] = useState(lesson.code);
  const [result, setResult] = useState<RunResult | null>(null);
  const [running, setRunning] = useState(false);
  const [hintOpen, setHintOpen] = useState(false);

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
    <div className="practice-page">
      <aside className="practice-sidebar glass-panel">
        <button className="back-link light" onClick={onBack}><span aria-hidden="true">←</span> К разделам</button>
        <p className="sidebar-eyebrow">КОДОВАЯ ПРАКТИКА</p>
        <h2>{TRACKS[track].name}</h2>
        <div className="language-switch" role="group" aria-label="Язык практики">
          <button className={track === "ios" ? "active" : ""} onClick={() => onTrackChange("ios")}>Swift</button>
          <button className={track === "go" ? "active" : ""} onClick={() => onTrackChange("go")}>Go</button>
        </div>
        <ol className="task-list">
          <li className="done"><span>✓</span><div><strong>Теория</strong><small>Короткий разбор</small></div></li>
          <li className="done"><span>✓</span><div><strong>Вопросы</strong><small>3 вопроса интервью</small></div></li>
          <li className="current"><span>03</span><div><strong>Задача с кодом</strong><small>{lesson.compiler}</small></div></li>
          <li><span>04</span><div><strong>Итоги</strong><small>Закрепить тему</small></div></li>
        </ol>
        <div className="sidebar-note"><span aria-hidden="true">⌁</span><p>Код отправляется в изолированный внешний компилятор. Не вставляйте секреты и токены.</p></div>
      </aside>

      <section className="workspace">
        <header className="workspace-head">
          <div><p>{lesson.category}</p><h1>{lesson.title}</h1></div>
          <span className={`completion-badge ${completed ? "done" : ""}`}>{completed ? "✓ Выполнено" : "Практика"}</span>
        </header>
        <div className="task-brief glass-panel">
          <div className="task-brief-number">03</div>
          <div><p className="eyebrow">ЗАДАЧА</p><p>{lesson.task}</p></div>
          <button onClick={() => setHintOpen((open) => !open)}>{hintOpen ? "Скрыть" : "Подсказка"}</button>
        </div>
        {hintOpen && <div className="hint-panel glass-panel"><span aria-hidden="true">✦</span><p>{lesson.hint}</p></div>}

        <div className="code-lab">
          <div className="editor-panel">
            <div className="panel-toolbar"><span className="file-name"><i className={track} />{track === "ios" ? "main.swift" : "main.go"}</span><button onClick={() => setCode(lesson.code)}>Сбросить</button></div>
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
            <div className="panel-toolbar"><span>Консоль</span><span className="runtime-dot">{lesson.compiler}</span></div>
            <div className={`console-output ${result ? (result.ok ? "success" : "error") : ""}`} aria-live="polite">
              {!result && <div className="console-empty"><span>›_</span><p>Запустите код, чтобы увидеть результат компиляции и вывод программы.</p></div>}
              {result && <><p className="console-status">{result.ok ? "✓ Выполнено успешно" : "× Ошибка выполнения"}</p>{result.stdout && <pre>{result.stdout}</pre>}{result.stderr && <pre className="stderr">{result.stderr}</pre>}<small>{result.compiler}</small></>}
            </div>
          </div>
        </div>
        <div className="runner-bar glass-panel">
          <div><span className="live-dot" />Изолированный запуск · лимит 10 КБ</div>
          <button className="run-button" onClick={run} disabled={running || !code.trim()}>{running ? <><i className="spinner" /> Компилирую…</> : <><span aria-hidden="true">▶</span> Запустить код</>}</button>
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
