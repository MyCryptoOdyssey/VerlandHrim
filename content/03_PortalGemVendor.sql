-- Verland_Hrim QoL 03 (v9.2): Mira Passageborn + portal gems @ 1p, Bonded
-- v9.2 (2026-08-07): FIX - strip inherited level gate from beach portal.
--   The 4100028 genome clone from stock portal 30695 dragged in
--   MinLevel(86)=100, contradicting the v9 founder ruling ('no level
--   gate'). Caught live on prod fresh-build walk by a level-1 fixture
--   (UAT ran on KRIEG, who out-leveled every gate). Clone now excludes
--   int types 86/87 (Min/MaxLevel). No other change.
-- <!-- probe: PORTALGEM-v9.2-20260807 -->
-- v9.1 (2026-08-07): Withered Beach gem gets its own GemForge hue -
--   Ashen Teal (founder-approved proof sheet), icon 0x06F0000A =
--   100724746, injected via the GemForge pipeline (tenth in the family).
-- v9 (founder ruling 2026-08-07): TENTH GEM - Withered Beach.
--   Founder-endorsed quest-bypass to the XP beach (no level gate; 'there
--   is a built-in level requirement if you want to survive'). Destination
--   = the Ravaged Cathedral EXIT portal drop, FOUNDER-WITNESSED /loc
--   2026-08-07: 0x1D140003 [12.0 49.0 52.755997] q(-0.057048,0,0,-0.998371).
--   Mechanism: certified sibling pattern (spell 157 + did 31 LinkedPortal)
--   pointing at NEW custom portal weenie 4100028 (genome cloned from stock
--   portal 30695 minus position/name; literal witnessed destination row;
--   never placed in the world - exists only as the gem's target).
--   Gem wcid 4100019 continues the run; added to Mudira's shelf.
-- v8 (founder rulings F3, 2026-08-07): gems Value 0 -> 1 (display 1p;
--   'nothing is free') and Bonded(33)=1 (no sell-back, no trade, stays
--   through death). Applies to all nine gems 4100010-4100018.
--   Mudira (4100002) untouched.
-- Vendor template: Master Aluvian Archmage 2246 (weenie type 12 = Vendor).
-- Gems: clone of stock TN gem 43020 (type 38); d_i_d 28 = spell 157, d_i_d 31 = destination.
-- Stack 25, burden 100/unit, value 0. Tints via PaletteTemplate int 3 (still experimental).

DELETE FROM `weenie_properties_int` WHERE `object_Id` IN (4100002,4100010,4100011,4100012,4100013,4100014,4100015,4100016,4100017,4100018,4100019,4100028);
DELETE FROM `weenie_properties_bool` WHERE `object_Id` IN (4100002,4100010,4100011,4100012,4100013,4100014,4100015,4100016,4100017,4100018,4100019,4100028);
DELETE FROM `weenie_properties_float` WHERE `object_Id` IN (4100002,4100010,4100011,4100012,4100013,4100014,4100015,4100016,4100017,4100018,4100019,4100028);
DELETE FROM `weenie_properties_string` WHERE `object_Id` IN (4100002,4100010,4100011,4100012,4100013,4100014,4100015,4100016,4100017,4100018,4100019,4100028);
DELETE FROM `weenie_properties_d_i_d` WHERE `object_Id` IN (4100002,4100010,4100011,4100012,4100013,4100014,4100015,4100016,4100017,4100018,4100019,4100028);
DELETE FROM `weenie_properties_position` WHERE `object_Id` IN (4100019,4100028);
DELETE FROM `weenie_properties_create_list` WHERE `object_Id` IN (4100002,4100010,4100011,4100012,4100013,4100014,4100015,4100016,4100017,4100018,4100019,4100028);
DELETE FROM `weenie_properties_attribute` WHERE `object_Id` IN (4100002,4100010,4100011,4100012,4100013,4100014,4100015,4100016,4100017,4100018,4100019,4100028);
DELETE FROM `weenie_properties_attribute_2nd` WHERE `object_Id` IN (4100002,4100010,4100011,4100012,4100013,4100014,4100015,4100016,4100017,4100018,4100019,4100028);
DELETE FROM `weenie_properties_emote_action` WHERE `emote_Id` IN
  (SELECT `id` FROM `weenie_properties_emote` WHERE `object_Id` = 4100002);
DELETE FROM `weenie_properties_emote` WHERE `object_Id` = 4100002;
DELETE FROM `weenie` WHERE `class_Id` IN (4100002,4100010,4100011,4100012,4100013,4100014,4100015,4100016,4100017,4100018,4100019,4100028);
DELETE FROM `landblock_instance` WHERE `guid` = 0x7016C103;

-- ============ Mira Passageborn ============
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100002,'vh-mira-passageborn',12,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100002,1,16),(4100002,2,31),(4100002,6,-1),(4100002,7,-1),(4100002,8,120),
 (4100002,16,32),(4100002,25,126),(4100002,27,0),
 (4100002,74,833536),(4100002,75,0),(4100002,76,1000000),
 (4100002,93,2098200),(4100002,126,5000),(4100002,127,2000),
 (4100002,133,4),(4100002,134,16),(4100002,146,4532);
INSERT INTO `weenie_properties_bool` (`object_Id`,`type`,`value`) VALUES
 (4100002,1,1),(4100002,6,0),(4100002,12,1),(4100002,13,0),(4100002,19,0),
 (4100002,39,1),(4100002,41,1),(4100002,50,1),(4100002,51,1),(4100002,52,1);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES
 (4100002,1,5),(4100002,2,0),(4100002,3,0.16),(4100002,4,5),(4100002,5,1),
 (4100002,11,300),(4100002,13,0.9),(4100002,14,1),(4100002,15,1.1),
 (4100002,16,0.4),(4100002,17,0.4),(4100002,18,1),(4100002,19,0.6),
 (4100002,37,0.8),(4100002,38,1.1),(4100002,39,1.2),(4100002,54,3),
 (4100002,64,1),(4100002,65,1),(4100002,66,1),(4100002,67,1),(4100002,68,1),
 (4100002,69,1),(4100002,70,1),(4100002,71,1),(4100002,72,1),(4100002,73,1),
 (4100002,74,1),(4100002,75,1),(4100002,104,10),(4100002,125,1);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100002,1,'Mudira'),(4100002,5,'Portal Gem Merchant');
-- female setup from Sana-Mar archmage; if male on spawn, use 33554511
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100002,1,33554510),(4100002,2,150994945),(4100002,3,536870913),
 (4100002,4,805306368),(4100002,8,100667446);
INSERT INTO `weenie_properties_attribute` (`object_Id`,`type`,`init_Level`,`level_From_C_P`,`c_P_Spent`) VALUES
 (4100002,1,100,0,0),(4100002,2,100,0,0),(4100002,3,100,0,0),
 (4100002,4,100,0,0),(4100002,5,100,0,0),(4100002,6,100,0,0);
INSERT INTO `weenie_properties_attribute_2nd` (`object_Id`,`type`,`init_Level`,`level_From_C_P`,`c_P_Spent`,`current_Level`) VALUES
 (4100002,1,5000,0,0,5000),(4100002,3,5000,0,0,5000),(4100002,5,5000,0,0,5000);
INSERT INTO `weenie_properties_create_list` (`object_Id`,`destination_Type`,`weenie_Class_Id`,`stack_Size`,`palette`,`shade`,`try_To_Bond`) VALUES
 (4100002,2,21483,0,0,0,0),
 (4100002,4,43020,-1,0,0,0),
 (4100002,4,4100010,-1,0,0,0),
 (4100002,4,4100011,-1,0,0,0),
 (4100002,4,4100012,-1,0,0,0),
 (4100002,4,4100013,-1,0,0,0),
 (4100002,4,4100014,-1,0,0,0),
 (4100002,4,4100015,-1,0,0,0),
 (4100002,4,4100016,-1,0,0,0),
 (4100002,4,4100017,-1,0,0,0),
 (4100002,4,4100018,-1,0,0,0),
 (4100002,4,4100019,-1,0,0,0);
INSERT INTO `landblock_instance`
 (`guid`,`weenie_Class_Id`,`obj_Cell_Id`,`origin_X`,`origin_Y`,`origin_Z`,
  `angles_W`,`angles_X`,`angles_Y`,`angles_Z`,`is_Link_Child`,`last_Modified`)
VALUES (0x7016C103,4100002,0x016C01C3,56.976986,-43.551365,0.006500,0.999976,0.000000,0.000000,0.006934,0,NOW());

-- Mira's manners: welcome on shop-open (vendor_Type 1), farewell on purchase (4)
INSERT INTO `weenie_properties_emote`
 (`object_Id`,`category`,`probability`,`weenie_Class_Id`,`style`,`substyle`,`quest`,`vendor_Type`,`min_Health`,`max_Health`)
VALUES (4100002, 2, 1, NULL, NULL, NULL, NULL, 1, NULL, NULL);
SET @m_open = LAST_INSERT_ID();
INSERT INTO `weenie_properties_emote_action` (`emote_Id`,`order`,`type`,`delay`,`extent`,`message`)
VALUES (@m_open, 0, 10, 0, 1, 'Welcome, take what you need, not what you want... They are heavy!');
INSERT INTO `weenie_properties_emote`
 (`object_Id`,`category`,`probability`,`weenie_Class_Id`,`style`,`substyle`,`quest`,`vendor_Type`,`min_Health`,`max_Health`)
VALUES (4100002, 2, 1, NULL, NULL, NULL, NULL, 4, NULL, NULL);
SET @m_buy = LAST_INSERT_ID();
INSERT INTO `weenie_properties_emote_action` (`emote_Id`,`order`,`type`,`delay`,`extent`,`message`)
VALUES (@m_buy, 0, 10, 0, 1, 'Safe travels, my friend...');

-- ============ Gems ============
-- Ayan Baqur Portal Gem -> 7194
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100010,'vh-gem-4100010',38,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100010,1,2048),(4100010,5,100),(4100010,11,25),(4100010,12,1),(4100010,13,100),
 (4100010,15,0),(4100010,16,8),(4100010,18,32),(4100010,19,1),(4100010,33,1),
 (4100010,93,3092),(4100010,94,16),(4100010,106,210),(4100010,107,50),(4100010,108,50),
 (4100010,109,0),(4100010,110,0),(4100010,151,2),(4100010,280,1000);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES (4100010,167,15),(4100010,39,1.10);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100010,1,'Ayan Baqur Portal Gem'),
 (4100010,16,'Use this gem to summon a short-lived portal to Ayan Baqur. Works best used outside in a relatively flat area.');
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100010,1,33556769),(4100010,3,536870932),(4100010,6,67111919),
 (4100010,8,100724737),(4100010,22,872415275),(4100010,28,157),(4100010,31,7194);

-- Colosseum Portal Gem -> 35003
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100011,'vh-gem-4100011',38,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100011,1,2048),(4100011,5,100),(4100011,11,25),(4100011,12,1),(4100011,13,100),
 (4100011,15,0),(4100011,16,8),(4100011,18,4),(4100011,19,1),(4100011,33,1),
 (4100011,93,3092),(4100011,94,16),(4100011,106,210),(4100011,107,50),(4100011,108,50),
 (4100011,109,0),(4100011,110,0),(4100011,151,2),(4100011,280,1000);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES (4100011,167,15),(4100011,39,1.10);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100011,1,'Colosseum Portal Gem'),
 (4100011,16,'Use this gem to summon a short-lived portal to the Colosseum. Works best used outside in a relatively flat area.');
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100011,1,33556769),(4100011,3,536870932),(4100011,6,67111919),
 (4100011,8,100724738),(4100011,22,872415275),(4100011,28,157),(4100011,31,35003);

-- Graveyard Portal Gem -> 38728
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100012,'vh-gem-4100012',38,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100012,1,2048),(4100012,5,100),(4100012,11,25),(4100012,12,1),(4100012,13,100),
 (4100012,15,0),(4100012,16,8),(4100012,18,1),(4100012,19,1),(4100012,33,1),
 (4100012,93,3092),(4100012,94,16),(4100012,106,210),(4100012,107,50),(4100012,108,50),
 (4100012,109,0),(4100012,110,0),(4100012,151,2),(4100012,280,1000);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES (4100012,167,15),(4100012,39,1.10);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100012,1,'Graveyard Portal Gem'),
 (4100012,16,'Use this gem to summon a short-lived portal to the Graveyard. Works best used outside in a relatively flat area.');
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100012,1,33556769),(4100012,3,536870932),(4100012,6,67111919),
 (4100012,8,100724739),(4100012,22,872415275),(4100012,28,157),(4100012,31,38728);

-- Bandit Castle Portal Gem -> 1102
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100013,'vh-gem-4100013',38,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100013,1,2048),(4100013,5,100),(4100013,11,25),(4100013,12,1),(4100013,13,100),
 (4100013,15,0),(4100013,16,8),(4100013,18,16),(4100013,19,1),(4100013,33,1),
 (4100013,93,3092),(4100013,94,16),(4100013,106,210),(4100013,107,50),(4100013,108,50),
 (4100013,109,0),(4100013,110,0),(4100013,151,2),(4100013,280,1000);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES (4100013,167,15),(4100013,39,1.10);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100013,1,'Bandit Castle Portal Gem'),
 (4100013,16,'Use this gem to summon a short-lived portal to Bandit Castle. Works best used outside in a relatively flat area.');
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100013,1,33556769),(4100013,3,536870932),(4100013,6,67111919),
 (4100013,8,100724740),(4100013,22,872415275),(4100013,28,157),(4100013,31,1102);

-- Obsidian Rim Portal Gem -> 7210
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100014,'vh-gem-4100014',38,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100014,1,2048),(4100014,5,100),(4100014,11,25),(4100014,12,1),(4100014,13,100),
 (4100014,15,0),(4100014,16,8),(4100014,18,64),(4100014,19,1),(4100014,33,1),
 (4100014,93,3092),(4100014,94,16),(4100014,106,210),(4100014,107,50),(4100014,108,50),
 (4100014,109,0),(4100014,110,0),(4100014,151,2),(4100014,280,1000);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES (4100014,167,15),(4100014,39,1.10);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100014,1,'Obsidian Rim Portal Gem'),
 (4100014,16,'Use this gem to summon a short-lived portal to the Obsidian Rim (southern Valley of Death lifestone). Works best used outside in a relatively flat area.');
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100014,1,33556769),(4100014,3,536870932),(4100014,6,67111919),
 (4100014,8,100724741),(4100014,22,872415275),(4100014,28,157),(4100014,31,7210);

-- Wai Jhou Portal Gem -> 4218
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100015,'vh-gem-4100015',38,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100015,1,2048),(4100015,5,100),(4100015,11,25),(4100015,12,1),(4100015,13,100),
 (4100015,15,0),(4100015,16,8),(4100015,18,128),(4100015,19,1),(4100015,33,1),
 (4100015,93,3092),(4100015,94,16),(4100015,106,210),(4100015,107,50),(4100015,108,50),
 (4100015,109,0),(4100015,110,0),(4100015,151,2),(4100015,280,1000);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES (4100015,167,15),(4100015,39,1.10);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100015,1,'Wai Jhou Portal Gem'),
 (4100015,16,'Use this gem to summon a short-lived portal to Wai Jhou. Works best used outside in a relatively flat area.');
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100015,1,33556769),(4100015,3,536870932),(4100015,6,67111919),
 (4100015,8,100724742),(4100015,22,872415275),(4100015,28,157),(4100015,31,4218);

-- Candeth Keep Portal Gem -> 24579
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100016,'vh-gem-4100016',38,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100016,1,2048),(4100016,5,100),(4100016,11,25),(4100016,12,1),(4100016,13,100),
 (4100016,15,0),(4100016,16,8),(4100016,18,256),(4100016,19,1),(4100016,33,1),
 (4100016,93,3092),(4100016,94,16),(4100016,106,210),(4100016,107,50),(4100016,108,50),
 (4100016,109,0),(4100016,110,0),(4100016,151,2),(4100016,280,1000);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES (4100016,167,15),(4100016,39,1.10);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100016,1,'Candeth Keep Portal Gem'),
 (4100016,16,'Use this gem to summon a short-lived portal to Candeth Keep. Works best used outside in a relatively flat area.');
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100016,1,33556769),(4100016,3,536870932),(4100016,6,67111919),
 (4100016,8,100724743),(4100016,22,872415275),(4100016,28,157),(4100016,31,24579);

-- Asheron's Castle Portal Gem -> 35293
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100017,'vh-gem-4100017',38,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100017,1,2048),(4100017,5,100),(4100017,11,25),(4100017,12,1),(4100017,13,100),
 (4100017,15,0),(4100017,16,8),(4100017,18,8),(4100017,19,1),(4100017,33,1),
 (4100017,93,3092),(4100017,94,16),(4100017,106,210),(4100017,107,50),(4100017,108,50),
 (4100017,109,0),(4100017,110,0),(4100017,151,2),(4100017,280,1000);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES (4100017,167,15),(4100017,39,1.10);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100017,1,'Asheron''s Castle Portal Gem'),
 (4100017,16,'Use this gem to summon a short-lived portal to Asheron''s Castle island. Works best used outside in a relatively flat area.');
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100017,1,33556769),(4100017,3,536870932),(4100017,6,67111919),
 (4100017,8,100724744),(4100017,22,872415275),(4100017,28,157),(4100017,31,35293);

-- Crater Lake Village Portal Gem -> 2555 (portalcraterpathtopexit: village drop 0x90D00107)
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100018,'vh-gem-4100018',38,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100018,1,2048),(4100018,5,100),(4100018,11,25),(4100018,12,1),(4100018,13,100),
 (4100018,15,0),(4100018,16,8),(4100018,18,64),
 (4100018,19,1),(4100018,33,1),(4100018,93,3092),(4100018,94,16),(4100018,106,210),(4100018,107,50),(4100018,108,50),
 (4100018,109,0),(4100018,110,0),(4100018,151,2),(4100018,280,1000);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES (4100018,167,15),(4100018,39,1.10);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100018,1,'Crater Lake Village Portal Gem'),
 (4100018,16,'Use this gem to summon a short-lived portal to Crater Lake Village. Works best used outside in a relatively flat area.');
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100018,1,33556769),(4100018,3,536870932),(4100018,6,67111919),
 (4100018,8,100724745),(4100018,22,872415275),(4100018,28,157),(4100018,31,2555);

-- Mudira reorientation: heartbeat MoveHome snaps her back to her captured facing
INSERT INTO `weenie_properties_emote` (`object_Id`,`category`,`probability`,`vendor_Type`) VALUES (4100002, 5, 0.2, NULL);
INSERT INTO `weenie_properties_emote_action` (`emote_Id`,`order`,`type`,`delay`,`extent`)
SELECT e.id, 0, 4, 0, 1 FROM `weenie_properties_emote` e
 WHERE e.object_Id = 4100002 AND e.category = 5
 AND NOT EXISTS (SELECT 1 FROM `weenie_properties_emote_action` x WHERE x.emote_Id = e.id);

-- ============================================================
-- v9: Withered Beach Portal Gem (4100019) + destination portal (4100028)
-- ============================================================

-- The destination portal weenie: stock portal 30695 genome, witnessed drop
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100028,'vh-portal-witheredbeach',7,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`)
SELECT 4100028, `type`, `value` FROM `weenie_properties_int` WHERE `object_Id` = 30695 AND `type` NOT IN (86, 87); -- v9.2: strip inherited Min/MaxLevel (founder ruling: no level gate)
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`)
SELECT 4100028, `type`, `value` FROM `weenie_properties_float` WHERE `object_Id` = 30695;
INSERT INTO `weenie_properties_bool` (`object_Id`,`type`,`value`)
SELECT 4100028, `type`, `value` FROM `weenie_properties_bool` WHERE `object_Id` = 30695;
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`)
SELECT 4100028, `type`, `value` FROM `weenie_properties_d_i_d` WHERE `object_Id` = 30695;
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`)
SELECT 4100028, `type`, `value` FROM `weenie_properties_string` WHERE `object_Id` = 30695 AND `type` NOT IN (1);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES (4100028, 1, 'Withered Beach');
-- FOUNDER-WITNESSED destination (position_Type 2)
INSERT INTO `weenie_properties_position`
 (`object_Id`,`position_Type`,`obj_Cell_Id`,`origin_X`,`origin_Y`,`origin_Z`,`angles_W`,`angles_X`,`angles_Y`,`angles_Z`)
VALUES (4100028, 2, 0x1D140003, 12.000000, 49.000000, 52.755997, -0.057048, 0.000000, 0.000000, -0.998371);

-- The gem: certified sibling genome (pattern of 4100011), linked to 4100028
INSERT INTO `weenie` (`class_Id`,`class_Name`,`type`,`last_Modified`) VALUES (4100019,'vh-gem-4100019',38,NOW());
INSERT INTO `weenie_properties_int` (`object_Id`,`type`,`value`) VALUES
 (4100019,1,2048),(4100019,5,100),(4100019,11,25),(4100019,12,1),(4100019,13,100),
 (4100019,15,0),(4100019,16,8),(4100019,18,8),(4100019,19,1),(4100019,33,1),
 (4100019,93,3092),(4100019,94,16),(4100019,106,210),(4100019,107,50),(4100019,108,50),
 (4100019,109,0),(4100019,110,0),(4100019,151,2),(4100019,280,1000);
INSERT INTO `weenie_properties_float` (`object_Id`,`type`,`value`) VALUES (4100019,167,15),(4100019,39,1.10);
INSERT INTO `weenie_properties_string` (`object_Id`,`type`,`value`) VALUES
 (4100019,1,'Withered Beach Portal Gem'),
 (4100019,16,'Use this gem to summon a short-lived portal to the Withered Beach. Works best used outside in a relatively flat area. The sands are contested - arrive ready.');
INSERT INTO `weenie_properties_d_i_d` (`object_Id`,`type`,`value`) VALUES
 (4100019,1,33556769),(4100019,3,536870932),(4100019,6,67111919),
 (4100019,8,100724746),(4100019,22,872415275),(4100019,28,157),(4100019,31,4100028);

SELECT 'PORTALGEM-v9.2-20260807' AS probe;

