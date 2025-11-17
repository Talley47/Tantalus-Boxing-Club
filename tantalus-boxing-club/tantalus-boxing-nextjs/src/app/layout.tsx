import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

export const metadata: Metadata = {
  title: "Tantalus Boxing Club",
  description: "The ultimate virtual boxing league platform",
  keywords: ["boxing", "virtual", "league", "tournament", "fighting"],
  authors: [{ name: "TBC Promotions" }],
  viewport: "width=device-width, initial-scale=1",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="font-sans antialiased bg-gray-50">
        {children}
      </body>
    </html>
  );
}
