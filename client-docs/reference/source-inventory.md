# Source inventory

Everything comes from `SNOWFLAKE_SAMPLE_DATA`, a read-only inbound share from
`SFC_SAMPLES.SAMPLE_DATA`. The schema is driven by the `tpcds_schema` var so the scale factor can
change without editing the source YAML.

No freshness checks are configured. A static share has no load timestamps, so a `loaded_at_field`
would only ever produce a false failure.

Declared in `models/staging/_tpcds__sources.yml` as source `tpcds`.

## Tables in the share

Sizes are at `TPCDS_SF10TCL` (the 10 TB set) and describe the **full** table, before the date-key
window is applied.

| Table | Grain | Approx. size | Date key | Staged as |
|---|---|---|---|---|
| `store_sales` | One row per item per sales ticket | ~28.8 billion rows | `ss_sold_date_sk` | `stg_tpcds__store_sales` |
| `store_returns` | One row per item per return ticket | large | `sr_returned_date_sk` | `stg_tpcds__store_returns` |
| `date_dim` | One row per calendar day | ~73,000 rows, 1900–2100 | — | `stg_tpcds__date` |
| `item` | One row per product version (SCD2) | large | — | `stg_tpcds__item` |
| `customer` | One row per customer | ~65 million rows | — | `stg_tpcds__customer` |
| `customer_address` | One row per address | ~32.5 million rows | — | `stg_tpcds__customer_address` |
| `customer_demographics` | One row per unique demographic combination | moderate | — | `stg_tpcds__customer_demographics` |
| `store` | One row per store version (SCD2) | ~1,000 rows | — | `stg_tpcds__store` |
| `promotion` | One row per promotion | small | — | `stg_tpcds__promotion` |

**In the share but not modeled:** `catalog_sales` (`cs_sold_date_sk`), `web_sales`
(`ws_sold_date_sk`), and their returns and dimension counterparts. Adding one is
[how to add a staging model](../how-to/add-a-staging-model.md).

## The date-key window

The fact tables are clustered on their date surrogate key, so the predicate prunes micro-partitions
hard. **Fact staging models filter; dimension staging models do not** — filtering a dimension would
drop conformed members and break relationship tests. See
[ADR-0007](../adr/0007-date-key-window-on-fact-staging-models.md).

`d_date_sk` is the Julian day number.

| Window | `tpcds_start_date_sk` | `tpcds_end_date_sk` |
|---|---|---|
| One week (default) | `2452276` | `2452282` |
| January 2002 | `2452276` | `2452306` |
| All of 2002 | `2452276` | `2452640` |

## Quirks worth knowing

- **`customer.c_last_review_date` is a date key.** It breaks the source's own `_sk` naming convention
  but holds a `d_date_sk` value like every other date column, so `stg_tpcds__customer` renames it to
  `last_review_date_key`.
- **Demographics are snowflaked off customer.** Gender and marital status sit behind
  `customer_demographics`, so reaching them needs a second join. `dim_customer` flattens this.
- **`item` and `store` are SCD2.** `i_item_sk` identifies a *version* of a product; `i_item_id`
  identifies the product across versions. Same shape on `store`.
- **Birth dates arrive as three integers** (`c_birth_year`, `c_birth_month`, `c_birth_day`) and
  include invalid combinations such as 31 February. `dim_customer` assembles them with `try_to_date`,
  which returns null rather than erroring.
- **Promotion channels are eight `Y`/`N` flag columns.** `fct_store_sales` collapses them into one
  readable `promotion_channels` list.
- **Margins are negative.** Wholesale costs exceed what customers pay. See
  [metric definitions](./metric-definitions.md).

## The one non-TPC-DS input

`seeds/store_sales_regions.csv` — maps US state codes to sales regions and a named manager. TPC-DS has
no region concept, so this is the only genuinely local business content in the project. 50 states plus
DC; a store in an unlisted state falls back to `Unassigned` in `dim_store` rather than null.

| Column | Tests |
|---|---|
| `state_code` | `unique`, `not_null` |
| `state_name` | `not_null` |
| `sales_region` | `not_null`, `accepted_values: [Northeast, Midwest, South, West]` |
| `region_manager_name` | `not_null` |
