-- grain: one row per disorder-tagged condition episode per patient, filtered from stg_conditions
with conditions as (

    select * from {{ ref('stg_conditions') }}
    where clinical_semantic_tag = 'disorder'

),

enriched as (

    select
        condition_id,
        patient_id,
        encounter_id,
        snomed_concept_code,
        condition_name,
        clinical_semantic_tag,
        condition_start_date,
        condition_end_date,
        is_active_condition,

        datediff(
            'day',
            condition_start_date,
            coalesce(condition_end_date, current_date())
        )                                               as condition_duration_days,

        year(condition_start_date)                      as condition_onset_year

    from conditions

),

final as (

    select * from enriched

)

select * from final
