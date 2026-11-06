select *
from {{ ref('rep_sales_funnel_monthly') }}
where deals_count <= 0
