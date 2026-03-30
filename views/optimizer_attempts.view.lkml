view: optimizer_attempts {
  sql_table_name: ota.optimizer_attempts ;;

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
    hidden: yes
  }

  dimension: search_id {
    type: number
    sql: ${TABLE}.search_id ;;
    hidden: yes
    group_label: "2. CONTESTANT INFO"
  }

  dimension: package_id {
    type: number
    sql: ${TABLE}.package_id ;;
    hidden: yes
    group_label: "2. CONTESTANT INFO"
  }

  dimension: checkout_id {
    type: number
    sql: ${TABLE}.checkout_id ;;
    hidden: yes
    group_label: "2. CONTESTANT INFO"
  }

  dimension: trip_type {
    type: string
    sql: ${TABLE}.trip_type ;;
    hidden: yes
    group_label: "2. CONTESTANT INFO"
  }

  dimension: affiliate_id {
    type: number
    sql: ${TABLE}.affiliate_id ;;
    hidden: yes
    group_label: "2. CONTESTANT INFO"
  }

  dimension: target_id {
    type: number
    sql: ${TABLE}.target_id ;;
    hidden: yes
    group_label: "2. CONTESTANT INFO"
  }

  dimension: currency {
    type: string
    sql: ${TABLE}.currency ;;
    hidden: yes
    group_label: "MONETARY"
  }
}
