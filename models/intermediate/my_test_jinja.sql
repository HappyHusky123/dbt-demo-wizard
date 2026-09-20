-- Setting Variables
{% set countries = ["USA", "Canada", "Mexico", "Guatemala"] %}
{% set my_string2 = "FameMonster" %}
{% set my_integer = 2 %}

-- Reference a variable 
{{ countries }}

-- Note the behavior of jinja comments! See this:
{# for loops
{% for i in range(10) %}
    select {{ i }} as number {% if not loop.last %} union all {% endif %}

{% endfor %}
#}

--Versus this! 
-- {% for i in range(10) %}
--     select {{ i }} as number {% if not loop.last %} union all {% endif %}

-- {% endfor %}

-- Looping 
{% for country in countries %}

SELECT * FROM my_country_table
WHERE COUNTRY = {{ country }}

{% endfor %}

-- Note how you can index and slice in jinja lists
{{ countries[0] }}
{{ countries[1] }}
{{ countries[2] }}
{{ countries[1:3] }}

-- If/Else statements
{% set temperature = 65 %}
{% if temperature > 65 %}
Time for a cold brew!
{% else %}
Time for a cappuccino!
{% endif %}

-- Dictionaries
{% set my_dictionary = {
    'word': 'data',
    'speech_part': 'noun',
    'definition': 'if you know you know'
} -%}

{{ my_dictionary['word'] }} ({{my_dictionary['speech_part']}}): defined as {{my_dictionary['definition'] }}