# Engineering Decisions

This document captures the reasoning behind key modeling decisions in this project.

---

## Conditions Are Filtered to `clinical_semantic_tag = 'disorder'`

The Synthea conditions table contains a mix of clinical entry types — disorders, findings, administrative codes, and regimen entries. Only rows where `clinical_semantic_tag = 'disorder'` are carried into the intermediate and mart layers.

This filter is applied once in `int_condition_disorders` and inherited by all downstream models. Centralizing it means the scope can be changed in one place if the project expands.

The semantic tag is extracted from the SNOMED description field using a regex pattern in staging, making it explicit and testable rather than inferred at query time. Note: some conditions that are colloquially considered diseases — such as primary diabetes mellitus — carry a different SNOMED tag and are excluded by this filter.

---

## Mart Design: Two Separate Tables Instead of One Spine

An early design used a single spine with one row per patient per month per condition per observation. A wireframe simulation revealed that a patient with two active conditions and three lab readings in one month would produce six rows — duplicating every observation for every condition. Good modeling avoids fanout — duplication inflates row counts and makes aggregations unreliable.

The solution was two separate mart tables joined on `patient_id`:

- **`dim_patient_disorder_episodes`** — one row per patient per condition episode. No observations.
- **`patient_longitudinal_observation_spine`** — one row per patient per month per observation. No conditions.

Consumers join on `patient_id` when they need both, using `condition_start_date` and `condition_end_date` to determine which conditions were active during a given observation period. Each table is independently queryable without duplication. The AI agent benefits from this separation — comorbidity questions query `dim_patient_disorder_episodes`, biomarker questions query the spine, and cross-domain questions join them.

---

## Encounter Data as Perspective, Not a Semantic Domain

Encounters in this project are surfaced as cumulative patient-level counts — total encounters, ambulatory, wellness, emergency, and inpatient — rather than as a full longitudinal encounter layer. This is intentional.

The focus of this semantic layer is conditions and observations. Encounter data provides clinical context and perspective — how active is this patient in the healthcare system — without the complexity of a full encounter spine. A dedicated encounter semantic layer would be a separate project with its own grain, timeline, and analytical use cases.

---

## Observation Scope: What Was Included and Why

Observations are filtered to `observation_category IN ('laboratory', 'vital-signs')` as the primary scope. Three additional observations are included explicitly regardless of category:

- **Tobacco smoking status (`72166-2`)** — classified as social history in the source but clinically relevant as a longitudinal risk factor alongside disorder conditions.
- **PHQ-9 total score (`44261-6`)** — the most clinically validated mental health screening instrument. Included because mental health trajectory alongside chronic physical conditions is a meaningful analytical signal.
- **Quality of Life Score (`QOLS`)** — patient-level longitudinal wellbeing metric. Included because it provides a whole-person perspective on health state over time that complements biomarker data.

Categories fully excluded: social history (beyond smoking), survey (beyond PHQ-9), procedure, imaging, therapy. These either lack numeric values suitable for trend analysis or fall outside the clinical scope of this layer.

---

## `distance_from_normal` Pattern for Trend Evaluation

Trend status is derived from distance from the reference range boundary rather than raw value direction. This solves the directional ambiguity problem: a rising hemoglobin is clinically positive for an anemic patient but a rising HbA1c is negative for a diabetic one. Raw direction alone cannot distinguish these cases.

`distance_from_normal` is calculated as:
- Zero if the value is within the reference range
- The gap between the value and the nearest boundary if outside

`trend_status` is then derived by comparing the current `distance_from_normal` to the prior reading's distance using `lag()`. `abs()` is applied to both sides to ensure symmetry between above-range and below-range observations.

`trend_status` values:
- `normalized` — `distance_from_normal = 0` and prior reading was outside range in either direction. Clinically distinct from `stable` — a patient returning to normal range is a meaningful event worth surfacing independently.
- `improving` — moving closer to normal range
- `worsening` — moving further from normal range
- `stable` — distance unchanged
- `null` — first reading (no prior), or nominal observation with no numeric value

The biomarker seed does the clinical work by providing `range_low` and `range_high`. The SQL only measures proximity to those boundaries. Updating a reference range in the CSV automatically changes how trend is evaluated for that code — no SQL changes required.

See `int_observation_clinical` and `int_observation_trend` for the SQL implementation of this logic.

---

## Biomarker Reference Ranges — Seed as Allowlist

The biomarker seed file (`seeds/biomarker_reference_ranges.csv`) serves a dual purpose. It provides published clinical reference ranges for evaluating observation values, and it acts as an allowlist for the observation pipeline. The join between `stg_observations` and the seed is intentionally inner — only observations with a matching LOINC code in the seed are carried into the intermediate layer. This eliminates non-clinical observations miscategorized in the source without requiring brittle code-level exclusion filters.

Reference ranges were compiled from LOINC standards with the assistance of AI (Claude, Anthropic) and cross-referenced against Synthea's documented observation codes. In a production workflow, these thresholds would be sourced and validated by a clinical subject matter expert. Values should be treated as general published reference points, not as institution-specific or clinically validated thresholds.

---

## AI Agent Security Design

The AI agent connects to Snowflake via a dedicated read-only role (`CLINICAL_AGENT_ROLE`) scoped only to the two mart tables. It cannot access staging or intermediate models, cannot write or modify data, and has no access to other schemas or databases.

This principle aligns with HIPAA's minimum necessary standard — the agent is exposed only to the data it needs to answer analytical questions. The mart tables contain no PHI — no names, addresses, dates of birth, or other direct identifiers — making this architecture appropriate for demo and portfolio contexts without risk of patient data exposure.

Future grants are applied at the schema level so that table-level SELECT access persists across dbt runs. Snowflake drops grants when tables are dropped and recreated — a common occurrence with transient mart tables that fully materialize on every dbt run. Without future grants, every dbt run would silently revoke agent access until manually re-granted.

---

## Backlog

- [ ] Vital signs semantic layer (Oura use case) — ring-based signals: HRV, resting heart rate, respiratory rate, SpO2, skin temperature. Separate spine from disorder-based layer.
