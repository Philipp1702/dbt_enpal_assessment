with checks as (

    -- 1. All 11 funnel steps exist
    select
        '01_all_funnel_steps' as test_name,
        (select count(distinct funnel_step)
         from {{ ref('rep_sales_funnel_monthly') }}) = 11 as passed

    union all

    -- 2. All 1,995 leads accounted for
    select
        '02_lead_generation_count',
        (select coalesce(sum(deals_count), 0)
         from {{ ref('rep_sales_funnel_monthly') }}
         where funnel_step = '1') = 1995

    union all

    -- 3. No duplicate monthly funnel rows
    select
        '03_unique_monthly_funnel',
        not exists (
            select 1
            from {{ ref('rep_sales_funnel_monthly') }}
            group by month, funnel_step
            having count(*) > 1
        )

    union all

    -- 4. No null values in reporting
    select
        '04_no_null_values',
        not exists (
            select 1
            from {{ ref('rep_sales_funnel_monthly') }}
            where month is null
               or kpi_name is null
               or funnel_step is null
               or deals_count is null
        )

    union all

    -- 5. All deal counts are positive
    select
        '05_positive_deal_counts',
        not exists (
            select 1
            from {{ ref('rep_sales_funnel_monthly') }}
            where deals_count <= 0
        )

    union all

    -- 6. Exactly one creation event per deal
    select
        '06_unique_lead_creation',
        not exists (
            select 1
            from {{ ref('int_deal_stage_events') }}
            where funnel_step = '1'
            group by deal_id
            having count(*) <> 1
        )
        and (
            select count(*)
            from {{ ref('int_deal_stage_events') }}
            where funnel_step = '1'
        ) = (
            select count(distinct deal_id)
            from {{ ref('stg_deal_changes') }}
            where field_name = 'add_time'
        )

    union all

    -- 7. No unfinished sales calls included
    select
        '07_completed_sales_calls',
        not exists (
            select 1
            from {{ ref('int_sales_call_events') }} e
            where not exists (
                select 1
                from {{ ref('stg_activity') }} a
                where a.deal_id = e.deal_id
                  and a.due_at = e.event_at
                  and a.is_completed = true
                  and (
                      (e.funnel_step = '2.1' and a.activity_type = 'meeting')
                      or
                      (e.funnel_step = '3.1' and a.activity_type = 'sc_2')
                  )
            )
        )

    union all

    -- 8. Intermediate event count reconciles
    select
        '08_intermediate_event_count',
        (select count(*) from {{ ref('int_funnel_events') }})
        =
        (select count(*) from {{ ref('int_deal_stage_events') }})
        +
        (select count(*) from {{ ref('int_sales_call_events') }})

    union all

    -- 9. Reporting agrees with intermediate events
    select
        '09_reporting_reconciliation',
        not exists (
            select
                date_trunc('month', event_at)::date as month,
                funnel_step,
                count(distinct deal_id) as deals_count
            from {{ ref('int_funnel_events') }}
            where event_at is not null
              and deal_id is not null
            group by 1, 2

            except

            select month, funnel_step, deals_count
            from {{ ref('rep_sales_funnel_monthly') }}
        )
        and not exists (
            select month, funnel_step, deals_count
            from {{ ref('rep_sales_funnel_monthly') }}

            except

            select
                date_trunc('month', event_at)::date as month,
                funnel_step,
                count(distinct deal_id) as deals_count
            from {{ ref('int_funnel_events') }}
            where event_at is not null
              and deal_id is not null
            group by 1, 2
        )

    union all

    -- 10. All reporting months are normalized
    select
        '10_month_start_dates',
        not exists (
            select 1
            from {{ ref('rep_sales_funnel_monthly') }}
            where month <> date_trunc('month', month)::date
        )

    union all

    -- 11. Exactly 9 configured sales stages
    select
        '11_stage_reference_integrity',
        (select count(*) from {{ ref('stg_stages') }}) = 9

    union all

    -- 12. No unrecognized funnel steps
    select
        '12_valid_funnel_steps',
        not exists (
            select 1
            from {{ ref('rep_sales_funnel_monthly') }}
            where funnel_step not in (
                '1', '2', '2.1', '3', '3.1',
                '4', '5', '6', '7', '8', '9'
            )
        )
)

select test_name
from checks
where not coalesce(passed, false)
