-- 成员密码控制表
CREATE TABLE `t_member_passwd` (
	`F_id` int(10) unsigned NOT NULL COMMENT '成员ID',
	`F_login_key` char(32) COMMENT '登陆密码',
	`F_opera_key` char(32) COMMENT '操作密码',
	`F_token` char(32) COMMENT '当前会话',
	`F_last_login` datetime NOT NULL COMMENT '上次登陆时间',
	`F_update_time` timestamp NOT NULL COMMENT '记录更新时间',
	PRIMARY KEY (`F_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='成员简介表';
