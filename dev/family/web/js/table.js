// ajax 请求
var $DJ = {
	// 组装请求参数
	reqOption: function(reqData) {
		var opt = {
			method: "POST",
			contentType: "application/json",
			dataType: "json",
			data: JSON.stringify(reqData)
			// data: req // 会发送 api=query& 而不是 json 串
		};
		return opt;
	},

	requestAll: function() {
		var req = {"api":"query","data":{"all":1}};
		var opt = this.reqOption(req);
		this.table = $.ajax($DD.API_URL, opt)
			.done(function(res, textStatus, jqXHR) {
				// api 返回的应该是 json
				if (res.error) {
					$DV.log(res.error);
				}
				else {
					$DD.Table.load(res.data);
					$DV.Table.fill(res.data);
					$DE.onFillTable();
				}
			})
			.fail(this.resFail)
			.always(this.resAlways);
	},

	// 请求修改
	reqModify: function(_req) {
		if (!_req.api || _req.api != 'modify') {
			console.log('请求参数不对');
			return false;
		}
		this.modify = $.ajax($DD.API_URL, reqOption(req))
			.done(function(_res, textStatus, jqXHR) {
				// api 返回的应该是 json
				if (_res.error) {
					$DV.log(_res.error);
				}
				else {
					$DD.Table.modify(_res.data, _req.data);
					$DV.Table.modify(_res.data, _req.data);
					$DE.onModifyRow();
				}
			})
			.fail(this.resFail)
			.always(this.resAlways);
	},

	resFail: function(jqXHR, textStatus, errorThrown) {
		alert('ajax fails!'  +  jqXHR.status + textStatus);
	},
	resAlways: function(data, textStatus, jqXHR) {
		console.log('ajax finish with status: ' + textStatus);
	}
};

// 全局对象
var $DOC = {
	DATA: $DD,
	VIEW: $DV, 
	EVENT: $DE,
	AJAX: $DJ,

	INIT: function() {
		this.EVENT.onLoad();
		this.AJAX.requestAll();
	}
};

$(document).ready(function() {
	$DOC.INIT();
});

