view: content_integration_optimizer {
  sql_table_name: ota.optimizer_candidates ;;

  # -------------------------
  # Parameters
  # -------------------------

  parameter: start_date {
    type: date
    default_value: "2025-01-01"
  }

  # -------------------------
  # Keys (hidden)
  # -------------------------

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
    hidden: yes
  }

  # -------------------------
  # 1. DATE
  # -------------------------

  dimension_group: date {
    type: time
    timeframes: [raw, time, minute, hour, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
    group_label: "1. DATE"
  }

  # -------------------------
  # 2. CONTESTANT INFO
  # -------------------------

  dimension: contestant_id {
    type: number
    sql: ${TABLE}.id ;;
    group_label: "2. CONTESTANT INFO"
  }

  dimension: parent_id            { type: number sql: ${TABLE}.parent_id ;; group_label: "2. CONTESTANT INFO" }
  dimension: attempt_id           { type: number sql: ${TABLE}.attempt_id ;; group_label: "2. CONTESTANT INFO" }
  dimension: booking_order        { type: number sql: ${TABLE}.rank ;; group_label: "2. CONTESTANT INFO" }

  dimension: search_id            { type: number sql: ${optimizer_attempts.search_id} ;; group_label: "2. CONTESTANT INFO" }
  dimension: package_id           { type: number sql: ${optimizer_attempts.package_id} ;; group_label: "2. CONTESTANT INFO" }
  dimension: checkout_id          { type: number sql: ${optimizer_attempts.checkout_id} ;; group_label: "2. CONTESTANT INFO" }

  dimension: affiliate_id         { type: number sql: ${optimizer_attempts.affiliate_id} ;; group_label: "2. CONTESTANT INFO" }
  dimension: target_id            { type: number sql: ${optimizer_attempts.target_id} ;; group_label: "2. CONTESTANT INFO" }
  dimension: booking_id           { type: number sql: ${optimizer_attempt_bookings.booking_id} ;; group_label: "2. CONTESTANT INFO" }

  dimension: debug_link {
    type: string
    sql: CASE
      WHEN ${optimizer_attempt_bookings.booking_id} IS NOT NULL
      THEN CONCAT('https://reservations.voyagesalacarte.ca/booking/index/', CAST(${optimizer_attempt_bookings.booking_id} AS CHAR))
      ELSE CONCAT('https://reservations.voyagesalacarte.ca/debug-logs/log-group/', CAST(${optimizer_attempts.search_id} AS CHAR))
    END ;;
    link: {
      label: "Debug Link"
      url: "{{ value }}"
    }
    description: "Link to booking page with booking_id if booking exists, otherwise link to debug logs with search_id"
    group_label: "2. CONTESTANT INFO"
  }

  dimension: gds_account_id       { type: string sql: ${TABLE}.gds_account_id ;; group_label: "2. CONTESTANT INFO" }
  dimension: commission_trip_id   { type: number sql: ${TABLE}.commission_trip_id ;; group_label: "2. CONTESTANT INFO" }

  dimension: gds                  { type: string sql: ${TABLE}.gds ;; group_label: "2. CONTESTANT INFO"}
  dimension: fare_type            { type: string sql: ${TABLE}.fare_type ;; group_label: "2. CONTESTANT INFO"}
  dimension: validating_carrier   { type: string sql: ${TABLE}.validating_carrier ;; group_label: "2. CONTESTANT INFO"}
  dimension: pricing_options      { type: string sql: ${TABLE}.pricing_options ;; group_label: "2. CONTESTANT INFO"}
  dimension: flight_numbers       { type: string sql: ${TABLE}.flight_numbers ;; group_label: "2. CONTESTANT INFO"}
  dimension: booking_classes      { type: string sql: ${TABLE}.booking_classes ;; group_label: "2. CONTESTANT INFO"}
  dimension: cabin_codes          { type: string sql: ${TABLE}.cabin_codes ;; group_label: "2. CONTESTANT INFO"}
  dimension: fare_bases           { type: string sql: ${TABLE}.fare_bases ;; group_label: "2. CONTESTANT INFO"}
  dimension: fare_families        { type: string sql: ${TABLE}.fare_families ;; group_label: "2. CONTESTANT INFO"}
  dimension: trip_type            { type: string sql: ${optimizer_attempts.trip_type} ;; group_label: "2. CONTESTANT INFO"}

  dimension: is_multicurrency {
    type: yesno
    sql: CASE
          WHEN ${TABLE}.currency IS NOT NULL
               AND ${optimizer_attempts.currency} IS NOT NULL
               AND ${TABLE}.currency <> ${optimizer_attempts.currency}
          THEN TRUE
          ELSE FALSE
        END ;;
    group_label: "2. CONTESTANT INFO"
    hidden: yes
    description: "Check if candidate currency differs from attempt currency."
  }

    dimension: multiticket_part {
    type: string
    sql: (
      SELECT GROUP_CONCAT(DISTINCT oct.value ORDER BY oct.value SEPARATOR ', ')
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'MultiTicketPart'
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ) ;;
    group_label: "2. CONTESTANT INFO"
  }

  dimension: is_original {
    type: yesno
    sql: CASE
          WHEN ${TABLE}.reprice_type = 'original' THEN TRUE
          ELSE FALSE
        END ;;
    group_label: "2. CONTESTANT INFO"
    description: "Check if candidate came from search."
  }

  dimension: reprice_index {
    type: string
    sql: ${TABLE}.reprice_index ;;
    group_label: "2. CONTESTANT INFO"
  }

  dimension: is_unique_contestant {
    type: yesno
    sql: CASE
          WHEN (
            SELECT COUNT(DISTINCT
              CASE
                WHEN oc2.gds = 'Amadeus'
                THEN CONCAT('Amadeus:', CAST(COALESCE(oc2.gds_account_id, 0) AS CHAR))
                ELSE oc2.gds
              END
            )
            FROM ota.optimizer_candidates oc2
            WHERE oc2.attempt_id = ${attempt_id}
              AND oc2.candidacy = 'Eligible'
              AND oc2.created_at > {% parameter content_integration_optimizer.start_date %}
          ) = 1
          AND (
            SELECT COUNT(*)
            FROM ota.optimizer_candidates oc3
            WHERE oc3.attempt_id = ${attempt_id}
              AND oc3.created_at > {% parameter content_integration_optimizer.start_date %}
              AND oc3.candidacy <> 'Eligible'
          ) >= 1
          THEN TRUE
          ELSE FALSE
        END ;;
    group_label: "2. CONTESTANT INFO"
    description: "NOTE! Very heavy! True when the attempt_id has only one distinct content source across eligible contestants (GDS for non-Amadeus, gds_account_id for Amadeus) and at least one contestant in other candidacy buckets"
  }

  dimension: is_optimizer_off {
    type: yesno
    sql: CASE
          WHEN (
            SELECT COUNT(*)
            FROM ota.optimizer_candidates oc2
            WHERE oc2.attempt_id = ${attempt_id}
              AND oc2.created_at > {% parameter content_integration_optimizer.start_date %}
          ) = 1
          THEN TRUE
          ELSE FALSE
        END ;;
    group_label: "2. CONTESTANT INFO"
    description: "True when the optimization attempt has only one contestant (optimizer likely off)"
  }

  dimension: is_optimized {
    type: yesno
    sql: CASE
          WHEN ${optimizer_attempt_bookings.booking_id} IS NOT NULL
            AND ${contestant_id} <> (
              SELECT oc_orig.id
              FROM ota.optimizer_candidates oc_orig
              WHERE oc_orig.attempt_id = ${attempt_id}
                AND oc_orig.reprice_type = 'original'
                AND oc_orig.created_at > {% parameter content_integration_optimizer.start_date %}
              LIMIT 1
            )
          THEN TRUE
          ELSE FALSE
        END ;;
    group_label: "2. CONTESTANT INFO"
    description: "NOTE! Very heavy! True if the booked contestant is not the original one (optimized)"
  }

  # -------------------------
  # 3. BUCKETS
  # -------------------------

  dimension: candidacy {
    type: string
    sql: ${TABLE}.candidacy ;;
    description: "Candidate eligibility status"
    group_label: "3. BUCKETS"
    suggestions: ["Unprocessable", "Unbookable", "Inadmissible", "Unsalable", "Incalculable", "Unmatchable", "Unprofitable", "Eligible"]
  }

  # -------------------------
  # MONETARY
  # -------------------------

  dimension: candidate_currency   { type: string sql: ${TABLE}.currency ;; group_label: "MONETARY"}
  dimension: base                 { type: number value_format: "#,##0.00" sql: ${TABLE}.base ;; group_label: "MONETARY" }
  dimension: tax                  { type: number value_format: "#,##0.00" sql: ${TABLE}.tax ;; group_label: "MONETARY" }
  dimension: markup               { type: number value_format: "#,##0.00" sql: ${TABLE}.markup ;; group_label: "MONETARY" }
  dimension: total                { type: number value_format: "#,##0.00" sql: ${TABLE}.total ;; group_label: "MONETARY" }

  dimension: merchant_fee         { type: number value_format: "#,##0.00" sql: ${TABLE}.merchant_fee ;; group_label: "MONETARY" }
  dimension: supplier_fee         { type: number value_format: "#,##0.00" sql: ${TABLE}.supplier_fee ;; group_label: "MONETARY" }

  dimension: commission           { type: number value_format: "#,##0.00" sql: ${TABLE}.commission ;; group_label: "MONETARY" }
  dimension: dropnet_revenue      { type: number value_format: "#,##0.00" sql: ${TABLE}.dropnet_revenue ;; group_label: "MONETARY" }
  dimension: segment_revenue      { type: number value_format: "#,##0.00" sql: ${TABLE}.segment_revenue ;; group_label: "MONETARY" }

  dimension: revenue              { type: number value_format: "#,##0.00" sql: ${TABLE}.revenue ;; group_label: "MONETARY" }

  # -------------------------
  # 4. TAGS
  # -------------------------

  dimension: exception {
    type: string
    sql: (
      SELECT GROUP_CONCAT(DISTINCT oct.value ORDER BY oct.value SEPARATOR ', ')
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'Exception'
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ) ;;
    group_label: "4. TAGS"
    description: "Reason for being ineligible"
  }

  dimension: is_alternative_marketing_carrier {
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'AlternativeMarketingCarrier'
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ) THEN TRUE ELSE FALSE END ;;
    group_label: "4. TAGS"
    description: "Check if candidate has AlternativeMarketingCarrier tag"
  }

  dimension: is_downgrade {
    type: yesno
    sql: COALESCE((
      SELECT MAX(CASE WHEN ot.name = 'Downgrade' THEN 1 ELSE 0 END)
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ), 0) = 1 ;;
    group_label: "4. TAGS"
    description: "True when the candidate has at least one Downgrade tag in the start_date window."
  }

  dimension: demoted_values {
    type: string
    sql: (
      SELECT GROUP_CONCAT(DISTINCT oct.value ORDER BY oct.value SEPARATOR ', ')
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'Demoted'
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ) ;;
    group_label: "4. TAGS"
    hidden: yes
    description: "Distinct Demoted tag values for this candidate, comma-separated."
  }

  dimension: promoted_values {
    type: string
    sql: (
      SELECT GROUP_CONCAT(DISTINCT oct.value ORDER BY oct.value SEPARATOR ', ')
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'Promoted'
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ) ;;
    group_label: "4. TAGS"
    hidden: yes
    description: "Distinct Promoted tag values for this candidate, comma-separated."
  }

  dimension: is_demoted {
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'Demoted'
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ) THEN TRUE ELSE FALSE END ;;
    group_label: "4. TAGS"
    description: "True when the candidate has a Demoted tag in range."
  }

  dimension: is_promoted {
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'Promoted'
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ) THEN TRUE ELSE FALSE END ;;
    group_label: "4. TAGS"
    description: "True when the candidate has a Promoted tag in range."
  }

  dimension: is_mixed_fare_type {
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'MixedFareType'
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ) THEN TRUE ELSE FALSE END ;;
    group_label: "4. TAGS"
    description: "Check if candidate has MixedFareType tag"
  }

  dimension: is_risky {
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'Risky'
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ) THEN TRUE ELSE FALSE END ;;
    group_label: "4. TAGS"
    description: "Check if candidate has Risky tag"
  }

  dimension: tag_pairs {
    type: string
    sql: (
      SELECT GROUP_CONCAT(
        DISTINCT CONCAT(ot.name, ':', COALESCE(oct.value, ''))
        ORDER BY ot.name, oct.value
        SEPARATOR ', '
      )
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND oct.created_at > {% parameter content_integration_optimizer.start_date %}
    ) ;;
    group_label: "4. TAGS"
    label: "Tag pairs (debug)"
    description: "Field for debugging and comparing raw concatenated output in the UI."
  }

  # -------------------------
  # Measures - Counts
  # -------------------------

  measure: all_contestants_count {
    type: count_distinct
    sql: ${contestant_id} ;;
    label: "All Contestants Count"
    description: "Count of distinct contestants (candidates)"
    group_label: "Counts"
  }

  measure: bookings_count {
    type: count_distinct
    sql: ${booking_id} ;;
    label: "Bookings Count"
    description: "Count of distinct bookings"
    group_label: "Counts"
  }

  measure: eligible_contestants_count {
    type: count_distinct
    sql: CASE WHEN ${candidacy} = 'Eligible' THEN ${contestant_id} END ;;
    label: "Eligible Contestants Count"
    description: "Count of distinct contestants with candidacy = 'Eligible'"
    group_label: "Counts"
  }

  measure: demoted_contestants_count {
    type: count_distinct
    sql: CASE WHEN ${is_demoted} = TRUE THEN ${contestant_id} END ;;
    label: "Demoted Contestants Count"
    description: "Count of distinct contestants with a Demoted tag in the start_date window"
    group_label: "Counts"
  }

  measure: promoted_contestants_count {
    type: count_distinct
    sql: CASE WHEN ${is_promoted} = TRUE THEN ${contestant_id} END ;;
    label: "Promoted Contestants Count"
    description: "Count of distinct contestants with a Promoted tag in the start_date window"
    group_label: "Counts"
  }

  measure: alternative_marketing_carrier_contestants_count {
    type: count_distinct
    sql: CASE WHEN ${is_alternative_marketing_carrier} = TRUE THEN ${contestant_id} END ;;
    label: "Alternative Marketing Carrier Contestants Count"
    description: "Count of distinct contestants with an AlternativeMarketingCarrier tag in the start_date window"
    group_label: "Counts"
  }

  measure: mixed_fare_type_contestants_count {
    type: count_distinct
    sql: CASE WHEN ${is_mixed_fare_type} = TRUE THEN ${contestant_id} END ;;
    label: "Mixed Fare Type Contestants Count"
    description: "Count of distinct contestants with a MixedFareType tag in the start_date window"
    group_label: "Counts"
  }

  measure: risky_contestants_count {
    type: count_distinct
    sql: CASE WHEN ${is_risky} = TRUE THEN ${contestant_id} END ;;
    label: "Risky Contestants Count"
    description: "Count of distinct contestants with a Risky tag in the start_date window"
    group_label: "Counts"
  }

  measure: unique_contestants_count {
    type: count_distinct
    sql: CASE WHEN ${is_unique_contestant} = TRUE THEN ${contestant_id} END ;;
    label: "Unique Contestants Count"
    description: "NOTE! Very heavy! Count of distinct contestants with unique content sources"
    group_label: "Counts"
    hidden: yes
  }

  # -------------------------
  # Measures - Rates
  # -------------------------

  measure: eligibility_rate {
    type: number
    sql: ${eligible_contestants_count} / NULLIF(${all_contestants_count}, 0) ;;
    value_format: "0.00%"
    label: "Eligibility Rate"
    description: "Percentage of eligible contestants out of all contestants"
    group_label: "Rates"
  }

  measure: demoted_rate {
    type: number
    sql: ${demoted_contestants_count} / NULLIF(${all_contestants_count}, 0) ;;
    value_format: "0.00%"
    label: "Demoted Rate"
    description: "Share of all contestants that have a Demoted tag in the start_date window"
    group_label: "Rates"
  }

  measure: promoted_rate {
    type: number
    sql: ${promoted_contestants_count} / NULLIF(${all_contestants_count}, 0) ;;
    value_format: "0.00%"
    label: "Promoted Rate"
    description: "Share of all contestants that have a Promoted tag in the start_date window"
    group_label: "Rates"
  }

  measure: alternative_marketing_carrier_proportion {
    type: number
    sql: ${alternative_marketing_carrier_contestants_count} / NULLIF(${all_contestants_count}, 0) ;;
    value_format: "0.00%"
    label: "Alternative Marketing Carrier Proportion"
    description: "Proportion of all contestants that have an AlternativeMarketingCarrier tag in the start_date window"
    group_label: "Rates"
  }

  measure: mixed_fare_type_proportion {
    type: number
    sql: ${mixed_fare_type_contestants_count} / NULLIF(${all_contestants_count}, 0) ;;
    value_format: "0.00%"
    label: "Mixed Fare Type Proportion"
    description: "Proportion of all contestants that have a MixedFareType tag in the start_date window"
    group_label: "Rates"
  }

  measure: risky_proportion {
    type: number
    sql: ${risky_contestants_count} / NULLIF(${all_contestants_count}, 0) ;;
    value_format: "0.00%"
    label: "Risky Proportion"
    description: "Proportion of all contestants that have a Risky tag in the start_date window"
    group_label: "Rates"
  }

  measure: unique_content_proportion {
    type: number
    sql: ${unique_contestants_count} / NULLIF(${all_contestants_count}, 0) ;;
    value_format: "0.00%"
    label: "Unique Content Proportion"
    description: "NOTE! Very heavy! Proportion of contestants that have unique content sources (only one distinct GDS for non-Amadeus, or one distinct gds_account_id for Amadeus) among eligible contestants"
    group_label: "Rates"
  }

}
