with water_levels as (

    select 
        eventid,
        date,
        gauge, 
        depth
    from
        {{ source('environmental', 'water_levels')}}

)

select * from water_levels