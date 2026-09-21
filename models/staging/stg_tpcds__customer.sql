{#
    Customer master, renamed and typed. Roughly 65 million rows at the 10 TB
    scale factor.

    The birth date arrives as three separate integer columns rather than a date.
    Assembling them is business logic, so it happens in dim_customer, not here.
#}

with source as (

    select * from {{ source('tpcds', 'customer') }}

),

renamed as (

    select
        -- keys
        c_customer_sk           as customer_key,
        c_customer_id           as customer_id,
        c_current_cdemo_sk      as customer_demographics_key,
        c_current_hdemo_sk      as household_demographics_key,
        c_current_addr_sk       as customer_address_key,

        -- name
        c_salutation            as salutation,
        c_first_name            as first_name,
        c_last_name             as last_name,

        -- contact
        c_email_address         as email_address,
        c_login                 as login_name,

        -- attributes
        c_preferred_cust_flag   as preferred_customer_flag,
        c_birth_day             as birth_day_of_month,
        c_birth_month           as birth_month_of_year,
        c_birth_year            as birth_year,
        c_birth_country         as birth_country_name,

        -- lifecycle date keys
        c_first_sales_date_sk   as first_sales_date_key,
        c_first_shipto_date_sk  as first_ship_to_date_key,
        c_last_review_date_sk   as last_review_date_key

    from source

)

select * from renamed
