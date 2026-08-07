"use client";

import { motion, useScroll, useTransform } from "motion/react";

export default function Nav() {
  const { scrollY } = useScroll();
  const bg = useTransform(scrollY, [0, 120], ["rgba(10,10,11,0)", "rgba(10,10,11,0.82)"]);
  const border = useTransform(scrollY, [0, 120], ["rgba(244,242,236,0)", "rgba(244,242,236,0.09)"]);

  return (
    <motion.header
      style={{ backgroundColor: bg, borderColor: border }}
      className="fixed inset-x-0 top-0 z-50 border-b backdrop-blur-md"
    >
      <nav className="mx-auto flex h-16 max-w-6xl items-center justify-between px-6">
        <a href="#top" className="flex items-center gap-2.5">
          <span className="relative flex h-2.5 w-2.5">
            <span className="pulse-ring absolute inset-0 rounded-full bg-gold" />
            <span className="relative h-2.5 w-2.5 rounded-full bg-gold" />
          </span>
          <span className="caption text-fg">Dozent</span>
        </a>
        <div className="hidden items-center gap-8 sm:flex">
          <a href="#how" className="caption text-muted transition-colors hover:text-fg">
            How it works
          </a>
          <a href="#cities" className="caption text-muted transition-colors hover:text-fg">
            Cities
          </a>
          <a href="#features" className="caption text-muted transition-colors hover:text-fg">
            Features
          </a>
        </div>
        <a
          href="#get"
          className="caption rounded-full border border-brass px-4 py-2 text-gold transition-colors hover:bg-brass hover:text-bg"
        >
          Get the app
        </a>
      </nav>
    </motion.header>
  );
}
