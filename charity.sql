CREATE TABLE `zz_charity_gathering` (
    `GUID` INT(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'player guid',
    `NAME` VARCHAR(12) NULL DEFAULT NULL COMMENT 'player name' COLLATE 'utf8mb4_bin',
    `GOLD` INT(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'gold in copper every 10k is 1 gold',
    `time` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
)
COMMENT='this is for the npc that people can donate to and it will store the data in here so that way at the end of the month it will get evenly send out to players between level 10-20'
COLLATE='utf8mb3_general_ci'
ENGINE=InnoDB
;
