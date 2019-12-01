create database db_kaihe;
use db_kaihe;

-- 生成签到表
-- DROP TABLE IF EXISTS `t_signup`;
CREATE TABLE `t_signup` (
	`F_date` varchar(16) NOT NULL COMMENT '签到ID，建议日期',
	`F_room` varchar(8) NOT NULL COMMENT '签到房号',
	`F_state` tinyint DEFAULT 0 COMMENT '签到状态：0缺席1捐助2到场',
	PRIMARY KEY (`F_date`, `F_room`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='签到表';

CREATE TABLE `t_event` (
	`F_date` varchar(16) NOT NULL COMMENT '签到ID，建议日期',
	`F_short` varchar(32) NOT NULL COMMENT '简短介绍',
	`F_long` varchar(512) NOT NULL COMMENT '详细介绍',
	PRIMARY KEY (`F_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='事件表';

CREATE TABLE `t_room` (
	`F_room` varchar(8) NOT NULL COMMENT '房号',
	`F_name` varchar(16) NOT NULL COMMENT '姓名',
	`F_telephone` varchar(16) NOT NULL COMMENT '手机',
	PRIMARY KEY (`F_room`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='业主表';

