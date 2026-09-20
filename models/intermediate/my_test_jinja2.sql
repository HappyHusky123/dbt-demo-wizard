-- set variables
{% set my_string5 = 'hello' %}
{% set my_integer2 = 3 %}
{% set my_sexy_list = ['Giovanni', 'Gorge', 'Sebestian'] %}

-- use a for loop to call variables
{% for i in range(3): %}

SELECT 
    '{{my_sexy_list[i]}}' AS my_column, 
    3 - {{ my_integer2 }} as math,
    {{ my_string5 }} as my_other_string,
    {{ cents_to_dollars(100000) }} as amount

FROM {{ ref('fct_orders') }} 

{% endfor %}


-- use conditional logic
{% if my_integer2 == 2: %}

'This is my sexy #2 !'

{% elif my_integer2 == 3: %}

'This is my sexy #3 !'


{% else: %}

'This is not #2 or #3!'

{% endif %}

-- Dictionaries

{% set my_dictionary = {

    'testvar': 'hello',
    'my_int': 4,
    'my_list': ['too', 'much', 'shade']

} %}

{% for key in my_dictionary: %}

{{my_dictionary[key]}}

{% endfor %}