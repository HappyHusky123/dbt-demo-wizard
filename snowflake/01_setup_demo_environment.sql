/* =====================================================================
   Snowflake setup for the "Harness Engineering with dbt Cloud" demo
   ---------------------------------------------------------------------
   Creates:
     WAREHOUSE  DEMO_WH            MEDIUM, auto-suspend 60s
     DATABASE   DEMO_DB            schemas STAGE / CURATED / DATA_VIZ
     ROLE       DBT_DEMO_ROLE      write on DEMO_DB, read on the sample data
     MONITOR    DEMO_CREDIT_GUARD  trial credit backstop

   Run the whole file top to bottom in a Snowsight worksheet as
   ACCOUNTADMIN. It is idempotent, so re-running it is safe.

   Connection model: you sign in to dbt Cloud as your own trial admin
   user and select DBT_DEMO_ROLE. No service user is created. See the
   notes at the bottom before you configure the dbt Cloud connection.
   ===================================================================== */

USE ROLE ACCOUNTADMIN;


/* ---------------------------------------------------------------------
   1. Credit guard
   ---------------------------------------------------------------------
   A trial account is capped at roughly 400 credits. DEMO_WH is a MEDIUM,
   which burns 4 credits per hour while running. This monitor notifies at
   50%, notifies again at 75%, and hard-suspends the warehouse at 90% so
   a runaway TPCDS scan cannot drain the account the night before the talk.

   Adjust CREDIT_QUOTA to taste. 50 is generous for a single demo.
   --------------------------------------------------------------------- */

CREATE RESOURCE MONITOR IF NOT EXISTS DEMO_CREDIT_GUARD
  WITH
    CREDIT_QUOTA = 50
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
  TRIGGERS
    ON 50  PERCENT DO NOTIFY
    ON 75  PERCENT DO NOTIFY
    ON 90  PERCENT DO SUSPEND
    ON 100 PERCENT DO SUSPEND_IMMEDIATE;


/* ---------------------------------------------------------------------
   2. Warehouse
   ---------------------------------------------------------------------
   MEDIUM because the sources live in TPCDS_SF100TCL, the 100 TB scale
   factor. STORE_SALES there is roughly 288 billion rows, so an XSMALL
   turns a staging model into a coffee break. See note A at the bottom
   about filtering, which matters more than the warehouse size.

   AUTO_SUSPEND is deliberately 60 seconds. Between demo beats the
   warehouse should be off.
   --------------------------------------------------------------------- */

CREATE WAREHOUSE IF NOT EXISTS DEMO_WH
  WITH
    WAREHOUSE_SIZE = 'MEDIUM'
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Compute for the dbt Cloud harness demo';

-- Re-assert settings in case the warehouse already existed from an earlier run.
ALTER WAREHOUSE DEMO_WH SET
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    RESOURCE_MONITOR = DEMO_CREDIT_GUARD
    STATEMENT_TIMEOUT_IN_SECONDS = 1800
    STATEMENT_QUEUED_TIMEOUT_IN_SECONDS = 300;


/* ---------------------------------------------------------------------
   3. Database and schemas
   ---------------------------------------------------------------------
   Three fixed schemas are the production targets. dbt Cloud development
   environments will create their own dbt_<name> schemas alongside these,
   which is why the role gets CREATE SCHEMA on the database in step 5.
   --------------------------------------------------------------------- */

CREATE DATABASE IF NOT EXISTS DEMO_DB
  COMMENT = 'Tech Talk Tuesday demo warehouse for the dbt Cloud harness';

-- Trials default to 1 day of Time Travel. Keep it there, it is a demo.
ALTER DATABASE DEMO_DB SET DATA_RETENTION_TIME_IN_DAYS = 1;

CREATE SCHEMA IF NOT EXISTS DEMO_DB.STAGE
  COMMENT = 'Bronze. 1:1 with source, renamed and typed, no business logic';

CREATE SCHEMA IF NOT EXISTS DEMO_DB.CURATED
  COMMENT = 'Silver. Conformed dimensions and facts, business logic lives here';

CREATE SCHEMA IF NOT EXISTS DEMO_DB.DATA_VIZ
  COMMENT = 'Gold. Presentation models shaped for BI consumption';

-- dbt drops the default PUBLIC schema nowhere, so remove the noise by hand.
DROP SCHEMA IF EXISTS DEMO_DB.PUBLIC;


/* ---------------------------------------------------------------------
   4. Role
   --------------------------------------------------------------------- */

CREATE ROLE IF NOT EXISTS DBT_DEMO_ROLE
  COMMENT = 'Transformation role used by dbt Cloud for the harness demo';

-- Put the role under SYSADMIN so account admins inherit visibility of
-- everything dbt builds. This is the standard Snowflake role hierarchy.
GRANT ROLE DBT_DEMO_ROLE TO ROLE SYSADMIN;


/* ---------------------------------------------------------------------
   5. Write access to DEMO_DB
   --------------------------------------------------------------------- */

GRANT USAGE ON WAREHOUSE DEMO_WH TO ROLE DBT_DEMO_ROLE;
GRANT OPERATE ON WAREHOUSE DEMO_WH TO ROLE DBT_DEMO_ROLE;
GRANT MONITOR ON WAREHOUSE DEMO_WH TO ROLE DBT_DEMO_ROLE;

GRANT USAGE ON DATABASE DEMO_DB TO ROLE DBT_DEMO_ROLE;

-- CREATE SCHEMA is what lets a dbt Cloud development environment build
-- into DEMO_DB.dbt_jacob without anyone provisioning that schema first.
GRANT CREATE SCHEMA ON DATABASE DEMO_DB TO ROLE DBT_DEMO_ROLE;

-- Full control of the three production schemas. ALL PRIVILEGES on a schema
-- covers CREATE TABLE / VIEW / MATERIALIZED VIEW / STAGE / FILE FORMAT /
-- FUNCTION / PROCEDURE / SEQUENCE, which is every object type dbt emits
-- across models, seeds, snapshots and tests.
GRANT ALL PRIVILEGES ON SCHEMA DEMO_DB.STAGE    TO ROLE DBT_DEMO_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA DEMO_DB.CURATED  TO ROLE DBT_DEMO_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA DEMO_DB.DATA_VIZ TO ROLE DBT_DEMO_ROLE;

-- Objects dbt creates are owned by DBT_DEMO_ROLE, so it can already read
-- them. These grants cover anything created by another role, for example
-- a table you hand-load as ACCOUNTADMIN while building the demo.
GRANT SELECT ON ALL TABLES           IN DATABASE DEMO_DB TO ROLE DBT_DEMO_ROLE;
GRANT SELECT ON ALL VIEWS            IN DATABASE DEMO_DB TO ROLE DBT_DEMO_ROLE;
GRANT SELECT ON FUTURE TABLES        IN DATABASE DEMO_DB TO ROLE DBT_DEMO_ROLE;
GRANT SELECT ON FUTURE VIEWS         IN DATABASE DEMO_DB TO ROLE DBT_DEMO_ROLE;
GRANT USAGE  ON FUTURE SCHEMAS       IN DATABASE DEMO_DB TO ROLE DBT_DEMO_ROLE;


/* ---------------------------------------------------------------------
   6. Read access to the Snowflake sample data
   ---------------------------------------------------------------------
   THIS IS THE ONE THAT SURPRISES PEOPLE.

   SNOWFLAKE_SAMPLE_DATA is not an ordinary database. It is a read-only
   database created from the SFC_SAMPLES.SAMPLE_DATA inbound share. You
   cannot GRANT SELECT ON ALL TABLES IN SCHEMA against it, and you cannot
   grant at the schema level at all. Shared databases expose exactly one
   lever, IMPORTED PRIVILEGES, and it applies to the whole share.

   One statement, and DBT_DEMO_ROLE can select from every schema in the
   share including TPCDS_SF100TCL.
   --------------------------------------------------------------------- */

GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE DBT_DEMO_ROLE;

/* If the statement above fails with "Database SNOWFLAKE_SAMPLE_DATA does
   not exist", the trial did not provision it. Recreate it from the share
   and then re-run the grant:

     SHOW SHARES LIKE '%SAMPLE_DATA%';
     CREATE DATABASE SNOWFLAKE_SAMPLE_DATA FROM SHARE SFC_SAMPLES.SAMPLE_DATA;
     GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE DBT_DEMO_ROLE;
*/


/* ---------------------------------------------------------------------
   7. Grant the role to yourself
   ---------------------------------------------------------------------
   You are connecting dbt Cloud as your own trial admin user, so that user
   needs to hold the role. The block resolves CURRENT_USER() at runtime so
   there is nothing to hand-edit.
   --------------------------------------------------------------------- */

EXECUTE IMMEDIATE $$
DECLARE
  grant_stmt STRING;
BEGIN
  grant_stmt := 'GRANT ROLE DBT_DEMO_ROLE TO USER "' || CURRENT_USER() || '"';
  EXECUTE IMMEDIATE :grant_stmt;
  RETURN 'DBT_DEMO_ROLE granted to ' || CURRENT_USER();
END;
$$;

-- Optional quality of life: make the demo role and warehouse your defaults.
-- Uncomment if you do not want to pick them from the Snowsight role switcher
-- every time.
--
-- EXECUTE IMMEDIATE $$
-- BEGIN
--   EXECUTE IMMEDIATE 'ALTER USER "' || CURRENT_USER() ||
--                     '" SET DEFAULT_ROLE = DBT_DEMO_ROLE, DEFAULT_WAREHOUSE = DEMO_WH';
--   RETURN 'defaults set';
-- END;
-- $$;


/* ---------------------------------------------------------------------
   8. Verification
   ---------------------------------------------------------------------
   Run these as the demo role. If all four succeed you are ready to point
   dbt Cloud at the account. If step 8.4 returns rows, the share grant in
   step 6 worked, which is the piece most likely to be wrong.
   --------------------------------------------------------------------- */

USE ROLE DBT_DEMO_ROLE;
USE WAREHOUSE DEMO_WH;
USE DATABASE DEMO_DB;

-- 8.1 The three schemas exist and are visible to the role.
SHOW SCHEMAS IN DATABASE DEMO_DB;

-- 8.2 The role can write. Creates, reads, and cleans up after itself.
CREATE OR REPLACE TABLE DEMO_DB.STAGE._SETUP_SMOKE_TEST AS
SELECT CURRENT_TIMESTAMP() AS created_at, CURRENT_ROLE() AS created_by;

SELECT * FROM DEMO_DB.STAGE._SETUP_SMOKE_TEST;

DROP TABLE DEMO_DB.STAGE._SETUP_SMOKE_TEST;

-- 8.3 The role can create a schema, which is what dbt Cloud dev needs.
CREATE SCHEMA IF NOT EXISTS DEMO_DB._SETUP_SMOKE_SCHEMA;
DROP SCHEMA IF EXISTS DEMO_DB._SETUP_SMOKE_SCHEMA;

-- 8.4 The role can read the sample data. Metadata only, scans nothing.
SELECT table_name, row_count
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'TPCDS_SF100TCL'
ORDER BY row_count DESC
LIMIT 10;

-- 8.5 A real but cheap read against the biggest table. DATE_DIM is small,
-- so this proves the grant without touching STORE_SALES.
SELECT d_date_sk, d_date, d_year, d_moy
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.DATE_DIM
WHERE d_year = 2002 AND d_moy = 1
ORDER BY d_date
LIMIT 10;


/* =====================================================================
   NOTES
   =====================================================================

   A. FILTER THE SOURCES. This matters more than warehouse size.
      TPCDS_SF100TCL.STORE_SALES is roughly 288 billion rows. An
      unfiltered staging model will either run for a very long time or hit
      the 1800 second statement timeout set in step 2, and dbt Wizard in
      the platform stops a command after 5 minutes regardless.

      The fact tables are partitioned on their date surrogate key, so a
      predicate on SS_SOLD_DATE_SK prunes micro-partitions hard. Put a var
      in dbt_project.yml and reference it from every staging model:

        vars:
          tpcds_start_date_sk: 2452276   # 2002-01-01
          tpcds_end_date_sk:   2452640   # 2002-12-31

        -- models/stage/stg_store_sales.sql
        select ...
        from {{ source('tpcds', 'store_sales') }}
        where ss_sold_date_sk between {{ var('tpcds_start_date_sk') }}
                                  and {{ var('tpcds_end_date_sk') }}

      Confirm those surrogate keys against DATE_DIM before you rely on
      them. One year of STORE_SALES is a few hundred million rows, which a
      MEDIUM handles in seconds and still looks impressively large on
      stage. Narrow the window further if the demo needs to be snappier.

      If a beat of the demo still feels slow, drop the sources to
      TPCDS_SF10TCL. Step 6 already granted the whole share, so it is a
      one-line change in sources.yml with no Snowflake work.

   B. dbt Cloud connection settings.

        Account      <your trial account identifier, e.g. ab12345.us-east-1>
        Database     DEMO_DB
        Warehouse    DEMO_WH
        Role         DBT_DEMO_ROLE
        Auth         Your trial admin user

      Snowflake blocks single-factor password sign-in, so the credential
      on the dbt Cloud connection has to be a key pair or a programmatic
      access token even though it is your own user. Generate a key pair,
      attach the public key with ALTER USER ... SET RSA_PUBLIC_KEY, and
      paste the private key into dbt Cloud. Budget ten minutes for this
      and do not leave it for the morning of the talk.

   C. Environment targets in dbt Cloud.

        Production   DEMO_DB, schema CURATED
        Development  DEMO_DB, schema dbt_<yourname>

      The three fixed schemas are reached with a +schema config per folder
      in dbt_project.yml. In production dbt writes to STAGE / CURATED /
      DATA_VIZ. In development the same configs generate dbt_jacob_stage,
      dbt_jacob_curated and dbt_jacob_data_viz, which is why step 5 grants
      CREATE SCHEMA on the database.

      Note that this repo's dbt_project.yml currently sets
      models.jaffle_shop_sweets.marts.+schema: dbo, which will not produce
      the three-schema layout. Restructure the models block to stage /
      curated / data_viz folders before the demo.

   D. Teardown. Uncomment and run as ACCOUNTADMIN when the talk is over.

      -- USE ROLE ACCOUNTADMIN;
      -- DROP DATABASE IF EXISTS DEMO_DB;
      -- DROP WAREHOUSE IF EXISTS DEMO_WH;
      -- DROP ROLE IF EXISTS DBT_DEMO_ROLE;
      -- DROP RESOURCE MONITOR IF EXISTS DEMO_CREDIT_GUARD;
   ===================================================================== */
