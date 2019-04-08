"use strict";

var $DD = {
	TOPIC: {
		misc: "随笔杂文",
		game: "游戏娱乐",
		opera: "戏曲戏剧",
		snake: "白蛇研究",
		art: "文学艺术",
		code: "程序生涯"
	},
	
	// 博客分类
	Topic: {
		current: '',
		notelist: [],

		doneQuery: function(_resData) {
			this.current = _resData.tag;
			this.notelist = _resData.list;
			if (this.current !== 'recent') {
				this.notelist.reverse();
			}
		},

		LAST_PRETECT: true
	},

	// 博客文章
	Article: {
		noteid: '',
		topic: '',
		tags: [],
		title: '',
		date: '',
		url: '',
		author: '',
		content: '',

		doneQuery: function(_resData) {
			this.noteid = _resData.id;
			this.topic = _resData.topic;
			this.tags = _resData.tags;
			this.title = _resData.title;
			this.date = _resData.date;
			this.url = _resData.url;
			this.author = _resData.author;
			this.content = _resData.content;
		},

		LAST_PRETECT: true
	},

	LAST_PRETECT: true
};

var $DV = {
	Topic: {
		domid = 'blog-list',

		show: function() {
			$($DV.Topic.domid).show();
			$($DV.Article.domid).hide();
		},
		LAST_PRETECT: true
	},

	Article: {
		domid = 'blog-article',
		show: function() {
			$($DV.Topic.domid).hide();
			$($DV.Article.domid).show();
		},
		LAST_PRETECT: true
	},

	LAST_PRETECT: true
};

var $DE = {
};

// ajax 请求
var $DJ = {
	Config: {
		formMsg: 'operate-warn', // 表单操作错误消息区的 div class
		LAST_PRETECT: true
	},

	Fun: {
		// 解析地址栏的搜索部分
		urlParam: function() {
			var search = location.search;
			if (search.length < 1) {
				return {};
			}
			var param = search.substring(1).split('&');
			var res = {};
			for (var i = 0; i < param.length; ++i) {
				var kv = param[i].split('=');
				if (kv.length > 1) {
					res[kv[0]] = kv[1];
				}
				else if (kv.length > 0) {
					res[kv[0]] = true;
				}
			}
			return res;
		},

		hasLog: function() {
			var param = this.urlParam();
			return param && param['log'];
		},

		LAST_PRETECT: true
	},

	// 组装请求参数
	reqOption: function(_req) {
		var opt = {
			method: "POST",
			contentType: "application/json",
			dataType: "json",
			data: JSON.stringify(_req)
			// data: req // 会发送 api=query& 而不是 json 串
		};
		return opt;
	},

	// 封装请求服务端 api
	// _req: 为请求 api json 对象
	// _callback: 是成功时回调，可接收参数为(_res.data, _req.data, _res, _req)
	//   大多情况下只要处理返回的实际 data 部分
	// _form 与此请求相关联的 from id , 将自动处理重复提交
	// _msg 在请求返回时在页面给用户的友好提示，包括 .err 与 .suc 两种提示
	requestAPI: function(_req, _callback, _form, _msg) {
		if (this.Fun.hasLog()) {
			_req.log = 1;
		}
		var opt = this.reqOption(_req);
		$LOG('api req = ' + opt.data);

		var form = _form || 'formNULL';
		var $form = $('#' + form);
		var $msg = $form.find('div.' + $DJ.Config.formMsg);
		var $submit = $form.find('input:submit');

		var ajx = $.ajax($DD.API_URL, opt)
			.done(function(_res, _textStatus, _jqXHR) {
				// api 返回的 res 直接解析为 json
				if (_res.error) {
					$LOG('api err = ' + _res.error + '; errmsg = ' + _res.errmsg);
					// $DJ.resError(_res, _req);
					if (_form && _msg && _msg.err) {
						$msg.html(_msg.err);
					}
				}
				else {
					if (_form && _msg && _msg.suc) {
						$msg.html(_msg.suc);
					}
					_callback(_res.data, _req.data, _res, _req);
				}
			})
			.fail(function(_jqXHR, _textStatus, _errorThrown) {
				console.log('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
				if (_form) {
					$msg.html('请求服务器失败，可能服务器或网络故障');
				}
			})
			.always(function(_data, _textStatus, _jqXHR) {
				console.log('ajax finish with status: ' + _textStatus);
				if (_data.log) {
					console.log(_data.log);
				}
				if (_form) {
					$submit.removeAttr('disabled');
				}
			});

		// 禁止重复提交表单
		if (_form) {
			$msg.html('正在请求服务器通讯……');
			$submit.attr('disabled', 'disabled');
		}
		return ajx;
	},

	// 请求错误扩展处理
	resError: function(_res, _req) {
	},
    resFail: function(jqXHR, textStatus, errorThrown) {
        alert('从服务器获取数据失败'  +  jqXHR.status + textStatus);
    },
    resAlways: function(data, textStatus, jqXHR) {
        console.log('ajax finish with status: ' + textStatus);
    },

	// 默认拉取最近博客列表
	reqTopic: function() {
		var req = {"api":"topic","data":{"tag":"recent"}};
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DD.Topic.doneQuery(_resData, _reqData);
		});
	},

	// 请求博客文章
	reqQuery: function(_id) {
		var req = {"api":"article","data":{"id":_id}};
		this.query = this.requestAPI(_req, function(_resData, _reqData) {
			$DD.Article.doneQuery(_resData);
		}, form, msg);
	},

	LAST_PRETECT: true
};

// 全局对象
var $DOC = {
	DATA: $DD,
	VIEW: $DV, 
	EVENT: $DE,
	AJAX: $DJ,

	INIT: function() {
		// this.EVENT.onLoad();
		// this.VIEW.Page.init();
		// this.AJAX.reqConfig();
	}
};

var $LOG = function(_msg) {
	console.log(_msg);
};

$(document).ready(function() {
	$DOC.INIT();
});

