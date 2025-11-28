view: content_integration_optimizer {

  parameter: start_date {
    type: date
    default_value: "2025-01-01"
  }

  derived_table: {
    sql:
      WITH tags_agg AS (
        SELECT
          oct.candidate_id,

          /* This field is for debugging - It shows all tags for a contestant */
          GROUP_CONCAT(
            DISTINCT CONCAT(
                ot.name, ':', COALESCE(oct.value, '')
            )
            ORDER BY ot.name, oct.value
            SEPARATOR ', '
          ) AS tag_pairs,

          /* Keep this mapping updated!!! */
          CASE WHEN ot.name = 'Exception' THEN oct.value END AS exception_values,
          CASE WHEN ot.name = 'MultiTicketPart' THEN oct.value END AS multiticket_part_values,
          CASE WHEN ot.name = 'Downgrade' THEN oct.value END AS downgrade_values,
          CASE WHEN ot.name = 'MixedFareType' THEN 1 ELSE 0 END AS is_mixed_fare_type,
          CASE WHEN ot.name = 'AlternativeMarketingCarrier' THEN 1 ELSE 0 END AS is_alternative_marketing_carrier,
          CASE WHEN ot.name = 'Risky' THEN 1 ELSE 0 END AS is_risky_values

        FROM ota.optimizer_candidate_tags oct
        JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
        WHERE oct.created_at > {% parameter start_date %}
        GROUP BY oct.candidate_id
        )

        SELECT
          oc.id as contestant_id,
          oc.created_at,
          oc.parent_id,
          oc.attempt_id,
          oc.reprice_type,
          oc.reprice_index,
          oc.rank,
          oc.candidacy,
          oc.gds,
          oc.gds_account_id,
          oc.currency,
          oc.fare_type,
          oc.validating_carrier,
          oc.pricing_options,
          oc.flight_numbers,
          oc.commission_trip_id,
          oc.base,
          oc.tax,
          oc.markup,
          oc.total,
          oc.commission,
          oc.merchant_fee,
          oc.supplier_fee,
          oc.revenue,
          oc.dropnet_revenue,
          oc.segment_revenue,
          oc.booking_classes,
          oc.cabin_codes,
          oc.fare_bases,
          oc.fare_families,

          oa.search_id,
          oa.package_id,
          oa.checkout_id,
          oa.trip_type,
          oa.affiliate_id,
          oa.target_id,

          oab.booking_id,

          ta.tag_pairs,
          ta.exception_values,
          ta.multiticket_part_values,
          ta.downgrade_values,
          ta.is_mixed_fare_type,
          ta.is_alternative_marketing_carrier,
          ta.is_risky_values

        FROM optimizer_candidates oc
        LEFT JOIN optimizer_attempts oa ON oc.attempt_id = oa.id
        LEFT JOIN optimizer_attempt_bookings oab ON oab.candidate_id = oc.id
        LEFT JOIN tags_agg ta ON oc.id = ta.candidate_id
        WHERE oc.created_at > {% parameter start_date %}
        GROUP BY oc.id
      ;;
  }

  # -------------------------
  # Dimension groups / keys
  # -------------------------

  dimension: contestant_id {
    type: number
    sql: ${TABLE}.contestant_id ;;
    hidden: yes
    group_label: "2. CONTESTANT INFO"
  }

  dimension_group: date {
    type: time
    timeframes: [raw, time, minute, hour, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
    group_label: "1. DATE"
  }


  # -------------------------
  # Dimensions
  # -------------------------

  dimension: parent_id            { type: number sql: ${TABLE}.parent_id ;; group_label: "2. CONTESTANT INFO" }
  dimension: attempt_id           { type: number sql: ${TABLE}.attempt_id ;; group_label: "2. CONTESTANT INFO" }
  dimension: booking_order        { type: number sql: ${TABLE}.rank ;; group_label: "2. CONTESTANT INFO" }

  dimension: search_id            { type: number sql: ${TABLE}.search_id ;; group_label: "2. CONTESTANT INFO" }
  dimension: package_id           { type: number sql: ${TABLE}.package_id ;; group_label: "2. CONTESTANT INFO" }
  dimension: checkout_id          { type: number sql: ${TABLE}.checkout_id ;; group_label: "2. CONTESTANT INFO" }

  dimension: affiliate_id         { type: number sql: ${TABLE}.affiliate_id ;; group_label: "2. CONTESTANT INFO" }
  dimension: target_id            { type: number sql: ${TABLE}.target_id ;; group_label: "2. CONTESTANT INFO" }
  dimension: booking_id           { type: number sql: ${TABLE}.booking_id ;; group_label: "2. CONTESTANT INFO" }

  dimension: debug_link {
    type: string
    sql: CASE 
      WHEN ${booking_id} IS NOT NULL 
      THEN CONCAT('https://reservations.voyagesalacarte.ca/booking/index/', ${booking_id})
      ELSE CONCAT('https://reservations.voyagesalacarte.ca/debug-logs/log-group/', ${search_id})
    END ;;
    html: <a href="{{ value }}" target="_blank">View</a> ;;
    label: "Debug Link"
    description: "Link to booking page with booking_id if booking exists, otherwise link to debug logs with search_id"
    group_label: "2. CONTESTANT INFO"
  }

  dimension: gds_account_id       { type: number sql: ${TABLE}.gds_account_id ;; group_label: "2. CONTESTANT INFO" }
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
  dimension: trip_type            { type: string sql: ${TABLE}.trip_type ;; group_label: "2. CONTESTANT INFO"}

  # ----- Categorical -----
  dimension: candidacy {
    type: string
    sql: ${TABLE}.candidacy ;;
    description: "Candidate eligibility status"
    group_label: "3. BUCKETS"
    suggestions: ["Unprocessable", "Unbookable", "Inadmissible", "Unsalable", "Incalculable", "Unmatchable", "Unprofitable", "Eligible"]

  }

  # ----- Monetary -----
  dimension: candidate_currency   { type: string sql: ${TABLE}.candidate_currency ;; group_label: "MONETARY"}
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




  # ----- Contestant Info (Tag-related) -----
  dimension: is_multicurrency {
    type: yesno
    sql: CASE
          WHEN ${TABLE}.candidate_currency IS NOT NULL
               AND ${TABLE}.currency IS NOT NULL
               AND ${TABLE}.candidate_currency <> ${TABLE}.currency
          THEN TRUE
          ELSE FALSE
        END ;;
    group_label: "2. CONTESTANT INFO"
    hidden: yes
    description: "Check if candidate currency differs from attempt currency."
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

  dimension: multiticket_part {
    type: string
    sql: ${TABLE}.multiticket_part_values ;;
    group_label: "2. CONTESTANT INFO"
  }

  dimension: reprice_index {
    type: string
    sql: ${TABLE}.reprice_index ;;
    group_label: "2. CONTESTANT INFO"
  }

  dimension: has_exception {
    type: yesno
    sql: CASE WHEN ${exception_values} IS NOT NULL AND ${exception_values} <> '' THEN TRUE ELSE FALSE END ;;
    group_label: "2. CONTESTANT INFO"
    description: "Only ineligible candidates have an exception."
    hidden: yes
  }

  dimension: exception_values {
    type: string
    sql: ${TABLE}.exception_values ;;
    group_label: "2. CONTESTANT INFO"
  }

  dimension: is_alternative_marketing_carrier {
    type: yesno
    sql: CASE WHEN ${TABLE}.is_alternative_marketing_carrier LIKE '%1%' THEN TRUE ELSE FALSE END ;;
    group_label: "2. CONTESTANT INFO"
    description: "Check if candidate has AlternativeMarketingCarrier tag"
  }

  dimension: downgrade_values {
    type: string
    sql: ${TABLE}.downgrade_values ;;
    group_label: "2. CONTESTANT INFO"
  }

  dimension: is_mixed_fare_type {
    type: yesno
    sql: CASE WHEN ${TABLE}.is_mixed_fare_type LIKE '%1%' THEN TRUE ELSE FALSE END ;;
    group_label: "2. CONTESTANT INFO"
    description: "Check if candidate has MixedFareType tag"
  }

  dimension: is_risky {
    type: yesno
    sql: CASE WHEN ${TABLE}.is_risky_values LIKE '%1%' THEN TRUE ELSE FALSE END ;;
    group_label: "2. CONTESTANT INFO"
    description: "Check if candidate has Risky tag"
  }

  dimension: is_unique_contestant {
    type: yesno
    sql: CASE 
          WHEN (
            SELECT COUNT(DISTINCT oc2.gds)
            FROM optimizer_candidates oc2
            WHERE oc2.attempt_id = ${attempt_id}
              AND oc2.candidacy = 'Eligible'
              AND oc2.created_at > {% parameter start_date %}
          ) = 1 
          THEN TRUE 
          ELSE FALSE 
        END ;;
    group_label: "2. CONTESTANT INFO"
    description: "True when the attempt_id has only one distinct GDS value across eligible contestants"
  }

  # ----- Tags (Debug) -----
  dimension: tag_pairs {
    type: string
    description: "All tag key:value pairs (for debug only)."
    sql: ${TABLE}.tag_pairs ;;
    group_label: "TAGS"
  }


  ## IS single to multy add a dimension


  # -------------------------
  # Measures
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

  measure: eligibility_rate {
    type: number
    sql: ${eligible_contestants_count} / NULLIF(${all_contestants_count}, 0) ;;
    value_format: "0.00%"
    label: "Eligibility Rate"
    description: "Percentage of eligible contestants out of all contestants"
    group_label: "Rates"
  }

  ## add some measures


}
