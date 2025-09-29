view: optimizer_candidate_tags {
  sql_table_name: ota.optimizer_candidate_tags ;;

  dimension: id          { primary_key: yes type: number sql: ${TABLE}.id ;; hidden: yes}

  dimension_group: created_at {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }

  dimension: candidate_id { type: number sql: ${TABLE}.candidate_id ;; hidden: yes}
  dimension: tag_id       { type: number sql: ${TABLE}.tag_id ;; hidden: yes}
  dimension: value        { type: string sql: ${TABLE}.value ;; }

  measure: count { type: count drill_fields: [id, candidate_id, tag_id, value] }

}
