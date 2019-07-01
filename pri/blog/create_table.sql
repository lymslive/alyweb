CREATE TABLE db_blog.t_blog_visit (
	`F_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '递增ID',
	`F_note_id` varchar(16) NOT NULL COMMENT '日志id',
	`F_clien_ip` char(16) NOT NULL COMMENT '客户端id',
	`F_user_name` varchar(16) NOT NULL COMMENT '用户名',
	`F_from_url` varchar(128) NOT NULL COMMENT '来源链接地址',
	`F_stay_time` int DEFAULT 0 COMMENT '停留时间/秒'
	`F_date` date DEFAULT '2000-01-01' COMMENT '访问日期',
	`F_time` time DEFAULT '00:00:00' COMMENT '访问时间',
	PRIMARY KEY (`F_id`),
	KEY idx_note (`F_note_id`),
	KEY idx_date (`F_date`)
) ENGINE=InnoDB AUTO_INCREMENT=10001 DEFAULT CHARSET=utf8 COMMENT='博客日志访问记录表';

CREATE TABLE db_blog.t_blog_comment (
	`F_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '递增ID',
	`F_note_id` varchar(16) NOT NULL COMMENT '日志id',
	`F_clien_ip` char(16) NOT NULL COMMENT '客户端id',
	`F_user_name` varchar(16) NOT NULL COMMENT '用户名',
	`F_user_contact` varchar(32) NOT NULL COMMENT '联系方式',
	`F_comment` varchar(1024) NOT NULL COMMENT '评论',
	`F_refer_id` bigint unsigned DEFAULT 0 COMMENT '引用评论',
	`F_date` date DEFAULT '2000-01-01' COMMENT '评论日期',
	`F_time` time DEFAULT '00:00:00' COMMENT '评论时间',
	PRIMARY KEY (`F_id`),
	KEY idx_note (`F_note_id`),
	KEY idx_date (`F_date`)
) ENGINE=InnoDB AUTO_INCREMENT=10001 DEFAULT CHARSET=utf8 COMMENT='博客日志评论表';

