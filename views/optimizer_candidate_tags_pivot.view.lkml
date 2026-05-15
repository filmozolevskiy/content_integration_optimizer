view: optimizer_candidate_tags_pivot {
  derived_table: {
    sql:
      SELECT
        oct.candidate_id,
        GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Exception'                THEN oct.value END ORDER BY oct.value SEPARATOR ', ') AS exception,
        GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Dropped'                  THEN oct.value END ORDER BY oct.value SEPARATOR ', ') AS dropped_reason,
        GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Demoted'                  THEN oct.value END ORDER BY oct.value SEPARATOR ', ') AS demoted_values,
        GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Promoted'                 THEN oct.value END ORDER BY oct.value SEPARATOR ', ') AS promoted_values,
        GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Unfit'                    THEN oct.value END ORDER BY oct.value SEPARATOR ', ') AS unfit_values,
        GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'MultiTicketPart'          THEN oct.value END ORDER BY oct.value SEPARATOR ', ') AS multiticket_part,
        GROUP_CONCAT(DISTINCT CONCAT(ot.name, ':', COALESCE(oct.value, '')) ORDER BY ot.name, oct.value SEPARATOR ', ') AS tag_pairs,
        MAX(CASE WHEN ot.name = 'AlternativeMarketingCarrier' THEN 1 ELSE 0 END) AS is_alternative_marketing_carrier,
        MAX(CASE WHEN ot.name = 'MixedFareType'               THEN 1 ELSE 0 END) AS is_mixed_fare_type,
        MAX(CASE WHEN ot.name = 'Risky'                       THEN 1 ELSE 0 END) AS is_risky,
        MAX(CASE WHEN ot.name = 'Rogue'                       THEN 1 ELSE 0 END) AS is_rogue,
        MAX(CASE WHEN ot.name = 'Downgrade'                   THEN 1 ELSE 0 END) AS is_downgrade,
        MAX(CASE WHEN ot.name = 'Promoted'                    THEN 1 ELSE 0 END) AS is_promoted,
        MAX(CASE WHEN ot.name = 'Demoted'                     THEN 1 ELSE 0 END) AS is_demoted
      FROM ota.optimizer_candidates oc
      STRAIGHT_JOIN ota.optimizer_candidate_tags oct ON oct.candidate_id = oc.id
      STRAIGHT_JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE {% condition content_integration_optimizer.date_date %} oc.created_at {% endcondition %}
        AND {% condition content_integration_optimizer.gds %} oc.gds {% endcondition %}
        AND {% condition content_integration_optimizer.attempt_id %} oc.attempt_id {% endcondition %}
        -- Boolean tag pushdowns: only narrow when the user explicitly filters "= Yes".
        -- For "= No", outer-query filter on the pivot column handles it; pushing NOT EXISTS would
        -- force a near-full scan with no speed-up, and incorrectly narrows other pivot columns.
        {% if content_integration_optimizer.is_promoted._is_filtered and _filters['content_integration_optimizer.is_promoted'] == 'Yes' %}
        AND EXISTS (
          SELECT 1 FROM ota.optimizer_candidate_tags p
          INNER JOIN ota.optimizer_tags pt ON pt.id = p.tag_id
          WHERE p.candidate_id = oc.id AND pt.name = 'Promoted'
        )
        {% endif %}
        {% if content_integration_optimizer.is_demoted._is_filtered and _filters['content_integration_optimizer.is_demoted'] == 'Yes' %}
        AND EXISTS (
          SELECT 1 FROM ota.optimizer_candidate_tags d
          INNER JOIN ota.optimizer_tags dt ON dt.id = d.tag_id
          WHERE d.candidate_id = oc.id AND dt.name = 'Demoted'
        )
        {% endif %}
        {% if content_integration_optimizer.is_risky._is_filtered and _filters['content_integration_optimizer.is_risky'] == 'Yes' %}
        AND EXISTS (
          SELECT 1 FROM ota.optimizer_candidate_tags r
          INNER JOIN ota.optimizer_tags rt ON rt.id = r.tag_id
          WHERE r.candidate_id = oc.id AND rt.name = 'Risky'
        )
        {% endif %}
        {% if content_integration_optimizer.is_rogue._is_filtered and _filters['content_integration_optimizer.is_rogue'] == 'Yes' %}
        AND EXISTS (
          SELECT 1 FROM ota.optimizer_candidate_tags rg
          INNER JOIN ota.optimizer_tags rgt ON rgt.id = rg.tag_id
          WHERE rg.candidate_id = oc.id AND rgt.name = 'Rogue'
        )
        {% endif %}
      GROUP BY oct.candidate_id
    ;;
  }

  dimension: candidate_id { primary_key: yes type: number sql: ${TABLE}.candidate_id ;; hidden: yes }
  dimension: exception                    { type: string  sql: ${TABLE}.exception                    ;; hidden: yes }
  dimension: dropped_reason               { type: string  sql: ${TABLE}.dropped_reason               ;; hidden: yes }
  dimension: demoted_values               { type: string  sql: ${TABLE}.demoted_values               ;; hidden: yes }
  dimension: promoted_values              { type: string  sql: ${TABLE}.promoted_values              ;; hidden: yes }
  dimension: unfit_values                 { type: string  sql: ${TABLE}.unfit_values                 ;; hidden: yes }
  dimension: multiticket_part             { type: string  sql: ${TABLE}.multiticket_part             ;; hidden: yes }
  dimension: tag_pairs                    { type: string  sql: ${TABLE}.tag_pairs                    ;; hidden: yes }
  dimension: is_alternative_marketing_carrier { type: number sql: ${TABLE}.is_alternative_marketing_carrier ;; hidden: yes }
  dimension: is_mixed_fare_type           { type: number  sql: ${TABLE}.is_mixed_fare_type           ;; hidden: yes }
  dimension: is_risky                     { type: number  sql: ${TABLE}.is_risky                     ;; hidden: yes }
  dimension: is_rogue                     { type: number  sql: ${TABLE}.is_rogue                     ;; hidden: yes }
  dimension: is_downgrade                 { type: number  sql: ${TABLE}.is_downgrade                 ;; hidden: yes }
  dimension: is_promoted                  { type: number  sql: ${TABLE}.is_promoted                  ;; hidden: yes }
  dimension: is_demoted                   { type: number  sql: ${TABLE}.is_demoted                   ;; hidden: yes }
}
