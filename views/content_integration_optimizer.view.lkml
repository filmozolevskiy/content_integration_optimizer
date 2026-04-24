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
  # Hidden helpers (shared SQL fragments; reference with ${...})
  # -------------------------

  dimension: start_date_bound {
    hidden: yes
    sql: TIMESTAMP({% parameter content_integration_optimizer.start_date %}) ;;
  }

  dimension: original_contestant_id {
    hidden: yes
    type: number
    sql: (
      SELECT oc_orig.id
      FROM ota.optimizer_candidates oc_orig
      WHERE oc_orig.attempt_id = ${TABLE}.attempt_id
        AND oc_orig.reprice_type = 'original'
        AND oc_orig.created_at > ${start_date_bound}
      LIMIT 1
    ) ;;
  }

  dimension: original_contestant_gds_account_id {
    hidden: yes
    type: string
    sql: (
      SELECT oc_orig.gds_account_id
      FROM ota.optimizer_candidates oc_orig
      WHERE oc_orig.attempt_id = ${TABLE}.attempt_id
        AND oc_orig.reprice_type = 'original'
        AND oc_orig.created_at > ${start_date_bound}
      LIMIT 1
    ) ;;
  }

  dimension: is_child_of_single_to_multi {
    hidden: yes
    type: yesno
    sql: EXISTS (
      SELECT 1
      FROM ota.optimizer_candidates oc_parent
      WHERE oc_parent.id = ${TABLE}.parent_id
        AND oc_parent.reprice_type = 'single_to_multi'
        AND oc_parent.created_at > ${start_date_bound}
    ) ;;
    description: "TEMPORARY: True if this contestant is a child of a 'single_to_multi' reprice type. This logic should be removed once the underlying data source correctly identifies these as Inadmissible."
  }

  dimension: has_next_eligible_candidate {
    hidden: yes
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_candidates oc2
      WHERE oc2.attempt_id = ${TABLE}.attempt_id
        AND oc2.created_at > ${start_date_bound}
        AND oc2.id <> ${TABLE}.id
        AND oc2.candidacy = 'Eligible'
        AND oc2.`rank` > ${TABLE}.rank
        AND NOT EXISTS (
          SELECT 1 FROM ota.optimizer_candidates oc_p
          WHERE oc_p.id = oc2.parent_id
            AND oc_p.reprice_type = 'single_to_multi'
            AND oc_p.created_at > ${start_date_bound}
        )
        AND NOT EXISTS (
          SELECT 1
          FROM ota.optimizer_candidate_tags oct
          INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
          WHERE oct.candidate_id = oc2.id
            AND ot.name = 'Promoted'
            AND oct.created_at > ${start_date_bound}
        )
    ) THEN TRUE ELSE FALSE END ;;
    description: "True when there is a next competitor: another Eligible contestant on the same attempt with strictly greater rank than this row, with no Promoted tag in the start_date window (exclude candidates tagged Promoted). Also excludes children of single_to_multi reprice types."
  }

  dimension: next_eligible_non_promoted_revenue {
    hidden: yes
    type: number
    sql: CASE WHEN ${has_next_eligible_candidate} THEN (
      SELECT oc2.revenue
      FROM ota.optimizer_candidates oc2
      WHERE oc2.attempt_id = ${TABLE}.attempt_id
        AND oc2.created_at > ${start_date_bound}
        AND oc2.id <> ${TABLE}.id
        AND oc2.candidacy = 'Eligible'
        AND oc2.`rank` > ${TABLE}.rank
        AND NOT EXISTS (
          SELECT 1 FROM ota.optimizer_candidates oc_p
          WHERE oc_p.id = oc2.parent_id
            AND oc_p.reprice_type = 'single_to_multi'
            AND oc_p.created_at > ${start_date_bound}
        )
        AND NOT EXISTS (
          SELECT 1
          FROM ota.optimizer_candidate_tags oct
          INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
          WHERE oct.candidate_id = oc2.id
            AND ot.name = 'Promoted'
            AND oct.created_at > ${start_date_bound}
        )
      ORDER BY oc2.`rank` ASC, oc2.id ASC
      LIMIT 1
    ) ELSE NULL END ;;
    description: "Revenue of the next Eligible, non-promoted contestant (by rank) when has_next_eligible_candidate; NULL otherwise. Excludes children of single_to_multi reprice types."
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
      WHEN ${booking_id} IS NOT NULL
      THEN CONCAT('https://reservations.voyagesalacarte.ca/booking/index/', CAST(${booking_id} AS CHAR))
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

  dimension: original_office_id {
    type: string
    sql: ${original_contestant_gds_account_id} ;;
    group_label: "2. CONTESTANT INFO"
    label: "Original Office ID"
    description: "The gds_account_id (office ID) of the ORIGINAL contestant on this attempt. Filtering by a specific value (e.g. 'DIDACAD') returns every candidate on attempts where that office was the original, so you can analyze the full distribution of content generated against it."
  }

  dimension: booked_contestant_office_id_on_attempt {
    type: string
    sql: (
      SELECT oc_booked.gds_account_id
      FROM ota.optimizer_attempt_bookings oab
      INNER JOIN ota.optimizer_candidates oc_booked ON oc_booked.id = oab.candidate_id
      WHERE oab.attempt_id = ${TABLE}.attempt_id
        AND oab.booking_id IS NOT NULL
        AND oc_booked.created_at > ${start_date_bound}
      LIMIT 1
    ) ;;
    group_label: "2. CONTESTANT INFO"
    label: "Booked Office ID (on Attempt)"
    description: "The gds_account_id (office ID) of the BOOKED contestant on this attempt, propagated to every row of the attempt. Useful for side-by-side comparison: which office sourced a Price/Drop candidate vs. which office actually got the booking. NULL when no booking exists on the attempt."
  }

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

  # dimension: is_multicurrency {
  #   type: yesno
  #   sql: CASE
  #         WHEN ${TABLE}.currency IS NOT NULL
  #             AND ${optimizer_attempts.currency} IS NOT NULL
  #             AND ${TABLE}.currency <> ${optimizer_attempts.currency}
  #         THEN TRUE
  #         ELSE FALSE
  #       END ;;
  #   group_label: "2. CONTESTANT INFO"
  #   hidden: yes
  #   description: "Check if candidate currency differs from attempt currency."
  # }

  dimension: multiticket_part {
    type: string
    sql: (
      SELECT GROUP_CONCAT(DISTINCT oct.value ORDER BY oct.value SEPARATOR ', ')
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'MultiTicketPart'
        AND oct.created_at > ${start_date_bound}
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

  dimension: reprice_type {
    type: string
    sql: ${TABLE}.reprice_type ;;
    group_label: "2. CONTESTANT INFO"
    description: "The type of repricing applied to this candidate (e.g., original, single_to_multi, etc.)"
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
              AND oc2.created_at > ${start_date_bound}
              AND NOT EXISTS (
                SELECT 1 FROM ota.optimizer_candidates oc_p
                WHERE oc_p.id = oc2.parent_id
                  AND oc_p.reprice_type = 'single_to_multi'
                  AND oc_p.created_at > ${start_date_bound}
              )
          ) = 1
          AND (
            SELECT COUNT(*)
            FROM ota.optimizer_candidates oc3
            WHERE oc3.attempt_id = ${attempt_id}
              AND oc3.created_at > ${start_date_bound}
              AND (oc3.candidacy <> 'Eligible' OR EXISTS (
                SELECT 1 FROM ota.optimizer_candidates oc_p
                WHERE oc_p.id = oc3.parent_id
                  AND oc_p.reprice_type = 'single_to_multi'
                  AND oc_p.created_at > ${start_date_bound}
              ))
          ) >= 1
          THEN TRUE
          ELSE FALSE
        END ;;
    group_label: "2. CONTESTANT INFO"
    description: "NOTE! Very heavy! True when the attempt_id has only one distinct content source across eligible contestants (GDS for non-Amadeus, gds_account_id for Amadeus) and at least one contestant in other candidacy buckets. Excludes children of single_to_multi reprice types from eligibility."
  }

  dimension: is_optimizer_off {
    type: yesno
    sql: CASE
          WHEN (
            SELECT COUNT(*)
            FROM ota.optimizer_candidates oc2
            WHERE oc2.attempt_id = ${attempt_id}
              AND oc2.created_at > ${start_date_bound}
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
          WHEN ${booking_id} IS NOT NULL
            AND NOT ${is_original}
          THEN TRUE
          ELSE FALSE
        END ;;
    group_label: "2. CONTESTANT INFO"
    description: "True if the booked contestant is not the original one (optimized). Uses is_original to identify the starting contestant."
  }

  # -------------------------
  # 3. BUCKETS
  # -------------------------

  dimension: candidacy {
    type: string
    sql: CASE
          WHEN ${is_child_of_single_to_multi} THEN 'Inadmissible'
          ELSE ${TABLE}.candidacy
        END ;;
    description: "TEMPORARY OVERRIDE: Candidate eligibility status. Overrides 'Eligible' to 'Inadmissible' if the contestant is a child of a 'single_to_multi' reprice type. This override should be removed once the source data is corrected."
    group_label: "3. BUCKETS"
    suggestions: ["Unprocessable", "Unbookable", "Inadmissible", "Unsalable", "Incalculable", "Unmatchable", "Unprofitable", "Eligible"]
  }

  # -------------------------
  # MONETARY
  # -------------------------

  dimension: candidate_currency   { type: string sql: ${TABLE}.currency ;; group_label: "MONETARY"}

  dimension: displayed_currency {
    type: string
    sql: (
      SELECT bca.display_currency
      FROM ota.bookability_customer_attempts bca
      WHERE bca.search_hash = ${optimizer_attempts.search_id}
        AND bca.date_created > ${start_date_bound}
      ORDER BY bca.date_created DESC
      LIMIT 1
    ) ;;
    group_label: "MONETARY"
    label: "Displayed Currency"
    description: "Currency displayed to the customer on the search results page, pulled from ota.bookability_customer_attempts by matching search_hash to optimizer_attempts.search_id. When multiple bookability records exist for the same search_hash, returns the most recent one (by date_created). Filtered to date_created > start_date_bound for performance."
  }

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

  dimension: original_contestant_revenue {
    type: number
    value_format: "#,##0.00"
    sql: (
      SELECT oc_orig.revenue
      FROM ota.optimizer_candidates oc_orig
      WHERE oc_orig.attempt_id = ${TABLE}.attempt_id
        AND oc_orig.reprice_type = 'original'
        AND oc_orig.created_at > ${start_date_bound}
      LIMIT 1
    ) ;;
    group_label: "MONETARY"
    label: "Original Contestant Revenue"
    description: "Revenue of the ORIGINAL contestant (reprice_type = 'original') on this attempt. Every row on the same attempt returns the same value, so it can be used for side-by-side comparison against this row's revenue. NOTE: summing this field across rows will multi-count per attempt — use it as a dimension or filter, not as a measure-source."
  }

  dimension: booked_contestant_revenue {
    type: number
    value_format: "#,##0.00"
    sql: CASE WHEN ${booking_id} IS NOT NULL THEN ${revenue} END ;;
    group_label: "MONETARY"
    label: "Booked Contestant Revenue"
    description: "Revenue of the booked contestant on this attempt. Populated only on the candidate row that was actually booked (i.e. where booking_id is not null); NULL on other candidates of the same attempt. Safe to sum across any grouping — each attempt contributes at most one row."
  }

  dimension: booked_contestant_revenue_on_attempt {
    type: number
    value_format: "#,##0.00"
    sql: (
      SELECT oc_booked.revenue
      FROM ota.optimizer_attempt_bookings oab
      INNER JOIN ota.optimizer_candidates oc_booked ON oc_booked.id = oab.candidate_id
      WHERE oab.attempt_id = ${TABLE}.attempt_id
        AND oab.booking_id IS NOT NULL
        AND oc_booked.created_at > ${start_date_bound}
      LIMIT 1
    ) ;;
    group_label: "MONETARY"
    label: "Booked Contestant Revenue (on Attempt)"
    description: "Revenue of the BOOKED contestant on this attempt, propagated to every row of the attempt. Use for side-by-side comparison against this row's revenue (e.g., compare a Price or Drop candidate to whatever got booked). NULL when no booking exists on the attempt. NOTE: summing this field across rows will multi-count per attempt — use it as a dimension or filter, not as a measure source. For safe-to-sum totals, use `booked_contestant_revenue` instead."
  }

  dimension: promoted_booking_extra_revenue {
    type: number
    value_format: "#,##0.00"
    sql: CASE
      WHEN ${booking_id} IS NOT NULL
        AND ${is_promoted}
        AND ${is_booking_successful}
      THEN
        CASE
          WHEN ${has_next_eligible_candidate}
          THEN
            CASE
              WHEN ${next_eligible_non_promoted_revenue} IS NULL
              THEN NULL
              WHEN (${TABLE}.revenue - ${next_eligible_non_promoted_revenue}) < 0
              THEN NULL
              ELSE ABS(${TABLE}.revenue - ${next_eligible_non_promoted_revenue})
            END
          ELSE ${TABLE}.revenue
        END
      ELSE NULL
    END ;;
    group_label: "MONETARY"
    description: "Booked + Promoted + Successful only: when another Eligible non-promoted competitor exists at a higher rank on this attempt, value is absolute uplift vs that contestant (algebraic difference; 0.00 on tie; both revenues may be negative). When there is no such next competitor, value is this row's revenue only. NULL when a next competitor exists but this row is strictly worse than it (negative uplift), on rare data inconsistencies, or when not booked/not promoted/not successful. Does not compare to the original search contestant—use original_contestant_revenue vs revenue separately if you need that."
  }

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
        AND oct.created_at > ${start_date_bound}
    ) ;;
    group_label: "4. TAGS"
    description: "Reason for being ineligible"
  }

  dimension: dropped_reason {
    type: string
    sql: (
      SELECT GROUP_CONCAT(DISTINCT oct.value ORDER BY oct.value SEPARATOR ', ')
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'Dropped'
        AND oct.created_at > ${start_date_bound}
    ) ;;
    group_label: "4. TAGS"
    description: "Reason for dropped"
  }


  dimension: is_alternative_marketing_carrier {
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'AlternativeMarketingCarrier'
        AND oct.created_at > ${start_date_bound}
    ) THEN TRUE ELSE FALSE END ;;
    group_label: "4. TAGS"
    description: "Check if candidate has AlternativeMarketingCarrier tag"
  }

  dimension: is_multicurrency {
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_candidate_tags oct
      WHERE oct.candidate_id = ${TABLE}.id
        AND oct.reprice_type = 'multicurrency'
        AND oct.created_at > ${start_date_bound}
    ) THEN TRUE ELSE FALSE END ;;
    group_label: "4. TAGS"
    description: "Check if candidate currency differs from attempt currency."
  }

  dimension: is_downgrade {
    type: yesno
    sql: COALESCE((
      SELECT MAX(CASE WHEN ot.name = 'Downgrade' THEN 1 ELSE 0 END)
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND oct.created_at > ${start_date_bound}
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
        AND oct.created_at > ${start_date_bound}
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
        AND oct.created_at > ${start_date_bound}
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
        AND oct.created_at > ${start_date_bound}
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
        AND oct.created_at > ${start_date_bound}
    ) THEN TRUE ELSE FALSE END ;;
    group_label: "4. TAGS"
    description: "True when the candidate has a Promoted tag in range."
  }

  dimension: is_rogue{
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'Rogue'
        AND oct.created_at > ${start_date_bound}
    ) THEN TRUE ELSE FALSE END ;;
    group_label: "4. TAGS"
    description: "True when the candidate has a Rogue tag in range."
  }

  dimension: is_saved_by_promoted {
    type: yesno
    label: "Is Saved by promoted"
    sql: CASE
      WHEN ${booking_id} IS NOT NULL
        AND ${is_promoted}
        AND ${is_booking_successful}
        AND NOT ${has_next_eligible_candidate}
      THEN TRUE
      ELSE FALSE
    END ;;
    group_label: "4. TAGS"
    description: "Yes when this row is the booked candidate with a Promoted tag, the booking was successful, and there is no other Eligible, non-promoted contestant on the same attempt with a higher rank (using has_next_eligible_candidate). This identifies successful bookings that only succeeded because a promoted option existed without other competing eligible paths."
  }

  dimension: is_booking_successful {
    type: yesno
    sql: CASE
      WHEN ${booking_id} IS NOT NULL
      THEN EXISTS (
        SELECT 1
        FROM ota.bookings b
        WHERE b.id = ${booking_id}
          AND (
            b.cancel_reason IS NULL
            OR b.cancel_reason IN ('customer_request', 'test', 'cc_decline', 'fraud')
          )
      )
      ELSE FALSE
    END ;;
    group_label: "4. TAGS"
    description: "True if the booking associated with this candidate was successful (not cancelled, or cancelled for non-technical reasons like customer request or payment decline)."
  }

  dimension: is_test_booking {
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_attempt_bookings oab
      INNER JOIN ota.bookings b ON b.id = oab.booking_id
      WHERE oab.attempt_id = ${TABLE}.attempt_id
        AND (b.is_test = 1 OR b.cancel_reason = 'test')
    ) THEN TRUE ELSE FALSE END ;;
    group_label: "4. TAGS"
    description: "True for every candidate on an attempt whose booking is a test (is_test = 1 or cancel_reason = 'test'). Previously this was only set on the booked row (where booking_id is populated); now it propagates to all contestants on the same attempt so filtering out test data removes the whole attempt, not just the winning row."
  }

  dimension: is_mixed_fare_type {
    type: yesno
    sql: CASE WHEN EXISTS (
      SELECT 1
      FROM ota.optimizer_candidate_tags oct
      INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
      WHERE oct.candidate_id = ${TABLE}.id
        AND ot.name = 'MixedFareType'
        AND oct.created_at > ${start_date_bound}
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
        AND oct.created_at > ${start_date_bound}
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
        AND oct.created_at > ${start_date_bound}
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

  measure: ineligible_contestants_count {
    type: count_distinct
    sql: CASE WHEN ${candidacy} != 'Eligible' THEN ${contestant_id} END ;;
    label: "Ineligible Contestants Count"
    description: "Count of distinct contestants with candidacy = 'Ineligible'"
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

  measure: saved_by_promoted_bookings_count {
    type: count_distinct
    sql: CASE WHEN ${is_saved_by_promoted} = TRUE THEN ${booking_id} END ;;
    label: "Saved by Promoted Bookings Count"
    description: "Distinct bookings where the booked contestant is Promoted and no other Eligible non-original non-promoted contestant exists on the attempt (see is_saved_by_promoted)."
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

  measure: ineligibility_rate {
    type: number
    sql: ${ineligible_contestants_count} / NULLIF(${all_contestants_count}, 0) ;;
    value_format: "0.00%"
    label: "Ineligibility Rate"
    description: "Percentage of ineligibility contestants out of all contestants"
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

  # -------------------------
  # Measures - Revenue
  # -------------------------

  measure: promoted_booking_extra_revenue_sum {
    type: sum
    sql: ${promoted_booking_extra_revenue} ;;
    value_format: "#,##0.00"
    label: "Promoted Booking Extra Revenue (Sum)"
    description: "Sum of promoted_booking_extra_revenue. When a next Eligible non-promoted competitor exists, excludes rows with strictly negative uplift vs that competitor; ties (0.00) are included. When no next competitor exists, sums booked promoted revenue. Algebraic uplift when both revenues are negative uses absolute difference vs next; solo promoted bookings contribute full row revenue."
    group_label: "MONETARY"
  }

}
