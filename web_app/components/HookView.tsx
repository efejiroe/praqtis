"use client";
import { useState, useMemo, useRef, useEffect } from "react";
import { motion } from "framer-motion";
import { Practice, PracticeData } from "@/lib/types";

interface Props {
  data: PracticeData | null;
  onSelect: (practice: Practice) => void;
}

export default function HookView({ data, onSelect }: Props) {
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  const results = useMemo(() => {
    if (!data || query.length < 2) return [];
    const q = query.toUpperCase();
    return data.practices
      .filter(
        (p) =>
          p.gp_name.toUpperCase().includes(q) ||
          p.gp_code.toUpperCase().includes(q)
      )
      .slice(0, 8);
  }, [data, query]);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (
        containerRef.current &&
        !containerRef.current.contains(e.target as Node)
      ) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const handleSelect = (practice: Practice) => {
    setQuery(practice.gp_name);
    setOpen(false);
    onSelect(practice);
  };

  return (
    <section className="min-h-screen flex flex-col items-center justify-center px-6">
      <motion.p
        className="text-sm tracking-[0.3em] uppercase mb-8"
        style={{ color: "#666666" }}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 1 }}
      >
        PRAQTIS &middot; NHS Practice Intelligence
      </motion.p>

      <motion.h1
        className="text-4xl md:text-6xl font-black text-white text-center max-w-3xl leading-tight mb-4"
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8, delay: 0.2 }}
      >
        How much is patient non-adherence really costing your practice?
      </motion.h1>

      <motion.p
        className="text-lg text-center max-w-xl mb-16"
        style={{ color: "#666666" }}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.8, delay: 0.5 }}
      >
        We benchmarked 6,140 NHS GP practices using public data. Find yours.
      </motion.p>

      <motion.div
        ref={containerRef}
        className="relative w-full max-w-xl"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8, delay: 0.7 }}
      >
        <input
          type="text"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
          placeholder="ODS code or practice name (e.g. A81001)"
          disabled={!data}
          className="w-full bg-transparent text-white text-xl py-4 px-0 outline-none transition-colors duration-300"
          style={{
            borderBottom: "2px solid",
            borderBottomColor: open ? "#e8ff00" : "#ffffff",
            caretColor: "#e8ff00",
          }}
        />

        {!data && (
          <p className="text-sm mt-3" style={{ color: "#444444" }}>
            Loading practice data&hellip;
          </p>
        )}

        {open && results.length > 0 && (
          <ul
            className="absolute top-full left-0 right-0 z-50 max-h-72 overflow-y-auto"
            style={{
              background: "#111111",
              border: "1px solid #333333",
              marginTop: "1px",
            }}
          >
            {results.map((p) => (
              <li
                key={p.gp_code}
                onClick={() => handleSelect(p)}
                className="flex items-center justify-between px-4 py-3 cursor-pointer transition-colors"
                style={{ borderBottom: "1px solid #222222" }}
                onMouseEnter={(e) =>
                  ((e.currentTarget as HTMLLIElement).style.background =
                    "#1a1a1a")
                }
                onMouseLeave={(e) =>
                  ((e.currentTarget as HTMLLIElement).style.background =
                    "transparent")
                }
              >
                <span className="text-white text-sm font-medium">
                  {p.gp_name}
                </span>
                <span
                  className="text-xs font-mono ml-4"
                  style={{ color: "#666666" }}
                >
                  {p.gp_code}
                </span>
              </li>
            ))}
          </ul>
        )}

        {open && query.length >= 2 && results.length === 0 && data && (
          <div
            className="absolute top-full left-0 right-0 px-4 py-3"
            style={{
              background: "#111111",
              border: "1px solid #333333",
              marginTop: "1px",
            }}
          >
            <span className="text-sm" style={{ color: "#666666" }}>
              No practices found. Try a different name or ODS code.
            </span>
          </div>
        )}
      </motion.div>
    </section>
  );
}
