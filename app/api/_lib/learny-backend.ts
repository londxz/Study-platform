import { getChatGPTUser, type ChatGPTUser } from "@/app/chatgpt-auth";

const MAX_BODY_SIZE = 64 * 1024;

type RouteUser = Pick<ChatGPTUser, "userId" | "email">;

export async function proxyLearnyBackend(request: Request, upstreamPath: string): Promise<Response> {
  const baseURL = process.env.LEARNY_API_URL?.replace(/\/$/, "");
  if (!baseURL) return problem(503, "backend_unconfigured", "Backend Learny ещё не настроен");
  if (!upstreamPath.startsWith("/v1/") || upstreamPath.includes("..")) {
    return problem(400, "invalid_path", "Некорректный путь API");
  }

  const body = request.method === "GET" || request.method === "HEAD"
    ? new Uint8Array()
    : new Uint8Array(await request.arrayBuffer());
  if (body.byteLength > MAX_BODY_SIZE) return problem(413, "request_too_large", "Запрос слишком большой");

  const user = await routeUser();
  const headers = new Headers({ Accept: "application/json" });
  const contentType = request.headers.get("content-type");
  if (contentType) headers.set("Content-Type", contentType);

  if (user) {
    const secret = process.env.LEARNY_BFF_SECRET;
    if (!secret) return problem(503, "backend_unconfigured", "Защищённое соединение с backend не настроено");
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const bodyHash = await sha256Hex(body);
    const payload = [timestamp, request.method, upstreamPath, user.userId, user.email.toLowerCase(), bodyHash].join("\n");
    headers.set("X-Learny-User-Id", user.userId);
    headers.set("X-Learny-User-Email", user.email.toLowerCase());
    headers.set("X-Learny-Timestamp", timestamp);
    headers.set("X-Learny-Signature", await hmacHex(secret, payload));
  } else if (request.method !== "GET" && request.method !== "HEAD") {
    return problem(401, "unauthorized", "Войдите, чтобы продолжить");
  }

  try {
    const upstream = await fetch(`${baseURL}${upstreamPath}`, {
      method: request.method,
      headers,
      body: body.byteLength ? body : undefined,
      cache: "no-store",
    });
    const responseHeaders = new Headers({
      "Content-Type": upstream.headers.get("content-type") || "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    });
    const requestID = upstream.headers.get("x-request-id");
    if (requestID) responseHeaders.set("X-Request-Id", requestID);
    return new Response(upstream.body, { status: upstream.status, headers: responseHeaders });
  } catch {
    return problem(502, "backend_unavailable", "Backend Learny временно недоступен");
  }
}

async function routeUser(): Promise<RouteUser | null> {
  const user = await getChatGPTUser();
  if (user) return user;
  const userId = process.env.LEARNY_DEV_USER_ID?.trim();
  const email = process.env.LEARNY_DEV_USER_EMAIL?.trim();
  if (process.env.NODE_ENV !== "production" && userId && email) return { userId, email };
  return null;
}

async function sha256Hex(value: Uint8Array): Promise<string> {
  const bytes = Uint8Array.from(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes.buffer);
  return hex(new Uint8Array(digest));
}

async function hmacHex(secret: string, value: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey("raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(value));
  return hex(new Uint8Array(signature));
}

function hex(value: Uint8Array): string {
  return Array.from(value, (byte) => byte.toString(16).padStart(2, "0")).join("");
}

function problem(status: number, code: string, message: string): Response {
  return Response.json({ error: { code, message } }, { status });
}
