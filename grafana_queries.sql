-- percent change cost by service
with cost_per_project as (
  select
    sum(cost) as cost,
    service_id,
    invoice_date
  from
    cost
  where
    cost > 10 -- only consider services where the cost is > 10
  group by
    2,3
),
lag_cost_per_project as (
select
  cost,
  service_id,
  invoice_date,
  lag(cost) over (partition by service_id order by invoice_date) as previous_month_running_costs
from
  cost_per_project
),
service_percent_change as (
select
    *,
    coalesce(round((cost - previous_month_running_costs) / coalesce(nullif(previous_month_running_costs,0), 1) * 100),0) as percent_change
  from
    lag_cost_per_project
)
select
    service_name,
    percent_change
from
  service_percent_change c, service s
where
  s.service_id = c.service_id and
  c.percent_change > 0 and
  c.invoice_date = '2024-01-31'
order by
  c.percent_change desc
limit 10;


with cost_per_service as (
  select
    sum(cost) as cost,
    project_id,
    invoice_date
  from
    cost
  where
    cost > 10 -- only consider projects where the cost is > 10
  group by 2,3
),
lag_cost_per_service as (
select
  cost,
  project_id,
  invoice_date,
  lag(cost) over (partition by project_id order by invoice_date) as previous_month_running_costs
from
  cost_per_service
),
project_percent_change as (
select
    *,
    coalesce(round((cost - previous_month_running_costs) / coalesce(nullif(previous_month_running_costs,0), 1) * 100),0) as percent_change
  from
    lag_cost_per_service
)
select
  project_name,
  percent_change
from
  project_percent_change c,
  project p
where
  c.project_id = p.project_id and
  c.percent_change > 0 and
  c.invoice_date = '2024-01-31'
order by
  c.percent_change desc
limit 10;
