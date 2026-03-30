view: optimizer_attempt_bookings {
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
