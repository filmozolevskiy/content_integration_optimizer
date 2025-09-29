view: optimizer_candidate_tags_flat {
  derived_table: {

    sql:
      WITH pairs AS (
        SELECT
          oct.candidate_id,
          ot.name  AS tag_name,
          oct.value AS tag_value
        FROM ota.optimizer_candidate_tags oct
        JOIN ota.optimizer_tags ot
          ON ot.id = oct.tag_id
        GROUP BY oct.candidate_id, ot.name, oct.value
      )
      SELECT
        p.candidate_id,

      GROUP_CONCAT(
      DISTINCT CONCAT(p.tag_name, ':', COALESCE(p.tag_value, ''))
      ORDER BY p.tag_name, p.tag_value
      SEPARATOR ', '
      ) AS tag_pairs,

      GROUP_CONCAT(
      DISTINCT CASE WHEN p.tag_name = 'MultiCurrency' THEN p.tag_value END
      ORDER BY p.tag_value SEPARATOR ','
      ) AS multicurrency_values,

      GROUP_CONCAT(
      DISTINCT CASE WHEN p.tag_name = 'MultiTicketPart' THEN p.tag_value END
      ORDER BY p.tag_value SEPARATOR ','
      ) AS multiticketpart_values,

      GROUP_CONCAT(
      DISTINCT CASE WHEN p.tag_name = 'Original' THEN p.tag_value END
      ORDER BY p.tag_value SEPARATOR ','
      ) AS original_values,

      GROUP_CONCAT(
      DISTINCT CASE WHEN p.tag_name = 'RepriceIndex' THEN p.tag_value END
      ORDER BY p.tag_value SEPARATOR ','
      ) AS repriceindex_values

      FROM pairs p
      GROUP BY p.candidate_id
      ;;
    # Optional: persist if upstream changes frequently
    # persist_for: "6 hours"
    # or use a datagroup if you have one configured
    # datagroup_trigger: optimizer_hourly
  }

  dimension: candidate_id { primary_key: yes type: number sql: ${TABLE}.candidate_id ;; }

  # All tags as a single de-duplicated string "Name:Value, Name:Value, ..."
  dimension: tag_pairs { type: string sql: ${TABLE}.tag_pairs ;; }

  # The four exception groups as their own de-duplicated value lists
  dimension: multicurrency_values   { type: string sql: ${TABLE}.multicurrency_values ;; }
  dimension: multiticketpart_values { type: string sql: ${TABLE}.multiticketpart_values ;; }
  dimension: original               { type: string sql: ${TABLE}.original_values ;; }
  dimension: repriceindex           { type: string sql: ${TABLE}.repriceindex_values ;; }

  # Convenience yes/no flags
  dimension: has_multicurrency   { type: yesno sql: ${multicurrency_values}   IS NOT NULL AND ${multicurrency_values}   != '' ;; }
  dimension: has_multiticketpart { type: yesno sql: ${multiticketpart_values} IS NOT NULL AND ${multiticketpart_values} != '' ;; }
  dimension: is_original         { type: yesno sql: ${original}               IS NOT NULL AND ${original}               != '' ;; }
}
