with source as (

    select *
    from {{ source('pipedrive', 'deal_changes') }}

),

deduplicated as (

    select distinct
        deal_id,
        change_time,
        changed_field_key,
        new_value
    from source

),

renamed as (

    select
        deal_id,
        change_time as changed_at,
        changed_field_key as field_name,
        new_value as field_value
    from deduplicated

)

select *
from renamed