-- grain: one row per patient per condition episode, filtered to the disorder-tagged patient cohort
with condition_disorders as (

    select * from {{ ref('int_condition_disorders') }}

),

cohort as (

    select * from {{ ref('int_patient_cohort') }}

),

patients as (

    select * from {{ ref('stg_patients') }}

),

encounter_summary as (

    select * from {{ ref('int_patient_encounter_summary') }}

),

joined as (

    select
        cd.patient_id,
        cd.condition_id,

        p.gender,
        p.race,
        p.ethnicity,
        p.is_deceased,
        p.death_date,

        es.total_encounters,
        es.ambulatory_encounter_count,
        es.wellness_encounter_count,
        es.emergency_encounter_count,
        es.inpatient_encounter_count,

        cd.condition_name,
        cd.snomed_concept_code,
        cd.clinical_semantic_tag,
        cd.clinical_state,
        cd.clinical_category,
        cd.condition_start_date,
        cd.condition_end_date,
        cd.is_active_condition,
        cd.condition_duration_days,
        cd.condition_onset_year

    from condition_disorders as cd
    inner join cohort as co
        on cd.patient_id = co.patient_id
    left join patients as p
        on cd.patient_id = p.patient_id
    left join encounter_summary as es
        on cd.patient_id = es.patient_id

),

final as (

    select * from joined

)

select * from final
