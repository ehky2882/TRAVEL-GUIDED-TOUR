import Reveal from "./Reveal";
import Waveform from "./Waveform";

export default function CTA() {
  return (
    <section id="get" className="relative overflow-hidden border-t border-line">
      <div
        aria-hidden
        className="pointer-events-none absolute -bottom-56 left-1/2 h-[520px] w-[820px] -translate-x-1/2 rounded-full opacity-25 blur-3xl"
        style={{ background: "radial-gradient(closest-side, #8b7535, transparent 70%)" }}
      />

      <div className="relative mx-auto max-w-3xl px-6 py-32 text-center md:py-40">
        <Reveal>
          <Waveform bars={22} className="mx-auto mb-10 h-8" />
          <h2 className="text-5xl font-semibold leading-[1.05] tracking-tight sm:text-6xl">
            Put your phone away.
            <br />
            <span className="text-gold">Keep the story.</span>
          </h2>
          <p className="mx-auto mt-7 max-w-md leading-relaxed text-muted">
            Dozent is in beta on iPhone. Join and walk 871 tours across sixteen
            cities.
          </p>
          {/* TODO(owner): swap in the public TestFlight / App Store URL at launch */}
          <a
            href="mailto:edward.yung@gmail.com?subject=Dozent%20beta"
            className="caption mt-11 inline-block rounded-full bg-brass px-9 py-4 text-bg transition-transform hover:scale-[1.04] active:scale-[0.98]"
          >
            Request a beta invite
          </a>
          <p className="caption mt-6 text-[0.62rem] text-muted">
            iPhone · iOS 26 · TestFlight
          </p>
        </Reveal>
      </div>

      <footer className="relative border-t border-line">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 py-8 sm:flex-row">
          <span className="caption text-muted">Dozent</span>
          <span className="caption text-[0.62rem] text-muted/70">
            GPS-anchored audio tours · Made for walking
          </span>
        </div>
      </footer>
    </section>
  );
}
