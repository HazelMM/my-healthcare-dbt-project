-- grain: one row per encounter per patient, inherited from stg_encounters
with encounters as (

    select * from {{ ref('stg_encounters') }}

),

enriched as (

    select
        encounter_id,
        patient_id,
        encounter_class,
        encounter_code,
        encounter_type_description,
        encounter_start_datetime,
        encounter_end_datetime,
        is_completed,
        reason_code,
        encounter_reason_description,

        datediff(
            'minute',
            encounter_start_datetime,
            encounter_end_datetime
        )                                                               as encounter_duration_minutes,

        month(encounter_start_datetime)                                 as encounter_month,

        datediff(
            'day',
            lag(encounter_start_datetime) over (
                partition by patient_id
                order by encounter_start_datetime
            ),
            encounter_start_datetime
        )                                                               as days_since_last_encounter

    from encounters

),

final as (

    select * from enriched

)

select * from final
