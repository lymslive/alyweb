var $KAIHE = {
	API_URL: '/kaihe/japi.cgi',

	GetRooms: function(_callback) {
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
					_callback(_res);
				}
			})
			.fail(function(_jqXHR, _textStatus, _errorThrown) {
				console.log('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
			})
			.always(function(_data, _textStatus, _jqXHR) {
				console.log('ajax finish with status: ' + _textStatus);
			});
	},

	FillRooms: function($select, res) {
		for (var i = 0; i < res.length; ++i) {
			var room = res[i].id;
			var $option = $("<option></option>");
			$option.attr("value", room).html(room);
			$option.appendTo($select);
		}
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

		var ajx = $.ajax(this.API_URL, opt)
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

	__LAST__: true
};
