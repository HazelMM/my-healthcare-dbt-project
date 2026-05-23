-- grain: one row per patient, aggregated across all disorder-tagged condition episodes
with conditions as (

    select * from {{ ref('int_condition_disorders') }}

),

patient_summary as (

    select
        patient_id,
        count(*)                                                as total_disorder_count,
        sum(case when is_active_condition then 1 else 0 end)    as active_disorder_count,
        min(condition_start_date)                               as first_disorder_date,
        max(condition_start_date)                               as most_recent_disorder_date

    from conditions

    group by patient_id

),

final as (

    select * from patient_summary

)

select * from final
