view: optimizer_reprice_strategies {
  # ota.optimizer_reprice_strategies — lookup table of named repricing
  # strategies (e.g. Default, BestRevenue, Cheapest, Match, Alternative,
  # Other). New table (added 2026-08-31, verified 2026-09-02); 6 rows.
  sql_table_name: ota.optimizer_reprice_strategies ;;

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
    hidden: yes
  }

  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
    hidden: yes
  }

  dimension: created_at_raw {
    type: date_raw
    sql: ${TABLE}.created_at ;;
    hidden: yes
  }
}
