-- 生成家庭成员表
DROP TABLE IF EXISTS `t_family_member`;
CREATE TABLE `t_family_member` (
	`F_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '递增ID',
	`F_name` varchar(16) NOT NULL COMMENT '姓名',
	`F_sex` tinyint(4) NOT NULL COMMENT '性别，0女，1男',
	`F_level` smallint(6) NOT NULL COMMENT '代际，负数表示外来配偶',
	`F_father` int(10) unsigned DEFAULT NULL COMMENT '父亲ID',
	`F_mother` int(10) unsigned DEFAULT NULL COMMENT '母亲ID',
	`F_partner` int(10) unsigned DEFAULT NULL COMMENT '配偶ID',
	`F_birthday` date DEFAULT NULL COMMENT '生日',
	`F_deathday` date DEFAULT NULL COMMENT '忌日',
	`F_desc` int(10) unsigned DEFAULT NULL COMMENT '生平简介文本ID',
	`F_create_time` datetime NOT NULL COMMENT '记录入库时间',
	`F_update_time` datetime NOT NULL COMMENT '记录更新时间',
	PRIMARY KEY (`F_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10001 DEFAULT CHARSET=utf8 COMMENT='家庭成员表';

-- 说明
-- 成员表不仅记录男丁，也记录妇女与女孩，以及女儿的后代
-- 凡自祖宗传承的血脉均可入库
-- 第一代祖宗 F_level 设为 1，配置为 -1，儿子/女儿 F_level 为 2 ，儿媳/女婿为-2
-- 如有再婚的，F_parter 只为原配第一任，但每个子女会记录双亲
