-- 生成家庭流水账单
-- DROP TABLE IF EXISTS `t_family_bill`;
CREATE TABLE `t_family_bill` (
	`F_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '递增ID',
	`F_type` tinyint(4) NOT NULL COMMENT '类别1收入,-1支出',
	`F_subtype` tinyint(4) NOT NULL COMMENT '收支子类别，正负数',
	`F_money` int(10) NOT NULL COMMENT '金额，分',
	`F_date` date DEFAULT NULL COMMENT '消费日期',
	`F_time` time DEFAULT NULL COMMENT '消费日期',
	`F_target` varchar(16) DEFAULT NULL COMMENT '消费目标',
	`F_place` varchar(16) DEFAULT NULL COMMENT '消费地址',
	`F_note` varchar(64) DEFAULT NULL COMMENT '备注',
	`F_update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录更新时间',
	PRIMARY KEY (`F_id`),
	KEY idx_date (`F_date`),
	KEY idx_subtype (`F_subtype`)
) ENGINE=InnoDB AUTO_INCREMENT=10001 DEFAULT CHARSET=utf8 COMMENT='家庭消费帐单表';


-- 消费类型配置表
CREATE TABLE `t_type_config` (
	`F_subtype` tinyint(4) NOT NULL COMMENT '收支子类别',
	`F_typename` varchar(16) DEFAULT NULL COMMENT '类别职称',
	`F_update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录更新时间',
	-- `F_update_time` datetime NOT NULL COMMENT '记录更新时间',
	PRIMARY KEY (`F_subtype`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='类别配置表';
