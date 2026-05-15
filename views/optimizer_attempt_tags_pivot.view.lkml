view: optimizer_attempt_tags_pivot {
  # Hidden pivot — attempt-level analogue of optimizer_candidate_tags_pivot.
  # Why (2026-05-15, FM): same STRAIGHT_JOIN + {% condition %} pattern.
  # See optimizer_candidate_tags_pivot.view.lkml for the full rationale.
  derived_table: {
    sql:
      SELECT
        oat.attempt_id,
        GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Filtered' THEN oat.value END ORDER BY oat.value SEPARATOR ', ') AS attempt_filtered_values,
        GROUP_CONCAT(DISTINCT CONCAT(ot.name, ':', COALESCE(oat.value, '')) ORDER BY ot.name, oat.value SEPARATOR ', ') AS attempt_tag_pairs,
        MAX(CASE WHEN ot.name = 'Risky' THEN 1 ELSE 0 END) AS attempt_is_risky,
        MAX(CASE WHEN ot.name = 'Seats' THEN 1 ELSE 0 END) AS attempt_has_seats,
        MAX(CASE WHEN ot.name = 'Test'  THEN 1 ELSE 0 END) AS attempt_is_test
      FROM ota.optimizer_attempts oa
      STRAIGHT_JOIN ota.optimizer_attempt_tags oat ON oat.attempt_id = oa.id
      STRAIGHT_JOIN ota.optimizer_tags ot ON ot.id = oat.tag_id
      WHERE {% condition content_integration_optimizer.date_date %} oa.created_at {% endcondition %}
        AND {% condition content_integration_optimizer.gds %} oa.gds {% endcondition %}
        AND {% condition content_integration_optimizer.attempt_id %} oa.id {% endcondition %}
      GROUP BY oat.attempt_id
    ;;
  }

  dimension: attempt_id              { primary_key: yes type: number sql: ${TABLE}.attempt_id              ;; hidden: yes }
  dimension: attempt_filtered_values { type: string     sql: ${TABLE}.attempt_filtered_values ;; hidden: yes }
  dimension: attempt_tag_pairs       { type: string     sql: ${TABLE}.attempt_tag_pairs       ;; hidden: yes }
  dimension: attempt_is_risky        { type: number     sql: ${TABLE}.attempt_is_risky        ;; hidden: yes }
  dimension: attempt_has_seats       { type: number     sql: ${TABLE}.attempt_has_seats       ;; hidden: yes }
  dimension: attempt_is_test         { type: number     sql: ${TABLE}.attempt_is_test         ;; hidden: yes }
}
