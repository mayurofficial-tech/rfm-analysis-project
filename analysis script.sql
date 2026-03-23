-- step 1 appen all monthly sales table togather

create or replace table `rfm-analysis-490805.sales.sales_2025` AS
select * from `rfm-analysis-490805.sales.sales202501`
union all select * from `rfm-analysis-490805.sales.sales202502`
union all select * from `rfm-analysis-490805.sales.sales202503`
union all select * from `rfm-analysis-490805.sales.sales202504`
union all select * from `rfm-analysis-490805.sales.sales202505`
union all select * from `rfm-analysis-490805.sales.sales202506`
union all select * from `rfm-analysis-490805.sales.sales202507`
union all select * from `rfm-analysis-490805.sales.sales202508`
union all select * from `rfm-analysis-490805.sales.sales202509`
union all select * from `rfm-analysis-490805.sales.sales202510`
union all select * from `rfm-analysis-490805.sales.sales202511`
union all select * from `rfm-analysis-490805.sales.sales202512_clean`;


select * from `rfm-analysis-490805.sales.sales_2025`;

-- step 2: calculate revency, frequency,monetary, r ,f, m ranks
-- combine views with ctcs
create or replace view `rfm-analysis-490805.sales.rfm_metrics`
as 
with current_date as(
    select date('2026-03-20') as analysis_date -- today's date
),
rfm as (
  select
    CustomerID,
    max(OrderDate) as last_order_date,
    date_diff((select analysis_date from current_date),max(OrderDate),day) as recency,
    count(*) as frequency,
    sum(OrderValue) as monetary
  from `rfm-analysis-490805.sales.sales_2025`
  group by Customerid
)
select
rfm.*,
row_number() over(order by recency asc) as r_rank,
row_number() over(order by frequency desc) as f_rank,
row_number() over(order by monetary desc) as m_rank
from rfm;
 
-- step 3: Assing deciles (10=bast, 1=worst)
create or replace view `rfm-analysis-490805.sales.rfm_scores`
as
select
  *,
  ntile(10) over(order by r_rank desc) as r_scores,
  ntile(10) over(order by f_rank desc) as f_scores,
  ntile(10) over(order by m_rank desc) as m_scores
from `rfm-analysis-490805.sales.rfm_metrics`;

-- step 4 : total score
create or replace view `rfm-analysis-490805.sales.total_scores`
as
select
  *,
  (r_scores+f_scores+m_scores) as rfm_total_Scores
from `rfm-analysis-490805.sales.rfm_scores`
order by rfm_total_scores desc;

-- step 5 Bi ready rfm sqgments table

create or replace table `rfm-analysis-490805.sales.rfm_segments_final`
as 
select
  *,
  case
    when rfm_total_Scores >=28 THEN 'Champions'
    when rfm_total_Scores >=24 THEN 'loyal VIPs'
    when rfm_total_Scores >=20 THEN 'Postential Loyalists'
    when rfm_total_Scores >=16 THEN 'Promising'
    when rfm_total_Scores >=12 THEN 'Engaged'
    when rfm_total_Scores >=8 THEN 'Requires Attention'
    when rfm_total_Scores >=4 THEN 'At Risk'
    else 'lost/Inactive'
  end as rfm_segment
from `rfm-analysis-490805.sales.total_scores`
order by rfm_total_Scores desc;























