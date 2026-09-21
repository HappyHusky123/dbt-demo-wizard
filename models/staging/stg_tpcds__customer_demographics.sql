{#
    Demographic attribute combinations, renamed and typed. Roughly 1.9 million
    rows, one per unique combination of the attributes below.

    This is a snowflaked dimension. Customer does not hold gender or marital
    status directly, it holds a key into this table, which is why dim_customer
    needs a second join to reach them.
#}

with source as (

    select * from {{ source('tpcds', 'customer_demographics') }}

),

renamed as (

    select
        cd_demo_sk              as customer_demographics_key,
        cd_gender               as gender_code,
        cd_marital_status       as marital_status_code,
        cd_education_status     as education_status,
        cd_credit_rating        as credit_rating,
        cd_purchase_estimate    as annual_purchase_estimate,
        cd_dep_count            as dependent_count,
        cd_dep_employed_count   as employed_dependent_count,
        cd_dep_college_count    as college_dependent_count

    from source

)

select * from renamed
