"use client";

import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from "react";
import CodeEditorImport from "react-simple-code-editor";
import Prism from "prismjs";
import "prismjs/components/prism-go";
import "prismjs/components/prism-swift";
import {
  createInterviewSession,
  finishInterviewSession,
  loadCatalog,
  loadProgress,
  saveProgress,
  saveInterviewItem,
  type InterviewSession,
  type LearnCatalog,
  type LearnCodingTask,
  type LearnProgress,
  type MockMode,
  type PathId,
  type TrackId,
} from "./learny-api";

// vinext keeps CommonJS default exports wrapped in the browser bundle.
// Unwrap the editor component so React receives the actual forwardRef value.
const CodeEditor = (
  (CodeEditorImport as unknown as { default?: typeof CodeEditorImport }).default
  ?? CodeEditorImport
) as typeof CodeEditorImport;

type Screen = "home" | "track" | "section" | "practice" | "mock" | "progress";

type RunResult = {
  ok: boolean;
  stdout: string;
  stderr: string;
  compiler: string;
};

type PracticeTask = {
  id?: string;
  sessionItemId?: string;
  title: string;
  category: string;
  language: "swift" | "go";
  compiler: string;
  task: string;
  hint: string;
  code: string;
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
  },
  go: {
    short: "Go",
    name: "Go Development",
  },
} as const;

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
  const [practiceSectionId, setPracticeSectionId] = useState<string | null>(null);
  const [mockMode, setMockMode] = useState<MockMode>("theory");
  const [interviewTaskCount, setInterviewTaskCount] = useState(1);
  const [catalog, setCatalog] = useState<LearnCatalog | null>(null);
  const [progress, setProgress] = useState<LearnProgress[]>([]);
  const [catalogError, setCatalogError] = useState("");
  const [interviewSession, setInterviewSession] = useState<InterviewSession | null>(null);
  const [searchOpen, setSearchOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [mobileNav, setMobileNav] = useState(false);
  const searchRef = useRef<HTMLInputElement>(null);

  const refreshProgress = useCallback(async () => {
    try { setProgress(await loadProgress()); } catch { /* public catalog still works without a signed-in user */ }
  }, []);

  const refreshCatalog = useCallback(async () => {
    try {
      setCatalog(await loadCatalog());
      setCatalogError("");
    } catch (error) {
      setCatalogError(error instanceof Error ? error.message : "Не удалось загрузить материалы");
    }
  }, []);

  useEffect(() => {
    let active = true;
    void loadCatalog().then((value) => {
      if (!active) return;
      setCatalog(value);
      setCatalogError("");
    }, (error: unknown) => {
      if (active) setCatalogError(error instanceof Error ? error.message : "Не удалось загрузить материалы");
    });
    void loadProgress().then((value) => { if (active) setProgress(value); }, () => undefined);
    return () => { active = false; };
  }, []);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        setSearchOpen(true);
      }
      if (event.key === "Escape") {
        setSearchOpen(false);
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

  const searchItems = useMemo(() => catalog?.directions.flatMap((direction) => direction.tracks.flatMap((item) =>
    item.sections.map((section) => ({ title: section.title, description: section.description, track: direction.slug })))) ?? [], [catalog]);

  return (
    <main className={`app-shell screen-${screen}`}>
      <div className="noise" aria-hidden="true" />
      <div className="ambient ambient-one" aria-hidden="true" />
      <div className="ambient ambient-two" aria-hidden="true" />
      <div className="ambient ambient-three" aria-hidden="true" />

      {catalogError && <button className="backend-status" type="button" onClick={() => void refreshCatalog()}>Материалы недоступны · повторить</button>}

      <header className="topbar">
        <button className="brand-button" onClick={() => navigate("home")} aria-label="Learny — на главную">
          <Brand />
        </button>
        <nav className={`main-nav ${mobileNav ? "mobile-open" : ""}`} aria-label="Основная навигация">
          <button className={["home", "track", "section", "practice", "mock"].includes(screen) ? "active" : ""} onClick={() => navigate("home")}>Обучение</button>
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
          catalog={catalog}
          progress={progress}
          onOpenTrack={(id) => navigate("track", id)}
          onPractice={(id, selectedPath = "interview", sectionId = null) => {
            setPath(selectedPath);
            setPracticeSectionId(sectionId);
            setInterviewTaskCount(1);
            navigate("practice", id);
          }}
        />
      )}
      {screen === "track" && (
        <TrackView
          key={track}
          track={track}
          catalog={catalog}
          progress={progress}
          onBack={() => navigate("home")}
          onOpenSection={(selectedPath, sectionId) => {
            setPath(selectedPath);
            setPracticeSectionId(sectionId);
            navigate("section", track);
          }}
          onMockInterview={(mode) => {
            setMockMode(mode);
            setInterviewSession(null);
            setPath("interview");
            navigate("mock", track);
          }}
        />
      )}
      {screen === "section" && practiceSectionId && (
        <SectionView
          track={track}
          path={path}
          sectionId={practiceSectionId}
          catalog={catalog}
          progress={progress}
          onBack={() => navigate("track", track)}
          onPractice={() => {
            setInterviewSession(null);
            setInterviewTaskCount(1);
            navigate("practice", track);
          }}
          onComplete={() => void refreshProgress()}
        />
      )}
      {screen === "practice" && (
        <PracticeView
          key={`${track}-${path}-${practiceSectionId ?? "all"}-${interviewSession?.id ?? interviewTaskCount}`}
          track={track}
          path={path}
          sectionId={practiceSectionId}
          catalog={catalog}
          progress={progress}
          interviewSession={interviewSession}
          sessionCount={path === "interview" ? interviewTaskCount : 1}
          onTrackChange={setTrack}
          onBack={() => navigate(practiceSectionId ? "section" : "track", track)}
          onComplete={() => void refreshProgress()}
        />
      )}
      {screen === "mock" && (
        <MockInterviewView
          key={`${track}-${mockMode}`}
          track={track}
          mode={mockMode}
          onBack={() => navigate("track", track)}
          onStartLivecoding={(session) => {
            setPath("interview");
            setPracticeSectionId(null);
            setInterviewTaskCount(session.items.length);
            setInterviewSession(session);
            navigate("practice", track);
          }}
        />
      )}
      {screen === "progress" && <ProgressView catalog={catalog} progress={progress} onOpenTrack={(id) => navigate("track", id)} />}
      {searchOpen && (
        <SearchModal
          query={search}
          inputRef={searchRef}
          items={searchItems}
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

function Dashboard({ catalog, progress, onOpenTrack, onPractice }: {
  catalog: LearnCatalog | null;
  progress: LearnProgress[];
  onOpenTrack: (id: TrackId) => void;
  onPractice: (id: TrackId, path?: PathId, sectionId?: string | null) => void;
}) {
  const latestTaskID = progress.find((item) => item.contentType === "coding_task")?.contentId;
  const resumeTask = catalog?.codingTasks.find((item) => item.id === latestTaskID) ?? catalog?.codingTasks[0];
  const sectionTaskCount = resumeTask ? catalog?.codingTasks.filter((item) => item.sectionId === resumeTask.sectionId).length ?? 0 : 0;
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
            const direction = catalog?.directions.find((entry) => entry.slug === id);
            const total = direction ? direction.tracks.flatMap((entry) => entry.sections).reduce((sum, section) => sum + section.itemCount, 0) : 0;
            const done = completedForDirection(catalog, progress, id);
            const percent = total ? Math.round((done / total) * 100) : 0;
            return (
              <button className={`track-card ${id}-card glass-panel`} type="button" onClick={() => onOpenTrack(id)} key={id} aria-label={`Открыть направление ${direction?.name ?? item.name}`}>
                <span className="track-card-top">
                  <span className={`track-logo ${id}-logo`} aria-hidden="true">{item.short}</span>
                  <span className={`language-logo ${id === "ios" ? "swift" : "go"}`} aria-hidden="true" />
                </span>
                <span className="track-copy">
                  <span className="track-title">{direction?.name ?? item.name}</span>
                </span>
                <span className="progress-row"><span>Пройдено {done} из {total} материалов</span><strong>{percent}%</strong></span>
                <span className="progress-bar" aria-label={`Прогресс ${item.short}: ${percent}%`}><span style={{ width: `${percent}%` }} /></span>
                <span className="track-link">Открыть направление <span aria-hidden="true">↗</span></span>
              </button>
            );
          })}
        </div>
      </section>

      {resumeTask && <section className="resume-section" aria-labelledby="last-task-title">
        <div className="section-heading compact">
          <div><p className="eyebrow">ПРОДОЛЖИТЬ</p><h2 id="last-task-title">Последняя задача</h2></div>
        </div>
        <div className="resume-panel glass-panel">
          <div className="resume-label"><span aria-hidden="true">▶</span> {latestTaskID ? "ПРОДОЛЖИТЬ" : "НАЧАТЬ"}</div>
          <div className="resume-body">
            <span className="lesson-index">{String(resumeTask.position).padStart(2, "0")}</span>
            <div><p>{TRACKS[resumeTask.directionSlug].short} · {resumeTask.trackSlug === "interview" ? "Подготовка к интервью" : "Учебный план"}</p><h2 id="resume-title">{resumeTask.title}</h2><span>{resumeTask.sectionTitle} · {sectionTaskCount} {pluralTasks(sectionTaskCount)}</span></div>
          </div>
          <button className="primary-button" type="button" onClick={() => onPractice(resumeTask.directionSlug, resumeTask.trackSlug, resumeTask.sectionId)}>Открыть задачу <span aria-hidden="true">→</span></button>
        </div>
      </section>}
    </div>
  );
}

function TrackView({ track, catalog, progress, onBack, onOpenSection, onMockInterview }: {
  track: TrackId;
  catalog: LearnCatalog | null;
  progress: LearnProgress[];
  onBack: () => void;
  onOpenSection: (path: PathId, sectionId: string) => void;
  onMockInterview: (mode: MockMode) => void;
}) {
  const [selectedPath, setSelectedPath] = useState<PathId | null>(null);
  const details = TRACKS[track];
  const direction = catalog?.directions.find((item) => item.slug === track);
  const paths = useMemo(() => direction?.tracks.slice().sort((left, right) => left.position - right.position).map((item, index) => ({
    ...item,
    id: item.slug,
    index: String(index + 1).padStart(2, "0"),
    kicker: item.slug === "interview" ? "ИНТЕРВЬЮ" : "УЧЕБНЫЙ ПЛАН",
    total: item.sections.reduce((sum, section) => sum + section.itemCount, 0),
    done: completedForTrack(catalog, progress, track, item.slug),
  })) ?? [], [catalog, direction, progress, track]);

  if (!direction || !paths.length) {
    return <div className="page-wrap track-page"><button className="back-link" onClick={onBack}><span aria-hidden="true">←</span> Все направления</button><div className="content-state glass-panel"><span>⌁</span><h1>Загружаю материалы</h1><p>Каталог появится здесь, как только backend ответит.</p></div></div>;
  }

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
            const percent = item.total ? Math.round((item.done / item.total) * 100) : 0;
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
                <span className="progress-row"><span>Пройдено {item.done} из {item.total} материалов</span><strong>{percent}%</strong></span>
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
  const modules = selected.sections;

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
            const done = completedForSection(catalog, progress, module.id);
            const pct = module.itemCount ? Math.round((done / module.itemCount) * 100) : 0;
            return (
              <button className="module-card glass-panel" onClick={() => onOpenSection(selectedPath, module.id)} key={module.id} aria-label={`Открыть ${module.title}`}>
                <span className="module-icon" aria-hidden="true">{module.icon}</span>
                <span className="module-order">{String(index + 1).padStart(2, "0")}</span>
                <strong>{module.title}</strong>
                <small>{module.description}</small>
                <span className="module-progress"><i><b style={{ width: `${pct}%` }} /></i><em>{done}/{module.itemCount}</em></span>
              </button>
            );
          })}
        </div>
      </section>
    </div>
  );
}

function SectionView({ track, path, sectionId, catalog, progress, onBack, onPractice, onComplete }: {
  track: TrackId;
  path: PathId;
  sectionId: string;
  catalog: LearnCatalog | null;
  progress: LearnProgress[];
  onBack: () => void;
  onPractice: () => void;
  onComplete: () => void;
}) {
  const direction = catalog?.directions.find((item) => item.slug === track);
  const selectedTrack = direction?.tracks.find((item) => item.slug === path);
  const section = selectedTrack?.sections.find((item) => item.id === sectionId);
  const lessons = catalog?.lessons.filter((item) => item.sectionId === sectionId) ?? [];
  const questions = catalog?.questions.filter((item) => item.sectionId === sectionId) ?? [];
  const tasks = catalog?.codingTasks.filter((item) => item.sectionId === sectionId) ?? [];
  const completed = completedContentIds(progress);
  const [openedLesson, setOpenedLesson] = useState<string | null>(lessons[0]?.id ?? null);
  const [openedQuestion, setOpenedQuestion] = useState<string | null>(null);
  const [saving, setSaving] = useState<string | null>(null);
  const [error, setError] = useState("");

  const complete = async (contentType: "lesson" | "question", id: string) => {
    setSaving(id);
    setError("");
    try {
      await saveProgress(contentType, id, "completed");
      onComplete();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Не удалось сохранить прогресс");
    } finally {
      setSaving(null);
    }
  };

  if (!catalog || !section || !direction || !selectedTrack) {
    return <div className="page-wrap section-page"><button className="back-link" onClick={onBack}><span aria-hidden="true">←</span> К разделам</button><div className="content-state glass-panel"><span>⌁</span><h1>Раздел не найден</h1><p>Обновите каталог или вернитесь к списку материалов.</p></div></div>;
  }

  return (
    <div className="page-wrap section-page">
      <button className="back-link" onClick={onBack}><span aria-hidden="true">←</span> К разделам</button>
      <header className="section-detail-head">
        <div>
          <p className="eyebrow">{direction.shortName} · {path === "learning" ? "УЧЕБНЫЙ ПЛАН" : "БАЗА ИНТЕРВЬЮ"}</p>
          <h1>{section.title}</h1>
          {section.description && <p>{section.description}</p>}
        </div>
        <span className="section-detail-count">{completedForSection(catalog, progress, sectionId)} <small>из {section.itemCount}</small></span>
      </header>

      {error && <p className="inline-error" role="alert">{error}</p>}
      <div className="section-materials">
        {lessons.map((lesson, index) => {
          const isOpen = openedLesson === lesson.id;
          const isDone = completed.has(`lesson:${lesson.id}`);
          return <article className={`lesson-card glass-panel ${isOpen ? "open" : ""}`} key={lesson.id}>
            <button className="lesson-card-head" type="button" onClick={() => setOpenedLesson(isOpen ? null : lesson.id)} aria-expanded={isOpen}>
              <span>{String(index + 1).padStart(2, "0")}</span>
              <div><small>МАТЕРИАЛ · {lesson.durationMinutes || "—"} МИН</small><strong>{lesson.title}</strong></div>
              <em>{isDone ? "✓" : isOpen ? "−" : "+"}</em>
            </button>
            {isOpen && <div className="lesson-card-body">
              <div className="lesson-markdown">{renderLesson(lesson.bodyMarkdown)}</div>
              <button className="secondary-button" type="button" disabled={saving === lesson.id || isDone} onClick={() => void complete("lesson", lesson.id)}>{isDone ? "Материал пройден" : saving === lesson.id ? "Сохраняю…" : "Отметить пройденным"}</button>
            </div>}
          </article>;
        })}

        {questions.map((question, index) => {
          const isOpen = openedQuestion === question.id;
          const isDone = completed.has(`question:${question.id}`);
          return <article className={`question-card glass-panel ${isOpen ? "open" : ""}`} key={question.id}>
            <button className="question-card-head" type="button" onClick={() => setOpenedQuestion(isOpen ? null : question.id)} aria-expanded={isOpen}>
              <span>Q{String(index + 1).padStart(2, "0")}</span>
              <strong>{question.prompt}</strong>
              <em>{isDone ? "✓" : isOpen ? "−" : "+"}</em>
            </button>
            {isOpen && <div className="question-card-body">
              <p>{question.explanation || "Сформулируйте ответ вслух, как на настоящем собеседовании."}</p>
              <button className="secondary-button" type="button" disabled={saving === question.id || isDone} onClick={() => void complete("question", question.id)}>{isDone ? "Ответ засчитан" : saving === question.id ? "Сохраняю…" : "Я ответил"}</button>
            </div>}
          </article>;
        })}

        {tasks.length > 0 && <button className="section-practice-card glass-panel" type="button" onClick={onPractice}>
          <span aria-hidden="true">{`{ }`}</span>
          <div><small>ПРАКТИКА</small><strong>{tasks.length === 1 ? tasks[0].title : `${tasks.length} задач с кодом`}</strong></div>
          <em aria-hidden="true">→</em>
        </button>}

        {!lessons.length && !questions.length && !tasks.length && <div className="content-state glass-panel"><span>⌁</span><h1>Материалов пока нет</h1><p>Добавьте урок, вопрос или задачу через панель управления Learny.</p></div>}
      </div>
    </div>
  );
}

function renderLesson(markdown: string) {
  return markdown.split(/\n{2,}/).filter(Boolean).map((block, index) => {
    const value = block.trim();
    if (value.startsWith("### ")) return <h4 key={index}>{value.slice(4)}</h4>;
    if (value.startsWith("## ")) return <h3 key={index}>{value.slice(3)}</h3>;
    if (value.startsWith("# ")) return <h2 key={index}>{value.slice(2)}</h2>;
    if (value.startsWith("```")) return <pre key={index}><code>{value.replace(/^```\w*\n?/, "").replace(/```$/, "")}</code></pre>;
    return <p key={index}>{value}</p>;
  });
}

function MockInterviewView({ track, mode, onBack, onStartLivecoding }: {
  track: TrackId;
  mode: MockMode;
  onBack: () => void;
  onStartLivecoding: (session: InterviewSession) => void;
}) {
  const maxCount = mode === "theory" ? 20 : 10;
  const [count, setCount] = useState(mode === "theory" ? 6 : 3);
  const [session, setSession] = useState<InterviewSession | null>(null);
  const [current, setCurrent] = useState(0);
  const [finished, setFinished] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const questions = session?.items ?? [];
  const currentItem = questions[current];
  const progress = questions.length ? Math.round(((current + 1) / questions.length) * 100) : 0;

  const setSafeCount = (value: number) => {
    const normalized = Number.isFinite(value) ? Math.floor(value) : 1;
    setCount(Math.min(maxCount, Math.max(1, normalized)));
  };

  const start = async (event: FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError("");
    try {
      const created = await createInterviewSession(track, mode, count);
      if (mode === "livecoding") {
        onStartLivecoding(created);
        return;
      }
      setSession(created);
      setCurrent(0);
      setFinished(false);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Не удалось начать интервью");
    } finally {
      setBusy(false);
    }
  };

  const updateAnswer = (value: string) => {
    setSession((valueSession) => valueSession ? {
      ...valueSession,
      items: valueSession.items.map((item, index) => index === current ? { ...item, answer: value } : item),
    } : valueSession);
  };

  const moveNext = async () => {
    if (!session || !currentItem || busy) return;
    setBusy(true);
    setError("");
    try {
      const saved = await saveInterviewItem(session.id, currentItem.id, currentItem.answer);
      setSession(saved);
      if (current === questions.length - 1) {
        setSession(await finishInterviewSession(session.id));
        setFinished(true);
      } else {
        setCurrent((index) => index + 1);
      }
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Не удалось сохранить ответ");
    } finally {
      setBusy(false);
    }
  };

  const restart = () => {
    setSession(null);
    setCurrent(0);
    setFinished(false);
    setError("");
  };

  if (!session) {
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
          {error && <p className="inline-error" role="alert">{error}</p>}
          <button className="primary-button mock-start-button" type="submit" disabled={busy}>{busy ? "Готовлю вопросы…" : "Начать"} <span aria-hidden="true">→</span></button>
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
              <h1 id="mock-session-title">{currentItem?.snapshot.prompt}</h1>
              <p>Отвечайте так, как говорили бы интервьюеру: сначала короткий тезис, затем объяснение и пример.</p>
              <label htmlFor="mock-answer">Ваш ответ</label>
              <textarea id="mock-answer" value={currentItem?.answer ?? ""} onChange={(event) => updateAnswer(event.target.value)} placeholder="Запишите свой ответ здесь…" />
            </div>
            {error && <p className="inline-error" role="alert">{error}</p>}
            <footer className="mock-session-actions">
              <button className="secondary-button" type="button" onClick={() => void moveNext()} disabled={busy}>Пропустить</button>
              <button className="primary-button" type="button" onClick={() => void moveNext()} disabled={busy}>{busy ? "Сохраняю…" : current === questions.length - 1 ? "Завершить интервью" : "Следующий вопрос"} <span aria-hidden="true">→</span></button>
            </footer>
          </>
        ) : (
          <div className="mock-finished">
            <p className="eyebrow">ИНТЕРВЬЮ ЗАВЕРШЕНО</p>
            <h1 id="mock-session-title">Ответы собраны</h1>
            <p>Вы ответили на {questions.filter((item) => item.answer.trim()).length} из {questions.length} вопросов. Ответы и прогресс сохранены.</p>
            <div className="mock-answer-list">
              {questions.map((question, index) => (
                <article key={question.id}>
                  <span>{String(index + 1).padStart(2, "0")}</span>
                  <div><strong>{question.snapshot.prompt}</strong><p>{question.answer.trim() || "Ответ пропущен"}</p></div>
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

function PracticeView({ track, path, sectionId, catalog, progress, interviewSession, sessionCount, onTrackChange, onBack, onComplete }: {
  track: TrackId;
  path: PathId;
  sectionId: string | null;
  catalog: LearnCatalog | null;
  progress: LearnProgress[];
  interviewSession: InterviewSession | null;
  sessionCount: number;
  onTrackChange: (track: TrackId) => void;
  onBack: () => void;
  onComplete: () => void;
}) {
  const sessionTasks = useMemo<PracticeTask[]>(() => {
    if (path === "interview" && interviewSession?.mode === "livecoding") {
      return interviewSession.items.map((item) => ({
        id: item.codingTaskId,
        sessionItemId: item.id,
        title: item.snapshot.title || "Задача",
        category: item.snapshot.section || "Лайвкодинг",
        language: item.snapshot.language || (track === "ios" ? "swift" : "go"),
        compiler: item.snapshot.language === "go" ? "Go" : "Swift",
        task: item.snapshot.statementMarkdown || "",
        hint: item.snapshot.hint || "",
        code: item.code || item.snapshot.starterCode || "",
      }));
    }
    const tasks = catalog?.codingTasks.filter((item) => item.directionSlug === track && item.trackSlug === path
      && (!sectionId || item.sectionId === sectionId)) ?? [];
    return tasks.slice(0, path === "interview" ? Math.min(10, Math.max(1, sessionCount)) : 1).map(toSessionTask);
  }, [catalog, interviewSession, path, sectionId, sessionCount, track]);
  const [currentTask, setCurrentTask] = useState(0);
  const lesson = sessionTasks[currentTask] ?? null;
  const [code, setCode] = useState(sessionTasks[0]?.code ?? "");
  const [result, setResult] = useState<RunResult | null>(null);
  const [running, setRunning] = useState(false);
  const [hintOpen, setHintOpen] = useState(false);
  const hasNextTask = currentTask < sessionTasks.length - 1;
  const isLivecoding = path === "interview";
  const completed = !!lesson?.id && progress.some((item) => item.contentType === "coding_task" && item.contentId === lesson.id && item.status === "completed");

  const advanceTask = async () => {
    if (!lesson) return;
    if (interviewSession && lesson.sessionItemId) {
      try { await saveInterviewItem(interviewSession.id, lesson.sessionItemId, "", code); } catch { /* submission result remains saved */ }
    }
    if (!hasNextTask) {
      if (interviewSession) {
        try { await finishInterviewSession(interviewSession.id); } catch { /* progress can be refreshed later */ }
      }
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
    if (!lesson) return;
    setRunning(true);
    setResult(null);
    try {
      const response = await fetch("/api/run", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ codingTaskId: lesson.id, interviewItemId: lesson.sessionItemId, language: lesson.language, code }),
      });
      const data = await response.json() as RunResult & { error?: string | { message?: string } };
      const errorMessage = typeof data.error === "string" ? data.error : data.error?.message;
      if (!response.ok) throw new Error(errorMessage || "Компилятор недоступен");
      setResult(data);
      if (data.ok) onComplete();
    } catch (error) {
      setResult({ ok: false, stdout: "", stderr: error instanceof Error ? error.message : "Не удалось запустить код", compiler: lesson.compiler });
    } finally {
      setRunning(false);
    }
  };

  if (!lesson) {
    return <div className="page-wrap"><button className="back-link" onClick={onBack}><span aria-hidden="true">←</span> К разделам</button><div className="content-state glass-panel"><span>{`{ }`}</span><h1>Задач пока нет</h1><p>Добавьте первую задачу в панели управления Learny.</p></div></div>;
  }

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
        {isLivecoding ? <header className="livecoding-brief glass-panel">
          <button className="livecoding-back" type="button" onClick={onBack} aria-label="Вернуться к подготовке">←</button>
          <div className="livecoding-brief-copy">
            <div><h1>{lesson.title}</h1><span>{currentTask + 1} / {sessionTasks.length}</span></div>
            <p>{lesson.task}</p>
          </div>
          <button className="livecoding-hint" type="button" onClick={() => setHintOpen((open) => !open)}>{hintOpen ? "Скрыть" : "Подсказка"}</button>
        </header> : <header className="workspace-head">
          <div><p>{lesson.category}</p><h1>{lesson.title}</h1></div>
          <span className={`completion-badge ${completed ? "done" : ""}`}>{completed ? "✓ Выполнено" : "Практика"}</span>
        </header>}
        {!isLivecoding && <div className="task-brief glass-panel">
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
            {result?.ok && isLivecoding && <button className="secondary-button" type="button" onClick={() => void advanceTask()}>{hasNextTask ? "Следующая задача" : "Завершить"} <span aria-hidden="true">→</span></button>}
            <button className="run-button" onClick={run} disabled={running || !code.trim()}>{running ? <><i className="spinner" /> Компилирую…</> : <><span aria-hidden="true">▶</span> Запустить код</>}</button>
          </div>
        </div>
      </section>
    </div>
  );
}

function ProgressView({ catalog, progress, onOpenTrack }: { catalog: LearnCatalog | null; progress: LearnProgress[]; onOpenTrack: (id: TrackId) => void }) {
  const completed = progress.filter((item) => item.status === "completed");
  const completedTasks = completed.filter((item) => item.contentType === "coding_task").length;
  const week = useMemo(() => {
    const formatter = new Intl.DateTimeFormat("ru-RU", { weekday: "short" });
    const days = Array.from({ length: 7 }, (_, offset) => {
      const date = new Date();
      date.setHours(0, 0, 0, 0);
      date.setDate(date.getDate() - (6 - offset));
      const next = new Date(date); next.setDate(next.getDate() + 1);
      const count = progress.filter((item) => {
        const updated = new Date(item.updatedAt);
        return updated >= date && updated < next;
      }).length;
      return { label: formatter.format(date).replace(".", ""), count };
    });
    const peak = Math.max(1, ...days.map((day) => day.count));
    return days.map((day) => ({ ...day, height: day.count ? Math.max(18, Math.round(day.count / peak * 100)) : 4 }));
  }, [progress]);
  return (
    <div className="page-wrap progress-page">
      <section className="progress-hero">
        <p className="eyebrow">ВАШ ПРОГРЕСС</p><h1>Движение видно в деталях</h1><p>Спокойный обзор тем, практики и ритма занятий.</p>
      </section>
      <div className="stats-grid">
        <article className="stat-card glass-panel"><span>Пройдено материалов</span><strong>{completed.length}</strong><small>прогресс хранится в Learny</small></article>
        <article className="stat-card glass-panel"><span>Задачи с кодом</span><strong>{completedTasks}</strong><small>{completedTasks ? "решения сохранены" : "первая задача уже готова"}</small></article>
        <article className="stat-card glass-panel"><span>Активные дни</span><strong>{week.filter((day) => day.count > 0).length} <em>из 7</em></strong><small>за последнюю неделю</small></article>
      </div>
      <section className="activity-card glass-panel">
        <div><p className="eyebrow">АКТИВНОСТЬ</p><h2>Последние 7 дней</h2></div>
        <div className="activity-chart" aria-label="График активности за неделю">
          {week.map((day) => <div key={day.label}><span style={{ height: `${day.height}%` }} /><small>{day.label}</small></div>)}
        </div>
      </section>
      <section className="progress-tracks">
        {(Object.keys(TRACKS) as TrackId[]).map((id) => {
          const item = TRACKS[id];
          const direction = catalog?.directions.find((entry) => entry.slug === id);
          const total = direction?.tracks.flatMap((entry) => entry.sections).reduce((sum, section) => sum + section.itemCount, 0) ?? 0;
          const done = completedForDirection(catalog, progress, id);
          const percent = total ? Math.round(done / total * 100) : 0;
          return <button className={`progress-track glass-panel ${id}`} key={id} onClick={() => onOpenTrack(id)}><span className={`track-logo ${id}-logo`}>{item.short}</span><div><strong>{direction?.name ?? item.name}</strong><small>{done} из {total} материалов</small><i><b style={{ width: `${percent}%` }} /></i></div><em>{percent}%</em></button>;
        })}
      </section>
    </div>
  );
}
function SearchModal({ query, inputRef, items, onQuery, onClose, onSelect }: { query: string; inputRef: React.RefObject<HTMLInputElement | null>; items: { title: string; description: string; track: TrackId }[]; onQuery: (value: string) => void; onClose: () => void; onSelect: (track: TrackId) => void }) {
  const results = useMemo(() => {
    const normalized = query.toLowerCase().trim();
    return normalized ? items.filter((item) => `${item.title} ${item.description}`.toLowerCase().includes(normalized)) : items.slice(0, 5);
  }, [items, query]);
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

function toSessionTask(task: LearnCodingTask): PracticeTask {
  return {
    id: task.id,
    title: task.title,
    category: task.sectionTitle,
    language: task.language,
    compiler: task.language === "go" ? "Go" : "Swift",
    task: task.statementMarkdown,
    hint: task.hint,
    code: task.starterCode,
  };
}

function completedContentIds(progress: LearnProgress[]) {
  return new Set(progress
    .filter((item) => item.status === "completed")
    .map((item) => `${item.contentType}:${item.contentId}`));
}

function completedForDirection(catalog: LearnCatalog | null, progress: LearnProgress[], direction: TrackId) {
  if (!catalog) return 0;
  const completed = completedContentIds(progress);
  const questions = catalog.questions.filter((item) => item.directionSlug === direction
    && completed.has(`question:${item.id}`)).length;
  const lessons = catalog.lessons.filter((item) => item.directionSlug === direction
    && completed.has(`lesson:${item.id}`)).length;
  const tasks = catalog.codingTasks.filter((item) => item.directionSlug === direction
    && completed.has(`coding_task:${item.id}`)).length;
  return lessons + questions + tasks;
}

function completedForTrack(catalog: LearnCatalog | null, progress: LearnProgress[], direction: TrackId, track: PathId) {
  if (!catalog) return 0;
  const completed = completedContentIds(progress);
  const questions = catalog.questions.filter((item) => item.directionSlug === direction && item.trackSlug === track
    && completed.has(`question:${item.id}`)).length;
  const lessons = catalog.lessons.filter((item) => item.directionSlug === direction && item.trackSlug === track
    && completed.has(`lesson:${item.id}`)).length;
  const tasks = catalog.codingTasks.filter((item) => item.directionSlug === direction && item.trackSlug === track
    && completed.has(`coding_task:${item.id}`)).length;
  return lessons + questions + tasks;
}

function completedForSection(catalog: LearnCatalog | null, progress: LearnProgress[], sectionId: string) {
  if (!catalog) return 0;
  const completed = completedContentIds(progress);
  const questions = catalog.questions.filter((item) => item.sectionId === sectionId
    && completed.has(`question:${item.id}`)).length;
  const lessons = catalog.lessons.filter((item) => item.sectionId === sectionId
    && completed.has(`lesson:${item.id}`)).length;
  const tasks = catalog.codingTasks.filter((item) => item.sectionId === sectionId
    && completed.has(`coding_task:${item.id}`)).length;
  return lessons + questions + tasks;
}

function pluralTasks(value: number) {
  const lastTwo = value % 100;
  const last = value % 10;
  if (last === 1 && lastTwo !== 11) return "задача";
  if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) return "задачи";
  return "задач";
}
