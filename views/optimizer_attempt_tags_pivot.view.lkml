view: optimizer_attempt_tags_pivot {
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
        -- Boolean tag pushdowns: only narrow when the user explicitly filters "= Yes".
        -- For "= No", outer-query filter on the pivot column handles it; pushing NOT EXISTS would
        -- force a near-full scan with no speed-up, and incorrectly narrows other pivot columns.
        {% if content_integration_optimizer.attempt_is_risky._is_filtered and _filters['content_integration_optimizer.attempt_is_risky'] == 'Yes' %}
        AND EXISTS (
          SELECT 1 FROM ota.optimizer_attempt_tags r
          INNER JOIN ota.optimizer_tags rt ON rt.id = r.tag_id
          WHERE r.attempt_id = oa.id AND rt.name = 'Risky'
        )
        {% endif %}
        {% if content_integration_optimizer.attempt_has_seats._is_filtered and _filters['content_integration_optimizer.attempt_has_seats'] == 'Yes' %}
        AND EXISTS (
          SELECT 1 FROM ota.optimizer_attempt_tags s
          INNER JOIN ota.optimizer_tags st ON st.id = s.tag_id
          WHERE s.attempt_id = oa.id AND st.name = 'Seats'
        )
        {% endif %}
        {% if content_integration_optimizer.attempt_is_test._is_filtered and _filters['content_integration_optimizer.attempt_is_test'] == 'Yes' %}
        AND EXISTS (
          SELECT 1 FROM ota.optimizer_attempt_tags t
          INNER JOIN ota.optimizer_tags tt ON tt.id = t.tag_id
          WHERE t.attempt_id = oa.id AND tt.name = 'Test'
        )
        {% endif %}
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
