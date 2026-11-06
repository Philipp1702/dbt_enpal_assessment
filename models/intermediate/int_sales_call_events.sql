select
    a.deal_id,
    a.due_at as event_at,
    t.activity_type_name as kpi_name,
    case
        when a.activity_type = 'meeting' then '2.1'
        when a.activity_type = 'sc_2' then '3.1'
    end as funnel_step
from {{ ref('stg_activity') }} a
inner join {{ ref('stg_activity_types') }} t
    on a.activity_type = t.activity_type
where a.is_completed = true
  and a.activity_type in ('meeting', 'sc_2')
  and a.deal_id is not null
  and a.due_at is not null
