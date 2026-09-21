{#
    Conformed date dimension.

    Business logic applied here: the benchmark's Y/N character flags become real
    booleans, and the period boundaries every BI tool asks for are derived once
    so no downstream model has to repeat the date arithmetic.
#}

with dates as (

    select * from {{ ref('stg_tpcds__date') }}

),

final as (

    select
        -- keys
        date_key,
        date_id,
        calendar_date,

        -- calendar parts
        calendar_year,
        quarter_of_year,
        month_of_year,
        day_of_month,
        day_of_week,
        day_name,
        quarter_name,

        -- labels that BI tools sort and group on
        to_char(calendar_date, 'YYYY-MM')                   as year_month,
        to_char(calendar_date, 'Mon')                       as month_name_short,
        calendar_year || ' Q' || quarter_of_year            as year_quarter,

        -- period boundaries
        date_trunc('week',    calendar_date)                as week_start_date,
        date_trunc('month',   calendar_date)                as month_start_date,
        last_day(calendar_date, 'month')                    as month_end_date,
        date_trunc('quarter', calendar_date)                as quarter_start_date,
        date_trunc('year',    calendar_date)                as year_start_date,

        -- sequences, for period over period comparison
        month_sequence,
        week_sequence,
        quarter_sequence,

        -- fiscal parts
        fiscal_year,
        fiscal_quarter_sequence,
        fiscal_week_sequence,

        -- Y/N becomes boolean
        holiday_flag           = 'Y'                        as is_holiday,
        weekend_flag           = 'Y'                        as is_weekend,
        following_holiday_flag = 'Y'                        as is_following_holiday

    from dates

)

select * from final
