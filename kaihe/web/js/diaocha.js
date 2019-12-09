// 全局对象
var $DOC = {
	TableSrc: null,
	API_URL: '/kaihe/diaocha.cgi',

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
	},

	SelectRoom: function(room) {
		this.SendQuery(room);
	},

	InputRoom: function(room) {
		this.SendQuery(room);
	},

	requestAPI: function(_req, _callback, _form, _msg) {
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

		if (_form) {
			$msg.html('正在请求服务器通讯……');
			$submit.attr('disabled', 'disabled');
		}
		return ajx;
	},

	SendQuery: function() {
	},

	DoneQuery: function() {
	},

	SendSubmit: function() {
		if (!CheckSubmit()) {
			return false;
		}
	},

	DoneSubmit: function() {
	},

	CheckSubmit: function() {
		var $msg = $('#form-msg');
		var ps1 = $('#passwd-1').val();
		var ps2 = $('#passwd-1').val();
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
