var $PNEW = {
	PageID: 'pg1-new',
	FormID: 'formOperate',

	InitForm: function() {
		var that = this;
		var $select = $('#select-room');
		$select.change(function(_evt) {
			var room = $(this).val();
			if (room == 'tip-select') {
				$('#room').val('').removeAttr('disabled');
			}
			else {
				$('#room').val(room).attr('disabled', 'disabled');
			}
		});

		$('#submit').click(function(_evt) {
			_evt.preventDefault();
			that.SendSubmit();
		});
	},

	SendQuery: function(flowid) {
		var that = this;
		var req = {
			"api": "query",
			"data": {"flowid": flowid}
		};
		this.query = $KAIHE.requestAPI(req, function(_resData, _reqData) {
			that.DoneQuery(_resData);
		}, this.FormID, null);
	},

	DoneQuery: function(res) {
		this.ClearData();
		this.LoadData(room, res.json);
	},

	ClearData: function() {
		$('#flow').val('');
		$('#date').val('');
		$('#money').val('');
		$('#room').val('');
		$('#note').val('');

		var $form = $('#' + this.FormID);
		$form.find('input[name="type"]').prop('checked', false);
		$('#subtype').val('0');
	},

	LoadData: function(obj) {
		$('#flow').val(obj.flow);
		$('#date').val(obj.date);
		$('#money').val(obj.money);
		$('#room').val(obj.room);
		$('#note').val(obj.note);

		var $form = $('#' + this.FormID);
		var subtype = obj.type;
		if (obj.type > 0) {
			$form.find('input[name="type"][value="1"]').prop('checked', true);
		}
		else {
			$form.find('input[name="type"][value="-1"]').prop('checked', true);
			subtype = -subtype;
		}
		$('#subtype').val(subtype);
	},

	SaveData: function() {
		var obj = {};
		obj.flow = $('#name').val();
		obj.date = $('#date').val();
		obj.room = $('#room').val();
		obj.money = $('#money').val();
		obj.note = $('#note').val();
		obj.pass = $('#pass').val();

		var $form = $('#' + this.FormID);
		var type = $form.find('input[name="type"]:checked').val();
		var subtype = $('#subtype').val();
		obj.type = (0 + type) * (0 + subtype);

		return obj;
	},

	SendSubmit: function() {
		var obj = this.SaveData();
		if (!this.CheckSubmit(obj)) {
			return false;
		}

		var req = {
			"api": "create",
			"data": obj
		};
		if (obj.flow) {
			req.api = "modify";
		}
		var msg = {suc: '保存成功', err: '保存失败'};
		this.query = $KAIHE.requestAPI(req, function(_resData, _reqData) {
			$DOC.DoneSubmit(_resData);
		}, 'form', msg);
	},

	DoneSubmit: function() {
	},

	CheckSubmit: function(obj) {
		var $form = $('#' + this.FormID);
		var $msg = $form.find('div.operate-warn');
		$msg.html('');
		if (!obj.pass) {
			$msg.html('请输入安全密码');
			return false;
		}
		if (!obj.money) {
			$msg.html('请输入金额');
			return false;
		}
		if (!obj.date) {
			$msg.html('请输入日期');
			return false;
		}
		if (!obj.type) {
			$msg.html('请选择类别');
			return false;
		}
		return true;
	},

	__LAST__: true
};

// 全局对象
var $DOC = {
	TableSrc: null,
	API_URL: '/kaihe/bill.cgi',
	CURRENT: 'create',
	INCOME: ['收入', '统一基金', '缺席捐助', '结余补正'],
	OUTCOME: ['支出', '误工费', '路费', '餐费', '住宿费'],
	PAGES: ['pg1-new', 'pg2-see'],

	INIT: function() {
		$KAIHE.API_URL = this.API_URL;
		this.Version = $('#version').html();
		this.GetRooms(this.GotRooms);
		// this.InitForm();
		$PNEW.InitForm();
	},

	GotRooms: function(res) {
		this.TableSrc = res;
		var $select = $('#select-room');
		$KAIHE.FillRooms($select, res);
		$('#formOperate').find('div.operate-warn').html('');
		$select = $('#filter-room');
		$KAIHE.FillRooms($select, res);
	},

	__LAST__: true
};

$(document).ready(function() {
	$DOC.INIT();
});
