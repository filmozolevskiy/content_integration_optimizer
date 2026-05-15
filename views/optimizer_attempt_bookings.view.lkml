view: optimizer_attempt_bookings {
  # ota.optimizer_attempt_bookings — bridge attempt → booking. Used to
  # identify test bookings (joined to ota.bookings for is_test /
  # cancel_reason exclusion in several dashboard tiles).
  sql_table_name: ota.optimizer_attempt_bookings ;;

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
    hidden: yes
  }

  dimension: attempt_id {
    type: number
    sql: ${TABLE}.attempt_id ;;
    hidden: yes
  }

  dimension: candidate_id {
    type: number
    sql: ${TABLE}.candidate_id ;;
    hidden: yes
  }

  dimension: booking_id {
    type: number
    sql: ${TABLE}.booking_id ;;
    hidden: yes
    group_label: "2. CONTESTANT INFO"
  }
}
