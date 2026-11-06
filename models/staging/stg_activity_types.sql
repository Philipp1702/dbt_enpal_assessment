with source as (

    select *
    from {{ source('pipedrive', 'activity_types') }}

),

renamed as (

    select
        id as activity_type_id,
        name as activity_type_name,
        type as activity_type,
        case
            when lower(trim(active)) = 'yes' then true
            when lower(trim(active)) = 'no' then false
            else null
        end as is_active

    from source

)

select *
from renamed