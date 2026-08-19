"use client";

import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import Link from "next/link";

type Topic = { id: string; sectionId: string; slug: string; title: string; description: string; position: number; status: string };
type Section = { id: string; trackId: string; slug: string; title: string; description: string; icon: string; position: number; status: string; topics: Topic[] };
type Track = { id: string; title: string; slug: string; sections: Section[] };
type Direction = { id: string; slug: string; shortName: string; tracks: Track[] };
type Lesson = {
  id: string; topicId: string; directionSlug: string; sectionTitle: string; slug: string; title: string;
  bodyMarkdown: string; durationMinutes: number; position: number; status: string;
};
type Question = {
  id: string; topicId: string; directionSlug: string; sectionTitle: string; prompt: string;
  explanation: string; referenceAnswer: string; difficulty: number; position: number; status: string;
};
type CodingTask = {
  id: string; topicId: string; directionSlug: string; sectionTitle: string; slug: string; title: string;
  statementMarkdown: string; hint: string; language: "swift" | "go"; starterCode: string;
  referenceSolution: string; timeLimitMs: number; memoryLimitKb: number; difficulty: number;
  position: number; status: string;
};
type TaskEditor = Omit<CodingTask, "directionSlug" | "sectionTitle">;
type CodingTest = { id?: string; stdin: string; expectedStdout: string; hidden: boolean; position: number };
type Catalog = { directions: Direction[]; lessons: Lesson[]; questions: Question[]; codingTasks: CodingTask[] };
type Tab = "structure" | "lessons" | "questions" | "tasks";
type StructureKind = "section" | "topic";

const emptySection = { id: "", trackId: "", slug: "", title: "", description: "", icon: "◇", position: 0, status: "draft", topics: [] as Topic[] };
const emptyTopic = { id: "", sectionId: "", slug: "", title: "", description: "", position: 0, status: "draft" };
const emptyLesson = { id: "", topicId: "", slug: "", title: "", bodyMarkdown: "", durationMinutes: 10, position: 0, status: "draft" };
const emptyQuestion = { id: "", topicId: "", prompt: "", explanation: "", referenceAnswer: "", difficulty: 2, position: 0, status: "draft" };
const emptyTask: TaskEditor = { id: "", topicId: "", slug: "", title: "", statementMarkdown: "", hint: "", language: "swift",
  starterCode: "import Foundation\n\n// Напишите решение здесь\n", referenceSolution: "", timeLimitMs: 3000,
  memoryLimitKb: 128000, difficulty: 2, position: 0, status: "draft" };

export function AdminPanel() {
  const [catalog, setCatalog] = useState<Catalog | null>(null);
  const [tab, setTab] = useState<Tab>("structure");
  const [structureKind, setStructureKind] = useState<StructureKind>("section");
  const [section, setSection] = useState(emptySection);
  const [topic, setTopic] = useState(emptyTopic);
  const [lesson, setLesson] = useState(emptyLesson);
  const [question, setQuestion] = useState(emptyQuestion);
  const [task, setTask] = useState(emptyTask);
  const [taskTests, setTaskTests] = useState<CodingTest[]>([]);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    setError("");
    try {
      const response = await fetch("/api/backend/v1/admin/catalog", { cache: "no-store" });
      const data = await response.json() as Catalog & { error?: { message?: string } };
      if (!response.ok) throw new Error(data.error?.message || "Не удалось загрузить контент");
      setCatalog(data);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Backend недоступен");
    }
  }, []);

  useEffect(() => {
    const timeout = window.setTimeout(() => { void load(); }, 0);
    return () => window.clearTimeout(timeout);
  }, [load]);

  const tracks = useMemo(() => catalog?.directions.flatMap((direction) => direction.tracks.map((track) => ({
    ...track, label: `${direction.shortName} · ${track.slug === "interview" ? "Интервью" : "Учебный план"}`,
  }))) ?? [], [catalog]);

  const sections = useMemo(() => catalog?.directions.flatMap((direction) =>
    direction.tracks.flatMap((track) => track.sections.map((item) => ({
      ...item, directionSlug: direction.slug, trackSlug: track.slug,
      label: `${direction.shortName} · ${track.slug === "interview" ? "Интервью" : "Учебный план"} · ${item.title}`,
    })))) ?? [], [catalog]);

  const topics = useMemo(() => catalog?.directions.flatMap((direction) =>
    direction.tracks.flatMap((track) => track.sections.flatMap((section) => section.topics.map((topic) => ({
      ...topic, label: `${direction.shortName} · ${track.slug === "interview" ? "Интервью" : "Учебный план"} · ${section.title} · ${topic.title}`,
    }))))) ?? [], [catalog]);

  const saveSection = async (event: FormEvent) => {
    event.preventDefault();
    await save(`/api/backend/v1/admin/sections${section.id ? `/${section.id}` : ""}`, section.id ? "PUT" : "POST",
      { ...section, trackId: section.trackId || tracks[0]?.id || "", topics: undefined }, () => {
        setSection({ ...emptySection, trackId: tracks[0]?.id || "" });
      });
  };

  const saveTopic = async (event: FormEvent) => {
    event.preventDefault();
    await save(`/api/backend/v1/admin/topics${topic.id ? `/${topic.id}` : ""}`, topic.id ? "PUT" : "POST",
      { ...topic, sectionId: topic.sectionId || sections[0]?.id || "" }, () => {
        setTopic({ ...emptyTopic, sectionId: sections[0]?.id || "" });
      });
  };

  const saveLesson = async (event: FormEvent) => {
    event.preventDefault();
    await save(`/api/backend/v1/admin/lessons${lesson.id ? `/${lesson.id}` : ""}`, lesson.id ? "PUT" : "POST",
      { ...lesson, topicId: lesson.topicId || topics[0]?.id || "" }, () => {
        setLesson({ ...emptyLesson, topicId: topics[0]?.id || "" });
      });
  };

  const saveQuestion = async (event: FormEvent) => {
    event.preventDefault();
    await save(`/api/backend/v1/admin/questions${question.id ? `/${question.id}` : ""}`, question.id ? "PUT" : "POST",
      { ...question, topicId: question.topicId || topics[0]?.id || "" }, () => {
      setQuestion({ ...emptyQuestion, topicId: topics[0]?.id || "" });
    });
  };

  const saveTask = async (event: FormEvent) => {
    event.preventDefault();
    setBusy(true); setError(""); setMessage("");
    try {
      const response = await fetch(`/api/backend/v1/admin/coding-tasks${task.id ? `/${task.id}` : ""}`, {
        method: task.id ? "PUT" : "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...task, topicId: task.topicId || topics[0]?.id || "" }),
      });
      const saved = await response.json() as CodingTask & { error?: { message?: string; fields?: Record<string, string> } };
      if (!response.ok) throw new Error(saved.error?.fields ? Object.values(saved.error.fields).join(" · ") : saved.error?.message || "Не удалось сохранить задачу");
      const testsResponse = await fetch(`/api/backend/v1/admin/coding-tasks/${saved.id}/tests`, {
        method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ items: taskTests }),
      });
      const testsData = await testsResponse.json() as { error?: { message?: string } };
      if (!testsResponse.ok) throw new Error(testsData.error?.message || "Задача сохранена, но тесты не обновились");
      setMessage("Задача и тесты сохранены");
      setTask({ ...emptyTask, topicId: topics[0]?.id || "" });
      setTaskTests([]);
      await load();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Не удалось сохранить задачу");
    } finally { setBusy(false); }
  };

  const editTask = async (item: CodingTask) => {
    setTask({ ...item });
    setTaskTests([]);
    setError("");
    try {
      const response = await fetch(`/api/backend/v1/admin/coding-tasks/${item.id}/tests`, { cache: "no-store" });
      const data = await response.json() as { items?: CodingTest[]; error?: { message?: string } };
      if (!response.ok) throw new Error(data.error?.message || "Не удалось загрузить тесты");
      setTaskTests(data.items ?? []);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Не удалось загрузить тесты");
    }
  };

  const save = async (url: string, method: string, payload: unknown, reset: () => void) => {
    setBusy(true); setError(""); setMessage("");
    try {
      const response = await fetch(url, { method, headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) });
      const data = await response.json() as { error?: { message?: string; fields?: Record<string, string> } };
      if (!response.ok) throw new Error(data.error?.fields ? Object.values(data.error.fields).join(" · ") : data.error?.message || "Не удалось сохранить");
      setMessage("Сохранено"); reset(); await load();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Не удалось сохранить");
    } finally { setBusy(false); }
  };

  const archive = async (kind: "sections" | "topics" | "lessons" | "questions" | "coding-tasks", id: string) => {
    if (!window.confirm("Архивировать материал? Его можно будет восстановить через API.")) return;
    setBusy(true); setError("");
    try {
      const response = await fetch(`/api/backend/v1/admin/${kind}/${id}`, { method: "DELETE" });
      if (!response.ok) throw new Error("Не удалось архивировать");
      await load();
    } catch (cause) { setError(cause instanceof Error ? cause.message : "Ошибка"); }
    finally { setBusy(false); }
  };

  return (
    <main className="admin-shell">
      <div className="noise" aria-hidden="true" />
      <header className="admin-topbar">
        <Link className="brand" href="/"><span className="brand-mark" aria-hidden="true">L</span><span>Learny</span></Link>
        <div><span>Управление контентом</span><Link href="/">Вернуться на платформу ↗</Link></div>
      </header>

      <section className="admin-heading">
        <p className="eyebrow">ЛИЧНАЯ РЕДАКЦИЯ</p>
        <h1>База знаний Learny</h1>
        <p>Управляйте структурой, уроками, вопросами и задачами — от черновика до публикации без нового deploy.</p>
      </section>

      {error && <div className="admin-alert error" role="alert">{error}</div>}
      {message && <div className="admin-alert success" role="status">{message}</div>}

      <div className="admin-tabs" role="tablist" aria-label="Тип материала">
        <button className={tab === "structure" ? "active" : ""} onClick={() => setTab("structure")}>Структура <span>{sections.length + topics.length}</span></button>
        <button className={tab === "lessons" ? "active" : ""} onClick={() => setTab("lessons")}>Уроки <span>{catalog?.lessons.length ?? 0}</span></button>
        <button className={tab === "questions" ? "active" : ""} onClick={() => setTab("questions")}>Вопросы <span>{catalog?.questions.length ?? 0}</span></button>
        <button className={tab === "tasks" ? "active" : ""} onClick={() => setTab("tasks")}>Лайвкодинг <span>{catalog?.codingTasks.length ?? 0}</span></button>
      </div>

      <div className="admin-grid">
        {tab === "structure" ? <>
          {structureKind === "section" ? <form className="admin-editor glass-panel" onSubmit={saveSection}>
            <EditorHead title={section.id ? "Редактировать раздел" : "Новый раздел"} onReset={() => setSection({ ...emptySection, trackId: tracks[0]?.id || "" })} />
            <div className="admin-kind-switch wide" role="group" aria-label="Уровень структуры"><button className="active" type="button">Раздел</button><button type="button" onClick={() => setStructureKind("topic")}>Тема</button></div>
            <label className="wide"><span>Направление и формат</span><select required value={section.trackId || tracks[0]?.id || ""} onChange={(event) => setSection({ ...section, trackId: event.target.value })}><option value="" disabled>Выберите трек</option>{tracks.map((item) => <option value={item.id} key={item.id}>{item.label}</option>)}</select></label>
            <label><span>Название</span><input required value={section.title} onChange={(event) => setSection({ ...section, title: event.target.value, slug: section.id ? section.slug : toSlug(event.target.value) })} /></label>
            <label><span>Slug</span><input required pattern="[a-z0-9]+(?:-[a-z0-9]+)*" value={section.slug} onChange={(event) => setSection({ ...section, slug: event.target.value })} /></label>
            <label><span>Иконка</span><input maxLength={20} value={section.icon} onChange={(event) => setSection({ ...section, icon: event.target.value })} /></label>
            <label><span>Позиция</span><input type="number" min={0} value={section.position} onChange={(event) => setSection({ ...section, position: Number(event.target.value) })} /></label>
            <label className="wide"><span>Описание</span><textarea value={section.description} onChange={(event) => setSection({ ...section, description: event.target.value })} /></label>
            <StatusField status={section.status} onStatus={(status) => setSection({ ...section, status })} />
            <button className="admin-save" disabled={busy}>{busy ? "Сохраняю…" : section.id ? "Сохранить раздел" : "Добавить раздел"}<span>→</span></button>
          </form> : <form className="admin-editor glass-panel" onSubmit={saveTopic}>
            <EditorHead title={topic.id ? "Редактировать тему" : "Новая тема"} onReset={() => setTopic({ ...emptyTopic, sectionId: sections[0]?.id || "" })} />
            <div className="admin-kind-switch wide" role="group" aria-label="Уровень структуры"><button type="button" onClick={() => setStructureKind("section")}>Раздел</button><button className="active" type="button">Тема</button></div>
            <label className="wide"><span>Родительский раздел</span><select required value={topic.sectionId || sections[0]?.id || ""} onChange={(event) => setTopic({ ...topic, sectionId: event.target.value })}><option value="" disabled>Выберите раздел</option>{sections.map((item) => <option value={item.id} key={item.id}>{item.label}</option>)}</select></label>
            <label><span>Название</span><input required value={topic.title} onChange={(event) => setTopic({ ...topic, title: event.target.value, slug: topic.id ? topic.slug : toSlug(event.target.value) })} /></label>
            <label><span>Slug</span><input required pattern="[a-z0-9]+(?:-[a-z0-9]+)*" value={topic.slug} onChange={(event) => setTopic({ ...topic, slug: event.target.value })} /></label>
            <label><span>Позиция</span><input type="number" min={0} value={topic.position} onChange={(event) => setTopic({ ...topic, position: Number(event.target.value) })} /></label>
            <label className="wide"><span>Описание</span><textarea value={topic.description} onChange={(event) => setTopic({ ...topic, description: event.target.value })} /></label>
            <StatusField status={topic.status} onStatus={(status) => setTopic({ ...topic, status })} />
            <button className="admin-save" disabled={busy}>{busy ? "Сохраняю…" : topic.id ? "Сохранить тему" : "Добавить тему"}<span>→</span></button>
          </form>}
          <StructureList sections={sections} onEditSection={(item) => { setStructureKind("section"); setSection({ ...item }); }} onEditTopic={(item) => { setStructureKind("topic"); setTopic({ ...item }); }} onArchive={archive} />
        </> : tab === "lessons" ? <>
          <form className="admin-editor glass-panel" onSubmit={saveLesson}>
            <EditorHead title={lesson.id ? "Редактировать урок" : "Новый урок"} onReset={() => setLesson({ ...emptyLesson, topicId: topics[0]?.id || "" })} />
            <TopicSelect value={lesson.topicId || topics[0]?.id || ""} topics={topics} onChange={(topicId) => setLesson({ ...lesson, topicId })} />
            <label><span>Название</span><input required value={lesson.title} onChange={(event) => setLesson({ ...lesson, title: event.target.value, slug: lesson.id ? lesson.slug : toSlug(event.target.value) })} /></label>
            <label><span>Slug</span><input required pattern="[a-z0-9]+(?:-[a-z0-9]+)*" value={lesson.slug} onChange={(event) => setLesson({ ...lesson, slug: event.target.value })} /></label>
            <label><span>Длительность, минут</span><input type="number" min={0} max={600} value={lesson.durationMinutes} onChange={(event) => setLesson({ ...lesson, durationMinutes: Number(event.target.value) })} /></label>
            <label><span>Позиция</span><input type="number" min={0} value={lesson.position} onChange={(event) => setLesson({ ...lesson, position: Number(event.target.value) })} /></label>
            <label className="wide"><span>Материал в Markdown</span><textarea className="admin-markdown-field" required minLength={10} value={lesson.bodyMarkdown} onChange={(event) => setLesson({ ...lesson, bodyMarkdown: event.target.value })} placeholder="# Заголовок&#10;&#10;Текст урока и примеры кода" /></label>
            <StatusField status={lesson.status} onStatus={(status) => setLesson({ ...lesson, status })} />
            <button className="admin-save" disabled={busy}>{busy ? "Сохраняю…" : lesson.id ? "Сохранить урок" : "Добавить урок"}<span>→</span></button>
          </form>
          <ContentList title="Уроки" empty="Уроков пока нет" items={catalog?.lessons ?? []} onEdit={(item) => setLesson({ ...item })} onArchive={(id) => archive("lessons", id)} />
        </> : tab === "questions" ? <>
          <form className="admin-editor glass-panel" onSubmit={saveQuestion}>
            <EditorHead title={question.id ? "Редактировать вопрос" : "Новый вопрос"} onReset={() => setQuestion({ ...emptyQuestion, topicId: topics[0]?.id || "" })} />
            <TopicSelect value={question.topicId || topics[0]?.id || ""} topics={topics} onChange={(topicId) => setQuestion({ ...question, topicId })} />
            <label className="wide"><span>Вопрос</span><textarea required minLength={10} value={question.prompt} onChange={(event) => setQuestion({ ...question, prompt: event.target.value })} placeholder="Сформулируйте вопрос так, как его зададут на интервью" /></label>
            <label className="wide"><span>Эталонный ответ</span><textarea value={question.referenceAnswer} onChange={(event) => setQuestion({ ...question, referenceAnswer: event.target.value })} placeholder="Ответ виден только в админке" /></label>
            <label className="wide"><span>Пояснение</span><textarea value={question.explanation} onChange={(event) => setQuestion({ ...question, explanation: event.target.value })} /></label>
            <MetaFields difficulty={question.difficulty} status={question.status} onDifficulty={(difficulty) => setQuestion({ ...question, difficulty })} onStatus={(status) => setQuestion({ ...question, status })} />
            <button className="admin-save" disabled={busy}>{busy ? "Сохраняю…" : question.id ? "Сохранить изменения" : "Добавить вопрос"}<span>→</span></button>
          </form>
          <ContentList title="Вопросы" empty="Вопросов пока нет" items={catalog?.questions ?? []} onEdit={(item) => setQuestion({ ...item })} onArchive={(id) => archive("questions", id)} />
        </> : <>
          <form className="admin-editor glass-panel" onSubmit={saveTask}>
            <EditorHead title={task.id ? "Редактировать задачу" : "Новая задача"} onReset={() => { setTask({ ...emptyTask, topicId: topics[0]?.id || "" }); setTaskTests([]); }} />
            <TopicSelect value={task.topicId || topics[0]?.id || ""} topics={topics} onChange={(topicId) => setTask({ ...task, topicId })} />
            <label><span>Название</span><input required value={task.title} onChange={(event) => setTask({ ...task, title: event.target.value, slug: task.id ? task.slug : toSlug(event.target.value) })} /></label>
            <label><span>Slug</span><input required pattern="[a-z0-9]+(?:-[a-z0-9]+)*" value={task.slug} onChange={(event) => setTask({ ...task, slug: event.target.value })} /></label>
            <label><span>Язык</span><select value={task.language} onChange={(event) => setTask({ ...task, language: event.target.value as "swift" | "go" })}><option value="swift">Swift</option><option value="go">Go</option></select></label>
            <label className="wide"><span>Условие</span><textarea required minLength={10} value={task.statementMarkdown} onChange={(event) => setTask({ ...task, statementMarkdown: event.target.value })} /></label>
            <label className="wide"><span>Подсказка</span><textarea value={task.hint} onChange={(event) => setTask({ ...task, hint: event.target.value })} /></label>
            <label className="wide"><span>Стартовый код</span><textarea className="code-field" value={task.starterCode} onChange={(event) => setTask({ ...task, starterCode: event.target.value })} /></label>
            <label className="wide"><span>Эталонное решение</span><textarea className="code-field" value={task.referenceSolution} onChange={(event) => setTask({ ...task, referenceSolution: event.target.value })} /></label>
            <div className="admin-tests wide">
              <div className="admin-tests-head"><div><span>Тесты</span><small>Скрытые тесты никогда не попадут в browser.</small></div><button type="button" onClick={() => setTaskTests((items) => [...items, { stdin: "", expectedStdout: "", hidden: true, position: items.length + 1 }])}>+ Добавить тест</button></div>
              {!taskTests.length && <p>Пока тестов нет — задача будет проверяться только компиляцией.</p>}
              {taskTests.map((test, index) => <div className="admin-test" key={test.id || index}>
                <label><span>stdin</span><textarea value={test.stdin} onChange={(event) => setTaskTests((items) => items.map((value, itemIndex) => itemIndex === index ? { ...value, stdin: event.target.value } : value))} /></label>
                <label><span>Ожидаемый stdout</span><textarea value={test.expectedStdout} onChange={(event) => setTaskTests((items) => items.map((value, itemIndex) => itemIndex === index ? { ...value, expectedStdout: event.target.value } : value))} /></label>
                <label className="admin-hidden-test"><input type="checkbox" checked={test.hidden} onChange={(event) => setTaskTests((items) => items.map((value, itemIndex) => itemIndex === index ? { ...value, hidden: event.target.checked } : value))} /><span>Скрытый</span></label>
                <button type="button" aria-label="Удалить тест" onClick={() => setTaskTests((items) => items.filter((_, itemIndex) => itemIndex !== index))}>×</button>
              </div>)}
            </div>
            <MetaFields difficulty={task.difficulty} status={task.status} onDifficulty={(difficulty) => setTask({ ...task, difficulty })} onStatus={(status) => setTask({ ...task, status })} />
            <button className="admin-save" disabled={busy}>{busy ? "Сохраняю…" : task.id ? "Сохранить изменения" : "Добавить задачу"}<span>→</span></button>
          </form>
          <ContentList title="Задачи" empty="Задач пока нет" items={catalog?.codingTasks ?? []} onEdit={(item) => void editTask(item)} onArchive={(id) => archive("coding-tasks", id)} />
        </>}
      </div>
    </main>
  );
}

function EditorHead({ title, onReset }: { title: string; onReset: () => void }) {
  return <div className="admin-editor-head"><div><p className="eyebrow">РЕДАКТОР</p><h2>{title}</h2></div><button type="button" onClick={onReset}>Очистить</button></div>;
}

function TopicSelect({ value, topics, onChange }: { value: string; topics: (Topic & { label: string })[]; onChange: (value: string) => void }) {
  return <label className="wide"><span>Раздел</span><select required value={value} onChange={(event) => onChange(event.target.value)}><option value="" disabled>Выберите раздел</option>{topics.map((topic) => <option value={topic.id} key={topic.id}>{topic.label}</option>)}</select></label>;
}

function MetaFields({ difficulty, status, onDifficulty, onStatus }: { difficulty: number; status: string; onDifficulty: (value: number) => void; onStatus: (value: string) => void }) {
  return <><label><span>Сложность</span><select value={difficulty} onChange={(event) => onDifficulty(Number(event.target.value))}>{[1,2,3,4,5].map((value) => <option key={value} value={value}>{value} / 5</option>)}</select></label><label><span>Статус</span><select value={status} onChange={(event) => onStatus(event.target.value)}><option value="draft">Черновик</option><option value="published">Опубликовано</option><option value="archived">Архив</option></select></label></>;
}

function StatusField({ status, onStatus }: { status: string; onStatus: (value: string) => void }) {
  return <label><span>Статус</span><select value={status} onChange={(event) => onStatus(event.target.value)}><option value="draft">Черновик</option><option value="published">Опубликовано</option><option value="archived">Архив</option></select></label>;
}

function StructureList({ sections, onEditSection, onEditTopic, onArchive }: {
  sections: (Section & { directionSlug: string; trackSlug: string; label: string })[];
  onEditSection: (item: Section) => void;
  onEditTopic: (item: Topic) => void;
  onArchive: (kind: "sections" | "topics", id: string) => void;
}) {
  return <section className="admin-list glass-panel"><div className="admin-list-head"><p className="eyebrow">ДЕРЕВО</p><h2>Разделы и темы</h2></div><div className="admin-list-scroll">{!sections.length && <p className="admin-empty">Разделов пока нет</p>}{sections.map((section) => <div className="admin-structure-group" key={section.id}>
    <article><button className="admin-item-main" type="button" onClick={() => onEditSection(section)}><span>{section.directionSlug.toUpperCase()} · {section.trackSlug === "interview" ? "ИНТЕРВЬЮ" : "УЧЕБНЫЙ ПЛАН"}</span><strong>{section.title}</strong><small className={`status-${section.status}`}>{statusLabel(section.status)}</small></button><button className="admin-archive" type="button" onClick={() => onArchive("sections", section.id)} aria-label="Архивировать раздел">×</button></article>
    {section.topics.map((topic) => <article className="admin-topic-item" key={topic.id}><button className="admin-item-main" type="button" onClick={() => onEditTopic(topic)}><span>ТЕМА</span><strong>{topic.title}</strong><small className={`status-${topic.status}`}>{statusLabel(topic.status)}</small></button><button className="admin-archive" type="button" onClick={() => onArchive("topics", topic.id)} aria-label="Архивировать тему">×</button></article>)}
  </div>)}</div></section>;
}

function ContentList<T extends { id: string; title?: string; prompt?: string; directionSlug: string; sectionTitle: string; status: string }>({ title, empty, items, onEdit, onArchive }: { title: string; empty: string; items: T[]; onEdit: (item: T) => void; onArchive: (id: string) => void }) {
  return <section className="admin-list glass-panel"><div className="admin-list-head"><p className="eyebrow">БАЗА</p><h2>{title}</h2></div><div className="admin-list-scroll">{!items.length && <p className="admin-empty">{empty}</p>}{items.map((item) => <article key={item.id}><button className="admin-item-main" type="button" onClick={() => onEdit(item)}><span>{item.directionSlug.toUpperCase()} · {item.sectionTitle}</span><strong>{item.title || item.prompt}</strong><small className={`status-${item.status}`}>{statusLabel(item.status)}</small></button><button className="admin-archive" type="button" onClick={() => onArchive(item.id)} aria-label="Архивировать">×</button></article>)}</div></section>;
}

function statusLabel(status: string) { return status === "published" ? "Опубликовано" : status === "archived" ? "Архив" : "Черновик"; }
function toSlug(value: string) {
  const map: Record<string, string> = { а: "a", б: "b", в: "v", г: "g", д: "d", е: "e", ё: "e", ж: "zh", з: "z", и: "i", й: "y", к: "k", л: "l", м: "m", н: "n", о: "o", п: "p", р: "r", с: "s", т: "t", у: "u", ф: "f", х: "h", ц: "ts", ч: "ch", ш: "sh", щ: "sch", ъ: "", ы: "y", ь: "", э: "e", ю: "yu", я: "ya" };
  return value.toLowerCase().split("").map((character) => map[character] ?? character).join("").replace(/[^a-z0-9\s-]/g, "").trim().replace(/\s+/g, "-").replace(/-+/g, "-") || "material";
}
