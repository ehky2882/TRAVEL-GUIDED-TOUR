/** Animated audio waveform. Deterministic per-bar timing (no Math.random —
 *  keeps server and client renders identical). */
export default function Waveform({
  bars = 28,
  className = "",
  active = true,
}: {
  bars?: number;
  className?: string;
  active?: boolean;
}) {
  return (
    <div className={`flex items-center gap-[3px] ${className}`} aria-hidden>
      {Array.from({ length: bars }, (_, i) => {
        const seed = Math.abs(Math.sin(i * 12.9898) * 43758.5453) % 1;
        const height = 22 + Math.round(seed * 78);
        return (
          <span
            key={i}
            className={`w-[3px] rounded-full bg-gold ${active ? "wave-bar" : ""}`}
            style={{
              height: `${height}%`,
              animationDelay: `${(seed * 1.1).toFixed(2)}s`,
              animationDuration: `${(0.8 + seed * 0.9).toFixed(2)}s`,
              opacity: active ? undefined : 0.35,
            }}
          />
        );
      })}
    </div>
  );
}
