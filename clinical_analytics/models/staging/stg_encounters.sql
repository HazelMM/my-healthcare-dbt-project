-- grain: one row per clinical encounter per patient
with source as (

    select * from {{ source('synthea', 'encounters') }}

),

renamed as (

    select
        -- primary key
        id                                  as encounter_id,

        -- foreign keys
        patient                             as patient_id,

        -- encounter identity
        encounterclass                      as encounter_class,
        code                                as encounter_code,
        description                         as encounter_type_description,

        -- timeline
        start_time::timestamp_ntz           as encounter_start_datetime,
        stop::timestamp_ntz                 as encounter_end_datetime,
        stop is not null                    as is_completed,

        -- reason for visit
        reasoncode                          as reason_code,
        reasondescription                   as encounter_reason_description

    from source

),

final as (

    select * from renamed

)

select * from final
