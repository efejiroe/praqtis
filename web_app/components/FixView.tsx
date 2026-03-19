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
    framework: "Social & Timely",
    title: "Re-write your SMS template",
    body: 'Stop sending generic reminders. Update your accuRx/EMIS template to introduce a social cost: "Missing your appointment wastes £40 of clinical time set aside for you." Loss aversion is twice as powerful as potential gain in driving behaviour change.',
  },
  {
    number: "02",
    framework: "Easy",
    title: "The 48-hour micro-commitment",
    body: "Don't wait 3 months for a chronic review. Set your system to send an automated digital check-in 48 hours after prescribing new medications: \"Have you picked up your prescription? Y/N\". A single frictionless reply doubles follow-up attendance.",
  },
  {
    number: "03",
    framework: "Targeted",
    title: "Predictive profiling — stop texting everyone",
    body: "Use your EMIS filters to flag patients with ≥2 previous DNAs. Divert this high-risk cohort away from automated SMS entirely and trigger a proactive 30-second human phone call. The human touch drastically reduces non-adherence for the most chronic offenders.",
  },
];

export default function FixView({ practice }: Props) {
  const ref = useRef<HTMLElement>(null);
  const inView = useInView(ref, { once: true, margin: "-20% 0px" });

  const roiInvestment = 1000;
  const roiSaving = Math.round(practice.wasted_capacity_gbp * 0.5);

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
          The Actionable Fix — EASY Framework
        </motion.p>

        <motion.h2
          className="text-3xl md:text-5xl font-black text-white mb-6 leading-tight"
          initial={{ opacity: 0, y: 20 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.2 }}
        >
          You don&rsquo;t need new software.{" "}
          <span style={{ color: "#e8ff00" }}>
            You need to use what you have — differently.
          </span>
        </motion.h2>

        {/* ROI callout */}
        <motion.div
          className="mb-12 p-6"
          style={{ border: "1px solid #e8ff00" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 0.4 }}
        >
          <p
            className="text-xs uppercase tracking-widest mb-2"
            style={{ color: "#666666" }}
          >
            Immediate ROI
          </p>
          <p className="text-white text-lg leading-relaxed">
            Spending{" "}
            <span className="font-bold" style={{ color: "#e8ff00" }}>
              &pound;{roiInvestment.toLocaleString("en-GB")}
            </span>{" "}
            on targeted interventions for your high-risk cohort can halve your
            monthly deficit — recovering an estimated{" "}
            <span className="font-bold" style={{ color: "#e8ff00" }}>
              &pound;{roiSaving.toLocaleString("en-GB")}
            </span>{" "}
            per month. Implement these 3 nudges today:
          </p>
        </motion.div>

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
                <p
                  className="text-xs uppercase tracking-widest mb-1"
                  style={{ color: "#e8ff00" }}
                >
                  {nudge.framework}
                </p>
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

        <motion.p
          className="text-xs text-center mt-12"
          style={{ color: "#333333" }}
          initial={{ opacity: 0 }}
          animate={inView ? { opacity: 1 } : {}}
          transition={{ duration: 0.8, delay: 1.4 }}
        >
          Data: NHS England &middot; Appointments in General Practice (Jan 2026)
          &middot; QOF 2023&ndash;24 &middot; GP Patient List Sizes &middot;
          Analysis by REPLIQR
        </motion.p>
      </div>
    </section>
  );
}
