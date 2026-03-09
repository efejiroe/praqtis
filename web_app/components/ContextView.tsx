"use client";
import { useRef } from "react";
import { motion, useInView } from "framer-motion";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Cell,
  ResponsiveContainer,
  Tooltip,
} from "recharts";
import { Practice, Archetype } from "@/lib/types";

interface Props {
  practice: Practice;
  archetypes: Record<string, Archetype>;
}

export default function ContextView({ practice, archetypes }: Props) {
  const ref = useRef<HTMLElement>(null);
  const inView = useInView(ref, { once: true, margin: "-20% 0px" });

  const archetype = archetypes[String(practice.archetype)];
  const gapIsPositive = practice.benchmark_gap_pct > 0;

  const chartData = [
    {
      name: "Top 10% peers",
      value: archetype.top10_dna_rate_pct,
      color: "#e8ff00",
    },
    {
      name: "Archetype average",
      value: archetype.avg_dna_rate_pct,
      color: "#444444",
    },
    {
      name: "Your practice",
      value: practice.dna_rate_pct,
      color: "#ffffff",
    },
  ];

  const domainMax = Math.ceil(
    Math.max(...chartData.map((d) => d.value)) * 1.4
  );

  return (
    <section
      ref={ref}
      className="min-h-screen flex flex-col items-center justify-center px-6"
    >
      <div className="w-full max-w-3xl">
        <motion.p
          className="text-sm tracking-widest uppercase mb-4"
          style={{ color: "#666666" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.6 }}
        >
          Benchmark Context &middot; {archetype.label}
        </motion.p>

        <motion.h2
          className="text-3xl md:text-5xl font-black text-white mb-6 leading-tight"
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.2 }}
        >
          A DNA rate of{" "}
          <span style={{ color: "#e8ff00" }}>
            {practice.dna_rate_pct.toFixed(1)}%
          </span>{" "}
          looks bad. But context matters.
        </motion.h2>

        <motion.p
          className="text-lg mb-12 max-w-2xl"
          style={{ color: "#666666" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 0.4 }}
        >
          We compared you only against {archetype.label.toLowerCase()}s with
          similar patient demographics &mdash; {archetype.count.toLocaleString()}{" "}
          practices in your archetype. Compared to the top 10% of your exact
          peers, you are{" "}
          {gapIsPositive ? (
            <span className="text-white font-semibold">
              underperforming by {practice.benchmark_gap_pct.toFixed(2)}{" "}
              percentage points.
            </span>
          ) : (
            <span style={{ color: "#e8ff00" }} className="font-semibold">
              outperforming the top 10% benchmark.
            </span>
          )}
        </motion.p>

        <motion.div
          style={{ height: "200px" }}
          initial={{ opacity: 0, x: -40 }}
          animate={inView ? { opacity: 1, x: 0 } : {}}
          transition={{ duration: 0.9, delay: 0.7 }}
        >
          {inView && <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={chartData}
              layout="vertical"
              margin={{ left: 0, right: 60, top: 8, bottom: 8 }}
            >
              <XAxis
                type="number"
                domain={[0, domainMax]}
                tick={{ fill: "#666666", fontSize: 11 }}
                tickFormatter={(v) => `${v}%`}
                axisLine={false}
                tickLine={false}
              />
              <YAxis
                type="category"
                dataKey="name"
                tick={{ fill: "#666666", fontSize: 12 }}
                axisLine={false}
                tickLine={false}
                width={130}
              />
              <Tooltip
                formatter={(v) =>
                  typeof v === "number"
                    ? [`${v.toFixed(2)}%`, "DNA rate"]
                    : [String(v), "DNA rate"]
                }
                contentStyle={{
                  background: "#111",
                  border: "1px solid #333",
                  color: "#fff",
                  fontSize: 12,
                }}
                cursor={{ fill: "rgba(255,255,255,0.03)" }}
              />
              <Bar dataKey="value" radius={[0, 2, 2, 0]}>
                {chartData.map((entry, i) => (
                  <Cell key={i} fill={entry.color} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>}
        </motion.div>

        <motion.div
          className="mt-8 grid grid-cols-3 gap-6 pt-8"
          style={{ borderTop: "1px solid #1a1a1a" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 1.2 }}
        >
          <div>
            <p
              className="text-2xl font-bold"
              style={{ color: "#e8ff00" }}
            >
              {archetype.top10_dna_rate_pct.toFixed(1)}%
            </p>
            <p
              className="text-xs uppercase tracking-widest mt-1"
              style={{ color: "#666666" }}
            >
              Top 10% threshold
            </p>
          </div>
          <div>
            <p className="text-2xl font-bold" style={{ color: "#666666" }}>
              {archetype.avg_dna_rate_pct.toFixed(1)}%
            </p>
            <p
              className="text-xs uppercase tracking-widest mt-1"
              style={{ color: "#666666" }}
            >
              Archetype average
            </p>
          </div>
          <div>
            <p className="text-2xl font-bold text-white">
              {practice.dna_rate_pct.toFixed(1)}%
            </p>
            <p
              className="text-xs uppercase tracking-widest mt-1"
              style={{ color: "#666666" }}
            >
              Your practice
            </p>
          </div>
        </motion.div>

        <motion.div
          className="flex flex-col items-center gap-2 mt-16"
          style={{ color: "#333333" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 1.8 }}
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
      </div>
    </section>
  );
}
