with creation_events as (
    select
        deal_id,
        min(field_value::timestamp) as event_at,
        'Lead Generation' as kpi_name,
        '1' as funnel_step
    from {{ ref('stg_deal_changes') }}
    where field_name = 'add_time'
      and field_value ~ '^\d{4}-\d{2}-\d{2}T'
    group by deal_id
),

stage_events as (
    select
        c.deal_id,
        c.changed_at as event_at,
        s.stage_name as kpi_name,
        s.stage_id::text as funnel_step
    from {{ ref('stg_deal_changes') }} c
    inner join {{ ref('stg_stages') }} s
        on c.field_value = s.stage_id::text
    where c.field_name = 'stage_id'
      and s.stage_id > 1
)

select * from creation_events

union all

select * from stage_events
