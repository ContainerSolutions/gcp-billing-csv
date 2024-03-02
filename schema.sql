drop table cost;
drop table project;
drop table service;
drop table sku;

create table project (
    project_id text primary key,
    project_name text not null,
    project_hierarchy text not null
);

create table service (
    service_id text primary key,
    service_name text not null
);

create table sku (
    sku_id text primary key,
    sku_name text
);

create table cost (
    cost_id serial primary key,
    credit_type text,
    cost_type text,
    usage_start_date date not null,
    usage_end_date date not null,
    usage_amount decimal(15,2),
    usage_unit text,
    project_id text references project(project_id),
    service_id text references service(service_id),
    sku_id text references sku(sku_id),
    unrounded_cost decimal(15, 2) not null,
    cost decimal(15, 2) not null,
    invoice_date date not null,
    constraint cost_cost_unique unique (credit_type,cost_type,usage_start_date,usage_end_date,project_id,service_id,sku_id)
);

