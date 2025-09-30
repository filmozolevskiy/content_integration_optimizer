connection: "ota"

include: "/views/**/*.view.lkml"


explore: optimizer_candidates {
  label: "Optimizer Candidates"
  description: "Candidate-level pricing rows, with tags and attempt context."

  join: optimizer_attempts {
    type: left_outer
    relationship: many_to_one
    sql_on: ${optimizer_candidates.attempt_id} = ${optimizer_attempts.id} ;;
  }

  join: optimizer_attempt_bookings {
    type: left_outer
    relationship: many_to_one
    sql_on: ${optimizer_candidates.id} = ${optimizer_attempt_bookings.candidate_id} ;;
  }

  join: optimizer_candidate_tags_flat {
    type: left_outer
    relationship: many_to_one
    sql_on: ${optimizer_candidates.id} = ${optimizer_candidate_tags_flat.candidate_id} ;;
  }

}
