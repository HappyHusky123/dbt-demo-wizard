{{ config(materialized='incremental') }}

select 
    eventid,
    date as measurement_date,
    gauge,
    depth
from {{ ref('stg_environmental__water_levels')}}

{% if is_incremental() %}
    where date > (select max(measurement_date) from {{ this }})
{% endif %}