
-- Use the `ref` function to select from other models

{{ config(
    materialized="incremental",
    cluster_by=["word"],
    table_format="iceberg",
    post_hook=[export_iceberg_metadata(this)],
    base_location = var(),
    tags=["bigquery"]    
)
}}

SELECT
      word,
      SUM(word_count) AS count
    FROM
      {{ ref('my_third_dbt_model') }}
    WHERE
      word LIKE "%raisin%"
    GROUP BY
      word
