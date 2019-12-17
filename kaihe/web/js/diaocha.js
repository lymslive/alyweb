// 全局对象
var $DOC = {
	TableSrc: null,
	API_URL: '/kaihe/diaocha.cgi',
	CURRENT: 'create',

	INIT: function() {
		this.Version = $('#version').html();
		this.InitForm();
	},

	InitForm: function() {
		this.GetRooms();

		var $select = $('#select-room');
		$select.change(function(_evt) {
			var room = $(this).val();
			if (room == 'tip-select') {
				$('#room').val('').removeAttr('disabled');
			}
			else {
				$('#room').val(room).attr('disabled', 'disabled');
				$DOC.SelectRoom(room);
			}
		});

		var $input = $('#room');
		$input.change(function(_evt) {
			var room = $(this).val();
			$DOC.InputRoom(room);
		});

		$('#submit').click(function(_evt) {
			_evt.preventDefault();
			$DOC.SendSubmit();
		});
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
					$DOC.GotRooms(_res);
				}
			})
			.fail(function(_jqXHR, _textStatus, _errorThrown) {
				console.log('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
			})
			.always(function(_data, _textStatus, _jqXHR) {
				console.log('ajax finish with status: ' + _textStatus);
			});
	},

	GotRooms: function(res) {
		this.TableSrc = res;
		var $select = $('#select-room');
		for (var i = 0; i < res.length; ++i) {
			var room = res[i].id;
			var $option = $("<option></option>");
			$option.attr("value", room).html(room);
			$option.appendTo($select);
		}
		$('#getting-room').html('');
	},

	SelectRoom: function(room) {
		this.SendQuery(room);
	},

	InputRoom: function(room) {
		this.SendQuery(room);
	},

	reqOption: function(_req) {
		var opt = {
			method: "POST",
			contentType: "application/json",
			dataType: "json",
			data: JSON.stringify(_req)
		};
		return opt;
	},

	requestAPI: function(_req, _callback, _form, _msg) {
		var opt = this.reqOption(_req);
		this._last_req = _req;

		var $form = $('#' + _form);
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

		if (_form) {
			$msg.html('正在请求服务器通讯……');
			$submit.attr('disabled', 'disabled');
		}
		return ajx;
	},

	SendQuery: function(room) {
		var req = {
			"api": "query",
			"data": {"room": room}
		};
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DOC.DoneQuery(_resData);
		}, null, null);
	},

	DoneQuery: function(res) {
		this.ClearData();
		if (!res.room) {
			$('#already').html('还未填写过');
			this.CURRENT = 'create';
			return;
		}
		var room = res.room;
		$('#already').html('已填写，可修改');
		this.CURRENT = 'modify';
		this.LoadData(room, res.json);
	},

	ClearData: function() {
		// $('#room').val('');
		$('#name').val('');
		$('#telephone').val('');
		$('#idcard').val('');
		$('#shoufu-date').val('');
		$('#fangdai-date').val('');
		$('#area').val('');
		$('#taolu-more').val('');
		$('#say-more').val('');

		$('input[name="beian"]').prop('checked', false);
		$('input[name="taolu"]').prop('checked', false);
	},

	LoadData: function(room, strJson) {
		var obj = JSON.parse(strJson);
		$('#room').val(obj.room);
		$('#name').val(obj.name);
		$('#telephone').val(obj.telephone);
		$('#idcard').val(obj.idcard);
		$('#shoufu-date').val(obj.shoufu_date);
		$('#fangdai-date').val(obj.fangdai_date);
		$('#area').val(obj.area);
		$('#taolu-more').val(obj.taolu_more);
		$('#say-more').val(obj.say_more);

		// $('#beian').val(obj.beian);
		if (obj.beian == 'yes') {
			$('input[name="beian"][value="yes"]').prop('checked', true);
		}
		else {
			$('input[name="beian"][value="no"]').prop('checked', true);
		}

		var taolu = obj.taolu;
		var $taolu = $('input[name="taolu"]');
		$taolu.prop('checked', false);
		$taolu.each(function(_idx, _element) {
			var val = $(this).val();
			if (taolu.indexOf(val) >= 0) {
				$(this).prop('checked', true);
			}
		});
	},

	SaveData: function() {
		var obj = {};
		obj.room = $('#room').val();
		obj.name = $('#name').val();
		obj.telephone = $('#telephone').val();
		obj.idcard = $('#idcard').val();
		obj.shoufu_date = $('#shoufu-date').val();
		obj.fangdai_date = $('#fangdai-date').val();
		obj.beian = $('input[name="beian"]:checked').val();
		obj.area = $('#area').val();

		// obj.taolu 复选框
		var taolu = [];
		$('input[name="taolu"]:checked').each(function(_idx, _element) {
			taolu.push($(this).val());
		});
		obj.taolu = taolu;
		obj.taolu_more = $('#taolu-more').val();

		obj.say_more = $('#say-more').val();
		return obj;
	},

	SendSubmit: function() {
		if (!this.CheckSubmit()) {
			return false;
		}
		var obj = this.SaveData();
		var strJson = JSON.stringify(obj);

		var pass = $('#passwd-1').val();
		var req = {
			"api": "create",
			"data": {"room": obj.room, "json": strJson, "pass": pass}
		};
		if (this.CURRENT == 'modify') {
			req.api = "modify";
		}
		var msg = {suc: '保存成功', err: '保存失败'};
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DOC.DoneSubmit(_resData);
		}, 'form', msg);
	},

	DoneSubmit: function() {
	},

	CheckSubmit: function() {
		var $msg = $('#form-msg');
		$msg.html('');
		var ps1 = $('#passwd-1').val();
		var ps2 = $('#passwd-2').val();
		if (!ps1) {
			$msg.html('请输入安全密码');
			return false;
		}
		if (!ps2) {
			$msg.html('请输入确认密码');
			return false;
		}
		if (ps1 !== ps2) {
			$msg.html('两次密码不匹配');
			return false;
		}
		return true;
	},

	__LAST__: true
};

$(document).ready(function() {
	$DOC.INIT();
});
