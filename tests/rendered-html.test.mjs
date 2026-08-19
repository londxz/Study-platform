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
  assert.match(html, /Последняя задача/);
  assert.match(html, /iOS Development/);
  assert.match(html, /Go Development/);
  assert.doesNotMatch(html, /codex-preview|react-loading-skeleton/i);
});

test("ships learning paths, code runner limits and project metadata", async () => {
  const [runner, layout, packageJson, platform] = await Promise.all([
    readFile(new URL("../app/api/run/route.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(new URL("../package.json", import.meta.url), "utf8"),
    readFile(new URL("../app/StudyPlatform.tsx", import.meta.url), "utf8"),
  ]);

  assert.match(platform, /Изучение iOS/);
  assert.match(platform, /Подготовка к собеседованиям iOS/);
  assert.match(platform, /Изучение Go/);
  assert.match(platform, /Подготовка к собеседованиям Go/);
  assert.match(platform, /МОК-ИНТЕРВЬЮ/);
  assert.match(platform, /<strong>Теория<\/strong>/);
  assert.match(platform, /<strong>Лайвкодинг<\/strong>/);
  assert.match(platform, /maxCount = mode === "theory" \? 20 : 10/);
  assert.match(platform, /type="number" min="1" max=\{maxCount\}/);
  assert.ok(platform.indexOf("Подготовка к собеседованиям iOS") < platform.indexOf("Изучение iOS"));
  assert.ok(platform.indexOf("Подготовка к собеседованиям Go") < platform.indexOf("Изучение Go"));
  assert.match(platform, /MockInterviewView/);
  assert.match(platform, /PATH_MODULES\[track\]\[selectedPath\]/);
  assert.match(runner, /id: 83/);
  assert.match(runner, /id: 107/);
  assert.match(runner, /code\.length > 10_000/);
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
