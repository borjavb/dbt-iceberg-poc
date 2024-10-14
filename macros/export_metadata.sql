{% macro export_iceberg_metadata( relation) -%}
    EXPORT TABLE METADATA FROM {{relation}}
{% endmacro %}
