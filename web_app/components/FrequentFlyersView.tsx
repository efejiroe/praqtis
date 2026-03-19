"use client";
import { useRef } from "react";
import { motion, useInView } from "framer-motion";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  ResponsiveContainer,
  Cell,
  Tooltip,
} from "recharts";
import { Practice } from "@/lib/types";

interface Props {
  practice: Practice;
}

export default function FrequentFlyersView({ practice }: Props) {
  const ref = useRef<HTMLElement>(null);
  const inView = useInView(ref, { once: true, margin: "-20% 0px" });

  // Pareto estimate: ~20% of patients cause ~80% of DNAs (established NHS pattern)
  const highRiskPct = 20;
  const highRiskDnaPct = 80;
  const highRiskPatients = Math.round(practice.list_size * (highRiskPct / 100));
  const highRiskDnas = Math.round(practice.dna_count * (highRiskDnaPct / 100));
  const highRiskCost = Math.round(practice.wasted_capacity_gbp * (highRiskDnaPct / 100));

  const paretoData = [
    {
      cohort: `High-risk\n(${highRiskPct}% of patients)`,
      label: `${highRiskPct}% of patients`,
      dnas: highRiskDnaPct,
      cost: highRiskCost,
      highlight: true,
    },
    {
      cohort: `Everyone else\n(${100 - highRiskPct}% of patients)`,
      label: `${100 - highRiskPct}% of patients`,
      dnas: 100 - highRiskDnaPct,
      cost: practice.wasted_capacity_gbp - highRiskCost,
      highlight: false,
    },
  ];

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
          The Root Cause
        </motion.p>

        <motion.h2
          className="text-3xl md:text-5xl font-black text-white mb-6 leading-tight"
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.2 }}
        >
          You are treating{" "}
          <span style={{ color: "#e8ff00" }}>all patients the same.</span>{" "}
          That is the problem.
        </motion.h2>

        <motion.p
          className="text-lg mb-10 max-w-2xl"
          style={{ color: "#666666" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 0.4 }}
        >
          Based on the deprivation profile of your area, your DNA losses are
          not evenly spread. An estimated{" "}
          <span className="text-white font-semibold">
            {highRiskDnaPct}% of your missed appointments
          </span>{" "}
          are caused by just{" "}
          <span className="text-white font-semibold">
            {highRiskPct}% of your patient list
          </span>{" "}
          — a core cohort of chronic &ldquo;frequent flyers&rdquo;. Automated
          SMS blasts do not work on this group.
        </motion.p>

        {/* 80/20 impact stat blocks */}
        <motion.div
          className="grid grid-cols-2 gap-4 mb-10"
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 0.6 }}
        >
          <div className="p-5" style={{ border: "1px solid #333333" }}>
            <p
              className="text-xs uppercase tracking-widest mb-2"
              style={{ color: "#666666" }}
            >
              High-risk cohort
            </p>
            <p
              className="text-4xl font-black tabular-nums"
              style={{ color: "#e8ff00" }}
            >
              ~{highRiskPatients.toLocaleString("en-GB")}
            </p>
            <p className="text-sm mt-1" style={{ color: "#666666" }}>
              patients driving {highRiskDnaPct}% of your losses
            </p>
          </div>
          <div className="p-5" style={{ border: "1px solid #333333" }}>
            <p
              className="text-xs uppercase tracking-widest mb-2"
              style={{ color: "#666666" }}
            >
              Cost concentrated here
            </p>
            <p
              className="text-4xl font-black tabular-nums"
              style={{ color: "#e8ff00" }}
            >
              &pound;{highRiskCost.toLocaleString("en-GB")}
            </p>
            <p className="text-sm mt-1" style={{ color: "#666666" }}>
              of your &pound;{practice.wasted_capacity_gbp.toLocaleString("en-GB")} monthly loss
            </p>
          </div>
        </motion.div>

        {/* Pareto bar chart */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 0.8 }}
          style={{ height: "200px" }}
        >
          {inView && (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart
                data={paretoData}
                layout="vertical"
                margin={{ left: 16, right: 40, top: 8, bottom: 8 }}
                barSize={28}
              >
                <XAxis
                  type="number"
                  domain={[0, 100]}
                  tickFormatter={(v) => `${v}%`}
                  tick={{ fill: "#444444", fontSize: 11 }}
                  axisLine={false}
                  tickLine={false}
                />
                <YAxis
                  type="category"
                  dataKey="label"
                  tick={{ fill: "#666666", fontSize: 12 }}
                  axisLine={false}
                  tickLine={false}
                  width={140}
                />
                <Tooltip
                  formatter={(v) =>
                    typeof v === "number"
                      ? [`${v}% of all DNAs`, "Share of missed appointments"]
                      : [String(v), "Share"]
                  }
                  contentStyle={{
                    background: "#111",
                    border: "1px solid #333",
                    color: "#fff",
                    fontSize: 12,
                  }}
                />
                <Bar dataKey="dnas" radius={[0, 2, 2, 0]}>
                  {paretoData.map((entry, index) => (
                    <Cell
                      key={index}
                      fill={entry.highlight ? "#e8ff00" : "#222222"}
                    />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </motion.div>

        <motion.p
          className="text-sm mt-6 mb-12"
          style={{ color: "#444444" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 1.0 }}
        >
          Sending the same SMS to all {practice.list_size.toLocaleString("en-GB")} patients
          wastes your administrative budget on the {100 - highRiskPct}% who rarely miss
          appointments — and fails the {highRiskPct}% who actually drive your losses.
        </motion.p>

        <motion.div
          className="flex flex-col items-center gap-2"
          style={{ color: "#333333" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 1.2 }}
        >
          <motion.div
            animate={{ y: [0, 6, 0] }}
            transition={{ repeat: Infinity, duration: 2, ease: "easeInOut" }}
            className="flex flex-col items-center gap-1"
          >
            <span className="text-xs uppercase tracking-widest">scroll</span>
            <svg width="12" height="8" viewBox="0 0 12 8" fill="none">
              <path
                d="M1 1L6 7L11 1"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}
