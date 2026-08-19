import { proxyLearnyBackend } from "@/app/api/_lib/learny-backend";

export async function POST(request: Request) {
  return proxyLearnyBackend(request, "/v1/submissions");
}
