{% docs snomed_clinical_state %}
Static reference seed mapping SNOMED-CT concept codes to their clinical state (acute vs. chronic) and
clinical system category (e.g., respiratory, cardiovascular). Grain: one row per SNOMED concept code.
Intended for joins in intermediate models to enrich condition episodes with standardized clinical
classification that supports cohort stratification and downstream ML features.

**Note:** This reference table was assembled with the assistance of Claude AI and is intended for
learning purposes only. Clinical classifications are approximations and should not be used for
real patient care or clinical decision-making.
{% enddocs %}

{% docs snomed_clinical_state__snomed_concept_code %}
The SNOMED-CT numeric concept identifier for the condition. Primary key of this seed. Used as the
join key to `stg_conditions` and intermediate disorder models.
{% enddocs %}

{% docs snomed_clinical_state__condition_name %}
Human-readable SNOMED-CT preferred term for the condition, stripped of semantic tag parentheticals.
Provided for reference; authoritative condition labels should be sourced from `stg_conditions`.
{% enddocs %}

{% docs snomed_clinical_state__clinical_state %}
Broad temporal classification of the condition's expected clinical course: `'acute'` for conditions
that typically resolve within weeks, or `'chronic'` for conditions that persist over months to years
and require ongoing management. NULL when a concept code is not present in this seed.
{% enddocs %}

{% docs snomed_clinical_state__clinical_category %}
Body-system or disease-domain grouping for the condition (e.g., `'respiratory'`, `'cardiovascular'`,
`'oncologic'`). Used for clinical cohort segmentation and feature engineering in downstream models.
NULL when a concept code is not present in this seed.
{% enddocs %}

{% docs biomarker_reference_ranges %}
Static reference seed mapping LOINC observation codes to their clinical reference ranges, units,
and interpretation notes. Grain: one row per LOINC code per clinical category. A small number of
codes (e.g., 8478-0 Mean Blood Pressure) appear in multiple categories reflecting distinct clinical
monitoring contexts. Intended for joins in intermediate models to flag abnormal biomarker values
against standard thresholds.

**Note:** This reference table was assembled with the assistance of Claude AI and is intended for
learning purposes only. Clinical reference ranges are approximations and should not be used for
real patient care or clinical decision-making.
{% enddocs %}

{% docs biomarker_reference_ranges__loinc_code %}
The Logical Observation Identifiers Names and Codes (LOINC) code identifying the clinical observation
or test. A small number of entries use SNOMED CT codes or proprietary identifiers (e.g., QOLS) where
no standard LOINC equivalent exists. Forms part of the composite grain key alongside `category`.
{% enddocs %}

{% docs biomarker_reference_ranges__observation_name %}
Full human-readable name of the clinical observation or laboratory test, sourced from the LOINC long
common name where applicable.
{% enddocs %}

{% docs biomarker_reference_ranges__category %}
Clinical domain grouping for the observation (e.g., metabolic, hematology, renal). Used alongside
`loinc_code` to form the composite grain, as some codes appear in multiple clinical contexts.
{% enddocs %}

{% docs biomarker_reference_ranges__range_low %}
Lower bound of the clinically normal reference range. NULL for categorical observations or those
without a defined lower numeric threshold. Values are inclusive.
{% enddocs %}

{% docs biomarker_reference_ranges__range_high %}
Upper bound of the clinically normal reference range. NULL for categorical observations or those
without a defined upper numeric threshold. Values are inclusive.
{% enddocs %}

{% docs biomarker_reference_ranges__unit %}
Unit of measure expressed in UCUM (Unified Code for Units of Measure) notation where applicable.
NULL for purely categorical observations.
{% enddocs %}

{% docs biomarker_reference_ranges__notes %}
Free-text clinical annotation describing interpretation thresholds, sub-population-specific ranges
(e.g., sex-stratified), or flags for categorical observations where numeric ranges do not apply.
{% enddocs %}
