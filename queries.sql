-- service and project ordered by cost
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
group by 2,3
having
  sum(c.cost) > 0
order by 1;


-- service ordered by cost
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
  sum(c.cost) > 0
order by
  1;

-- project ordered by cost
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
  sum(c.cost) > 0
order by
  1;


--
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
  s.service_name,
  c.cost;


-- Show growth over time per project+service+sku
-- Can adapt to make specific to project/service
select
  c.cost_id,
  s.service_name,
  p.project_name,
  k.sku_name,
  c.invoice_date,
  sum(cost) over (partition by c.project_id, c.service_id, c.sku_id order by c.invoice_date) AS running_cost
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
  k.sku_name;


-- Compare costs with previous month, showing any percentage change greater than x
with cost_lag AS (
  select
    c.cost_id,
    s.service_name,
    p.project_name,
    k.sku_name,
    c.invoice_date,
    c.cost,
    lag(cost) over (partition by c.project_id, c.service_id, c.sku_id order by c.invoice_date) AS previous_month_running_costs
  from
    cost c, service s, project p, sku k
  where
    c.service_id = s.service_id and
    c.project_id = p.project_id and
    c.sku_id = k.sku_id and
    c.cost > 1
),
percent_change as (
  select
    *,
    coalesce(round((cost - previous_month_running_costs) / coalesce(nullif(previous_month_running_costs,0), 1) * 100),0) AS percent_change
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
  percent_change;



-- As above, but just for project
with cost_lag AS (
  select
    c.cost_id,
    p.project_name,
    c.invoice_date,
    c.cost,
    lag(cost) over (partition by c.project_id order by c.invoice_date) AS previous_month_running_costs
  from
    cost c, project p
  where
    c.project_id = p.project_id and
    c.cost > 1
),
percent_change as (
  select
    *,
    coalesce(round((cost - previous_month_running_costs) / coalesce(nullif(previous_month_running_costs,0), 1) * 100),0) AS percent_change
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
  percent_change;



-- As above but for service
with cost_lag AS (
  select
    c.cost_id,
    s.service_name,
    c.invoice_date,
    c.cost,
    lag(cost) over (partition by c.service_id order by c.invoice_date) AS previous_month_running_costs
  from
    cost c, service s
  where
    c.service_id = s.service_id and
    c.cost > 1
),
percent_change as (
  select
    *,
    coalesce(round((cost - previous_month_running_costs) / coalesce(nullif(previous_month_running_costs,0), 1) * 100),0) AS percent_change
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
  percent_change;


