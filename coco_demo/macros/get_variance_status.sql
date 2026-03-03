{%- macro get_variance_status(variance_column, is_active_column) -%}
    CASE 
        WHEN {{ is_active_column }} AND COALESCE({{ variance_column }}, 0) = 0 THEN 'Fully Reconciled'
        WHEN {{ is_active_column }} AND COALESCE({{ variance_column }}, 0) < {{ var('variance_threshold_minor') }} THEN 'Minor Variance'
        WHEN {{ is_active_column }} AND COALESCE({{ variance_column }}, 0) < {{ var('variance_threshold_moderate') }} THEN 'Moderate Variance'
        WHEN {{ is_active_column }} THEN 'High Variance'
        ELSE 'Inactive'
    END
{%- endmacro -%}
