-- grain: one row per patient who has at least one disorder-tagged condition
with cohort as (

    select distinct patient_id
    from {{ ref('int_condition_disorders') }}

),

final as (

    select * from cohort

)

select * from final
