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

CREATE TABLE `t_diaocha` (
	`F_room` varchar(8) NOT NULL COMMENT '房号',
	`F_pass` varchar(16) NOT NULL COMMENT '密码',
	`F_json` varchar(1024) NOT NULL COMMENT '调查数据',
	`F_create_time` datetime NOT NULL COMMENT '创建时间',
	`F_update_time` datetime NOT NULL COMMENT '更新时间',
	PRIMARY KEY (`F_room`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='调查表';

CREATE TABLE `t_bill` (
	`F_flow` varchar(8) NOT NULL COMMENT '流水号',
	`F_date` date NOT NULL COMMENT '日期',
	`F_type` tinyint(4) NOT NULL COMMENT '类别1收入,-1支出',
	`F_subtype` tinyint(4) NOT NULL COMMENT '收支子类别，正数',
	`F_room` varchar(8) NOT NULL COMMENT '房号',
	`F_money` int(10) NOT NULL COMMENT '金额，分',
	`F_balance` int(10) NOT NULL COMMENT '金额，分',
	`F_note` varchar(512) NOT NULL COMMENT '备注说明',
	`F_create_time` datetime NOT NULL COMMENT '创建时间',
	`F_update_time` datetime NOT NULL COMMENT '更新时间',
	PRIMARY KEY (`F_flow`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='帐单表';

