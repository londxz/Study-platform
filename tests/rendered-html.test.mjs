import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("http://localhost/", { headers: { accept: "text/html" } }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );
}

test("server-renders the Learny dashboard", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>Learny — личная платформа обучения<\/title>/i);
  assert.match(html, /С возвращением, londxz/);
  assert.match(html, /iOS Development/);
  assert.match(html, /Go Development/);
  assert.doesNotMatch(html, /codex-preview|react-loading-skeleton/i);
});

test("ships backend catalog, signed BFF and project metadata", async () => {
  const [runner, proxy, layout, packageJson, platform, admin, openapi, migration, lessonMigration] = await Promise.all([
    readFile(new URL("../app/api/run/route.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/api/_lib/learny-backend.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(new URL("../package.json", import.meta.url), "utf8"),
    readFile(new URL("../app/StudyPlatform.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/admin/AdminPanel.tsx", import.meta.url), "utf8"),
    readFile(new URL("../backend/openapi/openapi.yaml", import.meta.url), "utf8"),
    readFile(new URL("../backend/migrations/00001_init.sql", import.meta.url), "utf8"),
    readFile(new URL("../backend/migrations/00005_seed_lessons.sql", import.meta.url), "utf8"),
  ]);

  assert.match(platform, /МОК-ИНТЕРВЬЮ/);
  assert.match(platform, /<strong>Теория<\/strong>/);
  assert.match(platform, /<strong>Лайвкодинг<\/strong>/);
  assert.match(platform, /maxCount = mode === "theory" \? 20 : 10/);
  assert.match(platform, /type="number" min="1" max=\{maxCount\}/);
  assert.match(platform, /isLivecoding \? "livecoding-page"/);
  assert.match(platform, /isLivecoding \? "livecoding-runner"/);
  assert.match(platform, /!isLivecoding && <aside/);
  assert.match(platform, /MockInterviewView/);
  assert.match(platform, /loadCatalog/);
  assert.match(platform, /createInterviewSession/);
  assert.match(platform, /function SectionView/);
  assert.match(platform, /saveProgress/);
  assert.match(platform, /resumeTask/);
  assert.doesNotMatch(platform, /ARC и управление памятью/);
  assert.doesNotMatch(platform, /localStorage|PATH_MODULES|MOCK_QUESTIONS|LIVE_CODING_PROMPTS/);
  assert.match(admin, /Структура/);
  assert.match(admin, /Материал в Markdown/);
  assert.match(runner, /proxyLearnyBackend\(request, "\/v1\/submissions"\)/);
  assert.match(proxy, /X-Learny-Signature/);
  assert.match(proxy, /MAX_BODY_SIZE = 64 \* 1024/);
  assert.match(openapi, /\/v1\/admin\/questions:/);
  assert.match(openapi, /\/v1\/admin\/lessons:/);
  assert.match(openapi, /\/v1\/admin\/sections:/);
  assert.match(openapi, /\/v1\/submissions:/);
  assert.match(migration, /CREATE TABLE questions/);
  assert.match(migration, /CREATE TABLE coding_tasks/);
  assert.match(lessonMigration, /INSERT INTO lessons/);
  assert.match(layout, /og\.png/);
  assert.doesNotMatch(packageJson, /react-loading-skeleton/);
  await Promise.all([
    access(new URL("../public/og.png", import.meta.url)),
    access(new URL("../public/favicon.png", import.meta.url)),
    access(new URL("../public/streak-anime-avatar.png", import.meta.url)),
    access(new URL("../public/swift-logo.svg", import.meta.url)),
    access(new URL("../public/go-logo.svg", import.meta.url)),
  ]);
});
