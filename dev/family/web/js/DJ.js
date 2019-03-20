// ajax 请求
var $DJ = {
	Config: {
		formMsg: 'operate-warn', // 表单操作错误消息区的 div class
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
				// alert('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
				console.log('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
				if (_form) {
					$msg.html('请求服务器失败，可能服务器或网络故障');
				}
			})
			.always(function(_data, _textStatus, _jqXHR) {
				console.log('ajax finish with status: ' + _textStatus);
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

	// 默认拉取所有数据
	requestAll: function() {
		var req = {"api":"query","data":{"all":1}};
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DV.Table.Pager.doneQuery(_resData);
		});
	},

	// 请求查询
	reqQuery: function(_req) {
		if (!_req.api || _req.api != 'query') {
			console.log('请求参数不对');
			return false;
		}
		var form = 'formQuery';
		var msg = {suc: '查询完成，结果列于上表'};
		this.query = this.requestAPI(_req, function(_resData, _reqData) {
			$DV.Table.Pager.doneQuery(_resData);
		}, form, msg);
	},

	// 请求修改
	reqModify: function(_req) {
		if (!_req.api || _req.api != 'modify') {
			console.log('请求参数不对');
			return false;
		}
		var form = 'formOperate';
		var msg = {suc: '修改资料成功', err: '修改资料失败'};
		this.modify = this.requestAPI(_req, function(_resData, _reqData) {
			$DD.Table.modify(_resData, _reqData);
		}, form, msg);
	},

	// 请求增加
	reqAppend: function(_req) {
		if (!_req.api || _req.api != 'create') {
			console.log('请求参数不对');
			return false;
		}
		var form = 'formOperate';
		var msg = {suc: '添加子女成功', err: '添加子女失败'};
		this.create = this.requestAPI(_req, function(_resData, _reqData) {
			$DD.Table.modify(_resData, _reqData);
		}, form, msg);
	},

    // 请求帮助文档
	reqHelp: function() {
		var ajx = $.get($DD.HELP_URL)
			.done(function(res, textStatus, jqXHR) {
				$DV.Help.showdoc(res);
			})
			.fail(this.resFail)
			.always(this.resAlways);
		this.doc = ajx;
		return ajx;
	},

    // 请求查询或修改简介
    reqBrief: function(_req) {
		var form, msg;
		if (_req.api == 'modify_brief') {
			form = 'formBrief';
			msg = {suc: '修改简介成功', err: '修改简介失败'};
		}

        this.brief = this.requestAPI(_req, function(_resData, _reqData) {
            $DD.Person.onBriefRes(_resData, _reqData);
        }, form, msg);
    },

	// 请求登陆
	reqLogin: function(_reqData) {
		var req = {
			api: 'login',
			data: _reqData
		};
		var form = 'formLogin';
		var msg = {err: '登陆失败，请检查id或姓名是否存在，或是否重名'};
		this.login = this.requestAPI(req, function(_resData, _reqData) {
			$DD.Login.callback(_resData, _reqData);
		}, form, msg);
	},

	// 请求修改密码
	reqPasswd: function(_req) {
		var form = 'formPasswd';
		var msg = {err: '修改密码失败', suc: '修改密码成功，请牢记'};
		this.brief = this.requestAPI(_req, function(_resData, _reqData) {
			$DD.Login.onModifyPasswd(_resData, _reqData);
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

	divLog: '#debug-log',

	INIT: function() {
		$LOG.init(this.divLog);
		this.EVENT.onLoad();
		this.VIEW.Page.init();
		this.AJAX.requestAll();
	}
};

// 日志对象
var $LOG = function(_msg) {
	if (typeof(_msg) == 'object') {
		_msg = JSON.stringify(_msg);
	}
	if (!$LOG.div) {
		$LOG.div = 'body';
	}
	$($LOG.div).append("<p>" + _msg + "</p>");
	console.log(_msg);
};

$LOG.init = function(_div) {
	this.div = _div;
};

$LOG.open = function() {
	if (this.div !== 'body') {
		$(this.div).show();
	}
};

$LOG.close = function() {
	if (this.div !== 'body') {
		$(this.div).hide();
	}
};

$(document).ready(function() {
	$DOC.INIT();
});

