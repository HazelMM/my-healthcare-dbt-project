# Engineering Decisions

This document captures the reasoning behind key modeling decisions in this project. Understanding *why* choices were made is as important as understanding *what* was built.

---

## Grain: One Row Per Patient · Per Month · Per Condition · Per Observation

The spine is intentionally more granular than a simple patient-month table. A patient with two active conditions and two lab readings in a given month produces four rows for that month.

This was a deliberate choice over collapsing to one row per patient per month because:
- Collapsing would require either picking a "primary" observation (lossy) or pivoting observation types into columns (brittle — adding a new biomarker would require a schema change)
- Downstream consumers — BI tools, ML pipelines, AI agents — can always aggregate up; they cannot disaggregate down
- Clinical questions are inherently condition-specific: "is this patient's HbA1c improving" is a different question from "is their blood pressure improving"

---

## Encounter Aggregations Are Cumulative, Not Monthly

Encounter counts (`total_encounters`, `ambulatory_encounter_count`, etc.) reflect the full patient history as of the last dbt run, not the encounters within a given spine month.

The reason: the spine is materialized as a table. If encounter counts were calculated per month, they would reflect activity in that month only — but a BI user filtering to a date range would see encounter counts reset to zero for months with no activity, which is misleading. Cumulative counts are stable, honest facts about the patient that don't change based on the user's date filter.

Consumers who need "encounters in a given period" can calculate that by filtering spine rows to a date range and summing — the raw encounter dates are available for that purpose.

---

## Biomarker Reference Ranges Are a Seed File, Not Hardcoded Logic

Observation values are evaluated against published clinical reference ranges sourced from LOINC standards and Synthea's documented observation codes. These ranges live in `seeds/biomarker_reference_ranges.csv` rather than being hardcoded in SQL.

This means:
- Reference ranges are version-controlled and visible in git history
- Adding or updating a range requires editing a CSV, not a SQL model
- The seed is documentable in `schema.yml` like any other model
- The logic is auditable by non-engineers

The intent is reporting, not diagnosis. A value flagged as `above_range` reflects deviation from a published standard. Clinical interpretation remains with the physician.

---

## Conditions Are Filtered to `clinical_semantic_tag = 'disorder'`

The Synthea conditions table contains a mix of clinical entry types — disorders, findings, administrative codes, and regimen entries. Only rows where `clinical_semantic_tag = 'disorder'` are carried into the intermediate and mart layers.

This filter is applied once in `int_conditions_disorders` and inherited by all downstream models. Centralizing it means the definition of "disorder" can be changed in one place if the scope of the project expands.

The semantic tag is extracted from the SNOMED description field using a regex pattern in staging, making it explicit and testable rather than inferred at query time.

---

## Trend Direction Is Directional, Not Evaluative

`trend_direction` (`improving` / `worsening` / `stable`) reflects the direction of movement of a lab value relative to the patient's previous reading of the same observation code — not whether the value is clinically good or bad.

This is intentional. Whether a rising value is good or bad depends on the condition and the clinical context. A rising hemoglobin is improving for an anemic patient. A rising HbA1c is worsening for a diabetic one. The model does not make that judgment — `range_status` (derived from the biomarker seed) provides the reference point, and clinical interpretation is left to the consumer. 

---

## Biomarker Seed File

The biomarker seed file serves as an allowlist. The join between observations and the seed is intentionally inner, meaning only observations with a matching LOINC code in the seed are carried into the intermediate layer. This eliminates non-clinical observations that are miscategorized in the source without requiring brittle code-level exclusion filters. *Note: Reference ranges were compiled from LOINC standards with the assistance of AI (Claude, Anthropic) and cross-referenced against Synthea's documented observation codes. Values should be treated as general published reference points, not as institution-specific or clinically validated thresholds. 

---

## Backlog

- [ ] Vital signs semantic layer (Oura use case) — ring-based signals: HRV, resting heart rate, respiratory rate, SpO2, skin temperature. Separate spine from disorder-based layer.
