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
