view: content_integration_optimizer {

  derived_table: {
    sql:
      WITH pairs AS (
        SELECT
          oct.candidate_id,
          ot.name  AS tag_name,
          CASE WHEN ot.name = 'Original' THEN 'Yes' ELSE oct.value END  AS tag_value
        FROM ota.optimizer_candidate_tags oct
        JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
        GROUP BY oct.candidate_id, ot.name, oct.value
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

        -- need to keep this updated
        GROUP_CONCAT(DISTINCT CONCAT(p.tag_name, ':', COALESCE(p.tag_value, '')) ORDER BY p.tag_name, p.tag_value SEPARATOR ', ') AS tag_pairs,
        GROUP_CONCAT(DISTINCT CASE WHEN p.tag_name = 'MultiCurrency'                    THEN p.tag_value END) AS multicurrency_values,
        GROUP_CONCAT(DISTINCT CASE WHEN p.tag_name = 'MultiTicketPart'                  THEN p.tag_value END) AS multiticketpart_values,
        GROUP_CONCAT(DISTINCT CASE WHEN p.tag_name = 'Original'                         THEN p.tag_value END) AS original_values,
        GROUP_CONCAT(DISTINCT CASE WHEN p.tag_name = 'Exception'                        THEN p.tag_value END) AS exception_values

      FROM optimizer_candidates oc
      LEFT JOIN optimizer_attempts oa ON oc.attempt_id = oa.id
      LEFT JOIN optimizer_attempt_bookings oab ON oab.attempt_id = oa.id
      LEFT JOIN pairs p ON oc.id = p.candidate_id

      GROUP BY p.candidate_id
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
  dimension: candidacy            { type: string sql: ${TABLE}.candidacy ;; }
  dimension: gds                  { type: string sql: ${TABLE}.gds ;; }
  dimension: currency             { type: string sql: ${TABLE}.currency ;; }
  dimension: fare_type            { type: string sql: ${TABLE}.fare_type ;; }
  dimension: validating_carrier   { type: string sql: ${TABLE}.validating_carrier ;; }
  dimension: pricing_options      { type: string sql: ${TABLE}.pricing_options ;; }
  dimension: flight_numbers       { type: string sql: ${TABLE}.flight_numbers ;; }
  dimension: booking_classes      { type: string sql: ${TABLE}.booking_classes ;; }
  dimension: cabin_codes          { type: string sql: ${TABLE}.cabin_codes ;; }
  dimension: fare_bases           { type: string sql: ${TABLE}.fare_bases ;; }
  dimension: fare_families        { type: string sql: ${TABLE}.fare_families ;; }
  dimension: trip_type            { type: string sql: ${TABLE}.trip_type ;; }

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

  dimension: multicurrency {
    type: string
    sql: ${TABLE}.multicurrency_values ;;
    group_label: "Tags"
  }

  dimension: multiticket_part {
    type: string
    sql: ${TABLE}.multiticketpart_values ;;
    group_label: "Tags"
  }

  dimension: is_original {
    type: yesno
    sql: CASE WHEN ${TABLE}.original_value LIKE '%Yes%' THEN TRUE ELSE FALSE END ;;
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


  # -------------------------
  # Measures
  # -------------------------

  measure: all_contestants_count {
    type: count
  }

  measure: contestants {
    type: count_distinct
    sql: ${contestant_id} ;;
  }

  measure: attempts {
    type: count_distinct
    sql: ${attempt_id} ;;
  }

  measure: bookings {
    type: count_distinct
    sql: ${booking_id} ;;
  }

  measure: searches {
    type: count_distinct
    sql: ${search_id} ;;
  }

  # Money rollups
  measure: sum_base            { type: sum sql: ${base} ;; }
  measure: sum_tax             { type: sum sql: ${tax} ;; }
  measure: sum_markup          { type: sum sql: ${markup} ;; }
  measure: sum_total           { type: sum sql: ${total} ;; }
  measure: sum_commission      { type: sum sql: ${commission} ;; }
  measure: sum_merchant_fee    { type: sum sql: ${merchant_fee} ;; }
  measure: sum_supplier_fee    { type: sum sql: ${supplier_fee} ;; }
  measure: sum_revenue         { type: sum sql: ${revenue} ;; }
  measure: sum_dropnet_revenue { type: sum sql: ${dropnet_revenue} ;; }
  measure: sum_segment_revenue { type: sum sql: ${segment_revenue} ;; }

  # Averages & Extremes
  measure: avg_total     { type: average sql: ${total} ;; }
  measure: avg_revenue   { type: average sql: ${revenue} ;; }
  measure: max_total     { type: max sql: ${total} ;; }
  measure: min_total     { type: min sql: ${total} ;; }

  # Ratios (null-safe where possible)
  measure: revenue_per_booking {
    type: number
    value_format: "#,##0.00"
    sql: CASE WHEN ${bookings} > 0 THEN ${sum_revenue} / NULLIF(${bookings}, 0) END ;;
  }

  measure: margin_amount {
    type: number
    value_format: "#,##0.00"
    sql: ${sum_revenue} - ${sum_supplier_fee} - ${sum_merchant_fee} ;;
  }

  measure: margin_pct {
    type: number
    value_format: "0.0%"
    sql: CASE WHEN ${sum_revenue} <> 0 THEN (${margin_amount}) / NULLIF(${sum_revenue}, 0) END ;;
  }

  # Tag-based counts
  measure: exception_rows {
    type: count
    filters: [has_exception: "yes"]
  }

  measure: original_rows {
    type: count
    filters: [is_original: "yes"]
  }

}
