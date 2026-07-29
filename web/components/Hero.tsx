"use client";

import { motion, useReducedMotion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";
import PhoneFrame from "./PhoneFrame";
import Waveform from "./Waveform";

const HEADLINE = ["The", "city,", "narrated."];

export default function Hero() {
  const reduced = useReducedMotion();
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end start"] });
  const phoneY = useTransform(scrollYProgress, [0, 1], [0, reduced ? 0 : 90]);
  const fade = useTransform(scrollYProgress, [0, 0.7], [1, 0]);

  return (
    <section ref={ref} id="top" className="relative overflow-hidden">
      {/* Ambient brass glow */}
      <div
        aria-hidden
        className="pointer-events-none absolute -top-40 left-1/2 h-[560px] w-[900px] -translate-x-1/2 rounded-full opacity-25 blur-3xl"
        style={{ background: "radial-gradient(closest-side, #8b7535, transparent 70%)" }}
      />

      <div className="mx-auto grid max-w-6xl items-center gap-16 px-6 pb-24 pt-36 md:grid-cols-[1.1fr_0.9fr] md:pb-32 md:pt-44">
        <motion.div style={{ opacity: fade }}>
          <motion.p
            className="caption mb-6 text-gold"
            initial={reduced ? false : { opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.8, delay: 0.1 }}
          >
            GPS-anchored audio tours
          </motion.p>

          <h1 className="text-6xl font-semibold leading-[1.02] tracking-tight sm:text-7xl md:text-8xl">
            {HEADLINE.map((word, i) => (
              <span key={word} className="inline-block overflow-hidden pb-1 align-top">
                <motion.span
                  className={`inline-block ${i === 2 ? "text-gold" : ""}`}
                  initial={reduced ? false : { y: "110%" }}
                  animate={{ y: 0 }}
                  transition={{ duration: 0.9, delay: 0.15 + i * 0.12, ease: [0.22, 1, 0.36, 1] }}
                >
                  {word}
                </motion.span>
                {i < HEADLINE.length - 1 && <span>&nbsp;</span>}
              </span>
            ))}
          </h1>

          <motion.p
            className="mt-8 max-w-md text-lg leading-relaxed text-muted"
            initial={reduced ? false : { opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.65 }}
          >
            Walk up to a place and its story starts itself. No screens, no
            searching — just the street in front of you, narrated by someone who
            knows it.
          </motion.p>

          <motion.div
            className="mt-10 flex flex-wrap items-center gap-5"
            initial={reduced ? false : { opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.8 }}
          >
            {/* TODO(owner): point at the public TestFlight / App Store link at launch */}
            <a
              href="#get"
              className="caption rounded-full bg-brass px-7 py-4 text-bg transition-transform hover:scale-[1.04] active:scale-[0.98]"
            >
              Join the beta
            </a>
            <div className="flex items-center gap-3">
              <Waveform bars={16} className="h-6" />
              <span className="caption text-muted">Now playing · 16 cities</span>
            </div>
          </motion.div>
        </motion.div>

        <motion.div
          style={{ y: phoneY }}
          className="relative mx-auto w-[260px] sm:w-[300px]"
          initial={reduced ? false : { opacity: 0, y: 60 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1, delay: 0.4, ease: [0.22, 1, 0.36, 1] }}
        >
          <PhoneFrame src="/screens/home.webp" alt="Dozent home map with gold tour pins over Manhattan" priority />
        </motion.div>
      </div>
    </section>
  );
}
