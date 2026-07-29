"use client";

import { motion, useReducedMotion } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import Waveform from "./Waveform";

/** The signature moment, made tangible: drag yourself toward the pin. Cross the
 *  30 m ring and the tour starts itself — exactly what the app does on a street. */

const STOP = { x: 0.62, y: 0.42 }; // pin position, fraction of the canvas
const TRIGGER_RADIUS = 0.14; // fraction of canvas width — the "30 m" ring
const START = { x: 0.16, y: 0.78 };

export default function GeofenceDemo() {
  const reduced = useReducedMotion();
  const canvasRef = useRef<HTMLDivElement>(null);
  const [pos, setPos] = useState(START);
  const [dragging, setDragging] = useState(false);
  const [hasMoved, setHasMoved] = useState(false);

  const dist = Math.hypot(pos.x - STOP.x, pos.y - STOP.y);
  const inside = dist <= TRIGGER_RADIUS;
  // Map canvas distance to a plausible street distance, so the readout feels real.
  const meters = Math.max(0, Math.round((dist / TRIGGER_RADIUS) * 30));

  const moveTo = useCallback((clientX: number, clientY: number) => {
    const el = canvasRef.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    setPos({
      x: Math.min(1, Math.max(0, (clientX - r.left) / r.width)),
      y: Math.min(1, Math.max(0, (clientY - r.top) / r.height)),
    });
    setHasMoved(true);
  }, []);

  useEffect(() => {
    if (!dragging) return;
    const onMove = (e: PointerEvent) => {
      e.preventDefault();
      moveTo(e.clientX, e.clientY);
    };
    const onUp = () => setDragging(false);
    window.addEventListener("pointermove", onMove, { passive: false });
    window.addEventListener("pointerup", onUp);
    window.addEventListener("pointercancel", onUp);
    return () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
      window.removeEventListener("pointercancel", onUp);
    };
  }, [dragging, moveTo]);

  // Keyboard access — arrows walk the marker.
  const onKeyDown = (e: React.KeyboardEvent) => {
    const step = 0.05;
    const map: Record<string, [number, number]> = {
      ArrowUp: [0, -step],
      ArrowDown: [0, step],
      ArrowLeft: [-step, 0],
      ArrowRight: [step, 0],
    };
    const d = map[e.key];
    if (!d) return;
    e.preventDefault();
    setPos((p) => ({
      x: Math.min(1, Math.max(0, p.x + d[0])),
      y: Math.min(1, Math.max(0, p.y + d[1])),
    }));
    setHasMoved(true);
  };

  return (
    <section className="mx-auto max-w-6xl px-6 py-28 md:py-36">
      <div className="grid items-center gap-14 md:grid-cols-[0.85fr_1.15fr]">
        <div>
          <p className="caption mb-6 text-gold">The signature moment</p>
          <h2 className="text-4xl font-semibold leading-[1.1] tracking-tight sm:text-5xl">
            It knows when
            <br />
            you&apos;ve arrived.
          </h2>
          <p className="mt-6 max-w-sm leading-relaxed text-muted">
            Every stop carries a 30-meter geofence. Step inside it and the story
            begins — no tapping, no reading. Drag the dot and feel it happen.
          </p>

          <div className="mt-8 flex items-center gap-4">
            <span
              className={`caption rounded-full border px-3 py-1.5 transition-colors duration-300 ${
                inside ? "border-brass bg-brass text-bg" : "border-line text-muted"
              }`}
            >
              {inside ? "Inside · playing" : `${meters} m away`}
            </span>
            {!hasMoved && (
              <span className="caption text-muted/60">← drag the dot</span>
            )}
          </div>
        </div>

        {/* Canvas */}
        <div
          ref={canvasRef}
          className="relative aspect-[4/3] w-full touch-none select-none overflow-hidden rounded-2xl border border-line bg-surface"
          onPointerDown={(e) => {
            setDragging(true);
            moveTo(e.clientX, e.clientY);
          }}
        >
          {/* Street grid */}
          <svg aria-hidden className="absolute inset-0 h-full w-full">
            <defs>
              <pattern id="streets" width="56" height="56" patternUnits="userSpaceOnUse">
                <path d="M56 0H0v56" fill="none" stroke="rgba(244,242,236,0.055)" strokeWidth="1" />
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#streets)" />
            <path
              d="M-40 78% L120% 22%"
              fill="none"
              stroke="rgba(244,242,236,0.05)"
              strokeWidth="10"
            />
          </svg>

          {/* Geofence ring */}
          <div
            className="absolute -translate-x-1/2 -translate-y-1/2"
            style={{
              left: `${STOP.x * 100}%`,
              top: `${STOP.y * 100}%`,
              width: `${TRIGGER_RADIUS * 200}%`,
              aspectRatio: "1",
            }}
          >
            <motion.div
              className="h-full w-full rounded-full border border-dashed"
              animate={{
                borderColor: inside ? "rgba(196,162,101,0.85)" : "rgba(196,162,101,0.3)",
                backgroundColor: inside ? "rgba(139,117,53,0.16)" : "rgba(139,117,53,0.05)",
                scale: inside && !reduced ? 1.04 : 1,
              }}
              transition={{ duration: 0.35, ease: "easeOut" }}
            />
            {!inside && <span className="pulse-ring absolute inset-0 rounded-full bg-brass/25" />}
          </div>

          {/* Stop pin */}
          <div
            className="absolute flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-2"
            style={{ left: `${STOP.x * 100}%`, top: `${STOP.y * 100}%` }}
          >
            <span className="h-4 w-4 rounded-full border-2 border-bg bg-gold shadow-[0_0_0_1px_rgba(196,162,101,0.6)]" />
            <span className="caption whitespace-nowrap text-[0.6rem] text-muted">
              Flatiron Building
            </span>
          </div>

          {/* You */}
          <button
            type="button"
            aria-label="Your position — drag or use arrow keys to walk toward the stop"
            onKeyDown={onKeyDown}
            className="absolute z-10 -translate-x-1/2 -translate-y-1/2 cursor-grab rounded-full outline-none focus-visible:ring-2 focus-visible:ring-gold active:cursor-grabbing"
            style={{
              left: `${pos.x * 100}%`,
              top: `${pos.y * 100}%`,
              transition: dragging ? "none" : "left 0.35s ease-out, top 0.35s ease-out",
            }}
          >
            <span className="relative flex h-5 w-5 items-center justify-center">
              <span className="absolute h-9 w-9 rounded-full bg-[#0a84ff]/20" />
              <span className="h-4 w-4 rounded-full border-2 border-white bg-[#0a84ff]" />
            </span>
          </button>

          {/* Now-playing card, revealed on entry */}
          <motion.div
            className="absolute inset-x-3 bottom-3 z-20 flex items-center gap-3 rounded-xl border border-line bg-bg/92 p-3 backdrop-blur-md"
            initial={false}
            animate={{
              opacity: inside ? 1 : 0,
              y: inside ? 0 : 14,
              pointerEvents: inside ? "auto" : "none",
            }}
            transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
          >
            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-brass text-bg">
              ▶
            </span>
            <span className="min-w-0 flex-1">
              <span className="caption block truncate text-fg">Flatiron Building</span>
              <span className="caption block text-[0.6rem] text-muted">
                Atlas Studio NYC · auto-started
              </span>
            </span>
            <Waveform bars={12} className="h-5 w-16 shrink-0" active={inside} />
          </motion.div>
        </div>
      </div>
    </section>
  );
}
