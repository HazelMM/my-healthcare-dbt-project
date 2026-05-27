# AI-Ready Longitudinal Clinical Analytics Foundation

## Project Overview

This repository contains an end-to-end analytics engineering project focused on transforming raw longitudinal electronic health record (EHR) data into semantically consistent, AI-ready clinical datasets.

Using dbt and Snowflake, the project models patient health trajectories across clinical conditions, biomarker observations, and healthcare encounters to create trusted analytical foundations for downstream analytics, machine learning, and AI-assisted clinical reasoning workflows.

Rather than treating healthcare data as isolated reporting tables, this project emphasizes longitudinal patient state modeling, semantic normalization, and clinically meaningful context generation.

The semantic layer is exposed through a natural language AI agent — built with the Claude API and Streamlit — that allows users to query the clinical dataset using plain English and receive back auditable SQL, tabular results, and downloadable exports.

**[🩺 Try the live demo](https://clinical-analytics-agent-demo.streamlit.app/)**

> Built with synthetic data only. No real patient information is used or stored.
> Data source: [Synthea by MITRE](https://synthea.mitre.org/downloads)

---

## Core Objectives

### Longitudinal Patient Modeling
Build patient-centric analytical models that capture changes in health state over time across diagnoses, biomarkers, and encounters.

### Clinical Semantic Layer
Normalize and organize clinical concepts (SNOMED-CT conditions, biomarker observations, encounter events) into reusable semantic domains and governed analytical entities.

### Biomarker & Observation Standardization
Standardize laboratory observations and vital measurements into consistent, queryable longitudinal structures suitable for analytics and feature engineering. Biomarker reference ranges are maintained as a versioned seed file — in a production workflow these thresholds would be sourced and validated by a clinical subject matter expert.

### AI-Ready Clinical Context
Create semantically structured datasets optimized for natural language querying, machine learning feature engineering, and AI-assisted clinical analysis.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Cloud Data Warehouse | Snowflake |
| Transformation Framework | dbt Core (`dbt-snowflake`) |
| AI Agent Interface and Agent | Streamlit + Claude API (`claude-sonnet-4-6`) |
| Development Environment | GitHub Codespaces |
| Source Dataset | Synthea Synthetic Healthcare Data |

---

## Architecture (DAG)

```
Raw Synthea CSVs loaded into Snowflake (patients, conditions, observations, encounters)
        │
        ▼
    Staging Layer          ← source cleaning, type casting, surrogate keys
        │
        ▼
  Intermediate Layer       ← business logic, clinical enrichment, trend scoring
        │
        ▼
    Marts Layer            ← two semantic tables, materialized as Snowflake tables
        │
        ├── dim_patient_disorder_episodes
        └── patient_longitudinal_observation_spine
                │
                ▼
        AI Agent (Streamlit + Claude API)
```

### Staging
One model per source table. Cleans raw data, renames columns, casts types, generates surrogate keys, and deduplicates. Regex transformations are isolated here and do not travel downstream.

### Intermediate
The intermediate layer applies business logic and clinical enrichment. Key models:

- **`int_condition_disorders`** — filters conditions to `clinical_semantic_tag = 'disorder'` only, following SNOMED CT ontology. Joins to the SNOMED clinical state seed to classify each condition as chronic or acute and assign a clinical category (cardiovascular, renal, oncologic, etc.)
- **`int_observation_clinical`** — inner joins observations to the biomarker reference ranges seed, which acts as an allowlist. Only observations with a matching LOINC code are carried forward. Calculates `distance_from_normal` — how far each reading sits from its published reference range boundary.
- **`int_observation_trend`** — lags `distance_from_normal` to derive `trend_status`: `improving`, `worsening`, `normalized`, or `stable`. Split into a separate model from `int_observation_clinical` because Snowflake does not support the WINDOW clause inside a CTE.
- **`int_patient_encounter_summary`** — aggregates cumulative encounter counts per patient by encounter class.

### Marts
Two semantic tables serve as the foundation for analytics and the AI agent (kept intentionally separate to prevent condition-observation fanout- A major focus of this project was preserving longitudinal grain integrity and preventing fanout across clinical entities):

- **`dim_patient_disorder_episodes`** — one row per patient per condition episode. Combines demographics, cumulative encounter history, and condition timeline with clinical state classification.
- **`patient_longitudinal_observation_spine`** — one row per patient per month per observation. Monthly biomarker snapshots with trend scoring, reference range evaluation, and distance-from-normal scoring.

### Seeds
Two reference datasets support the intermediate layer:

- **`biomarker_reference_ranges`** — maps LOINC codes to published clinical reference ranges. Serves as both a lookup table and an allowlist for the observation pipeline. In a production workflow, these thresholds would be sourced and validated by a clinical SME.
- **`snomed_clinical_state`** — maps SNOMED concept codes present in this dataset to clinical state (chronic/acute) and clinical category. Scoped to codes found in this Synthea subset only and not an exhaustive SNOMED reference.

---

## Semantic Modeling Principles

This project prioritizes semantic consistency and longitudinal grain preservation across healthcare entities.

Key modeling decisions include:
- preserving source-derived clinical semantics rather than inferring unsupported ontology classifications
- preventing fanout across conditions, encounters, and observations
- separating raw clinical context from derived analytical logic
- maintaining reusable longitudinal entities instead of denormalized reporting tables

---

## AI Agent

The Streamlit agent translates natural language questions into Snowflake SQL using the Claude API. It queries two mart tables only, via a dedicated read-only Snowflake role (`CLINICAL_AGENT_ROLE`) scoped exclusively to those tables.

**Security design:**
- `CLINICAL_AGENT_USER` has SELECT on mart tables only — no access to staging, intermediate, or raw data
- No PHI in the mart tables — no names, addresses, or direct identifiers
- Future grants applied so table-level access persists across dbt runs
- All credentials managed via environment variables, never hardcoded

**Capabilities:**
- Natural language to SQL translation
- Out-of-scope detection — returns a plain English explanation instead of guessing
- Automatic time series chart for single-patient observation queries
- CSV download for any result set
- Row preview capped at 200 rows; full dataset available via download

---

## Running Locally

**Prerequisites:** Snowflake account, Python 3.12+, dbt Core with `dbt-snowflake`.

Setup instructions follow standard dbt and Streamlit conventions. See `clinical_analytics/dbt_project.yml` and `agent/requirements.txt` for dependencies. Credentials are managed via environment variables — see the security design notes in the AI Agent section above.

---

## Key Engineering Decisions

See [DECISIONS.md](./DECISIONS.md) for detailed reasoning behind modeling choices including grain selection, materialization strategy, the biomarker seed as allowlist, comorbidity handling, trend scoring logic, and the read-only agent security model.

---

## Notes on Scope

- Conditions are filtered to SNOMED `disorder` semantic tag only. Some clinically common conditions carry a different SNOMED tag and are not present in this dataset.
- Biomarker reference ranges are general published standards (sourced using Claude AI), not institution-specific thresholds. Clinical interpretation remains with qualified practitioners.
- All data is Synthea-generated synthetic data. Not intended for clinical use.
