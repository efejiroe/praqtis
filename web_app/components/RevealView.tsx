"use client";
import { useEffect, useRef, useState } from "react";
import { motion, useInView } from "framer-motion";
import { Practice } from "@/lib/types";

interface Props {
  practice: Practice;
}

export default function RevealView({ practice }: Props) {
  const ref = useRef<HTMLElement>(null);
  const inView = useInView(ref, { once: true, margin: "-20% 0px" });
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (!inView) return;
    const target = practice.wasted_capacity_gbp;
    const duration = 2500;
    const start = Date.now();
    const tick = () => {
      const elapsed = Date.now() - start;
      const progress = Math.min(elapsed / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      setCount(Math.round(target * eased));
      if (progress < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }, [inView, practice.wasted_capacity_gbp]);

  return (
    <section
      ref={ref}
      className="min-h-screen flex flex-col items-center justify-center px-6 text-center"
    >
      <motion.p
        className="text-sm tracking-widest uppercase mb-12"
        style={{ color: "#666666" }}
        initial={{ opacity: 0 }}
        animate={inView ? { opacity: 1 } : {}}
        transition={{ duration: 0.6 }}
      >
        {practice.gp_name} &middot; {practice.gp_code}
      </motion.p>

      <motion.p
        className="text-xl max-w-xl mb-6"
        style={{ color: "#666666" }}
        initial={{ opacity: 0, y: 20 }}
        animate={inView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.8, delay: 0.3 }}
      >
        Based on public NHS data, your practice lost an estimated
      </motion.p>

      <motion.div
        className="text-7xl md:text-9xl font-black my-4 tabular-nums"
        style={{ color: "#e8ff00" }}
        initial={{ opacity: 0, scale: 0.8 }}
        animate={inView ? { opacity: 1, scale: 1 } : {}}
        transition={{ duration: 0.6, delay: 0.5 }}
      >
        &pound;{count.toLocaleString("en-GB")}
      </motion.div>

      <motion.p
        className="text-xl max-w-xl mt-6"
        style={{ color: "#666666" }}
        initial={{ opacity: 0 }}
        animate={inView ? { opacity: 1 } : {}}
        transition={{ duration: 0.8, delay: 1.2 }}
      >
        to missed appointments last month.
      </motion.p>

      <motion.div
        className="mt-16 grid grid-cols-3 gap-12 text-center"
        initial={{ opacity: 0, y: 20 }}
        animate={inView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.8, delay: 1.8 }}
      >
        <div>
          <p className="text-3xl font-bold text-white">
            {practice.dna_count.toLocaleString()}
          </p>
          <p
            className="text-xs uppercase tracking-widest mt-2"
            style={{ color: "#666666" }}
          >
            Missed appointments
          </p>
        </div>
        <div>
          <p className="text-3xl font-bold text-white">
            {practice.dna_rate_pct.toFixed(1)}%
          </p>
          <p
            className="text-xs uppercase tracking-widest mt-2"
            style={{ color: "#666666" }}
          >
            DNA rate
          </p>
        </div>
        <div>
          <p className="text-3xl font-bold text-white">
            {practice.list_size.toLocaleString()}
          </p>
          <p
            className="text-xs uppercase tracking-widest mt-2"
            style={{ color: "#666666" }}
          >
            Registered patients
          </p>
        </div>
      </motion.div>

      <motion.div
        className="flex flex-col items-center gap-2 mt-20"
        style={{ color: "#333333" }}
        initial={{ opacity: 0 }}
        animate={inView ? { opacity: 1 } : {}}
        transition={{ duration: 0.8, delay: 2.4 }}
      >
        <motion.div
          animate={{ y: [0, 6, 0] }}
          transition={{ repeat: Infinity, duration: 2, ease: "easeInOut" }}
          className="flex flex-col items-center gap-1"
        >
          <span className="text-xs uppercase tracking-widest">scroll</span>
          <svg width="12" height="8" viewBox="0 0 12 8" fill="none">
            <path d="M1 1L6 7L11 1" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </motion.div>
      </motion.div>
    </section>
  );
}
