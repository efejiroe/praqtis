"use client";
import { useRef } from "react";
import { motion, useInView } from "framer-motion";
import { Practice } from "@/lib/types";

interface Props {
  practice: Practice;
}

const nudges = [
  {
    number: "01",
    title: "Cost-Aware SMS Reminders",
    body: 'Send appointment reminders that state the real financial cost: "Missing your appointment wastes \u00a340 of NHS clinical time set aside for you." Loss aversion is twice as powerful as potential gain in driving behaviour change.',
  },
  {
    number: "02",
    title: "Automated 48-Hour Follow-Up",
    body: "Enforce a digital check-in 48 hours after prescribing new chronic medication. Patients who feel personally followed-up are significantly more likely to attend their review appointment \u2014 directly protecting your QOF achievement.",
  },
  {
    number: "03",
    title: "Delegation to Allied Health Staff",
    body: "Shift routine chronic reviews (hypertension, diabetes, asthma) to practice nurses and clinical pharmacists. This reduces per-appointment time pressure, improves patient relationships, and frees GP capacity for complex cases.",
  },
];

export default function FixView({ practice }: Props) {
  const ref = useRef<HTMLElement>(null);
  const inView = useInView(ref, { once: true, margin: "-20% 0px" });

  return (
    <section
      ref={ref}
      className="min-h-screen flex flex-col items-center justify-center px-6 pb-24"
    >
      <div className="w-full max-w-3xl">
        <motion.p
          className="text-sm tracking-widest uppercase mb-4"
          style={{ color: "#666666" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.6 }}
        >
          The Actionable Fix
        </motion.p>

        <motion.h2
          className="text-3xl md:text-5xl font-black text-white mb-6 leading-tight"
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.2 }}
        >
          To reclaim{" "}
          <span style={{ color: "#e8ff00" }}>
            &pound;{practice.wasted_capacity_gbp.toLocaleString("en-GB")}
          </span>
          , you need to change patient behaviour &mdash; not work harder.
        </motion.h2>

        <motion.p
          className="text-lg mb-12"
          style={{ color: "#666666" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 0.4 }}
        >
          Implement these 3 evidence-based nudges today:
        </motion.p>

        <div>
          {nudges.map((nudge, i) => (
            <motion.div
              key={nudge.number}
              className="flex gap-8 py-8"
              style={{ borderTop: "1px solid #1a1a1a" }}
              initial={{ opacity: 0, y: 30 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.7, delay: 0.6 + i * 0.2 }}
            >
              <span
                className="text-5xl font-black flex-shrink-0 tabular-nums select-none"
                style={{ color: "#1a1a1a" }}
              >
                {nudge.number}
              </span>
              <div>
                <h3 className="text-white text-xl font-bold mb-3">
                  {nudge.title}
                </h3>
                <p
                  className="text-base leading-relaxed"
                  style={{ color: "#666666" }}
                >
                  {nudge.body}
                </p>
              </div>
            </motion.div>
          ))}
          <div style={{ borderTop: "1px solid #1a1a1a" }} />
        </div>

        {/* QOF at-risk callout */}
        <motion.div
          className="mt-16 p-8 text-center"
          style={{ border: "1px solid #e8ff00" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 1.4 }}
        >
          <p
            className="text-sm uppercase tracking-widest mb-3"
            style={{ color: "#666666" }}
          >
            Also at risk
          </p>
          <p className="text-white text-lg">
            Your QOF achievement gap puts an estimated{" "}
            <span className="font-bold" style={{ color: "#e8ff00" }}>
              &pound;{practice.qof_at_risk_gbp.toLocaleString("en-GB")}
            </span>{" "}
            of annual bonus income at risk.
          </p>
          <p className="text-sm mt-2" style={{ color: "#666666" }}>
            {practice.qof_pct.toFixed(1)}% of maximum QOF points achieved
            &middot; {practice.qof_achieved_points.toFixed(0)} /{" "}
            {practice.qof_max_points.toFixed(0)} points
          </p>
        </motion.div>

        <motion.p
          className="text-xs text-center mt-12"
          style={{ color: "#333333" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 1.8 }}
        >
          Data: NHS England &middot; Appointments in General Practice (Jan 2026)
          &middot; QOF 2023&ndash;24 &middot; GP Patient List Sizes &middot;
          Analysis by REPLIQR
        </motion.p>
      </div>
    </section>
  );
}
