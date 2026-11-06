select
    deal_id,
    event_at,
    kpi_name,
    funnel_step
from {{ ref('int_deal_stage_events') }}

union all

select
    deal_id,
    event_at,
    kpi_name,
    funnel_step
from {{ ref('int_sales_call_events') }}
