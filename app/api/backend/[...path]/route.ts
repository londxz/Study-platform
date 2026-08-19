import { proxyLearnyBackend } from "@/app/api/_lib/learny-backend";

type Context = { params: Promise<{ path: string[] }> };

async function handle(request: Request, context: Context) {
  const { path } = await context.params;
  const url = new URL(request.url);
  const upstreamPath = `/${path.map(encodeURIComponent).join("/")}${url.search}`;
  return proxyLearnyBackend(request, upstreamPath);
}

export const GET = handle;
export const POST = handle;
export const PUT = handle;
export const PATCH = handle;
export const DELETE = handle;

