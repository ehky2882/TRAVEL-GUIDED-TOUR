"use client";

import { motion, useReducedMotion } from "motion/react";
import Reveal from "./Reveal";
import Waveform from "./Waveform";

const FEATURES = [
  {
    title: "Works offline",
    body: "Download a tour before you fly. No signal, no roaming, no problem — the audio and the geofences live on your phone.",
    span: "md:col-span-2",
  },
  {
    title: "Listen together",
    body: "One person leads, everyone nearby hears the same words at the same moment. Over Bluetooth, so it works underground.",
  },
  {
    title: "Journeys",
    body: "String tours into your own ordered route and share it.",
  },
  {
    title: "Bilingual",
    body: "Titles in the local script across Tokyo, Kyoto, Seoul, Bangkok, Hong Kong and Ho Chi Minh City.",
  },
  {
    title: "Made by locals",
    body: "Sixteen city bureaus. Real narrators who live where they're pointing.",
    span: "md:col-span-2",
  },
];

export default function Features() {
  const reduced = useReducedMotion();

  return (
    <section id="features" className="mx-auto max-w-6xl px-6 py-28 md:py-36">
      <Reveal>
        <p className="caption mb-4 text-gold">Built for walking</p>
        <h2 className="mb-14 max-w-xl text-4xl font-semibold leading-[1.1] tracking-tight sm:text-5xl">
          Everything else gets out of the way.
        </h2>
      </Reveal>

      <div className="grid gap-4 md:grid-cols-3">
        {FEATURES.map((f, i) => (
          <Reveal key={f.title} delay={i * 0.06} className={f.span}>
            <motion.div
              whileHover={reduced ? undefined : { y: -4 }}
              transition={{ duration: 0.3, ease: "easeOut" }}
              className="group relative h-full overflow-hidden rounded-2xl border border-line bg-surface/60 p-7 transition-colors hover:border-brass/50"
            >
              <div
                aria-hidden
                className="pointer-events-none absolute -right-12 -top-12 h-40 w-40 rounded-full bg-brass/0 blur-2xl transition-all duration-500 group-hover:bg-brass/20"
              />
              <h3 className="relative text-xl font-medium tracking-tight">{f.title}</h3>
              <p className="relative mt-3 max-w-md leading-relaxed text-muted">{f.body}</p>
              {i === 0 && (
                <Waveform bars={34} className="relative mt-7 h-8 opacity-70" />
              )}
            </motion.div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
