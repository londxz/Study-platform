const COMPILERS = {
  swift: { id: 83, label: "Swift 5.2.3" },
  go: { id: 107, label: "Go 1.23.5" },
} as const;

type SupportedLanguage = keyof typeof COMPILERS;

type JudgeResult = {
  stdout?: string | null;
  stderr?: string | null;
  compile_output?: string | null;
  message?: string | null;
  status?: { id: number; description: string };
};

export async function POST(request: Request) {
  let payload: { language?: string; code?: string };

  try {
    payload = await request.json();
  } catch {
    return Response.json({ error: "Некорректный запрос" }, { status: 400 });
  }

  if (!payload.language || !(payload.language in COMPILERS)) {
    return Response.json({ error: "Поддерживаются только Swift и Go" }, { status: 400 });
  }

  const code = payload.code?.trim();
  if (!code) {
    return Response.json({ error: "Добавьте код перед запуском" }, { status: 400 });
  }
  if (code.length > 10_000) {
    return Response.json({ error: "Код не должен превышать 10 КБ" }, { status: 413 });
  }

  const compiler = COMPILERS[payload.language as SupportedLanguage];

  try {
    const upstream = await fetch("https://ce.judge0.com/submissions?base64_encoded=false&wait=true&fields=stdout,stderr,compile_output,message,status", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        language_id: compiler.id,
        source_code: code,
        stdin: "",
        cpu_time_limit: 3,
        wall_time_limit: 5,
        memory_limit: 128000,
      }),
    });

    if (!upstream.ok) {
      return Response.json({ error: "Сервис компиляции временно недоступен" }, { status: 502 });
    }

    const result = await upstream.json() as JudgeResult;
    const stderr = [result.compile_output, result.stderr, result.message]
      .filter(Boolean)
      .join("\n");
    const stdout = result.stdout || "";
    const ok = result.status?.id === 3;

    return Response.json({ ok, stdout, stderr, compiler: compiler.label });
  } catch {
    return Response.json({ error: "Не удалось связаться с компилятором. Попробуйте ещё раз." }, { status: 502 });
  }
}
