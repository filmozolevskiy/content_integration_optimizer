

 dimension: is_low_revenue {
 type: yesno
 sql: CASE WHEN EXISTS (
 SELECT 1
 FROM ota.optimizer_candidate_tags oct
 INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
 WHERE oct.candidate_id = ${TABLE}.id
 AND ot.name = 'LowRevenue'
 AND oct.created_at > ${start_date_bound}
 ) THEN TRUE ELSE FALSE END ;;
 group_label: "4. TAGS"
 description: "True when the candidate has a LowRevenue tag in the start_date window."
 }

 dimension: is_selected {
 type: yesno
 sql: CASE WHEN EXISTS (
 SELECT 1
 FROM ota.optimizer_candidate_tags oct
 INNER JOIN ota.optimizer_tags ot ON ot.id = oct.tag_id
 WHERE oct.candidate_id = ${TABLE}.id
 AND ot.name = 'Selected'
 AND oct.created_at > ${start_date_bound}
 ) THEN TRUE ELSE FALSE END ;;
 group_label: "4. TAGS"
 description: "True when the candidate has a Selected tag in the start_date window."
 }

}
