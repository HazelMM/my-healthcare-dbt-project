-- grain: one row per patient per spine_month per observation
with conditions as (

    select * from {{ ref('int_condition_disorders') }}

),

encounter_summary as (

    select * from {{ ref('int_patient_encounter_summary') }}

),

observations as (

    select * from {{ ref('int_observation_trend') }}

),

patient_bounds as (

    select
        cd.patient_id,
        date_trunc('month', min(cd.condition_start_date))               as spine_start,
        date_trunc('month', coalesce(es.death_date, current_date()))    as spine_end

    from conditions as cd
    left join encounter_summary as es
        on cd.patient_id = es.patient_id

    group by cd.patient_id, es.death_date

),

monthly_calendar as (

    {{ dbt_utils.date_spine(
        datepart="month",
        start_date="cast('1990-01-01' as date)",
        end_date="cast(current_date() as date)"
    ) }}

),

patient_spine as (

    select
        pb.patient_id,
        cal.date_month::date                                            as spine_month

    from patient_bounds as pb
    inner join monthly_calendar as cal
        on cal.date_month between pb.spine_start and pb.spine_end

),

joined as (

    select
        ps.patient_id,
        ps.spine_month,

        es.gender,
        es.race,
        es.ethnicity,
        datediff('year', es.birth_date, ps.spine_month)                as age_at_month,
        es.is_deceased,
        es.death_date,

        es.total_encounters,
        es.ambulatory_encounter_count,
        es.wellness_encounter_count,
        es.emergency_encounter_count,
        es.inpatient_encounter_count,

        obs.observation_date,
        obs.observation_code,
        obs.observation_name,
        obs.observation_value_numeric,
        obs.observation_unit,
        obs.range_low,
        obs.range_high,
        obs.distance_from_normal,
        obs.range_status,
        obs.trend_status

    from patient_spine as ps
    left join observations as obs
        on ps.patient_id = obs.patient_id
        and obs.observation_month = ps.spine_month
    left join encounter_summary as es
        on ps.patient_id = es.patient_id

),

final as (

    select * from joined

)

select * from final
