{% macro generate_model_import_ctes(model_name, leading_commas = false) %}

    {%- if execute -%}
    {%- set nodes = graph.nodes.values() -%}

    {%- set model = (nodes
        | selectattr('name', 'equalto', model_name) 
        | selectattr('resource_type', 'equalto', 'model')
        | list).pop() -%}

    {%- set model_raw_sql = model.raw_sql -%}
    {%- else -%}
    {%- set model_raw_sql = '' -%}
    {%- endif -%}

    {#-

        REGEX Explanations

        # from_ref 
        - matches (from or join) followed by some spaces and then {{ref(<something>)}}

        # from_source 
        - matches (from or join) followed by some spaces and then {{source(<something>,<something_else>)}}

        # from_table_1
        - matches (from or join) followed by some spaces and then <something>.<something_else>

        # from_table_2
        - matches (from or join) followed by some spaces and then (` or [ or ")<something>(` or ] or ")

        # config block
        - matches the start of the file followed by anything and then {{config(<something>)}}

    -#}
    
    {%- set from_regexes = {
        'from_ref':'(?i)(from|join)\s+({{\s*ref\s*\()([^)]+)(\)\s*}})',
        'from_source':'(?i)(from|join)\s+({{\s*source\s*\([^)]+,)([^)]+)(\)\s*}})',
        'from_table_1':'(?i)(from|join)\s+([\[`\"]?\w+[\]`\"]?\.)([\[`\"]?\w+[\]`\"]?)',
        'from_table_2':'(?i)(from|join)\s+([\[`\"])([\w ]+)([\]`\"])',
        'config_block':'(?i)(?s)^.*{{\s*config\s*\([^)]+\)\s*}}'
    } -%}

    {%- set re = modules.re -%}

    {%- set from_list = [] -%}
    {%- set config_list = [] -%}

    {%- for regex_name, regex_pattern in from_regexes.items() -%}

        {%- set all_regex_matches = re.findall(regex_pattern, model_raw_sql) -%}

        {%- for match in all_regex_matches -%}

            {%- if regex_name == 'config_block' -%}
                {%- set match_tuple = (match|trim, regex_name) -%}
                {%- do config_list.append(match_tuple) -%}
            {%- else -%}
                {%- set full_from_clause = match[1:]|join|trim -%}
                {%- set cte_name = match[2]|replace("'","")|trim|lower -%}
                {%- set match_tuple = (cte_name, full_from_clause, regex_name) -%}
                {%- do from_list.append(match_tuple) -%}
            {%- endif -%}

        {%- endfor -%}

    {%- endfor -%}

    {%- set unique_from_list = set(from_list) -%}

{%- if unique_from_list|length > 0 -%}

{%- set ns = namespace(model_sql = model_raw_sql) -%}

{%- set model_import_ctes -%}

    {%- for config_obj in config_list -%}

    {%- set ns.model_sql = ns.model_sql|replace(config_obj[0], '') -%}

{{ config_obj[0] }}

{% endfor -%}

    {%- for from_obj in unique_from_list|sort -%}
        
        {%- set ns.model_sql = ns.model_sql|replace(from_obj[1], from_obj[0]) -%}

{%- if loop.first -%}with {% else -%}{%- if leading_commas -%},{%- endif -%}{%- endif -%}{{ from_obj[0] }} as (

    select * from {{ from_obj[1] }}
    {%- if from_obj[2] == 'from_source' and from_list|length > 1 %} 
    -- CAUTION: It's best practice to create staging layer for raw sources
    {%- elif from_obj[2] == 'from_table_1' or from_obj[2] == 'from_table_2' %}
    -- CAUTION: It's best practice to use the ref or source function instead of a direct reference
    {%- endif %}
  
){%- if not leading_commas -%},{%- endif %}
{% endfor -%}

{%- if leading_commas -%}
{%- set replace_with = ',' -%}
{%- else -%}
{%- set replace_with = '' -%}
{%- endif -%}

{{ re.sub('(?i)with\s', replace_with, ns.model_sql, 1)|trim }}

{%- endset -%}

{%- else -%}

{% set model_import_ctes = model_raw_sql %}

{%- endif -%}

{%- if execute -%}

{{ log(model_import_ctes, info=True) }}
{% do return(model_import_ctes) %}

{% endif %}

{% endmacro %}