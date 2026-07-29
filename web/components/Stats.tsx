"use client";

import { animate, useInView, useReducedMotion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import Reveal from "./Reveal";

const STATS = [
  { value: 871, label: "Tours", note: "and counting" },
  { value: 16, label: "City bureaus", note: "3 continents" },
  { value: 1076, label: "Stops", note: "each geofenced" },
  { value: 35, label: "Walking routes", note: "multi-stop" },
];

// City bureaus, in catalog order of size.
const CITIES = [
  "London",
  "New York",
  "Tokyo",
  "Kyoto",
  "Lisbon",
  "Hong Kong",
  "Paris",
  "Bangkok",
  "Ho Chi Minh City",
  "Toronto",
  "Los Angeles",
  "Porto",
  "Amsterdam",
  "Seoul",
  "San Francisco",
  "Naoshima",
];

function Counter({ to }: { to: number }) {
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: "-60px" });
  const reduced = useReducedMotion();
  const [n, setN] = useState(0);

  useEffect(() => {
    if (!inView || reduced) return;
    const controls = animate(0, to, {
      duration: 1.6,
      ease: [0.16, 1, 0.3, 1],
      onUpdate: (v) => setN(Math.round(v)),
    });
    return () => controls.stop();
  }, [inView, to, reduced]);

  // Reduced motion skips the count-up and shows the final figure.
  const shown = reduced ? to : n;

  return (
    <span ref={ref} className="tabular-nums">
      {shown.toLocaleString()}
    </span>
  );
}

export default function Stats() {
  return (
    <section id="cities" className="border-y border-line bg-surface/40">
      <div className="mx-auto max-w-6xl px-6 py-24">
        <Reveal>
          <p className="caption mb-12 text-gold">The catalog</p>
        </Reveal>

        <div className="grid grid-cols-2 gap-10 md:grid-cols-4">
          {STATS.map((s, i) => (
            <Reveal key={s.label} delay={i * 0.08}>
              <p className="text-5xl font-semibold tracking-tight sm:text-6xl">
                <Counter to={s.value} />
              </p>
              <p className="caption mt-3 text-fg">{s.label}</p>
              <p className="caption mt-1 text-[0.62rem] text-muted">{s.note}</p>
            </Reveal>
          ))}
        </div>
      </div>

      {/* City marquee */}
      <div className="marquee relative overflow-hidden border-t border-line py-6">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-y-0 left-0 z-10 w-24 bg-gradient-to-r from-bg to-transparent"
        />
        <div
          aria-hidden
          className="pointer-events-none absolute inset-y-0 right-0 z-10 w-24 bg-gradient-to-l from-bg to-transparent"
        />
        <div className="marquee-track flex w-max gap-10">
          {[...CITIES, ...CITIES].map((city, i) => (
            <span key={`${city}-${i}`} className="caption flex items-center gap-10 text-muted">
              {city}
              <span className="h-1 w-1 rounded-full bg-brass" />
            </span>
          ))}
        </div>
      </div>
    </section>
  );
}
