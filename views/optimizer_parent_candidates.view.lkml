view: optimizer_parent_candidates {
  sql_table_name: ota.optimizer_candidates ;;

  dimension: id          { primary_key: yes type: number sql: ${TABLE}.id           ;; hidden: yes }
  dimension: reprice_type { type: string    sql: ${TABLE}.reprice_type              ;; hidden: yes }
  dimension: created_at_raw { type: date_raw sql: ${TABLE}.created_at              ;; hidden: yes }
}
