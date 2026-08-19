import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { headers } from "next/headers";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export async function generateMetadata(): Promise<Metadata> {
  const requestHeaders = await headers();
  const host = requestHeaders.get("x-forwarded-host") || requestHeaders.get("host") || "localhost:3000";
  const safeHost = /^[a-z0-9.:[\]-]+$/i.test(host) ? host : "localhost:3000";
  const protocol = requestHeaders.get("x-forwarded-proto") || (safeHost.includes("localhost") ? "http" : "https");
  const origin = `${protocol}://${safeHost}`;
  const title = "Learny — личная платформа обучения";
  const description = "Практика iOS и Go, подготовка к интервью и понятный прогресс.";

  return {
    metadataBase: new URL(origin),
    title,
    description,
    icons: { icon: "/favicon.png", shortcut: "/favicon.png" },
    openGraph: {
      type: "website",
      url: origin,
      siteName: "Learny",
      title,
      description,
      images: [{ url: `${origin}/og.png`, width: 1200, height: 630, alt: "Learny — практика iOS и Go" }],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [`${origin}/og.png`],
    },
  };
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ru">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
