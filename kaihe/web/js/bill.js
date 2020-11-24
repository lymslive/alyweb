var $PNEW = {
	PageID: 'pg1-new',
	FormID: 'formOperate',
	RoomSrc: null,
	CurFlow: 0,
	CurBill: null,  // 当前操作流水记录
	INCOME: ['收入', '统一基金', '缺席捐助', '结余补正'],
	OUTCOME: ['支出', '误工费', '路费', '餐费', '住宿费'],

	InitForm: function() {
		var that = this;
		var $form = $('#' + this.FormID);

		var $radio = $form.find('input:radio[name=type]');
		$radio.change(function(_evt) {
			that.ChangeType();
		});

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

		$form.find('input:submit').click(function(_evt) {
			_evt.preventDefault();
			that.SendSubmit();
		});

		$('#flow').attr('disabled', 'disabled');
		$('#new-flow').click(function(_evt) {
			that.ClearData();
			that.EnableInput();
		});
		$('#mod-flow').click(function(_evt) {
			if (that.CurFlow && $('#flow').val()) {
				that.EnableInput();
			}
		});
		$('#prev-flow').click(function(_evt) {
			that.ChangeBill(-1);
		});
		$('#next-flow').click(function(_evt) {
			that.ChangeBill(1);
		});
	},

	GotRooms: function(res) {
		this.RoomSrc = res;
		var $select = $('#select-room');
		$KAIHE.FillRooms($select, res);
		this.ShowMsg('');
	},

	ShowMsg: function(msg) {
		var $form = $('#' + this.FormID);
		$form.find('div.operate-warn').html(msg);
	},

	DisableInput: function() {
		$('#date').attr('disabled', 'disabled');
		$('#money').attr('disabled', 'disabled');
		$('#room').attr('disabled', 'disabled');
		$('#note').attr('disabled', 'disabled');
	},

	EnableInput: function() {
		$('#date').removeAttr('disabled');
		$('#money').removeAttr('disabled');
		$('#room').removeAttr('disabled');
		$('#note').removeAttr('disabled');
		var that = this;
		if (!this.RoomSrc) {
			$KAIHE.GetRooms(function(res){
				that.GotRooms(res);
			});
		}
	},

	ChangeType: function() {
		var $form = $('#' + this.FormID);
		var type = $form.find('input:radio[name=type]:checked').val();
		var options;
		if (type == 1) {
			options = this.INCOME;
		}
		else if (type == -1) {
			options = this.OUTCOME;
		}
		else {
			return;
		}

		var $select = $('#subtype');
		$select.find('option').remove();
		options.forEach(function(_item, _idx) {
			if (_item) {
				var $option = $("<option></option>");
				$option.attr("value", _idx).html(_item);
				$option.appendTo($select);
			}
		}, this);
	},

	ChangeBill: function(shift) {
		if (!$DOC.MaxFlow) {
			this.ShowMsg('还没有帐单');
			return;
		}
		var flow = 0;
		if (this.CurFlow == 0) {
			flow = $DOC.MaxFlow;
		}
		else {
			flow = this.CurFlow + shift;
		}
		if (flow > 0 && flow <= $DOC.MaxFlow) {
			this.ShowBill(flow);
		}
		else {
			this.ShowMsg('无效单号');
		}
	},

	ShowBill: function(flowid) {
		if ($DOC.PSEE.MapBills[flowid]) {
			var bill = $DOC.PSEE.MapBills[flowid];
			this.ClearData();
			this.LoadData(bill);
		}
		else {
			this.SendQuery(flowid);
		}
	},

	SendQuery: function(flowid) {
		var that = this;
		var req = {
			"api": "query",
			"data": {"flow": flowid}
		};
		this.query = $KAIHE.requestAPI(req, function(_resData, _reqData) {
			that.DoneQuery(_resData);
		}, this.FormID, null);
	},

	DoneQuery: function(res) {
		if (res.records && res.records.length > 0) {
			this.ClearData();
			var bill = res.records[0];
			this.LoadData(bill);
			$DOC.PSEE.SaveBillMap(bill);
		}
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
		$('#money').val(obj.money / 100);
		$('#room').val(obj.room);
		$('#note').val(obj.note);

		var $form = $('#' + this.FormID);
		var subtype = obj.subtype;
		if (obj.type > 0) {
			$form.find('input[name="type"][value="1"]').prop('checked', true);
		}
		else {
			$form.find('input[name="type"][value="-1"]').prop('checked', true);
		}
		this.ChangeType();
		$('#subtype').val(subtype);

		this.DisableInput();
		this.ShowMsg('');
		this.CurFlow = parseInt(obj.flow);
	},

	SaveData: function() {
		var obj = {};
		obj.flow = $('#flow').val();
		obj.date = $('#date').val();
		obj.room = $('#room').val();
		obj.money = $('#money').val();
		obj.note = $('#note').val();
		obj.pass = $('#pass').val();
		obj.admin = $('#admin').val();

		obj.money = obj.money * 100;

		var $form = $('#' + this.FormID);
		var type = $form.find('input[name="type"]:checked').val();
		var subtype = $('#subtype').val();
		obj.type = type;
		obj.subtype = subtype;

		return obj;
	},

	SendSubmit: function() {
		var obj = this.SaveData();
		var sess = this.CheckSubmit(obj);
		if (!sess) {
			return false;
		}

		this.CurBill = obj;

		obj.requery = 1;
		var that = this;
		var req = {
			"data": obj,
			"sess": sess
		};
		if (obj.flow) {
			req.api = "modify";
			var msg = {suc: '修改成功', err: '修改失败'};
			this.query = $KAIHE.requestAPI(req, function(_resData, _reqData) {
				that.DoneCreate(_resData);
			}, 'formOperate', msg);
		}
		else {
			req.api = "create";
			var msg = {suc: '创建成功', err: '创建失败'};
			this.query = $KAIHE.requestAPI(req, function(_resData, _reqData) {
				that.DoneModify(_resData);
			}, 'formOperate', msg);
		}
	},

	DoneSubmit: function() {
	},

	DoneCreate: function(res) {
		var bill = res.mine;
		this.LoadData(bill);
		$DOC.PSEE.SaveBillMap(bill);
		$DOC.PSEE.Table.updateBill(bill);
		$DOC.FreshTotal(bill.flow);
	},

	DoneModify: function(res) {
		var bill = res.mine;
		this.LoadData(bill);
		$DOC.PSEE.Table.updateBill(bill);
	},

	CheckSubmit: function(obj) {
		var $form = $('#' + this.FormID);
		var $msg = $form.find('div.operate-warn');
		$msg.html('');
		if (!obj.admin) {
			$msg.html('请输入管理员房号');
			return false;
		}
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
		// return true;
		var sess = {"admin": obj.admin, "password": obj.pass};
		delete obj.admin;
		delete obj.pass;
		return sess;
	},

	__LAST__: true
};

var $PSEE = {
	PageID: 'pg2-see',

	// 所有加载过的帐单
	MapBills: {}, 
	SaveBillMap: function(bill) {
		if (bill && bill.flow) {
			this.MapBills[bill.flow] = bill;
		}
	},

	// 当前分页显示的帐单视图
	Table : {
		PageNo: 0,
		MaxFlow: 0,
		MinFlow: 0,
		Bills: [],

		domid: '#tabBill',
		rows: 0,
		rowcss: 'rowdata',

		show_msg: function(msg) {
			$('#tabFoot div.operate-warn').html(msg);
		},

		got_bill: function(bills) {
			this.Bills = bills;
			this.MaxFlow = 0;
			this.MinFlow = 0;
			for (var i = 0; i < this.Bills.length; ++i) {
				var flow = this.Bills[i].flow;
				if (this.MaxFlow == 0 || this.MaxFlow < flow) {
					this.MaxFlow = flow;
				}
				if (this.MinFlow == 0 || this.MinFlow > flow) {
					this.MinFlow = flow;
				}

				$DOC.PSEE.SaveBillMap(this.Bills[i]);
			}

			if ($DOC.MaxFlow < this.MaxFlow) {
				$DOC.FreshTotal(this.MaxFlow);
			}
		},

		empty: function() {
			if (this.rows <= 0) {
				return;
			}

			console.log('将清空表格数据行：' + this.rows);
			$(this.domid).find('.' + this.rowcss).remove();
			this.rows = 0;
		},

		fill: function() {
			var data = this.Bills;
			if (data.length <= 0) {
				return;
			}
			if (this.rows) {
				this.empty();
			}
			console.log('将填充表格数据行：' + data.length);
			var $table = $(this.domid);
			for (var i=0; i<data.length; i++) {
				var $tr = this.formatRow(data[i]);
				this.rows++;
				// if (this.rows % 2 == 0) {
				if (data[i].flow % 2 == 0) {
					$tr.addClass("even");
				}
				$table.append($tr);
			}
		},

		formatRow: function(jrow) {
			var flow = jrow.flow;
			var date = jrow.date
			var money = jrow.money;
			var balance = jrow.balance;

			// 金额转换显示单位，分转元
			money /= 100;
			balance /= 100;

			// 类别转换显示名字
			var subtype = jrow.subtype;
			var type = jrow.type;
			var showtype = '--';
			if (type > 0) {
				var names = $DOC.PNEW.INCOME;
				showtype = names[subtype];
			}
			else {
				var names = $DOC.PNEW.OUTCOME;
				showtype = names[subtype];
				money = - money;
			}

			var html = '';

			var $tr = $("<tr></tr>\n")
				.attr('id', 'r' + flow)
				.attr('class', this.rowcss)
			;

			var $td = $('<td class="rowid"></td>').html(flow);
			$tr.append($td);
			$td = $('<td></td>').html(date);
			$tr.append($td);
			$td = $('<td></td>').html(money);
			$tr.append($td);
			$td = $('<td></td>').html(balance);
			$tr.append($td);
			$td = $('<td></td>').html(showtype);
			$tr.append($td);

			$tr.mouseover(function() {
				$(this).addClass("over");
			});
			$tr.mouseout(function() {
				$(this).removeClass("over");
			});

			$tr.click(function(_evt) {
				$PNEW.ShowBill(flow);
				$('body').scrollTop($('#flow').offset().top);
			});
			return $tr;
		},

		// 更新一行，替换或加在表头
		updateBill: function(bill) {
			var id = bill.flow;
			var rid = '#r' + id;
			var $old = $(rid);
			var $tr = this.formatRow(bill);
			if ($old.length > 0) {
				if ($old.hasClass('even')) {
					$tr.addClass('even');
				}
				$old.replaceWith($tr);
			}
			else {
				this.rows++;
				// if (this.rows % 2 == 0) {
				if (bill.flow % 2 == 0) {
					$tr.addClass("even");
				}
				$tr.insertAfter($('#topTH'));
				if (this.MaxFlow + 1 == bill.flow) {
					this.MaxFlow = bill.flow;
				}
			}
		},

		switch_page: function(direction) {
			this.show_msg('');
			var flow = 0;
			if (direction < 0) {
				if (this.MaxFlow >= $DOC.MaxFlow) {
					this.show_msg('没有上一页了');
					return;
				}
				flow = '>' + this.MaxFlow;
			}
			else if (direction > 0) {
				if (this.MinFlow <= 1) {
					this.show_msg('没有下一页了');
					return;
				}
				flow = '<' + this.MinFlow;
			}
			else {
				this.show_msg('请点击上一页或下一页');
				return;
			}

			this.SendQuery({"flow": flow});
		},

		SendQuery: function(data) {
			var req = {
				"api": "query",
				"data": data
			};
			var that = this;
			this.query = $KAIHE.requestAPI(req, function(_resData, _reqData) {
				that.DoneQuery(_resData);
			}, null, null);
		},

		DoneQuery: function(res) {
			this.got_bill(res.records);
			this.fill();
		},

		Init: function() {
			this.SendQuery({});
		},

		__LAST__: true
	},

	__LAST__: true
};

// 全局对象
var $DOC = {
	TableSrc: null,
	API_URL: '/kaihe/bill.cgi',
	MaxFlow: 0,
	AllBalance: 0,
	PNEW: $PNEW,
	PSEE: $PSEE,
	Initing: false,

	INIT: function() {
		this.Initing = true;
		var that = this;
		$KAIHE.API_URL = this.API_URL;
		this.Version = $('#version').html();

		$PNEW.InitForm();
		$PSEE.Table.Init();
	},

	FreshTotal: function(flow) {
		this.MaxFlow = flow;
		this.AllBalance = $DOC.PSEE.MapBills[this.MaxFlow].balance;
		$('#last-flow').html(this.MaxFlow);
		$('#last-balance').html(this.AllBalance / 100);

		if (this.Initing) {
			this.PNEW.ShowBill(this.MaxFlow);
			this.Initing = false;
		}
	},

	__LAST__: true
};

$(document).ready(function() {
	$DOC.INIT();
});
