view: optimizer_candidates {
  sql_table_name: ota.optimizer_candidates ;;

  dimension: id { primary_key: yes type: number sql: ${TABLE}.id ;; hidden: yes}
  dimension: parent_id { type: number sql: ${TABLE}.parent_id ;; hidden: yes}

  dimension_group: created_at {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }

  dimension: attempt_id { type: number sql: ${TABLE}.attempt_id ;; hidden: yes}
  dimension: rank       { type: number sql: ${TABLE}.rank ;; }
  dimension: candidacy  { type: string sql: ${TABLE}.candidacy ;; }

  dimension: gds            { type: string sql: ${TABLE}.gds ;; }
  dimension: gds_account_id { type: string sql: ${TABLE}.gds_account_id ;; }
  dimension: fare_type      { type: string sql: ${TABLE}.fare_type ;; }
  dimension: validating_carrier { type: string sql: ${TABLE}.validating_carrier ;; }
  dimension: pricing_options   { type: string sql: ${TABLE}.pricing_options ;; }
  dimension: flight_numbers    { type: string sql: ${TABLE}.flight_numbers ;; }
  dimension: commission_trip_id { type: number sql: ${TABLE}.commission_trip_id ;; }

  # Monetary fields
  dimension: base            { type: number value_format: "#,##0.00" sql: ${TABLE}.base ;; }
  dimension: tax             { type: number value_format: "#,##0.00" sql: ${TABLE}.tax ;; }
  dimension: markup          { type: number value_format: "#,##0.00" sql: ${TABLE}.markup ;; }
  dimension: total           { type: number value_format: "#,##0.00" sql: ${TABLE}.total ;; }
  dimension: commission      { type: number value_format: "#,##0.00" sql: ${TABLE}.commission ;; }
  dimension: merchant_fee    { type: number value_format: "#,##0.00" sql: ${TABLE}.merchant_fee ;; }
  dimension: supplier_fee    { type: number value_format: "#,##0.00" sql: ${TABLE}.supplier_fee ;; }
  dimension: revenue         { type: number value_format: "#,##0.00" sql: ${TABLE}.revenue ;; }
  dimension: dropnet_revenue { type: number value_format: "#,##0.00" sql: ${TABLE}.dropnet_revenue ;; }
  dimension: segment_revenue { type: number value_format: "#,##0.00" sql: ${TABLE}.segment_revenue ;; }

  dimension: booking_classes { type: string sql: ${TABLE}.booking_classes ;; }
  dimension: cabin_codes     { type: string sql: ${TABLE}.cabin_codes ;; }
  dimension: fare_bases      { type: string sql: ${TABLE}.fare_bases ;; }
  dimension: fare_families   { type: string sql: ${TABLE}.fare_families ;; }

  dimension: package_json { type: string sql: ${TABLE}.package ;; hidden: yes}

}
