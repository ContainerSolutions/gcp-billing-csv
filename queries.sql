\! echo "============================================="
\! echo "All-time service and project ordered by cost > x"
\! echo "============================================="
select
  sum(c.cost),
  s.service_name,
  p.project_name
from
  cost c,
  project p,
  service s
where
  c.project_id = p.project_id and
  s.service_id = c.service_id
group by
  2,3
having
  sum(c.cost) > 10
order by
  1;


\! echo "============================================="
\! echo "All-time service ordered by cost > x"
\! echo "============================================="
select
  sum(c.cost),
  s.service_name
from
  cost c,
  service s
where
  s.service_id = c.service_id
group by
  s.service_name
having
  sum(c.cost) > 10
order by
  1;



\! echo "============================================="
\! echo "Cost per month"
\! echo "============================================="
select date_trunc('month', c.invoice_date) as month, sum(c.cost) as monthly_cost
from cost c
group by month
order by month;

\! echo "============================================="
\! echo "Cost per month trend per project"
\! echo "============================================="
select p.project_name, date_trunc('month', c.invoice_date) as month, sum(c.cost) as total_cost
from cost c
join project p on c.project_id = p.project_id
group by p.project_name, month
order by p.project_name, month;


\! echo "============================================="
\! echo "Cost per month trend per service"
\! echo "============================================="
select s.service_name, date_trunc('month', c.invoice_date) as month, sum(c.cost) as service_cost
from cost c
join service s on c.service_id = s.service_id
group by s.service_name, month
order by s.service_name, month;


\! echo "============================================="
\! echo "Cost per month trend per sku"
\! echo "============================================="
select sku.sku_name, date_trunc('month', c.invoice_date) as month, sum(c.usage_amount) as total_usage, sum(c.cost) as total_cost
from cost c
join sku on c.sku_id = sku.sku_id
group by sku.sku_name, month
order by sku.sku_name, month;


\! echo "============================================="
\! echo "Cost per month trend for specific project"
\! echo "============================================="
select s.service_name, date_trunc('month', c.invoice_date) as month, sum(c.cost) as total_cost
from cost c
join service s on c.service_id = s.service_id
where c.project_id = 'container-solutions-finance'
group by s.service_name, month
order by s.service_name, month;





\! echo "============================================="
\! echo "Savings through credits"
\! echo "============================================="
select credit_type, sum(c.cost) as saved_cost
from cost c
where c.credit_type is not null
group by credit_type
order by saved_cost desc;


\! echo "============================================="
\! echo "Usage and costs of skus"
\! echo "============================================="
select sku.sku_name, sum(c.usage_amount) as total_usage, sum(c.cost) as total_cost
from cost c
join sku on c.sku_id = sku.sku_id
group by sku.sku_name
order by total_cost desc;


\! echo "============================================="
\! echo "Project ordered by cost > x"
\! echo "============================================="
select
  sum(c.cost),
  p.project_name
from
  cost c,
  project p
where
  c.project_id = p.project_id
group by
  p.project_name
having
  sum(c.cost) > 10
order by
  1;


\! echo "============================================="
\! echo "All-time costs ordered by service and cost"
\! echo "============================================="
select
  c.invoice_date,
  c.cost,
  c.usage_amount,
  c.usage_unit,
  p.project_name,
  s.service_name
from
  cost c,
  project p,
  service s
where
  c.usage_amount is not null and
  p.project_id = c.project_id and
  s.service_id = c.service_id and
  c.cost > 0
order by
  c.cost desc,
  s.service_name
limit 10;


\! echo "============================================="
\! echo "Show growth over time per project+service+sku"
\! echo "============================================="
-- Can adapt to make specific to project/service
with cost_lag as (
  select
    c.cost_id,
    s.service_name,
    p.project_name,
    k.sku_name,
    c.invoice_date,
    c.credit_type,
    c.cost_type,
    c.sku_id,
    c.usage_unit,
    sum(cost) over (partition by c.project_id, c.service_id, c.sku_id, c.credit_type, c.cost_type order by c.invoice_date) as running_cost
  from
    cost c, service s, project p, sku k
  where
    c.service_id = s.service_id and
    c.project_id = p.project_id and
    c.sku_id = k.sku_id
  order by
    c.invoice_date,
    s.service_name,
    p.project_name,
    k.sku_name
)
select
  *
from
  cost_lag
where
  running_cost > 10
order by
  running_cost desc
limit 100;


\! echo "============================================="
\! echo "Compare costs with previous month, showing any percentage change greater than x"
\! echo "============================================="
with cost_lag as (
  select
    c.cost_id,
    s.service_name,
    p.project_name,
    k.sku_name,
    c.invoice_date,
    c.cost,
    lag(cost) over (partition by c.project_id, c.service_id, c.sku_id order by c.invoice_date) as previous_month_running_costs
  from
    cost c, service s, project p, sku k
  where
    c.service_id = s.service_id and
    c.project_id = p.project_id and
    c.sku_id = k.sku_id
),
percent_change as (
  select
    *,
    coalesce(round((cost - previous_month_running_costs) / coalesce(nullif(previous_month_running_costs,0), 1) * 100),0) as percent_change
  from
    cost_lag
)
select
  *
from
  percent_change
where
  percent_change > 0
order by
  percent_change desc
limit 10;


\! echo "============================================="
\! echo "As above, but per project"
\! echo "============================================="
with cost_per_service as (
  select
    sum(cost) as cost,
    project_id,
    invoice_date
  from
    cost
  group by
    2,3
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
  cost,
  project_name,
  invoice_date,
  previous_month_running_costs,
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


\! echo "============================================="
\! echo "As above, but per service"
\! echo "============================================="
with cost_per_project as (
  select
    sum(cost) as cost,
    service_id,
    invoice_date
  from
    cost
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
    cost,
    service_name,
    invoice_date,
    previous_month_running_costs,
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
