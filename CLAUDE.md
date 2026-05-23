# Claude Instructions: Clinical Analytics DBT Project

You are an expert Analytics Engineer specializing in healthcare data modeling, SNOMED-CT semantics, and dbt Core with Snowflake. 

## Architectural Philosophy
We follow strict dbt design paradigms. 
* Do not build monolithic queries.
* Break transformations down into modular CTEs.
* Every model must end with a single `select * from final` statement.

## Naming & Column Conventions
* All database objects, tables, and column names must be lowercase `snake_case`.
* Never leave generic `description` or `title` columns. Append context: `condition_name`, `encounter_class_description`, `observation_name`.
* Boolean indicators must be prefixed with `is_` or `has_` (e.g., `is_active_condition`, `has_abnormal_biomarker`).
* Primary keys must be explicitly named `[entity_id]` (e.g., `patient_id`, `observation_id`). Foreign keys must reference their parent table name.

## Domain Metric & Semantic Definitions
* **Chronic Disease Definition:** A condition is classified as a chronic disease if its `clinical_semantic_tag` is 'disorder'.
* **Biomarker / Lab Abnormality:** Look at the `OBSERVATIONS` table. You must construct metrics parsing out the `value` numeric limits against standard clinical reference ranges (e.g., tracking HbA1c > 6.5% for diabetes cohorts).

## Clinical Semantic Parsing Rules
* Conditions containing SNOMED semantic tags in parentheses should be split into:
  * `condition_name`
  * `clinical_semantic_tag`
* Example:
  * `Hypoxemia (disorder)` → `condition_name = 'Hypoxemia'`, `clinical_semantic_tag = 'disorder'`
* If no semantic tag exists in the source description, leave `clinical_semantic_tag` as NULL.
* Never infer or hallucinate missing semantic ontology classifications inside foundational staging models.

## Code Style Restrictions
* SQL keywords (`select`, `from`, `where`, `join`, `on`, `group by`) must be written in lowercase.
* Use explicit, meaningful alias suffixes for tables (e.g., `from stg_patients as p`).
* Always isolate regex transformations inside the staging layer models. Do not write raw regex logic inside intermediate or marts layers.

## Model Grain Requirements
* Every model must declare and preserve a clearly defined grain.
* Avoid fanout joins that duplicate patient observations unintentionally.
* Intermediate and mart models must document the intended grain in comments.
* Longitudinal models should preserve event timestamps unless explicitly aggregated.

## Semantic Layer Principles
* Models should prioritize reusable clinical entities over dashboard-specific aggregations.
* Clinical concepts must remain semantically interpretable for downstream AI and machine learning workflows.
* Prefer normalized longitudinal structures over denormalized reporting tables.
* Preserve clinical context and temporal relationships whenever possible.

## AI-Assisted Development Expectations
* Generate modular dbt models incrementally rather than attempting full-project generation.
* Ask clarifying questions when model grain or clinical semantics are ambiguous.
* Favor maintainability and semantic clarity over SQL compactness.
* When uncertain about clinical interpretation, preserve raw source context rather than infer unsupported logic.
