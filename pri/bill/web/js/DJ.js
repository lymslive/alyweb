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

	// 默认拉取所有配置类型
	reqConfig: function() {
		var req = {"api":"query_config","data":{"all":1}};
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DD.Table.doneConfig(_resData, _reqData);
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
			$DV.Table.Filter.doneQuery(_resData);
		}, form, msg);
	},

	// 请求修改
	reqModify: function(_req) {
		if (!_req.api || _req.api != 'modify') {
			console.log('请求参数不对');
			return false;
		}
		var form = 'formOperate';
		var msg = {suc: '修改帐单成功', err: '修改帐单失败'};
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
		var msg = {suc: '添加帐单成功', err: '添加帐单失败'};
		this.create = this.requestAPI(_req, function(_resData, _reqData) {
			$DD.Table.modify(_resData, _reqData);
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

	LAST_PRETECT: true
};

// 全局对象
var $DOC = {
	DATA: $DD,
	VIEW: $DV, 
	EVENT: $DE,
	AJAX: $DJ,

	INIT: function() {
		this.EVENT.onLoad();
		this.VIEW.Page.init();
		this.AJAX.reqConfig();
	}
};

var $LOG = function(_msg) {
	console.log(_msg);
};

$(document).ready(function() {
	$DOC.INIT();
});

