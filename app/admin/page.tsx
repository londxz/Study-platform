import type { Metadata } from "next";
import { requireChatGPTUser } from "@/app/chatgpt-auth";
import { AdminPanel } from "./AdminPanel";

export const metadata: Metadata = {
  title: "Управление контентом — Learny",
  description: "Закрытая панель управления учебными материалами Learny.",
};

export const dynamic = "force-dynamic";

export default async function AdminPage() {
  if (process.env.NODE_ENV === "production") await requireChatGPTUser("/admin");
  return <AdminPanel />;
}
