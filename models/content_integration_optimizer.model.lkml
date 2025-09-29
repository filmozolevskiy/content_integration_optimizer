connection: "ota"

include: "/views/**/*.view.lkml"


explore: optimizer_attempts {
  label: "Optimizer Attempts"
  description: "Attempts with candidate pricing & tags and optional booking linkage."

  join: optimizer_candidates {
    type: left_outer
    relationship: one_to_many
    sql_on: ${optimizer_attempts.id} = ${optimizer_candidates.attempt_id} ;;
  }

  join: optimizer_candidate_tags {
    type: left_outer
    relationship: one_to_many
    sql_on: ${optimizer_candidates.id} = ${optimizer_candidate_tags.candidate_id} ;;
  }

  join: optimizer_tags {
    type: left_outer
    relationship: one_to_many
    sql_on: ${optimizer_candidate_tags.tag_id} = ${optimizer_tags.id} ;;
  }

  join: optimizer_attempt_bookings {
    type: left_outer
    relationship: one_to_one
    sql_on: ${optimizer_attempts.id} = ${optimizer_attempt_bookings.attempt_id} ;;
  }
}


explore: optimizer_candidates {
  label: "Optimizer Candidates"
  description: "Candidate-level pricing rows, with tags and attempt context."

  join: optimizer_attempts {
    type: left_outer
    relationship: many_to_one
    sql_on: ${optimizer_candidates.attempt_id} = ${optimizer_attempts.id} ;;
  }

  join: optimizer_candidate_tags {
    type: left_outer
    relationship: one_to_many
    sql_on: ${optimizer_candidates.id} = ${optimizer_candidate_tags.candidate_id} ;;
  }

  join: optimizer_tags {
    type: left_outer
    relationship: one_to_many
    sql_on: ${optimizer_candidate_tags.tag_id} = ${optimizer_tags.id} ;;
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
