{% macro ref(project_or_package, model_name) %}
  {% if target.name == 'duckdb'%}
    {# There should be way more checks here and all that#}
    {% set project_or_package, model_name = setup_project_and_model_name(project_or_package, model_name) %}
    {% set base_location = var("storage_base_url_iceberg") %}
    {% set iceberg_path = base_location ~ "/" ~ model_name %}
    {% set reference_to_iceberg = "iceberg_scan('" ~ iceberg_path ~ "')" %}
    {{ return (reference_to_iceberg) }}
  {% else %}
    {% if model_name is undefined %}
      {{ return (builtins.ref(project_or_package, **kwargs)) }}
    {% else %}
      {{ return (builtins.ref(project_or_package, model_name, **kwargs)) }}
    {% endif %}
  {% endif %}
{% endmacro %}

{% macro setup_project_and_model_name(project_or_package, model_name) %}
  {% set updated_project_or_package = project_or_package if model_name is defined else model.package_name %}
  {% set updated_model_name = model_name if model_name is defined else project_or_package %}
  {{ return((updated_project_or_package, updated_model_name)) }}
{% endmacro %}