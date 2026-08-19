import type { Metadata } from "next";
import { StudyPlatform } from "./StudyPlatform";

export const metadata: Metadata = {
  title: "Learny — личная платформа обучения",
  description: "Практика iOS и Go, подготовка к интервью и понятный прогресс.",
};

export default function Home() {
  return <StudyPlatform />;
}
