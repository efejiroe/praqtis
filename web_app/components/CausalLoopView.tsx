"use client";
import { useState, useRef, useMemo } from "react";
import { motion, useInView } from "framer-motion";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  ResponsiveContainer,
  ReferenceDot,
  Tooltip,
  CartesianGrid,
} from "recharts";
import { Practice } from "@/lib/types";

interface Props {
  practice: Practice;
}

export default function CausalLoopView({ practice }: Props) {
  const ref = useRef<HTMLElement>(null);
  const inView = useInView(ref, { once: true, margin: "-20% 0px" });
  const [extra, setExtra] = useState(0);

  const base = practice.dna_rate_pct;

  const lineData = useMemo(
    () =>
      Array.from({ length: 21 }, (_, i) => ({
        extra: i,
        dna: parseFloat(
          Math.min(base + i * 0.15 + i * i * 0.01, 100).toFixed(2)
        ),
      })),
    [base]
  );

  const currentDna = lineData[extra].dna;
  const yMax = Math.ceil(lineData[20].dna * 1.3);

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
          The Unintended Consequence
        </motion.p>

        <motion.h2
          className="text-3xl md:text-5xl font-black text-white mb-6 leading-tight"
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.2 }}
        >
          The standard fix is to{" "}
          <span style={{ color: "#e8ff00" }}>
            cram more appointments in.
          </span>{" "}
          Let&rsquo;s see what happens.
        </motion.h2>

        <motion.p
          className="text-lg mb-10 max-w-2xl"
          style={{ color: "#666666" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 0.4 }}
        >
          Pull the slider to increase your daily patient load and watch the
          causal loop take effect.
        </motion.p>

        <motion.div
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 0.6 }}
        >
          {/* Slider */}
          <div className="mb-10">
            <div className="flex items-center justify-between mb-3">
              <span className="text-white text-sm font-medium">
                Extra patients per day
              </span>
              <span
                className="text-2xl font-black tabular-nums"
                style={{ color: "#e8ff00" }}
              >
                +{extra}
              </span>
            </div>
            <input
              type="range"
              min={0}
              max={20}
              value={extra}
              onChange={(e) => setExtra(Number(e.target.value))}
              className="w-full cursor-pointer"
              style={{ accentColor: "#e8ff00" }}
            />
            <div className="flex justify-between text-xs mt-2" style={{ color: "#444444" }}>
              <span>No change</span>
              <span>+20 patients / day</span>
            </div>
          </div>

          {/* Impact callout */}
          <div
            className="mb-10 p-5 flex items-center gap-6"
            style={{ border: "1px solid #333333" }}
          >
            <div>
              <p
                className="text-xs uppercase tracking-widest"
                style={{ color: "#666666" }}
              >
                Projected DNA rate
              </p>
              <p
                className="text-4xl font-black tabular-nums mt-1"
                style={{ color: "#e8ff00" }}
              >
                {currentDna.toFixed(1)}%
              </p>
            </div>
            <div
              className="self-stretch w-px"
              style={{ background: "#333333" }}
            />
            <div>
              <p
                className="text-xs uppercase tracking-widest mb-1"
                style={{ color: "#666666" }}
              >
                Why?
              </p>
              <p className="text-white text-sm leading-relaxed">
                Rushed clinicians &rarr; confused patients &rarr; higher
                non-adherence
              </p>
            </div>
          </div>

          {/* Line chart */}
          <div style={{ height: "220px" }}>
            {inView && <ResponsiveContainer width="100%" height="100%">
              <LineChart
                data={lineData}
                margin={{ left: 10, right: 20, top: 8, bottom: 24 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#1a1a1a" />
                <XAxis
                  dataKey="extra"
                  tick={{ fill: "#666666", fontSize: 11 }}
                  label={{
                    value: "Extra patients / day",
                    position: "insideBottom",
                    fill: "#444444",
                    fontSize: 11,
                    dy: 16,
                  }}
                  axisLine={false}
                  tickLine={false}
                />
                <YAxis
                  tick={{ fill: "#666666", fontSize: 11 }}
                  tickFormatter={(v) => `${v}%`}
                  axisLine={false}
                  tickLine={false}
                  domain={[0, yMax]}
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
                />
                <Line
                  type="monotone"
                  dataKey="dna"
                  stroke="#e8ff00"
                  strokeWidth={2}
                  dot={false}
                />
                <ReferenceDot
                  x={extra}
                  y={currentDna}
                  r={6}
                  fill="#e8ff00"
                  stroke="#000000"
                  strokeWidth={2}
                />
              </LineChart>
            </ResponsiveContainer>}
          </div>

          <motion.div
            className="flex flex-col items-center gap-2 mt-12"
            style={{ color: "#333333" }}
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
        </motion.div>
      </div>
    </section>
  );
}
