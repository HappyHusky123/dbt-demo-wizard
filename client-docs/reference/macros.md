# Macros

Two project macros, both in `macros/`, both documented in `macros/_macros.yml`.

---

## `safe_divide`

```jinja
{{ safe_divide(numerator, denominator, default_value='null') }}
```

Division that returns `default_value` instead of erroring when the denominator is zero or null.

| Argument | Type | Description |
|---|---|---|
| `numerator` | string | Column or expression to divide |
| `denominator` | string | Column or expression to divide by |
| `default_value` | string | SQL literal returned when the denominator is zero or null. Defaults to `null` |

**Compiles to:**

```sql
case
    when coalesce(<denominator>, 0) = 0 then <default_value>
    else <numerator> / <denominator>
end
```

**Required** for every rate and percentage in this project — see
[ADR-0004](../adr/0004-safe-divide-for-all-rate-calculations.md). Raw `/` between two columns does not
appear in a model.

Every current call site passes `0` explicitly. Pass `0` when a zero denominator means the quantity is
genuinely zero; leave the default `null` when the ratio is genuinely undefined.

Notes:
- Arguments are strings interpolated into SQL, so wrap expressions in quotes:
  `{{ safe_divide('sum(gross_margin_amount)', 'sum(net_paid_amount)', 0) }}`.
- The denominator is emitted twice. Harmless for a column reference; worth noticing before passing an
  expensive scalar subquery.
- Under an enforced contract, wrap the whole call in an explicit cast — the `case` expression's
  natural type is rarely the declared one.

**Call sites:** `rpt_daily_store_sales`, `rpt_category_performance`, `rpt_customer_segment_sales`.

---

## `generate_schema_name`

```jinja
{% macro generate_schema_name(custom_schema_name, node) %}
```

Overrides dbt's default schema resolution. Not called directly — dbt calls it for every node.

| Argument | Type | Description |
|---|---|---|
| `custom_schema_name` | string | The `+schema` value configured on the model or its folder, or none |
| `node` | dict | The node dbt is resolving a schema for |

**Behavior:**

| Condition | Result |
|---|---|
| `custom_schema_name is none` | `target.schema` unchanged |
| `target.name == 'prod'` | `custom_schema_name` verbatim — `STAGE`, `CURATED`, `DATA_VIZ` |
| otherwise | `{{ target.schema }}_{{ custom_schema_name }}` — `dbt_jacob_STAGE` and friends |

dbt's built-in behavior concatenates target schema and custom schema in **all** environments, which
would produce `CURATED_STAGE` and land every model somewhere the setup script never granted. See
[ADR-0002](../adr/0002-three-schema-layering-and-name-routing.md).

**The failure mode:** production is identified by `target.name`, not `target.schema`. A production
environment whose target name is left at the default falls to the third branch and writes into the
developer-prefixed schemas. Nothing errors; production tables are simply empty.

---

## Packages

`dbt_utils` (`packages.yml`). The generic tests used from it:

| Test | Used on |
|---|---|
| `dbt_utils.unique_combination_of_columns` | The grain of every fact and every `rpt_` model |

## Project generic tests

`tests/generic/expect_average_greater_than.sql`

```yaml
data_tests:
  - expect_average_greater_than:
      arguments:
        min_value: -1000
        group_by_column: sold_date_key
```

Fails when the average of a column, optionally within each group, is at or below `min_value`. Written
for measures where a single bad row is noise but a whole group tipping means the upstream logic broke
— a `not_null` test cannot catch a margin calculation that started subtracting the wrong column.

| Argument | Default | Description |
|---|---|---|
| `min_value` | `0` | Floor. The test fails when a group's average is `<=` this |
| `group_by_column` | `none` | Group to evaluate within. Omit to test the whole column |

**Singular test:** `tests/assert_returns_not_greater_than_sales.sql`.
