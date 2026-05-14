connection: "ota"

include: "/views/**/*.view.lkml"

datagroup: optimizer_candidates_datagroup {
  sql_trigger: SELECT MAX(created_at) FROM ota.optimizer_candidates ;;
  max_cache_age: "1 hour"
}

explore: content_integration_optimizer {
  label: "New Optimizer"
  persist_with: optimizer_candidates_datagroup

  sql_always_where: ${content_integration_optimizer.date_raw} > TIMESTAMP({%- parameter content_integration_optimizer.start_date -%}) ;;

  join: optimizer_attempts {
    type: left_outer
    relationship: many_to_one
    sql_on: ${optimizer_attempts.id} = ${content_integration_optimizer.attempt_id} ;;
  }

  join: optimizer_attempt_bookings {
    type: left_outer
    relationship: many_to_one
    sql_on:
      ${optimizer_attempt_bookings.candidate_id} = ${content_integration_optimizer.id}
      AND ${optimizer_attempt_bookings.attempt_id} = ${content_integration_optimizer.attempt_id} ;;
  }

  join: optimizer_candidate_tags_pivot {
    type: left_outer
    relationship: many_to_one
    sql_on: ${optimizer_candidate_tags_pivot.candidate_id} = ${content_integration_optimizer.id} ;;
  }

  join: optimizer_attempt_tags_pivot {
    type: left_outer
    relationship: many_to_one
    sql_on: ${optimizer_attempt_tags_pivot.attempt_id} = ${content_integration_optimizer.attempt_id} ;;
  }

  join: optimizer_parent_candidates {
    type: left_outer
    relationship: many_to_one
    sql_on: ${optimizer_parent_candidates.id} = ${content_integration_optimizer.parent_id}
      AND ${optimizer_parent_candidates.reprice_type} = 'single_to_multi'
      AND ${optimizer_parent_candidates.created_at_raw} > ${content_integration_optimizer.start_date_bound} ;;
  }
}
