-- grain: one row per disorder-tagged condition episode per patient, filtered from stg_conditions
with conditions as (

    select * from {{ ref('stg_conditions') }}
    where clinical_semantic_tag = 'disorder'

),

snomed_state as (

    select * from {{ ref('snomed_clinical_state') }}

),

enriched as (

    select
        c.condition_id,
        c.patient_id,
        c.encounter_id,
        c.snomed_concept_code,
        c.condition_name,
        c.clinical_semantic_tag,
        ss.clinical_state,
        ss.clinical_category,
        c.condition_start_date,
        c.condition_end_date,
        c.is_active_condition,

        datediff(
            'day',
            c.condition_start_date,
            coalesce(c.condition_end_date, current_date())
        )                                               as condition_duration_days,

        year(c.condition_start_date)                    as condition_onset_year

    from conditions as c
    left join snomed_state as ss
        on c.snomed_concept_code = ss.snomed_concept_code

),

final as (

    select * from enriched

)

select * from final
