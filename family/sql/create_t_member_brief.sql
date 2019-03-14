-- 独立的生平简介文字
CREATE TABLE `t_member_brief` (
	`F_id` int(10) unsigned NOT NULL COMMENT '文本ID',
	`F_text` varchar(1024) DEFAULT NULL COMMENT '文本内容',
	PRIMARY KEY (`F_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='成员简介表';
