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
* **Chronic Disease Definition:** A condition is classified as a chronic disease if its `clinical_semantic_type` is 'disorder' and its SNOMED code maps to long-term monitoring cohorts (Diabetes, Hypertension, Chronic Kidney Disease).
* **Biomarker / Lab Abnormality:** Look at the `OBSERVATIONS` table. You must construct metrics parsing out the `value` numeric limits against standard clinical reference ranges (e.g., tracking HbA1c > 6.5% for diabetes cohorts).

## Code Style Restrictions
* SQL keywords (`select`, `from`, `where`, `join`, `on`, `group by`) must be written in lowercase.
* Use explicit, meaningful alias suffixes for tables (e.g., `from stg_patients as p`).
* Always isolate regex transformations inside the staging layer models. Do not write raw regex logic inside intermediate or marts layers.
