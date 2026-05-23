{% docs condition_duration_days %}
Calendar days from condition onset to resolution, calculated as `condition_end_date - condition_start_date`. For active conditions where `condition_end_date` is NULL, duration is calculated against the current date and will grow with each build.
{% enddocs %}

{% docs condition_onset_year %}
Calendar year the condition was first recorded. Derived from `condition_start_date`. Used for longitudinal cohort stratification and trend analysis.
{% enddocs %}

{% docs encounter_duration_minutes %}
Total duration of the encounter in minutes, derived from `encounter_end_datetime - encounter_start_datetime`. NULL for encounters where no end time was captured.
{% enddocs %}

{% docs encounter_month %}
Calendar month (1–12) the encounter began, derived from `encounter_start_datetime`. Used for seasonal utilization pattern analysis.
{% enddocs %}

{% docs days_since_last_encounter %}
Days elapsed since the patient's immediately preceding encounter, ordered by `encounter_start_datetime`. Computed via LAG window partitioned by `patient_id`. NULL for each patient's first recorded encounter.
{% enddocs %}

{% docs observation_month %}
Calendar month (1–12) the observation was recorded, derived from `observation_date`. Used for seasonal and longitudinal trend analysis.
{% enddocs %}

{% docs value_delta %}
Difference between the current `observation_value_numeric` and the patient's previous value for the same `observation_code`, ordered by `observation_date`. Computed via LAG window partitioned by `patient_id` and `observation_code`. NULL for a patient's first reading of a given code or for nominal observations.
{% enddocs %}

{% docs distance_from_normal %}
Signed numeric distance from the nearest boundary of the reference range defined in `biomarker_reference_ranges`. Positive values indicate how far the reading exceeds `range_high`; negative values indicate how far it falls below `range_low`; zero means the value is within normal limits. NULL for nominal observations, observations with no numeric value, or codes where no range is defined in the seed.
{% enddocs %}

{% docs trend_status %}
Clinical trajectory of the observation relative to its reference range, derived by comparing `distance_from_normal` to the patient's previous reading for the same observation code via LAG window partitioned by `patient_id` and `observation_code`. `'normalized'` means the current reading has returned to within normal limits from a previously out-of-range state (prior `distance_from_normal != 0`, either above or below range); `'worsening'` means the absolute deviation from normal increased; `'improving'` means it decreased; `'stable'` means it did not change. NULL when no prior reading exists or when `distance_from_normal` is NULL.
{% enddocs %}

{% docs range_status %}
Clinical position of the observation value relative to the reference range defined in `biomarker_reference_ranges`: `'normal'`, `'above_range'`, or `'below_range'`. NULL for nominal observations, observations with no numeric value, or codes where no numeric threshold is defined in the seed.
{% enddocs %}

{% docs reference_notes %}
Free-text clinical annotation from `biomarker_reference_ranges` describing interpretation thresholds, sub-population-specific ranges, or flags for categorical observations. Sourced from the seed; not derived from patient data.
{% enddocs %}

{% docs total_encounters %}
Cumulative count of all encounter records for the patient across all encounter classes and time. Reflects the state of the data as of the last dbt refresh.
{% enddocs %}

{% docs ambulatory_encounter_count %}
Cumulative count of encounters where `encounter_class = 'ambulatory'`. Includes routine office visits and outpatient appointments.
{% enddocs %}

{% docs wellness_encounter_count %}
Cumulative count of encounters where `encounter_class = 'wellness'`. Includes annual physicals and preventive care visits.
{% enddocs %}

{% docs emergency_encounter_count %}
Cumulative count of encounters where `encounter_class = 'emergency'`. Used as a proxy for acute care burden in downstream patient profiles.
{% enddocs %}

{% docs inpatient_encounter_count %}
Cumulative count of encounters where `encounter_class = 'inpatient'`. Represents hospitalisation events and is used as a proxy for high-acuity care burden in downstream patient profiles.
{% enddocs %}

{% docs last_encounter_date %}
Date of the patient's most recent encounter, derived from the maximum `encounter_start_datetime`. Static as of last refresh.
{% enddocs %}

{% docs total_disorder_count %}
Total number of disorder-tagged condition episodes recorded for the patient across all time, including both active and resolved conditions.
{% enddocs %}

{% docs active_disorder_count %}
Count of condition episodes for the patient currently marked as active (`is_active_condition = true`), meaning no `condition_end_date` has been recorded.
{% enddocs %}

{% docs first_disorder_date %}
Date of the patient's earliest recorded disorder-tagged condition onset (`condition_start_date`).
{% enddocs %}

{% docs most_recent_disorder_date %}
Date of the patient's most recently recorded disorder-tagged condition onset (`condition_start_date`). Does not reflect the most recently active condition — a resolved condition recorded later may take precedence.
{% enddocs %}
