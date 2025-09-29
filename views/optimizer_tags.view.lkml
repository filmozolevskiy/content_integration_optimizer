view: optimizer_tags {
  sql_table_name: ota.optimizer_tags ;;

  dimension: id { primary_key: yes type: number sql: ${TABLE}.id ;; hidden: yes}
  dimension: name { type: string sql: ${TABLE}.name ;; }

  dimension_group: created_at {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }

}
