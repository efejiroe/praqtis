"use client";
import { useState, useEffect, useRef } from "react";
import { motion, useScroll, useSpring } from "framer-motion";
import { Practice, PracticeData } from "@/lib/types";
import HookView from "@/components/HookView";
import RevealView from "@/components/RevealView";
import ContextView from "@/components/ContextView";
import CausalLoopView from "@/components/CausalLoopView";
import FixView from "@/components/FixView";

export default function Home() {
  const [data, setData] = useState<PracticeData | null>(null);
  const [selected, setSelected] = useState<Practice | null>(null);
  const revealRef = useRef<HTMLDivElement>(null);

  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, { stiffness: 120, damping: 30 });

  useEffect(() => {
    fetch("/data/practice_data.json")
      .then((r) => r.json())
      .then((d: PracticeData) => setData(d));
  }, []);

  const handleSelect = (practice: Practice) => {
    setSelected(practice);
    setTimeout(() => {
      revealRef.current?.scrollIntoView({ behavior: "smooth" });
    }, 150);
  };

  return (
    <>
      {selected && (
        <motion.div
          className="fixed top-0 left-0 right-0 z-50 origin-left"
          style={{ height: "2px", background: "#e8ff00", scaleX }}
        />
      )}
      <main className="bg-black overflow-x-hidden">
        <HookView data={data} onSelect={handleSelect} />

        {selected && data && (
          <>
            <div ref={revealRef}>
              <RevealView practice={selected} />
            </div>
            <ContextView practice={selected} archetypes={data.archetypes} />
            <CausalLoopView practice={selected} />
            <FixView practice={selected} />
          </>
        )}
      </main>
    </>
  );
}
