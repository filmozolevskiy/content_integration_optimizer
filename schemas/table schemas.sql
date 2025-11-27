--  these are table schemas just for reference

CREATE TABLE `optimizer_attempts` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `checkout_id` varchar(32) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `search_id` varchar(32) COLLATE utf8mb4_general_ci DEFAULT '',
  `package_id` varchar(32) COLLATE utf8mb4_general_ci DEFAULT '',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `gds` varchar(30) COLLATE utf8mb4_general_ci DEFAULT '',
  `gds_account_id` varchar(30) COLLATE utf8mb4_general_ci DEFAULT '',
  `currency` char(3) COLLATE utf8mb4_general_ci DEFAULT '',
  `fare_type` enum('published','private') COLLATE utf8mb4_general_ci DEFAULT 'published',
  `price_qualifiers` varchar(30) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `trip_type` enum('oneway','roundtrip','multi') COLLATE utf8mb4_general_ci DEFAULT NULL,
  `validating_carrier` varchar(4) COLLATE utf8mb4_general_ci DEFAULT '',
  `flight_numbers` varchar(100) COLLATE utf8mb4_general_ci DEFAULT '',
  `commission_trip_id` bigint DEFAULT NULL,
  `void_rule_id` int DEFAULT NULL,
  `base` decimal(10,2) DEFAULT NULL,
  `tax` decimal(10,2) DEFAULT NULL,
  `markup` decimal(10,2) DEFAULT NULL,
  `total` decimal(10,2) DEFAULT NULL,
  `commission` decimal(10,2) DEFAULT NULL,
  `merchant_fee` decimal(10,2) DEFAULT NULL,
  `supplier_fee` decimal(10,2) DEFAULT NULL,
  `revenue` decimal(10,2) DEFAULT NULL,
  `dropnet_revenue` decimal(10,2) DEFAULT NULL,
  `segment_revenue` decimal(10,2) DEFAULT NULL,
  `booking_classes` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `cabin_codes` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `fare_bases` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `fare_families` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `affiliate_id` int DEFAULT NULL,
  `target_id` int DEFAULT NULL,
  `package` json DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `checkout_id_idx` (`checkout_id`),
  KEY `search_id_idx` (`search_id`),
  KEY `created_at_idx` (`created_at`),
  KEY `validating_carrier_idx` (`validating_carrier`),
  KEY `gds_office_idx` (`gds`,`gds_account_id`),
  KEY `affiliate_id_idx` (`affiliate_id`),
  KEY `target_id_idx` (`target_id`)
) ENGINE=InnoDB AUTO_INCREMENT=40972 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


CREATE TABLE `optimizer_attempt_bookings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `attempt_id` bigint NOT NULL DEFAULT '0',
  `candidate_id` bigint NOT NULL DEFAULT '0',
  `booking_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_candidate_attempt_idx` (`candidate_id`,`attempt_id`),
  UNIQUE KEY `unique_attempt_booking_idx` (`attempt_id`,`booking_id`),
  KEY `booking_id_idx` (`booking_id`),
  CONSTRAINT `optimizer_attempt_bookings_attempt_id_fk` FOREIGN KEY (`attempt_id`) REFERENCES `optimizer_attempts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `optimizer_attempt_bookings_candidate_id_fk` FOREIGN KEY (`candidate_id`) REFERENCES `optimizer_candidates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=36342 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `optimizer_candidate_tags` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `candidate_id` bigint DEFAULT '0',
  `tag_id` int DEFAULT '0',
  `value` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tag_value_idx` (`tag_id`,`value`),
  KEY `created_at_idx` (`created_at`),
  KEY `candidate_idx` (`candidate_id`),
  CONSTRAINT `optimizer_candidate_tags_candidate_id_fk` FOREIGN KEY (`candidate_id`) REFERENCES `optimizer_candidates` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2199642 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `optimizer_tags` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT '',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_idx` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=92 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;