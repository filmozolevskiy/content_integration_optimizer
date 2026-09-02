view: optimizer_reprice_call_candidates {
  # ota.optimizer_reprice_call_candidates — bridge: one row per candidate
  # produced by a reprice call, tagged with the strategy that produced it.
  # New table (added 2026-08-31, verified 2026-09-02); ~1,480 rows so far.
  # candidate_id is unique per row — at most one reprice-call candidate row
  # per ota.optimizer_candidates row (verified 2026-09-02).
  sql_table_name: ota.optimizer_reprice_call_candidates ;;

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
    hidden: yes
  }

  dimension: reprice_call_id {
    type: number
    sql: ${TABLE}.reprice_call_id ;;
    hidden: yes
  }

  dimension: candidate_id {
    type: number
    sql: ${TABLE}.candidate_id ;;
    hidden: yes
  }

  dimension: strategy_id {
    type: number
    sql: ${TABLE}.strategy_id ;;
    hidden: yes
  }

  dimension: created_at_raw {
    type: date_raw
    sql: ${TABLE}.created_at ;;
    hidden: yes
  }

  dimension: extra {
    type: string
    sql: ${TABLE}.extra ;;
    hidden: yes
  }
}
