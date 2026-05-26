-- grain: one row per encounter per patient, inherited from stg_encounters
with encounters as (

    select * from {{ ref('stg_encounters') }}

),

patients as (

    select * from {{ ref('stg_patients') }}

),

enriched as (

    select
        e.encounter_id,
        e.patient_id,
        e.encounter_class,
        e.encounter_code,
        e.encounter_type_description,
        e.encounter_start_datetime,
        e.encounter_end_datetime,
        e.is_completed,
        e.reason_code,
        e.encounter_reason_description,

        p.gender,
        p.race,
        p.ethnicity,
        p.birth_date,
        p.is_deceased,
        p.death_date,

        datediff(
            'minute',
            e.encounter_start_datetime,
            e.encounter_end_datetime
        )                                                               as encounter_duration_minutes,

        month(e.encounter_start_datetime)                               as encounter_month,

        datediff(
            'day',
            lag(e.encounter_start_datetime) over (
                partition by e.patient_id
                order by e.encounter_start_datetime
            ),
            e.encounter_start_datetime
        )                                                               as days_since_last_encounter

    from encounters as e
    left join patients as p
        on e.patient_id = p.patient_id

),

final as (

    select * from enriched

)

select * from final
