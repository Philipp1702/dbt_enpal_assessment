select
    activity_id,
    deal_id,
    count(*) as occurrences
from {{ ref('stg_activity') }}
group by
    activity_id,
    deal_id
having count(*) > 1
