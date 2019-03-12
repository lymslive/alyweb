// ajax 请求
var $DJ = {
	// 组装请求参数
	reqOption: function(req) {
		var opt = {
			method: "POST",
			contentType: "application/json",
			dataType: "json",
			data: JSON.stringify(req)
			// data: req // 会发送 api=query& 而不是 json 串
		};
		return opt;
	},

	// 封装请求服务端 api
	// req 为请求 api json 对象， callback 是成功时回调，接收参数为响应与请求
	// 的实质 data 部分
	requestAPI: function(req, callback) {
		var opt = this.reqOption(req);
		var ajx = $.ajax($DD.API_URL, opt)
			.done(function(res, textStatus, jqXHR) {
				// api 返回的 res 直接解析为 json
				if (res.error) {
					$DV.log(res.error);
				}
				else {
					callback(res.data, req.data);
				}
			})
			.fail(this.resFail)
			.always(this.resAlways);
		return ajx;
	},

	// 默认拉取所有数据
	requestAll: function() {
		var req = {"api":"query","data":{"all":1}};
		this.table = this.requestAPI(req, function(_resData, _reqData) {
			$DD.Table.load(_resData);
			$DV.Table.fill();
			$DE.onFillTable();
		});
	},

	// 查询配偶
	reqPartnerAll: function() {
		var req = {"api":"query",
			"data":{
				"filter":{
					"F_level":{"<":0},  // 代际负为旁系
					"F_partner":{">":0},// 确实关联一个成员
				}
			}
		};
		this.modify = this.requestAPI(req, function(_resData, _reqData) {
			$DD.Table.storePartner(_resData, _reqData);
		});
	},

	// 请求修改
	reqModify: function(_req) {
		if (!_req.api || _req.api != 'modify') {
			console.log('请求参数不对');
			return false;
		}
		this.modify = this.requestAPI(_req, function(_resData, _reqData) {
			$DD.Table.modify(_resData, _reqData);
			$DE.onModifyRow();
		});
	},

	// 请求增加
	reqAppend: function(_req) {
		if (!_req.api || _req.api != 'create') {
			console.log('请求参数不对');
			return false;
		}
		this.create = this.requestAPI(_req, function(_resData, _reqData) {
			$DD.Table.modify(_resData, _reqData);
			$DE.onModifyRow();
		});
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
		this.VIEW.Page.init();
		this.AJAX.requestAll();
	}
};

$(document).ready(function() {
	$DOC.INIT();
});

/* 备注：
 * 跳转到指定地方：
 * var scroll_offset = $('#pos').offset()
 * $("body,html").animate({scrollTo:scroll_offset.top})
 */
