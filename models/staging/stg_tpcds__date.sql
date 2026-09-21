{#
    Conformed date dimension. Roughly 73,000 rows covering 1900 through 2100,
    so it is not filtered.

    The Y/N character flags are left as they arrive here. Converting them to
    booleans is business logic and belongs in CURATED.
#}

with source as (

    select * from {{ source('tpcds', 'date_dim') }}

),

renamed as (

    select
        d_date_sk                   as date_key,
        d_date_id                   as date_id,
        cast(d_date as date)        as calendar_date,

        -- calendar parts
        d_year                      as calendar_year,
        d_moy                       as month_of_year,
        d_dom                       as day_of_month,
        d_dow                       as day_of_week,
        d_qoy                       as quarter_of_year,
        d_day_name                  as day_name,
        d_quarter_name              as quarter_name,

        -- sequences, useful for period over period comparisons
        d_month_seq                 as month_sequence,
        d_week_seq                  as week_sequence,
        d_quarter_seq               as quarter_sequence,

        -- fiscal parts
        d_fy_year                   as fiscal_year,
        d_fy_quarter_seq            as fiscal_quarter_sequence,
        d_fy_week_seq               as fiscal_week_sequence,

        -- flags, still Y/N here
        d_holiday                   as holiday_flag,
        d_weekend                   as weekend_flag,
        d_following_holiday         as following_holiday_flag,

        -- period boundaries
        d_first_dom                 as first_day_of_month_key,
        d_last_dom                  as last_day_of_month_key

    from source

)

select * from renamed
