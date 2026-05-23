-- grain: one row per observation event per patient, limited to observations with a matching entry in biomarker_reference_ranges
with observations as (

    select * from {{ ref('stg_observations') }}

),

reference_ranges as (

    -- deduplicate to one row per loinc_code; a small number of codes appear in multiple categories
    select *
    from {{ ref('biomarker_reference_ranges') }}
    qualify row_number() over (partition by loinc_code order by category) = 1

),

joined as (

    select
        obs.observation_id,
        obs.patient_id,
        obs.encounter_id,
        obs.observation_date,
        obs.observation_category,
        obs.observation_code,
        obs.observation_name,
        obs.raw_value,
        obs.observation_value_numeric,
        obs.observation_unit,
        obs.value_type,
        date_trunc('month', obs.observation_date) as observation_month,
        ref.range_low,
        ref.range_high,
        ref.notes                           as reference_notes

    from observations as obs
    inner join reference_ranges as ref
        on obs.observation_code = ref.loinc_code

),

with_distances as (

    select
        *,

        observation_value_numeric
            - lag(observation_value_numeric) over (
                partition by patient_id, observation_code
                order by observation_date
            )                                                           as value_delta,

        case
            when observation_unit = '{nominal}'                         then null
            when observation_value_numeric is null                      then null
            when range_low is null and range_high is null               then null
            when range_high is not null
                and observation_value_numeric > range_high
                then observation_value_numeric - range_high
            when range_low is not null
                and observation_value_numeric < range_low
                then observation_value_numeric - range_low
            else 0
        end                                                             as distance_from_normal

    from joined

),

with_indicators as (

    select
        *,

        case
            when observation_unit = '{nominal}'                         then null
            when observation_value_numeric is null                      then null
            when range_low is null and range_high is null               then null
            when range_high is not null
                and observation_value_numeric > range_high              then 'above_range'
            when range_low is not null
                and observation_value_numeric < range_low               then 'below_range'
            else                                                             'normal'
        end                                                             as range_status

    from with_distances

),

final as (

    select * from with_indicators

)

select * from final
