export interface Practice {
  gp_code: string;
  gp_name: string;
  sub_icb_code: string;
  sub_icb_name: string;
  list_size: number;
  total_appointments: number;
  dna_count: number;
  dna_rate_pct: number;
  wasted_capacity_gbp: number;
  archetype: number;
  benchmark_gap_pct: number;
  qof_achieved_points: number;
  qof_max_points: number;
  qof_pct: number;
  qof_at_risk_gbp: number;
}

export interface Archetype {
  label: string;
  count: number;
  avg_list_size: number;
  avg_dna_rate_pct: number;
  top10_dna_rate_pct: number;
}

export interface PracticeData {
  generated_at: string;
  practice_count: number;
  archetypes: Record<string, Archetype>;
  practices: Practice[];
}
