-- depends_on: {{ ref('model_data_a'),ref('model_struct'), }}
-- depends_on: {{ ref('model_struct') }}
-- depends_on: {{ ref('model_without_import_ctes') }}
-- depends_on: {{ ref('model_without_any_ctes') }}

{% if execute %}
{% set actual_model_yaml = codegen.generate_model_yaml(
    model_names = codegen.get_models(prefix='model_')
  )
%}
{% endif %}

{% set expected_model_yaml %}
version: 2

models:
  - name: model_without_import_ctes
    description: ""
    columns:
  - name: model_without_any_ctes
    description: ""
    columns:
  - name: model_struct
    description: ""
    columns:
      - name: analytics
        description: ""

      - name: analytics.source
        description: ""

      - name: analytics.medium
        description: ""

      - name: analytics.source_medium
        description: ""

      - name: col_x
        description: ""

  - name: model_data_a
    description: ""
    columns:
      - name: col_a
        description: ""

      - name: col_b
        description: ""

{% endset %}

{{ assert_equal (actual_model_yaml | trim, expected_model_yaml | trim) }}
