"use client";

import { motion, useMotionValueEvent, useReducedMotion, useScroll } from "motion/react";
import Image from "next/image";
import { useRef, useState } from "react";
import PhoneFrame from "./PhoneFrame";

const STEPS = [
  {
    n: "01",
    title: "Browse the map",
    body: "Every gold pin is a tour. Filter by walks, landmarks, or hidden gems — or just see what's near you.",
    screen: "/screens/rails.webp",
    alt: "Tour shelves in the Dozent drawer",
  },
  {
    n: "02",
    title: "Pick a story",
    body: "Two-minute stories at single stops, or hour-long walks with a narrator in your ear the whole way.",
    screen: "/screens/detail.webp",
    alt: "Empire State Building tour detail",
  },
  {
    n: "03",
    title: "Walk. It plays itself.",
    body: "Cross the 30-meter ring around a stop and the audio starts on its own. Phone in pocket, eyes on the city.",
    screen: "/screens/player.webp",
    alt: "Dozent full-screen player",
  },
];

export default function HowItWorks() {
  const ref = useRef<HTMLDivElement>(null);
  const reduced = useReducedMotion();
  const [active, setActive] = useState(0);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end end"] });

  useMotionValueEvent(scrollYProgress, "change", (v) => {
    setActive(Math.min(STEPS.length - 1, Math.floor(v * STEPS.length)));
  });

  return (
    <section id="how" ref={ref} className="relative" style={{ height: `${STEPS.length * 100}vh` }}>
      <div className="sticky top-0 flex h-screen items-center overflow-hidden">
        <div className="mx-auto grid w-full max-w-6xl items-center gap-12 px-6 md:grid-cols-2">
          <div>
            <p className="caption mb-10 text-gold">How it works</p>
            <div className="space-y-10">
              {STEPS.map((step, i) => (
                <div key={step.n} className="flex gap-6">
                  <span
                    className={`caption pt-1 transition-colors duration-500 ${
                      i === active ? "text-gold" : "text-muted/40"
                    }`}
                  >
                    {step.n}
                  </span>
                  <div
                    className={`transition-all duration-500 ${
                      i === active ? "opacity-100" : "opacity-30"
                    }`}
                  >
                    <h3 className="text-2xl font-medium tracking-tight sm:text-3xl">{step.title}</h3>
                    <p
                      className={`mt-2 max-w-sm leading-relaxed text-muted transition-all duration-500 ${
                        i === active ? "max-h-32" : "max-h-0 overflow-hidden opacity-0"
                      }`}
                    >
                      {step.body}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="relative mx-auto hidden w-[270px] md:block">
            <PhoneFrame>
              {STEPS.map((step, i) => (
                <motion.div
                  key={step.screen}
                  className="absolute inset-0"
                  initial={false}
                  animate={{ opacity: i === active ? 1 : 0, scale: i === active || reduced ? 1 : 1.04 }}
                  transition={{ duration: 0.5, ease: "easeOut" }}
                >
                  <Image
                    src={step.screen}
                    alt={step.alt}
                    fill
                    sizes="270px"
                    className="object-cover"
                    draggable={false}
                  />
                </motion.div>
              ))}
            </PhoneFrame>
          </div>
        </div>
      </div>
    </section>
  );
}
