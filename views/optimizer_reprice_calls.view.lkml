view: optimizer_reprice_calls {
  # ota.optimizer_reprice_calls — one row per repricing call the Optimizer
  # made for an attempt (one "master_N" slot per call). New table (added
  # 2026-08-31, verified 2026-09-02); ~1,450 rows so far, small rollout
  # footprint — most attempts have none yet. attempt_id always agrees with
  # the attempt_id of every candidate it produces (verified 2026-09-02).
  sql_table_name: ota.optimizer_reprice_calls ;;

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
    hidden: yes
  }

  dimension: attempt_id {
    type: number
    sql: ${TABLE}.attempt_id ;;
    hidden: yes
  }

  dimension: created_at_raw {
    type: date_raw
    sql: ${TABLE}.created_at ;;
    hidden: yes
  }

  dimension: reprice_index {
    type: string
    sql: ${TABLE}.reprice_index ;;
    hidden: yes
  }

  dimension: status {
    type: number
    sql: ${TABLE}.status ;;
    hidden: yes
  }

  dimension: runtime_ms {
    type: number
    sql: ${TABLE}.runtime_ms ;;
    hidden: yes
  }

  dimension: arguments {
    type: string
    sql: ${TABLE}.arguments ;;
    hidden: yes
  }
}
