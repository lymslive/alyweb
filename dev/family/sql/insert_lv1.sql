INSERT INTO t_family_member SET
F_name = '谭年浪',
F_sex = 1,
F_level = 1,
F_create_time = now(),
F_update_time = now();

SET @id = last_insert_id();

INSERT INTO t_family_member SET
F_name = '',
F_sex = 0,
F_level = -1,
F_partner= @id,
F_create_time = now(),
F_update_time = now();
