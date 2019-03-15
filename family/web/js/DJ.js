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
		$DV.log('api req = ' + opt.data);
		console.log('api req = ' + opt.data);
		var ajx = $.ajax($DD.API_URL, opt)
			.done(function(res, textStatus, jqXHR) {
				// api 返回的 res 直接解析为 json
				if (res.error) {
					$DV.log('api err = ' + res.error);
				}
				else {
					callback(res.data, req.data);
				}
			})
			.fail(this.resFail)
			.always(this.resAlways);
		return ajx;
	},

    resFail: function(jqXHR, textStatus, errorThrown) {
        alert('ajax fails!'  +  jqXHR.status + textStatus);
    },
    resAlways: function(data, textStatus, jqXHR) {
        console.log('ajax finish with status: ' + textStatus);
    },

	// 默认拉取所有数据
	requestAll: function() {
		var req = {"api":"query","data":{"all":1}};
		this.table = this.requestAPI(req, function(_resData, _reqData) {
			$DD.Table.load(_resData);
			$DV.Table.fill();
			$DE.onFillTable();
			$DJ.reqPartnerAll();
		});
	},

	// 查询配偶
	reqPartnerAll: function() {
		var req = {"api":"query",
			"data":{
				"filter":{
					"level":{"<":0},  // 代际负为旁系
					"partner":{">":0},// 确实关联一个成员
				}
			}
		};
		this.partner = this.requestAPI(req, function(_resData, _reqData) {
			$DD.Table.storePartner(_resData, _reqData);
			$DV.Table.updateName();
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
		});
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
    reqBrief: function(_id, _text, _create) {
        var req = {};
        var data = {id: _id}
        if (_text) {
            data.text = _text;
            if (_create) {
                data.create = 1;
            }
            req.api = 'modify_brief';
        }
        else {
            req.api = 'query_brief';
        }
        req.data = data;

        this.create = this.requestAPI(req, function(_resData, _reqData) {
            $DD.Person.onBriefRes(_resData, _reqData);
        });
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
		this.AJAX.requestAll();
	}
};

$(document).ready(function() {
	$DOC.INIT();
});
