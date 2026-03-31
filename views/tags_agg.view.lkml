# NDT must use the same explore that joins tags_agg: bind_all_filters is only allowed
# on that explore. Looker omits unneeded joins (e.g. tags_agg) from this subquery when
# only content_integration_optimizer.id is selected.
view: tags_agg_base {
  derived_table: {
    explore_source: content_integration_optimizer {
      column: id { field: content_integration_optimizer.id }
      bind_all_filters: yes
    }
  }
}

view: tags_agg {
  derived_table: {
    sql:
      SELECT
          oct.candidate_id,
          /* Keep this mapping updated!!! */
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Exception' THEN oct.value END ORDER BY oct.value SEPARATOR ', ') AS exception_values,
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'MultiTicketPart' THEN oct.value END ORDER BY oct.value SEPARATOR ', ') AS multiticket_part_values,
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Downgrade' THEN oct.value END ORDER BY oct.value SEPARATOR ', ') AS downgrade_values,
          MAX(CASE WHEN ot.name = 'MixedFareType' THEN 1 ELSE 0 END) AS is_mixed_fare_type,
          MAX(CASE WHEN ot.name = 'AlternativeMarketingCarrier' THEN 1 ELSE 0 END) AS is_alternative_marketing_carrier,
          MAX(CASE WHEN ot.name = 'Risky' THEN 1 ELSE 0 END) AS is_risky_values,

          /* This field is for debugging */
          GROUP_CONCAT(
              DISTINCT CONCAT(ot.name, ':', COALESCE(oct.value, ''))
              ORDER BY ot.name, oct.value
              SEPARATOR ', '
          ) AS tag_pairs

      FROM ${tags_agg_base.SQL_TABLE_NAME} AS b
      JOIN ota.optimizer_candidate_tags oct ON oct.candidate_id = b.id
      JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.created_at > {% parameter content_integration_optimizer.start_date %}
      GROUP BY 1
    ;;
  }

  # -------------------------
  # Dimensions
  # -------------------------

  dimension: candidate_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.candidate_id ;;
    hidden: yes
  }

  dimension: exception_values {
    type: string
    sql: ${TABLE}.exception_values ;;
    hidden: yes
  }

  dimension: multiticket_part_values {
    type: string
    sql: ${TABLE}.multiticket_part_values ;;
    hidden: yes
  }

  dimension: downgrade_values {
    type: string
    sql: ${TABLE}.downgrade_values ;;
    hidden: yes
  }

  dimension: is_mixed_fare_type {
    type: yesno
    sql: ${TABLE}.is_mixed_fare_type = 1 ;;
    hidden: yes
  }

  dimension: is_alternative_marketing_carrier {
    type: yesno
    sql: ${TABLE}.is_alternative_marketing_carrier = 1 ;;
    hidden: yes
  }

  dimension: is_risky {
    type: yesno
    sql: ${TABLE}.is_risky_values = 1 ;;
    hidden: yes
  }

  dimension: tag_pairs {
    type: string
    sql: ${TABLE}.tag_pairs ;;
    hidden: yes
  }
}
