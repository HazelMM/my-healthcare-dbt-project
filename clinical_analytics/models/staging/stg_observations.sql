-- grain: one row per observation reading per patient (patient + encounter + code + date + value)
with source as (

    select * from {{ source('synthea', 'observations') }}

),

deduped as (

    -- true duplicate rows exist in the source; remove before any transformation
    select distinct * from source

),

renamed as (

    select
        -- surrogate key (value included: same code can produce multiple readings per encounter, e.g. SNOMED qualifier hierarchies)
        {{ dbt_utils.generate_surrogate_key(['patient', 'encounter', 'code', 'date', 'value']) }} as observation_id,

        -- foreign keys
        patient                                                                              as patient_id,
        encounter                                                                            as encounter_id,

        -- observation identity
        date::date                                                                           as observation_date,
        category                                                                             as observation_category,
        code                                                                                 as observation_code,
        description                                                                          as observation_name,

        -- measurement
        value                                                                                as raw_value,
        try_to_number(value)                                                                 as observation_value_numeric,
        units                                                                                as observation_unit,
        type                                                                                 as value_type

    from deduped

),

final as (

    select * from renamed

)

select * from final
