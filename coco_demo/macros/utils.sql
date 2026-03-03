{%- macro filter_soft_deletes(table_alias, delete_flag_column='DELETE_FLAG') -%}
    ({{ table_alias }}.{{ delete_flag_column }} = FALSE OR {{ table_alias }}.{{ delete_flag_column }} IS NULL)
{%- endmacro -%}

{%- macro safe_divide(numerator, denominator, default_value=0) -%}
    CASE 
        WHEN {{ denominator }} IS NULL OR {{ denominator }} = 0 THEN {{ default_value }}
        ELSE {{ numerator }} / {{ denominator }}
    END
{%- endmacro -%}

{%- macro coalesce_zero(column) -%}
    COALESCE({{ column }}, 0)
{%- endmacro -%}
