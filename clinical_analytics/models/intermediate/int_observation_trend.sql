-- grain: one row per observation event per patient, inherited from int_observation_clinical
with clinical as (

    select * from {{ ref('int_observation_clinical') }}

),

with_lag as (

    select
        *,

        lag(distance_from_normal) over (
            partition by patient_id, observation_code
            order by observation_date
        )                                                               as prev_distance_from_normal

    from clinical

),

with_trend as (

    select
        * exclude (prev_distance_from_normal),

        case
            when distance_from_normal is null
                 or prev_distance_from_normal is null                   then null
            when distance_from_normal = 0
                 and prev_distance_from_normal != 0                     then 'normalized'
            when abs(distance_from_normal)
                 > abs(prev_distance_from_normal)                       then 'worsening'
            when abs(distance_from_normal)
                 < abs(prev_distance_from_normal)                       then 'improving'
            else                                                             'stable'
        end                                                             as trend_status

    from with_lag

),

final as (

    select * from with_trend

)

select * from final
