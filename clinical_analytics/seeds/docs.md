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
