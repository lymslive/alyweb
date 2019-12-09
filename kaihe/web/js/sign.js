// 全局空间
var $DOC = {
	API_URL: '/kaihe/sign.cgi',
	TableID: "#maintbl",
	TableSrc: null,
	State_Que: 0,
	State_Dao: 2,
	State_Zhu: 1,
	Sign_Que: "缺",
	Sign_Dao: "到",
	Sign_Zhu: "助",
	Count_Que: 0,
	Count_Dao: 0,
	Count_Zhu: 0,
	Version: '',
	Submitting: false,
	SignData: null,  // 本地保存一份签到表
	SignMode: 'new', // 新建模式或修改模式(new/old)

	INIT: function() {
		this.Version = $('#version').html();
		this.GetRooms();
		this.GetEvent();
		this.InitForm();
	},

	GetRooms: function() {
		var url = 'rooms.json';
		var opt = {
			method: "get",
			contentType: "application/json",
			dataType: "json",
		};
		var ajx = $.ajax(url, opt)
			.done(function(_res, _textStatus, _jqXHR) {
				if (_res.error) {
					console.log('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
				}
				else {
					$DOC.Tablefy(_res);
				}
			})
			.fail(function(_jqXHR, _textStatus, _errorThrown) {
				console.log('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
			})
			.always(function(_data, _textStatus, _jqXHR) {
				console.log('ajax finish with status: ' + _textStatus);
			});
	},

	Tablefy: function(res) {
		this.TableSrc = res;
		var $table = $(this.TableID);
		res.forEach(function(_item, _idx) {
			var $tr = $("<tr></tr>").appendTo($table);
			$("<td></td>").appendTo($tr)
				.html($DOC.Sign_Que).addClass('que')
				.attr("id", _item.id);
				
			$("<td></td>").append($DOC.SignLink(_item.id)).appendTo($tr);
			$("<td></td>").html(_item.name).appendTo($tr);
			$("<td></td>").html(_item.telephone).appendTo($tr);
		}, this);

		$('#all-count').html(this.TableSrc.length);
		this.Count_Que = this.TableSrc.length;
		this.Count_Dao = 0;
		this.Count_Zhu = 0;
		this.RecountSign(false);
	},

	SignLink: function(id) {
		var $a = $("<a></a>").html(id).attr("href", "#" + id);
		$a.addClass("room-id");
		$a.click(function(_evt) {
			_evt.preventDefault();
			var href = $(this).attr('href');
			$DOC.ToggleSign(href);
		});
		return $a;
	},

	ToggleSign: function(id) {
		var $sign = $(id);
		var sold = $sign.html();
		var snew = "";
		if (sold == this.Sign_Que) {
			snew = this.Sign_Dao
			$sign.removeClass('que');
			$sign.addClass('dao');
			this.Count_Que--;
			this.Count_Dao++;
		}
		else if (sold == this.Sign_Dao) {
			snew = this.Sign_Zhu
			$sign.removeClass('dao');
			$sign.addClass('zhu');
			this.Count_Dao--;
			this.Count_Zhu++;
		}
		else {
			snew = this.Sign_Que;
			$sign.removeClass('zhu');
			$sign.addClass('que');
			this.Count_Zhu--;
			this.Count_Que++;
		}
		$sign.html(snew);
		this.RecountSign(false);
	},

	ChangeSign: function(id, state) {
		var $sign = $('#' + id);
		var snew = this.Sign_Que;
		if (state == this.State_Que) {
			// already reset
			// snew = this.Sign_Que;
			// $sign.addClass('que');
		}
		else if (state == this.State_Dao) {
			snew = this.Sign_Dao;
			$sign.addClass('dao');
		}
		else {
			snew = this.Sign_Zhu;
			$sign.addClass('zhu');
		}
		$sign.html(snew);
	},

	ResetSign: function() {
		if (!this.TableSrc) {
			return false;
		}
		this.TableSrc.forEach(function(_item, _idx) {
			var $sign = $("#" + _item.id);
			var sold = $sign.html();
			if (sold == this.Sign_Zhu) {
				$sign.removeClass('zhu');
			}
			else if (sold == this.Sign_Dao) {
				$sign.removeClass('dao');
			}
			else {
				return;
			}
			$sign.html(this.Sign_Que);
			$sign.addClass('que');
		}, this);
	},

	RecountSign: function(scan) {
		if (!scan) {
			$('#dao-count').html(this.Count_Dao);
			$('#zhu-count').html(this.Count_Zhu);
			$('#que-count').html(this.Count_Que);
			return;
		}
		if (!this.TableSrc) {
			return;
		}
		this.Count_Dao = 0;
		this.Count_Zhu = 0;
		this.Count_Que = 0;
		this.TableSrc.forEach(function(_item, _idx) {
			var $sign = $("#" + _item.id);
			var sval = $sign.html();
			if (sval == this.Sign_Zhu) {
				this.Count_Zhu++;
			}
			else if (sval == this.Sign_Dao) {
				this.Count_Dao++;
			}
			else {
				this.Count_Que++;
			}
		}, this);
		this.RecountSign(false);
	},

	SaveSign: function() {
		if (!this.TableSrc) {
			return false;
		}

		var sign_array = [];
		this.TableSrc.forEach(function(_item, _idx) {
			var $sign = $("#" + _item.id);
			var sval = $sign.html();
			var ival = this.State_Que;
			if (sval == this.Sign_Zhu) {
				ival = this.State_Zhu;
			}
			else if (sval == this.Sign_Dao) {
				ival = this.State_Dao;
			}
			var signed = {"room": _item.id, "state": ival};
			sign_array.push(signed);
		}, this);

		var date = $('#date').val();
		var shortDesc = $('#short-desc').val();
		var longDesc = $('#long-desc').val();

		var data = {"date": date, "short": shortDesc, "long": longDesc, "signed": sign_array};
		return data;
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
		if ("sess" in _req) {
			_req.sess.version = this.Version;
		}
		else {
			_req.sess = {"version": this.Version};
		}
		var opt = this.reqOption(_req);
		this._last_req = _req;

		var form = _form || 'formNULL';
		var $form = $('#' + form);
		var $msg = $form.find('div.operate-warn');
		var $submit = $form.find('input:submit');

		var ajx = $.ajax($DOC.API_URL, opt)
			.done(function(_res, _textStatus, _jqXHR) {
				// api 返回的 res 直接解析为 json
				if (_res.error) {
					console.log('api err = ' + _res.error + '; errmsg = ' + _res.errmsg);
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

	GetEvent: function() {
		var form = 'formSign';
		var msg = {suc: '在表头处下拉列表可选历史签到'};
		var req = {"api":"query_event","data":{}}
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DOC.GotEvent(_resData);
		}, form, msg);
	},

	GotEvent: function(res) {
		for (var i = 0; i < res.date.length; ++i) {
			var date = res.date[i];
			this.AddEvent(date);
		}
	},

	AddEvent: function(date) {
		var $select = $('#event');
		var text = date + '聚会';
		var $option = $("<option></option>");
		$option.attr("value", date).html(text);
		$option.appendTo($select);
	},

	SendCreate: function(data, sess) {
		var form = 'formSign';
		var msg = {suc: '签到已保存至服务器', err: '服务器保存签到失败'};
		var req = {"api":"create", "data":data, "sess":sess};
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DOC.DoneCreate(_resData);
		}, form, msg);
		$DOC.Submitting = true;
	},

	DoneCreate: function(res) {
		var date = res.date;
		$('#date').val(date).attr('disabled', 'disabled');
		$DOC.Submitting = false;
		$DOC.SignMode = 'old';

		this.AddEvent(date);
		$('#event').val(date);
	},

	SendQuery: function(data) {
		var form = 'formSign';
		var msg = {suc: '成功从服务器加载签到表', err: '服务器查询签到失败'};
		var req = {"api":"query", "data":data};
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DOC.DoneQuery(_resData);
		}, form, msg);
	},

	DoneQuery: function(res) {
		$DOC.SignData = res;
		$('#date').val(res.date);
		$('#short-desc').val(res.short);
		$('#long-desc').val(res.long);
		if (!this.TableSrc) {
			return false;
		}
		$DOC.ResetSign();
		res.signed.forEach(function(_item, _idx) {
			$DOC.ChangeSign(_item.room, _item.state);
		}, this);
		this.RecountSign(true);
	},

	SendModify: function(data, sess) {
		var form = 'formSign';
		var msg = {suc: '签到已修改保存至服务器', err: '服务器保存修改签到失败'};
		var req = {"api":"modify", "data":data, "sess":sess};
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DOC.DoneModify(_resData);
		}, form, msg);
		$DOC.Submitting = true;
	},

	DoneModify: function(res) {
		var date = res.date;
		$('#event').val(date);
		$DOC.Submitting = false;
	},

	CheckForm: function() {
		var date = $('#date').val();
		var admin = $('#admin').val();
		var password = $('#password').val();
		if (!date) {
			$('#form-msg').html('请选择或输入聚会日期');
			return null;
		}
		if (!admin || !password) {
			$('#form-msg').html('提交前请输入管理员房号与密码');
			return null;
		}
		return {"admin": admin, "password": password};
	},

	InitForm: function() {
		$('#date').val(this.Today());
		$('#reset').click(function(_evt) {
			$DOC.ResetSign();
			$('#date').val($DOC.Today());
		});
		$('#submit').click(function(_evt) {
			_evt.preventDefault();
			var sess = $DOC.CheckForm();
			if (!sess) {
				return;
			}
			var data = $DOC.SaveSign();
			$DOC.SignData = data;
			if ($DOC.SignMode == 'new') {
				$DOC.SendCreate(data, sess);
			}
			else {
				$DOC.SendModify(data, sess);
			}
		});
		$('#event').change(function(_evt) {
			var date = $(this).val();
			if (date == 'new-date') {
				$DOC.SignMode = 'new';
				$('#reset').click();
				$('#date').val($DOC.Today()).removeAttr('disabled');
			}
			else {
				$DOC.SignMode = 'old';
				$('#date').val(date).attr('disabled', 'disabled');
				$DOC.SendQuery({"date":date});
			}
		});
	},

	Today: function() {
		var today = new Date();
		var y = today.getFullYear();
		var m = today.getMonth() + 1;
		var d = today.getDate();

		return y + '-' + (m < 10 ? '0' + m : m) + '-' + (d < 10 ? '0' + d : d);
	},
	__LAST__: true
};

$(document).ready(function() {
	$DOC.INIT();
});
