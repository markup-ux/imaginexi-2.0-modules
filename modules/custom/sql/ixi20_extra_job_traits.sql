-- Imagine XI 2.0 extra job traits (1.0 imaginexi.sql extras + RDM Shield Mastery at 1).
-- Apply after ixi20_job_progression_37cap.sql. WAR-RUN only (no MON, no Soldier).
-- Revert with ixi20_REVERT.sql on xidb_ixi20 only.

-- Dual Wield V (35%) on every retail job at 1. Higher rank replaces NIN/THF/DNC stepping.
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
  (18,'dual wield',1,1,5,259,35,NULL,0),
  (18,'dual wield',2,1,5,259,35,NULL,0),
  (18,'dual wield',3,1,5,259,35,NULL,0),
  (18,'dual wield',4,1,5,259,35,NULL,0),
  (18,'dual wield',5,1,5,259,35,NULL,0),
  (18,'dual wield',6,1,5,259,35,NULL,0),
  (18,'dual wield',7,1,5,259,35,NULL,0),
  (18,'dual wield',8,1,5,259,35,NULL,0),
  (18,'dual wield',9,1,5,259,35,NULL,0),
  (18,'dual wield',10,1,5,259,35,NULL,0),
  (18,'dual wield',11,1,5,259,35,NULL,0),
  (18,'dual wield',12,1,5,259,35,NULL,0),
  (18,'dual wield',13,1,5,259,35,NULL,0),
  (18,'dual wield',14,1,5,259,35,NULL,0),
  (18,'dual wield',15,1,5,259,35,NULL,0),
  (18,'dual wield',16,1,5,259,35,NULL,0),
  (18,'dual wield',17,1,5,259,35,NULL,0),
  (18,'dual wield',18,1,5,259,35,NULL,0),
  (18,'dual wield',19,1,5,259,35,NULL,0),
  (18,'dual wield',20,1,5,259,35,NULL,0),
  (18,'dual wield',21,1,5,259,35,NULL,0),
  (18,'dual wield',22,1,5,259,35,NULL,0)
ON DUPLICATE KEY UPDATE
  `name`=VALUES(`name`), `rank`=VALUES(`rank`), `value`=VALUES(`value`), `content_tag`=VALUES(`content_tag`), `meritid`=VALUES(`meritid`);

-- Treasure Hunter III on THF / BST / RNG / COR at 1
DELETE FROM `traits` WHERE `traitid` = 65 AND `job` IN (6, 9, 11, 17);
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
  (65,'treasure hunter iii',6,1,3,303,1,NULL,0),
  (65,'treasure hunter iii',9,1,3,303,1,NULL,0),
  (65,'treasure hunter iii',11,1,3,303,1,NULL,0),
  (65,'treasure hunter iii',17,1,3,303,1,NULL,0);

-- Gilfinder is not a 2.0 extra (gil converts to XP). Drop the custom grants on
-- THF/BST/RNG/COR and restore THF's compressed retail Gilfinder I from 37-cap.
DELETE FROM `traits` WHERE `traitid` = 20 AND `job` IN (6, 9, 11, 17);
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
  (20,'gilfinder',6,2,1,897,1,NULL,0);

-- Auto Refresh II on caster jobs at 1
DELETE FROM `traits` WHERE `traitid` = 10 AND `job` IN (3, 4, 5, 7, 8, 15, 16, 20, 21, 22);
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
  (10,'auto refresh',3,1,2,369,3,NULL,0),
  (10,'auto refresh',4,1,2,369,3,NULL,0),
  (10,'auto refresh',5,1,2,369,3,NULL,0),
  (10,'auto refresh',7,1,2,369,3,NULL,0),
  (10,'auto refresh',8,1,2,369,3,NULL,0),
  (10,'auto refresh',15,1,2,369,3,NULL,0),
  (10,'auto refresh',16,1,2,369,3,NULL,0),
  (10,'auto refresh',20,1,2,369,3,NULL,0),
  (10,'auto refresh',21,1,2,369,3,NULL,0),
  (10,'auto refresh',22,1,2,369,3,NULL,0);

-- Clear Mind VI on the same casters at 1
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
  (24,'clear mind',3,1,6,71,18,NULL,0),
  (24,'clear mind',4,1,6,71,18,NULL,0),
  (24,'clear mind',5,1,6,71,18,NULL,0),
  (24,'clear mind',7,1,6,71,18,NULL,0),
  (24,'clear mind',8,1,6,71,18,NULL,0),
  (24,'clear mind',15,1,6,71,18,NULL,0),
  (24,'clear mind',16,1,6,71,18,NULL,0),
  (24,'clear mind',20,1,6,71,18,NULL,0),
  (24,'clear mind',21,1,6,71,18,NULL,0),
  (24,'clear mind',22,1,6,71,18,NULL,0)
ON DUPLICATE KEY UPDATE
  `name`=VALUES(`name`), `rank`=VALUES(`rank`), `value`=VALUES(`value`), `content_tag`=VALUES(`content_tag`), `meritid`=VALUES(`meritid`);

-- Conserve MP VII on the same casters at 1
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
  (13,'conserve mp',3,1,7,296,43,NULL,0),
  (13,'conserve mp',4,1,7,296,43,NULL,0),
  (13,'conserve mp',5,1,7,296,43,NULL,0),
  (13,'conserve mp',7,1,7,296,43,NULL,0),
  (13,'conserve mp',8,1,7,296,43,NULL,0),
  (13,'conserve mp',15,1,7,296,43,NULL,0),
  (13,'conserve mp',16,1,7,296,43,NULL,0),
  (13,'conserve mp',20,1,7,296,43,NULL,0),
  (13,'conserve mp',21,1,7,296,43,NULL,0),
  (13,'conserve mp',22,1,7,296,43,NULL,0)
ON DUPLICATE KEY UPDATE
  `name`=VALUES(`name`), `rank`=VALUES(`rank`), `value`=VALUES(`value`), `content_tag`=VALUES(`content_tag`), `meritid`=VALUES(`meritid`);

-- Fast Cast V on those casters plus BRD at 1
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
  (12,'fast cast',3,1,5,170,30,NULL,0),
  (12,'fast cast',4,1,5,170,30,NULL,0),
  (12,'fast cast',5,1,5,170,30,NULL,0),
  (12,'fast cast',7,1,5,170,30,NULL,0),
  (12,'fast cast',8,1,5,170,30,NULL,0),
  (12,'fast cast',10,1,5,170,30,NULL,0),
  (12,'fast cast',15,1,5,170,30,NULL,0),
  (12,'fast cast',16,1,5,170,30,NULL,0),
  (12,'fast cast',20,1,5,170,30,NULL,0),
  (12,'fast cast',21,1,5,170,30,NULL,0),
  (12,'fast cast',22,1,5,170,30,NULL,0)
ON DUPLICATE KEY UPDATE
  `name`=VALUES(`name`), `rank`=VALUES(`rank`), `value`=VALUES(`value`), `content_tag`=VALUES(`content_tag`), `meritid`=VALUES(`meritid`);

-- RDM Shield Mastery at 1 (stock/37-cap already had ranks at 33/37; put max rank at 1)
DELETE FROM `traits` WHERE `traitid` = 25 AND `job` = 5;
INSERT INTO `traits` (`traitid`,`name`,`job`,`level`,`rank`,`modifier`,`value`,`content_tag`,`meritid`) VALUES
  (25,'shield mastery',5,1,2,485,20,NULL,0);
