-- Gem icon address relocation: 0x06F0000X -> 0x0600F00X
UPDATE weenie_properties_d_i_d SET value=100724737 WHERE type=8 AND object_Id=4100010;
UPDATE weenie_properties_d_i_d SET value=100724738 WHERE type=8 AND object_Id=4100011;
UPDATE weenie_properties_d_i_d SET value=100724739 WHERE type=8 AND object_Id=4100012;
UPDATE weenie_properties_d_i_d SET value=100724740 WHERE type=8 AND object_Id=4100013;
UPDATE weenie_properties_d_i_d SET value=100724741 WHERE type=8 AND object_Id=4100014;
UPDATE weenie_properties_d_i_d SET value=100724742 WHERE type=8 AND object_Id=4100015;
UPDATE weenie_properties_d_i_d SET value=100724743 WHERE type=8 AND object_Id=4100016;
UPDATE weenie_properties_d_i_d SET value=100724744 WHERE type=8 AND object_Id=4100017;
UPDATE weenie_properties_d_i_d SET value=100724745 WHERE type=8 AND object_Id=4100018;
UPDATE weenie_properties_d_i_d SET value=100724746 WHERE type=8 AND object_Id=4100019;
SELECT object_Id, value, HEX(value) AS hex FROM weenie_properties_d_i_d WHERE type=8 AND object_Id BETWEEN 4100010 AND 4100019 ORDER BY object_Id;
