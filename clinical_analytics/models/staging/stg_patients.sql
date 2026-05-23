-- grain: one row per patient
with source as (

    select * from {{ source('synthea', 'patients') }}

),

renamed as (

    select
        -- primary key
        id                      as patient_id,

        -- identity
        first                   as first_name,
        last                    as last_name,

        -- demographics
        birthdate::date         as birth_date,
        deathdate::date         as death_date,
        deathdate is not null   as is_deceased,
        gender,
        race,
        ethnicity,
        marital                 as marital_status,

        -- geographic context
        birthplace,
        city,
        county,
        state

    from source

),

final as (

    select * from renamed

)

select * from final
