{% docs patient_id %}
Unique identifier for a patient, sourced from the Synthea `patients.id` field. Used as the primary key across all patient-centric models.
{% enddocs %}

{% docs is_deceased %}
Boolean flag derived from the presence of a `death_date`. True when the patient has a recorded date of death in the source data.
{% enddocs %}

{% docs condition_name %}
The human-readable clinical condition label with the SNOMED-CT semantic tag stripped out. Parsed from the raw `description` field (e.g. `'Hypoxemia (disorder)'` → `'Hypoxemia'`).
{% enddocs %}

{% docs clinical_semantic_tag %}
The SNOMED-CT semantic tag extracted from the raw condition description (e.g. `'disorder'`, `'finding'`, `'situation'`). NULL when no parenthetical tag is present in the source. Never inferred — only populated when explicitly present in the source value.
{% enddocs %}

{% docs is_active_condition %}
Boolean flag indicating the condition episode has no recorded end date and is considered clinically ongoing. True when `condition_end_date` is NULL.
{% enddocs %}

{% docs snomed_concept_code %}
The numeric SNOMED-CT concept code identifying the clinical condition. Used for cohort mapping to chronic disease groups (Diabetes, Hypertension, Chronic Kidney Disease) in downstream models.
{% enddocs %}

{% docs encounter_id %}
Unique identifier for a clinical encounter, sourced from `encounters.id`. Used as the primary key for encounter-centric models and as a foreign key in conditions and observations.
{% enddocs %}

{% docs encounter_type_description %}
Human-readable label describing the type of encounter (e.g. `'Encounter for check up'`), sourced from the raw `description` field.
{% enddocs %}

{% docs is_completed %}
Boolean flag indicating the encounter has a recorded end datetime. False for encounters that are still in progress or where no end time was captured.
{% enddocs %}

{% docs observation_id %}
Surrogate key generated from `patient`, `encounter`, `code`, and `date`. The observations source has no natural primary key; this hash ensures a stable, unique row identifier across builds.
{% enddocs %}

{% docs observation_code %}
The clinical code identifying the observation type. Carries LOINC codes for laboratory results and vital signs (e.g. `4548-4` for HbA1c), and SNOMED-CT codes for qualitative findings and qualifier values. Used to apply clinical reference range thresholds in `has_abnormal_biomarker`.
{% enddocs %}

{% docs observation_name %}
Human-readable label for the observation, sourced from the raw `description` field (e.g. `'Hemoglobin A1c/Hemoglobin.total in Blood'`).
{% enddocs %}

{% docs raw_value %}
The unmodified source value string for the observation. Preserved for audit and for non-numeric results (e.g. qualitative text findings).
{% enddocs %}

{% docs observation_value_numeric %}
Numeric cast of `raw_value` using `TRY_TO_NUMBER`. NULL when the source value is non-numeric (e.g. text results, coded responses). Used as the basis for clinical threshold comparisons.
{% enddocs %}

{% docs has_abnormal_biomarker %}
Boolean flag set to true when the observation value exceeds a standard clinical reference range threshold for the chronic disease cohorts tracked in this project: HbA1c > 6.5% (LOINC 4548-4), fasting glucose >= 126 mg/dL (LOINC 2339-0), eGFR < 60 mL/min/1.73m² (LOINC 33914-3), systolic BP >= 130 mmHg (LOINC 8480-6). False for all other observations.
{% enddocs %}
