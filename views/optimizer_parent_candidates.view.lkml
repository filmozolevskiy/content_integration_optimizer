view: optimizer_parent_candidates {
  # Hidden self-alias of ota.optimizer_candidates joined on parent_id.
  # Why (2026-05-15, FM): lets is_child_of_single_to_multi resolve as a
  # column read instead of a correlated EXISTS (fired on every
  # candidacy-grouped tile — 30+ tiles).
  sql_table_name: ota.optimizer_candidates ;;

  dimension: id          { primary_key: yes type: number sql: ${TABLE}.id           ;; hidden: yes }
  dimension: reprice_type { type: string    sql: ${TABLE}.reprice_type              ;; hidden: yes }
  dimension: created_at_raw { type: date_raw sql: ${TABLE}.created_at              ;; hidden: yes }
}
