select
    month,
    funnel_step
from {{ ref('rep_sales_funnel_monthly') }}
group by month, funnel_step
having count(*) > 1
