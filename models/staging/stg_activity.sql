
with source as (

    select *
    from {{ source('pipedrive', 'activity') }}

),

deduplicated as (

    select distinct
        activity_id,
        type,
        assigned_to_user,
        deal_id,
        done,
        due_to
    from source

),

renamed as (

    select
        activity_id,
        type as activity_type,
        assigned_to_user as user_id,
        deal_id,
        done as is_completed,
        due_to as due_at
    from deduplicated

)

select *
from renamed