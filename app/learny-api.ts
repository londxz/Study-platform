export type TrackId = "ios" | "go";
export type PathId = "learning" | "interview";
export type MockMode = "theory" | "livecoding";

export type LearnTopic = {
  id: string;
  sectionId?: string;
  slug: string;
  title: string;
  description: string;
  position: number;
  status: string;
};

export type LearnSection = {
  id: string;
  trackId?: string;
  slug: string;
  title: string;
  description: string;
  icon: string;
  position: number;
  status: string;
  itemCount: number;
  topics: LearnTopic[];
};

export type LearnTrack = {
  id: string;
  slug: PathId;
  title: string;
  description: string;
  position: number;
  status: string;
  sections: LearnSection[];
};

export type LearnDirection = {
  id: string;
  slug: TrackId;
  shortName: string;
  name: string;
  position: number;
  status: string;
  tracks: LearnTrack[];
};

export type LearnQuestion = {
  id: string;
  topicId: string;
  trackSlug: PathId;
  sectionId: string;
  directionSlug: TrackId;
  sectionTitle: string;
  prompt: string;
  explanation?: string;
  difficulty: number;
  position: number;
  status: string;
};

export type LearnLesson = {
  id: string;
  topicId: string;
  trackSlug: PathId;
  sectionId: string;
  directionSlug: TrackId;
  sectionTitle: string;
  slug: string;
  title: string;
  bodyMarkdown: string;
  durationMinutes: number;
  position: number;
  status: string;
};

export type LearnCodingTask = {
  id: string;
  topicId: string;
  trackSlug: PathId;
  sectionId: string;
  directionSlug: TrackId;
  sectionTitle: string;
  slug: string;
  title: string;
  statementMarkdown: string;
  hint: string;
  language: "swift" | "go";
  starterCode: string;
  timeLimitMs: number;
  memoryLimitKb: number;
  difficulty: number;
  position: number;
  status: string;
};

export type LearnCatalog = {
  directions: LearnDirection[];
  lessons: LearnLesson[];
  questions: LearnQuestion[];
  codingTasks: LearnCodingTask[];
};

export type LearnProgress = {
  contentType: "lesson" | "question" | "coding_task" | "topic" | "section";
  contentId: string;
  status: "not_started" | "in_progress" | "completed";
  lastPosition: number;
  startedAt?: string;
  completedAt?: string;
  updatedAt: string;
};

export type InterviewItem = {
  id: string;
  position: number;
  questionId?: string;
  codingTaskId?: string;
  snapshot: {
    prompt?: string;
    title?: string;
    statementMarkdown?: string;
    hint?: string;
    language?: "swift" | "go";
    starterCode?: string;
    difficulty?: number;
    section?: string;
  };
  answer: string;
  code: string;
  passed?: boolean;
};

export type InterviewSession = {
  id: string;
  directionSlug: TrackId;
  mode: MockMode;
  requestedCount: number;
  status: "active" | "completed" | "abandoned";
  startedAt: string;
  completedAt?: string;
  items: InterviewItem[];
};

export async function loadCatalog(): Promise<LearnCatalog> {
  return api<LearnCatalog>("/api/backend/v1/catalog");
}

export async function loadProgress(): Promise<LearnProgress[]> {
  const result = await api<{ items: LearnProgress[] }>("/api/backend/v1/me/progress");
  return result.items;
}

export async function saveProgress(contentType: LearnProgress["contentType"], contentId: string, status: LearnProgress["status"]): Promise<LearnProgress> {
  return api<LearnProgress>(`/api/backend/v1/me/progress/${contentType}/${contentId}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ status, lastPosition: 0 }),
  });
}

export async function createInterviewSession(direction: TrackId, mode: MockMode, count: number): Promise<InterviewSession> {
  return api<InterviewSession>("/api/backend/v1/interview-sessions", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ direction, mode, count }),
  });
}

export async function saveInterviewItem(sessionId: string, itemId: string, answer: string, code = ""): Promise<InterviewSession> {
  return api<InterviewSession>(`/api/backend/v1/interview-sessions/${sessionId}/items/${itemId}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ answer, code }),
  });
}

export async function finishInterviewSession(sessionId: string): Promise<InterviewSession> {
  return api<InterviewSession>(`/api/backend/v1/interview-sessions/${sessionId}/complete`, { method: "POST" });
}

async function api<T>(url: string, init?: RequestInit): Promise<T> {
  const response = await fetch(url, { cache: "no-store", ...init });
  const data = await response.json() as T & { error?: { message?: string } };
  if (!response.ok) throw new Error(data.error?.message || "Backend Learny недоступен");
  return data;
}
