import CTA from "@/components/CTA";
import Features from "@/components/Features";
import GeofenceDemo from "@/components/GeofenceDemo";
import Hero from "@/components/Hero";
import HowItWorks from "@/components/HowItWorks";
import Nav from "@/components/Nav";
import ScrollProgress from "@/components/ScrollProgress";
import Stats from "@/components/Stats";

export default function Home() {
  return (
    <>
      <ScrollProgress />
      <Nav />
      <main className="flex-1">
        <Hero />
        <HowItWorks />
        <GeofenceDemo />
        <Stats />
        <Features />
        <CTA />
      </main>
    </>
  );
}
