{#
    Route models to the three fixed schemas provisioned by
    snowflake/01_setup_demo_environment.sql.

    dbt's built in behaviour concatenates the target schema and the custom
    schema, so a production target schema of CURATED plus a folder level
    +schema of STAGE would land in CURATED_STAGE. Nothing would end up where
    the setup script granted privileges.

    In production the custom schema is used verbatim, giving STAGE, CURATED and
    DATA_VIZ. Everywhere else it is prefixed with the developer schema, giving
    dbt_jacob_STAGE and friends, which is why the setup script grants
    CREATE SCHEMA on DEMO_DB.

    Production is identified by target NAME, not target schema. The dbt Cloud
    production environment must have its target name set to prod.
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- elif target.name == 'prod' -%}

        {{ custom_schema_name | trim }}

    {%- else -%}

        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
