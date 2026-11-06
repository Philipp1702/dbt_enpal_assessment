with monthly_funnel as (
    select
        date_trunc('month', event_at)::date as month,
        kpi_name,
        funnel_step,
        count(distinct deal_id) as deals_count
    from {{ ref('int_funnel_events') }}
    where event_at is not null
      and deal_id is not null
    group by 1, 2, 3
)

select
    month,
    kpi_name,
    funnel_step,
    deals_count
from monthly_funnel
