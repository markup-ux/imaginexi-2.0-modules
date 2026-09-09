-- Imagine XI 2.0: persistent dropped-item caskets.

CREATE TABLE IF NOT EXISTS `dropped_caskets` (
    `id`           INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `zoneid`       SMALLINT(5) UNSIGNED NOT NULL,
    `x`            FLOAT NOT NULL,
    `y`            FLOAT NOT NULL,
    `z`            FLOAT NOT NULL,
    `rotation`     TINYINT(3) UNSIGNED NOT NULL DEFAULT 0,
    `created_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_dropped_caskets_zone` (`zoneid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `dropped_casket_items` (
    `casket_id`  INT(10) UNSIGNED NOT NULL,
    `slot`       TINYINT(3) UNSIGNED NOT NULL,
    `itemId`     SMALLINT(5) UNSIGNED NOT NULL DEFAULT 0,
    `quantity`   INT(10) UNSIGNED NOT NULL DEFAULT 1,
    `signature`  VARCHAR(20) NOT NULL DEFAULT '',
    `extra`      BLOB(24) DEFAULT NULL,
    PRIMARY KEY (`casket_id`, `slot`),
    CONSTRAINT `fk_dropped_casket_items_casket`
        FOREIGN KEY (`casket_id`) REFERENCES `dropped_caskets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
