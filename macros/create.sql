{% macro snowflake__create_table_as(temporary, relation, compiled_code, language='sql') -%}
  {%- set transient = config.get('transient', default=true) -%}
  {%- set iceberg = config.get('iceberg') -%}

  {% if temporary -%}
    {%- set table_type = "temporary" -%}
  {%- elif iceberg -%}
    {%- set table_type = "iceberg" -%}
  {%- elif transient -%}
    {%- set table_type = "transient" -%}
  {%- else -%}
    {%- set table_type = "" -%}
  {%- endif %}

  {%- if language == 'sql' -%}
    
    {%- set cluster_by_keys = config.get('cluster_by', default=none) -%}
    {%- set enable_automatic_clustering = config.get('automatic_clustering', default=false) -%}
    {%- set copy_grants = config.get('copy_grants', default=false) -%}
    {%- if cluster_by_keys is not none and cluster_by_keys is string -%}
      {%- set cluster_by_keys = [cluster_by_keys] -%}
    {%- endif -%}
    {%- if cluster_by_keys is not none -%}
      {%- set cluster_by_string = cluster_by_keys|join(", ")-%}
    {% else %}
      {%- set cluster_by_string = none -%}
    {%- endif -%}
    {%- set sql_header = config.get('sql_header', none) -%}

    {%- set catalog = var('catalog_iceberg') -%}
    {%- set external_volume = var('external_volume_iceberg') -%}
    {%- set polaris_catalog_sync = var('polaris_catalog_sync') -%}
    {%- set base_location = relation.identifier -%}


    {{ sql_header if sql_header is not none }}

        create or replace {{ table_type }} table {{ relation }}
        {%- set contract_config = config.get('contract') -%}
        {%- if contract_config.enforced -%}
          {{ get_assert_columns_equivalent(sql) }}
          {{ get_table_columns_and_constraints() }}
          {% set compiled_code = get_select_subquery(compiled_code) %}
        {% endif %}
        {% if iceberg and catalog and external_volume and base_location %}
          CATALOG="{{ catalog }}",
          EXTERNAL_VOLUME="{{ external_volume }}",
          BASE_LOCATION="{{ base_location }}"
          {% if polaris_catalog_sync %}
            CATALOG_SYNC = "{{ polaris_catalog_sync }}"
          {% endif %}  
        {% endif %}  
        {% if copy_grants and not temporary -%} copy grants {%- endif %} as
        (
          {%- if cluster_by_string is not none -%}
            select * from (
              {{ compiled_code }}
              ) order by ({{ cluster_by_string }})
          {%- else -%}
            {{ compiled_code }}
          {%- endif %}
        )
      
      ;
      {% if cluster_by_string is not none and not temporary -%}
        alter table {{relation}} cluster by ({{cluster_by_string}});
      {%- endif -%}
      {% if enable_automatic_clustering and cluster_by_string is not none and not temporary  -%}
        alter table {{relation}} resume recluster;
      {%- endif -%}

  {%- elif language == 'python' -%}
    {{ py_write_table(compiled_code=compiled_code, target_relation=relation, table_type=table_type) }}
  {%- else -%}
      {% do exceptions.raise_compiler_error("snowflake__create_table_as macro didn't get supported language, it got %s" % language) %}
  {%- endif -%}

{% endmacro %}