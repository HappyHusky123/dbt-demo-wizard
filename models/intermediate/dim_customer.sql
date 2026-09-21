{#
    Conformed customer dimension.

    TPC-DS snowflakes the customer attributes anyone actually wants to slice by:
    gender and marital status sit behind customer_demographics, and location
    sits behind customer_address. This model flattens all three into one row per
    customer so the DATA_VIZ layer never has to know that.

    Both joins are left joins. A customer with a null demographics key is a real
    thing in the benchmark, and an inner join here would quietly delete those
    customers from every downstream total.

    Age is deliberately banded by birth year rather than calculated against
    current_date. A model whose output changes every night is a model whose
    tests fail for no reason, and TPC-DS data is fixed in the early 2000s.
#}

with customers as (

    select * from {{ ref('stg_tpcds__customer') }}

),

addresses as (

    select * from {{ ref('stg_tpcds__customer_address') }}

),

demographics as (

    select * from {{ ref('stg_tpcds__customer_demographics') }}

),

final as (

    select
        -- keys
        customers.customer_key,
        customers.customer_id,
        customers.customer_address_key,
        customers.customer_demographics_key,

        -- name
        customers.salutation,
        customers.first_name,
        customers.last_name,
        trim(
            coalesce(customers.first_name, '') || ' ' || coalesce(customers.last_name, '')
        )                                                       as full_name,

        -- contact
        customers.email_address,
        customers.email_address is not null                      as has_email_address,
        customers.preferred_customer_flag = 'Y'                  as is_preferred_customer,

        -- birth details. try_to_date returns null rather than erroring on the
        -- invalid combinations the generator produces, such as 31 February.
        customers.birth_year,
        customers.birth_country_name,
        try_to_date(
            customers.birth_year || '-'
                || lpad(customers.birth_month_of_year, 2, '0') || '-'
                || lpad(customers.birth_day_of_month, 2, '0'),
            'YYYY-MM-DD'
        )                                                        as birth_date,

        case
            when customers.birth_year is null      then 'Unknown'
            when customers.birth_year >= 1977      then 'Gen X or later'
            when customers.birth_year >= 1946      then 'Baby Boomer'
            when customers.birth_year >= 1928      then 'Silent Generation'
            else 'Greatest Generation'
        end                                                      as generation_band,

        -- demographics
        demographics.gender_code,
        case demographics.gender_code
            when 'M' then 'Male'
            when 'F' then 'Female'
            else 'Unknown'
        end                                                      as gender,

        demographics.marital_status_code,
        case demographics.marital_status_code
            when 'M' then 'Married'
            when 'S' then 'Single'
            when 'D' then 'Divorced'
            when 'W' then 'Widowed'
            when 'U' then 'Unknown'
            else 'Unknown'
        end                                                      as marital_status,

        coalesce(demographics.education_status, 'Unknown')       as education_status,
        coalesce(demographics.credit_rating, 'Unknown')          as credit_rating,
        demographics.annual_purchase_estimate,
        demographics.dependent_count,

        -- spend segment, the primary slicer for rpt_customer_segment_sales
        case
            when demographics.annual_purchase_estimate is null  then 'Unknown'
            when demographics.annual_purchase_estimate >= 7500  then 'High Value'
            when demographics.annual_purchase_estimate >= 4000  then 'Mid Value'
            when demographics.annual_purchase_estimate >= 1500  then 'Low Value'
            else 'Minimal'
        end                                                      as customer_segment,

        -- location, from the customer's current address
        addresses.city_name,
        addresses.county_name,
        addresses.state_code,
        addresses.postal_code,
        addresses.country_name,

        -- lifecycle
        customers.first_sales_date_key,
        customers.last_review_date_key

    from customers
    left join addresses
        on customers.customer_address_key = addresses.customer_address_key
    left join demographics
        on customers.customer_demographics_key = demographics.customer_demographics_key

)

select * from final
