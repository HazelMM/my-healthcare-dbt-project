-- grain: one row per condition episode per patient
with source as (

    select * from {{ source('synthea', 'conditions') }}

),

renamed as (

    select
        -- primary key
        {{ dbt_utils.generate_surrogate_key(['patient', 'encounter', 'code', 'start_date']) }}
                                                                                    as condition_id,

        -- foreign keys
        patient                                                                     as patient_id,
        encounter                                                                   as encounter_id,

        -- condition identity
        code                                                                        as snomed_concept_code,
        trim(regexp_replace(description, '\\s*\\([^)]+\\)$', ''))                  as condition_name,
        nullif(regexp_substr(description, '\\(([^)]+)\\)$', 1, 1, 'e', 1), '')    as clinical_semantic_tag,

        -- episode timeline
        start_date::date                                                            as condition_start_date,
        stop_date::date                                                             as condition_end_date,
        stop_date is null                                                           as is_active_condition

    from source

),

final as (

    select * from renamed

)

select * from final
