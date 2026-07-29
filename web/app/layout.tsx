import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Dozent — The city, narrated",
  description:
    "GPS-anchored audio tours that start themselves as you walk. 871 tours across 16 cities, narrated by people who know them.",
  openGraph: {
    title: "Dozent — The city, narrated",
    description:
      "GPS-anchored audio tours that start themselves as you walk. 871 tours across 16 cities.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased">
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
