import Image from "next/image";
import type { ReactNode } from "react";

/** iPhone-style bezel around a screenshot (or any content). */
export default function PhoneFrame({
  src,
  alt,
  children,
  className = "",
  priority = false,
  sizes = "(min-width: 768px) 300px, 260px",
}: {
  src?: string;
  alt?: string;
  children?: ReactNode;
  className?: string;
  priority?: boolean;
  sizes?: string;
}) {
  return (
    <div
      className={`relative aspect-[840/1826] w-full overflow-hidden rounded-[12%/5.5%] border border-line bg-black shadow-[0_24px_80px_-20px_rgba(0,0,0,0.9),0_0_0_10px_#1a1a1c,0_0_0_11px_rgba(244,242,236,0.12)] ${className}`}
    >
      {src && (
        <Image
          src={src}
          alt={alt ?? ""}
          fill
          sizes={sizes}
          priority={priority}
          className="object-cover"
          draggable={false}
        />
      )}
      {children}
      {/* Dynamic-island hint */}
      <div className="absolute left-1/2 top-[1.6%] h-[2.9%] w-[31%] -translate-x-1/2 rounded-full bg-black" />
    </div>
  );
}
