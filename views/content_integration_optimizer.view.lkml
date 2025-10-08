view: content_integration_optimizer {

  derived_table: {
    sql:
      WITH tags_agg AS (
        SELECT
          oct.candidate_id,

          GROUP_CONCAT(
            DISTINCT CONCAT(
              ot.name, ':', COALESCE(CASE WHEN ot.name = 'Original' THEN 'Yes' ELSE oct.value END, '')
            )
            ORDER BY ot.name, oct.value
            SEPARATOR ', '
          ) AS tag_pairs,

          /* Keep this mapping updated!!! */
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'MultiTicketPart' THEN oct.value END) AS multiticketpart_values,
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Original'        THEN 'Yes'       END) AS original_values,
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'AlternativeMarketingCarrier'       THEN oct.value END) AS alternative_marketing_carrier_values,
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Downgrade'       THEN oct.value END) AS downgrade_values,
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'KiwiVirtualInterlining'       THEN oct.value END) AS kiwi_virtual_interlining_values,
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'MixedFareType'       THEN oct.value END) AS mixed_fare_type_values,
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'NetUnderPub'       THEN oct.value END) AS net_under_pub_values,
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'SearchBoosterDiscount'       THEN oct.value END) AS search_booster_discount_values,
          GROUP_CONCAT(DISTINCT CASE WHEN ot.name = 'Exception'       THEN oct.value END) AS exception_values

        FROM ota.optimizer_candidate_tags oct
        JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
        GROUP BY oct.candidate_id
        )

        SELECT
        oc.id as contestant_id,
        oc.created_at,
        oc.parent_id,
        oc.attempt_id,
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
        ta.multiticketpart_values,
        ta.original_values,
        ta.alternative_marketing_carrier_values,
        ta.downgrade_values,
        ta.kiwi_virtual_interlining_values,
        ta.mixed_fare_type_values,
        ta.net_under_pub_values,
        ta.search_booster_discount_values,
        ta.exception_values

        FROM optimizer_candidates oc
        LEFT JOIN optimizer_attempts oa ON oc.attempt_id = oa.id
        LEFT JOIN optimizer_attempt_bookings oab ON oab.attempt_id = oa.id
        LEFT JOIN tags_agg ta ON oc.id = ta.candidate_id
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
  }

  dimension_group: date {
    type: time
    timeframes: [raw, time, minute, hour, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
    group_label: "1. Time"
  }


  # -------------------------
  # Dimensions
  # -------------------------

  dimension: parent_id            { type: number sql: ${TABLE}.parent_id ;; }
  dimension: attempt_id           { type: number sql: ${TABLE}.attempt_id ;; }
  dimension: booking_order        { type: number sql: ${TABLE}.rank ;; }

  dimension: search_id            { type: number sql: ${TABLE}.search_id ;; }
  dimension: package_id           { type: number sql: ${TABLE}.package_id ;; }
  dimension: checkout_id          { type: number sql: ${TABLE}.checkout_id ;; }

  dimension: affiliate_id         { type: number sql: ${TABLE}.affiliate_id ;; }
  dimension: target_id            { type: number sql: ${TABLE}.target_id ;; }
  dimension: booking_id           { type: number sql: ${TABLE}.booking_id ;; }

  dimension: gds_account_id       { type: number sql: ${TABLE}.gds_account_id ;; }
  dimension: commission_trip_id   { type: number sql: ${TABLE}.commission_trip_id ;; }

  # ----- Categorical -----
  dimension: candidacy {
    type: string
    sql: ${TABLE}.candidacy ;;
    description: "Candidate eligibility status"
    group_label: "General"
    suggestions: ["Unprocessable", "Unbookable", "Inadmissible", "Unsalable", "Incalculable", "Unmatchable", "Unprofitable", "Eligible"]

  }

  dimension: gds                  { type: string sql: ${TABLE}.gds ;; group_label: "General"}
  dimension: currency             { type: string sql: ${TABLE}.currency ;; group_label: "General"}
  dimension: fare_type            { type: string sql: ${TABLE}.fare_type ;; group_label: "General"}
  dimension: validating_carrier   { type: string sql: ${TABLE}.validating_carrier ;; group_label: "General"}
  dimension: pricing_options      { type: string sql: ${TABLE}.pricing_options ;; group_label: "General"}
  dimension: flight_numbers       { type: string sql: ${TABLE}.flight_numbers ;; group_label: "General"}
  dimension: booking_classes      { type: string sql: ${TABLE}.booking_classes ;; group_label: "General"}
  dimension: cabin_codes          { type: string sql: ${TABLE}.cabin_codes ;; group_label: "General"}
  dimension: fare_bases           { type: string sql: ${TABLE}.fare_bases ;; group_label: "General"}
  dimension: fare_families        { type: string sql: ${TABLE}.fare_families ;; group_label: "General"}
  dimension: trip_type            { type: string sql: ${TABLE}.trip_type ;; group_label: "General"}

  # ----- Monetary -----
  dimension: base                 { type: number value_format: "#,##0.00" sql: ${TABLE}.base ;; }
  dimension: tax                  { type: number value_format: "#,##0.00" sql: ${TABLE}.tax ;; }
  dimension: markup               { type: number value_format: "#,##0.00" sql: ${TABLE}.markup ;; }
  dimension: total                { type: number value_format: "#,##0.00" sql: ${TABLE}.total ;; }

  dimension: merchant_fee         { type: number value_format: "#,##0.00" sql: ${TABLE}.merchant_fee ;; }
  dimension: supplier_fee         { type: number value_format: "#,##0.00" sql: ${TABLE}.supplier_fee ;; }

  dimension: commission           { type: number value_format: "#,##0.00" sql: ${TABLE}.commission ;; }
  dimension: dropnet_revenue      { type: number value_format: "#,##0.00" sql: ${TABLE}.dropnet_revenue ;; }
  dimension: segment_revenue      { type: number value_format: "#,##0.00" sql: ${TABLE}.segment_revenue ;; }

  dimension: revenue              { type: number value_format: "#,##0.00" sql: ${TABLE}.revenue ;; }


  # ----- Tags -----

  dimension: tag_pairs {
    type: string
    description: "All tag key:value pairs (for debug only)."
    sql: ${TABLE}.tag_pairs ;;
    group_label: "Tags"
  }

  # dimension: multicurrency {
  #   type: string
  #   sql: ${TABLE}.multicurrency_values ;;
  #   group_label: "Tags"
  # }
  # need to rewrite it rely on the currency from original/attempt to the candidate


  dimension: multiticket_part {
    type: string
    sql: ${TABLE}.multiticketpart_values ;;
    group_label: "Tags"
  }

  dimension: is_original {
    type: yesno
    sql: CASE WHEN ${TABLE}.original_values LIKE 'Yes' THEN TRUE ELSE FALSE END ;;
    group_label: "Tags"
  }

  dimension: reprice_index {
    type: string
    sql: ${TABLE}.reprice_index ;;
    group_label: "Tags"
  }

  dimension: has_exception {
    type: yesno
    sql: CASE WHEN ${exception_values} IS NOT NULL AND ${exception_values} <> '' THEN TRUE ELSE FALSE END ;;
    group_label: "Tags"
  }

  dimension: exception_values {
    type: string
    sql: ${TABLE}.exception_values ;;
    group_label: "Tags"
  }

  dimension: alternative_marketing_carrier_values {
    type: string
    sql: ${TABLE}.alternative_marketing_carrier_values ;;
    group_label: "Tags"
  }

  dimension: downgrade_values {
    type: string
    sql: ${TABLE}.downgrade_values ;;
    group_label: "Tags"
  }

  dimension: kiwi_virtual_interlining_values {
    type: string
    sql: ${TABLE}.kiwi_virtual_interlining_values ;;
    group_label: "Tags"
  }

  dimension: mixed_fare_type_values {
    type: string
    sql: ${TABLE}.mixed_fare_type_values ;;
    group_label: "Tags"
  }

  dimension: net_under_pub_values {
    type: string
    sql: ${TABLE}.net_under_pub_values ;;
    group_label: "Tags"
  }

  dimension: search_booster_discount_values {
    type: string
    sql: ${TABLE}.search_booster_discount_values ;;
    group_label: "Tags"
  }


  # -------------------------
  # Measures
  # -------------------------

  measure: all_contestants_count {
    type: count_distinct
    sql: ${contestant_id} ;;
  }



}
