view: optimizer_attempts {
  # ota.optimizer_attempts — one row per Optimizer execution (~534K rows).
  # Carries attempt-level dimensions the candidate view doesn't have
  # (gds, validating_carrier, affiliate_id, search_id, ...).
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

  dimension: api_experiment_name {
    type: string
    sql: JSON_UNQUOTE(JSON_EXTRACT(${TABLE}.package, '$.info.api_experiment_name')) ;;
    group_label: "2. CONTESTANT INFO"
    label: "API Experiment Name"
    description: "Experiment name from optimizer_attempts.package->info.api_experiment_name. NULL when no experiment was active for this attempt."
  }

  dimension: api_experiment_variation {
    type: string
    sql: JSON_UNQUOTE(JSON_EXTRACT(${TABLE}.package, '$.info.api_experiment_variation')) ;;
    group_label: "2. CONTESTANT INFO"
    label: "API Experiment Variation"
    description: "Experiment variation (e.g. 'control', 'treatment') from optimizer_attempts.package->info.api_experiment_variation."
  }
}
