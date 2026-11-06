# Enpal – Analytics Engineering Take-Home

## Overview

The goal was to build a monthly sales funnel report based on Pipedrive CRM data using PostgreSQL and dbt.

I used a fairly simple dbt structure with staging, intermediate and reporting models. The idea was to keep the data preparation separate from the actual business logic, making it easier to understand and troubleshoot later.

The final output is `rep_sales_funnel_monthly`, which shows the number of deals per month and funnel step.

## Data Exploration

I started by looking at the six available Pipedrive tables:

- `activity` and `activity_types` for sales calls
- `deal_changes` for historical deal movements
- `stages` for the funnel structure
- `fields` and `users` for additional context

The most useful table turned out to be `deal_changes`, since it contains historical changes rather than just the current status of a deal.

A few things stood out during the analysis:

- Some records were duplicated, so I added deduplication in staging.
- Deal creation timestamps were not always consistent. I used the earliest valid `add_time` per deal.
- Sales activities and historical stage changes could not always be directly matched.
- For the monthly funnel, I decided to work with historical events rather than current deal statuses.

## Data Modeling

I split the project into three layers.

### Staging

This is where I read the raw PostgreSQL tables, select the relevant columns, remove duplicates and clean up column names.

I kept the transformations fairly simple here.

### Intermediate

This is where most of the actual logic happens.

I created separate models for historical deal movements and sales calls:

- `int_deal_stage_events` identifies deal creation and stage changes.
- `int_sales_call_events` extracts completed sales calls.
- `int_funnel_events` combines both into one event dataset.

For deal creation, I used the earliest available timestamp. For stage changes, I joined the historical changes with the stage definitions.

For sales calls, I used the activity types `meeting` and `sc_2` to represent Sales Call 1 and Sales Call 2.

### Reporting

The final model is `rep_sales_funnel_monthly`.

It groups events by month, KPI and funnel step and uses `COUNT(DISTINCT deal_id)` to avoid counting the same deal multiple times within the same KPI and month.

The output contains:

- `month`
- `kpi_name`
- `funnel_step`
- `deals_count`

## Testing

I added dbt tests and a few custom SQL checks to validate the data and reporting logic.

These cover things like duplicate IDs, missing values, funnel step mappings and consistency between intermediate models and the final report.

I also included additional checks in `tests/assert_final_assessment.sql`.

## Assumptions and Limitations

There are a few things worth mentioning:

- The report counts historical funnel events, not the number of deals sitting in each stage at the end of a month.
- Sales calls are assigned to months based on `due_at`, which is the scheduled date rather than the actual completion time.
- The mapping of `meeting` and `sc_2` to the two sales call steps is based on the available activity types.
- Some historical deal changes and sales activities do not have matching deal references, which limits how accurately the full customer journey can be reconstructed.
- The expected lead count of 1,995 is specific to the provided dataset.

With a larger production dataset, I would probably revisit some of these assumptions and make the validation checks more dynamic.

## Running the Project

Start the PostgreSQL database:

```bash
docker compose up -d
```

Install dbt if needed:

```bash
pip install dbt-core dbt-postgres
```

Make sure the local dbt profile is configured for the PostgreSQL database.

Check the connection:

```bash
dbt debug
```

Run the models and tests:

```bash
dbt build
```

Generate the dbt documentation if needed:

```bash
dbt docs generate
dbt docs serve
```

## Final Notes

I tried to keep the solution straightforward rather than overengineering it.

The main focus was understanding the source data, building a reasonable event-based funnel model and making the individual transformation steps easy to follow.

There are some limitations in the source data, especially around historical events and sales activities, but I think the current approach provides a useful basis for monthly funnel reporting.