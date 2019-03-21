-- 生成家庭成员表
-- DROP TABLE IF EXISTS `t_family_member`;
CREATE TABLE `t_family_member` (
	`F_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '递增ID',
	`F_name` varchar(16) NOT NULL COMMENT '姓名',
	`F_sex` tinyint(4) NOT NULL COMMENT '性别，0女，1男',
	`F_level` smallint(6) NOT NULL COMMENT '代际辈份',
	`F_father` int(10) unsigned DEFAULT NULL COMMENT '父亲ID',
	`F_partner` varchar(16) DEFAULT NULL COMMENT '配偶姓名',
	`F_sibold` smallint(6) DEFAULT 0 COMMENT '兄弟长幼次序',
	`F_birthday` date DEFAULT NULL COMMENT '生日',
	`F_deathday` date DEFAULT NULL COMMENT '忌日',
	`F_create_time` datetime NOT NULL COMMENT '记录入库时间',
	`F_update_time` datetime NOT NULL COMMENT '记录更新时间',
	PRIMARY KEY (`F_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10001 DEFAULT CHARSET=utf8 COMMENT='家庭成员表';

-- 说明
-- 只记录父系成员了，第一代祖宗 F_level 1，往后递增
