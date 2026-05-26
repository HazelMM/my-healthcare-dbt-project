-- grain: one row per patient, cumulative encounter counts as of last refresh
with encounters as (

    select * from {{ ref('int_encounter_enriched') }}

),

patient_summary as (

    select
        patient_id,
        max(gender)                                                                     as gender,
        max(race)                                                                       as race,
        max(ethnicity)                                                                  as ethnicity,
        max(birth_date)                                                                 as birth_date,
        max(is_deceased)                                                                as is_deceased,
        max(death_date)                                                                 as death_date,
        count(*)                                                                        as total_encounters,
        count(case when encounter_class = 'ambulatory'  then 1 end)                    as ambulatory_encounter_count,
        count(case when encounter_class = 'wellness'    then 1 end)                    as wellness_encounter_count,
        count(case when encounter_class = 'emergency'   then 1 end)                    as emergency_encounter_count,
        count(case when encounter_class = 'inpatient'  then 1 end)                    as inpatient_encounter_count,
        max(encounter_start_datetime)::date                                             as last_encounter_date

    from encounters

    group by patient_id

),

final as (

    select * from patient_summary

)

select * from final
