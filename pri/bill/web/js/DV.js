// 表观
var $DV = {
	// 通用函数
	Fun: {
		// 跳转到某位置
		jumpLink: function(_sid) {
			$(_sid)[0].scrollIntoView(true);
			// location.href = _sid;
		},

	},

	Page: {
		curid: '',

		// 自动选择第一页
		init: function() {
			var $curMenu = $('#menu-bar>ul>li').first();
			var curid = $curMenu.find('>a').attr('href');
			if (curid) {
				this.see(curid);
			}
		},

		// 只看某页，传入 #id
		see: function(_toid, _hasperson){
			if (this.curid == _toid) {
				return false;
			}
			$('div.page').hide();
			$(_toid).show();
			this.curid = _toid;
			$('#menu-bar li.page-menu').each(function() {
				if ($(this).find('a').attr('href') == _toid) {
					$(this).addClass('curr-page');
				}
				else {
					$(this).removeClass('curr-page');
				}
			});

			return true;
		},

		LAST_PRETECT: true
	},

	// 主表格
	Table: {
		domid: '#tabBill',
		rows: 0,
		rowcss: 'rowdata',

		// 10 行以上额外加底部标题行
		but_limit: 10,
		butid: 'butTH',

		// 创建表头行，返回 jq 对象
		hth: function(rid) {
			var $tr = $("<tr></tr>\n");
			if (rid) {
				$tr.attr('id', rid);
			}
			else {
				$tr.attr('id', this.butid);
			}
			var title = $DD.Table.Title;
			for (var i=0; i<title.length; i++) {
				var $th = $("<th></th>\n").html(title[i]);
				$tr.append($th);
			}
			return $tr;
		},

		empty: function() {
			if (this.rows <= 0) {
				return;
			}

			console.log('将清空表格数据行：' + this.rows);
			$(this.domid).find('.' + this.rowcss).remove();
			$('#' + this.butid).remove();
			this.rows = 0;
		},

		fill: function() {
			var data = $DD.Table.List;
			if (data.length <= 0) {
				return;
			}
			if (this.rows) {
				this.empty();
			}
			console.log('将填充表格数据行：' + data.length);
			var $table = $(this.domid);
			for (var i=0; i<data.length; i++) {
				if (!this.Filter.checkOK(data[i])) {
					continue;
				}

				var $tr = this.formatRow(data[i]);
				this.rows++;
				if (this.rows % 2 == 0) {
					$tr.addClass("even");
				}
				$table.append($tr);
			}
			if (this.rows > this.but_limit) {
				$table.append(this.hth());
			}

			var Pager = $DD.Table.Pager;
			var sumary = [Pager.curidx+1, Pager.pagemax, Pager.total];
			$('#tabSumary span.data').each(function(_idx, _ele) {
				$(this).html(sumary[_idx]);
			});
		},

		formatRow: function(jrow) {
			var id = jrow.F_id;
			var type = jrow.F_type;
			var subtype = jrow.F_subtype;
			var money = jrow.F_money;
			var date = jrow.F_date || $DD.NULL;
			var time = jrow.F_time || $DD.NULL;
			var target = jrow.F_target || $DD.NULL;
			var place = jrow.F_place || $DD.NULL;
			var note = jrow.F_note || $DD.NULL;

			// 金额转换显示单位，分转元
			money /= 100;
			// 类别转换显示名字
			type = $DD.typeName(type);
			subtype = $DD.subTypeName(subtype);

			var html = '';

			var $tr = $("<tr></tr>\n")
				.attr('id', 'r' + id)
				.attr('class', this.rowcss)
			;

			var $td = $("<td></td>").html(id);
			$tr.append($td);
			$td = $('<td></td>').html(date);
			$tr.append($td);
			$td = $('<td></td>').html(time);
			$tr.append($td);
			$td = $('<td></td>').html(type);
			$tr.append($td);
			$td = $('<td></td>').html(subtype);
			$tr.append($td);
			$td = $('<td></td>').html(money);
			$tr.append($td);
			$td = $('<td></td>').html(target);
			$tr.append($td);
			$td = $('<td></td>').html(place);
			$tr.append($td);
			$td = $('<td></td>').html(note);
			$tr.append($td);

			$tr.mouseover(function() {
				$(this).addClass("over");
			});
			$tr.mouseout(function() {
				$(this).removeClass("over");
			});

			return $tr;
		},

		// 更新一行，替换或加在表尾
		updateRow: function(_row) {
			var id = _row.F_id;
			var rid = '#r' + id;
			var $old = $(rid);
			var $tr = this.formatRow(_row);
			if ($old.length > 0) {
				if ($old.hasClass('even')) {
					$tr.addClass('even');
				}
				$old.replaceWith($tr);
			}
			else {
				this.rows++;
				if (this.rows % 2 == 0) {
					$tr.addClass("even");
				}
				$(this.domid).append($tr);
			}
		},

		// 过滤表单
		Filter: {
			type: 0,
			month: 0,
			typeIN: [0],
			typeOUT: [0],
			dateFrom: '',
			dateTo: '',

			checkOK: function(_row) {
				if (this.type && this.type != _row.F_type) {
					return false;
				}
				if (_row.F_type > 0 && this.typeIN.length > 1) {
					if (this.typeIN.indexOf(_row.F_subtype) < 0) {
						return false;
					}
				}
				else if (_row.F_type < 0 && this.typeOUT.length > 1) {
					if (this.typeOUT.indexOf(_row.F_subtype) < 0) {
						return false;
					}
				}
				// todo 判断日期
				return true;
			},

			// 下拉列表变化
			onSelection: function() {
				var $form = $('#formFilter');
				var $type = $form.find('select[name=type]');
				var $month = $form.find('select[name=month]');
				this.type = parseInt($type.val());
				this.month = parseInt($month.val());
				if (this.month) {
					// todo 更新日期起止
				}
				$DV.Table.fill();
				this.showCount(true);
			},

			// 复选框变化
			onCheckBox: functio(_evt) {
				var target = _evt.target;
				var subtype = target.value;
				if (subtype > 0) {
					if (target.checked) {
						this.typeIN.push(subtype);
					}
					else {
						// todo 取消选择
					}
				}
				else if (subtype < 0) {
					if (target.checked) {
						this.typeOUT.push(subtype);
					}
					else {
						// todo 取消选择
					}
				}
			},

			showCount: function(_filtered) {
				if (!_filtered) {
					$('#formFilter div.operate-warn').html('');
				}
				else {
					var msg = '当前页筛选：' + $DV.Table.rows + '/' + $DD.Table.List.length + '记录';
					$('#formFilter div.operate-warn').html(msg);
				}
			},

			// 撤销过滤，显示全表
			onReset: function() {
				if (this.type || this.month || this.dateFrom || this.dateTo
				|| this.typeIN.length > 1 || this.typeOUT.length > 1) {
					this.type = this.month = 0;
					this.dateFrom = this.dateTo = '';
					this.typeIN = [0];
					this.typeOUT = [0];
					$DV.Table.fill();
					this.showCount(false);
					$('#formFilter').trigger('reset');
				}
			},

			// 响应提交表单
			onSubmit: function() {
				var $form = $('#formFilter');
				var where = {};

				var type = $form.find('input:text[name=type]').val();
				if (type) {
					where.F_type = parseInt(type);
				}

				// todo 子类别条件

				// 日期
				var dateFrom  = $form.find('input[name=date-from]').val();
				var dateTo  = $form.find('input[name=date-to]').val();
				if (dateFrom && !dateTo) {
					where.F_date = {'>=': dateFrom};
				}
				else if (!dateFrom && dateTo) {
					where.F_date = {'<=': dateTo};
				}
				else if (dateFrom && dateTo) {
					where.F_date = {'-between': [dateFrom, dateTo]};
				}

				// 数据存到 $DD
				var that = $DD.Table.Pager;
				that.where = where;
				that.fresh = true;

				var page  = $form.find('input[name=page]').val();
				page = parseInt(page);
				if (page) {
					that.page = page;
				}
				var perpage  = $form.find('input[name=perpage]').val();
				perpage = parseInt(perpage);
				if (perpage) {
					that.perpage = perpage;
				}

				return this.doQuery();
			},

			doQuery: function() {
				var that = $DD.Table.Pager;
				var req = {api: 'query'};
				req.data = {page: that.page, perpage: that.perpage};
				if (that.where && Object.keys(that.where).length > 0) {
					req.data.where = that.where;
				}
				else {
					req.data.all = 1;
				}

				// console.log('req = ' + JSON.stringify(req));
				return $DJ.reqQuery(req);
			},

			doneQuery: function(_resData) {
				$DD.Table.load(_resData);
				$DV.Table.fill();
				$DV.Fun.jumpLink('#divBillTable');
			},

			doNext: function() {
				var flag = $DD.Table.Pager.next();
				if (!flag) {
					return;
				}
				if (flag == 'fill') {
					return $DV.Table.fill();
				}
				if (flag == 'query') {
					return this.doQuery();
				}
			},

			doPrev: function() {
				if ($DD.Table.Pager.prev()) {
					$DV.Table.fill();
				}
			},

			LAST_PRETECT: true
		},

		LAST_PRETECT: true
	},

	// 操作表单在某行数据行下展开
	Operate: {
		refid: 0, // 记录上行参照的成员id

		onRadio: function(_evt) {
			// todo 根据类别载入子类别
		},

		onModify: function(_id) {
			// todo 修改某笔流水，自动填充已有信息
		},

		submit: function(evt) {
			var $form = $('#formOperate');
			var id = $form.find('input[name=id]').val();
			var date = $form.find('input[name=date]').val();
			var time = $form.find('input[name=time]').val();
			var type = $form.find('input:radio[name=type]:checked').val();
			var subtype = $form.find('select[name=subtype]:selected').val();
			var money = $form.find('input[name=money]').val();
			var target = $form.find('input[name=target]').val();
			var place = $form.find('input[name=place]').val();
			var note = $form.find('input[name=note]').val();

			id = parseInt(id);
			money = Math.round(parseFloat(money) * 100);
			type = parseInt(type);
			subtype = parseInt(subtype);

			var $error = $form.find('div.operate-warn');
			var fieldvals = {};
			if (id) {
				fieldvals.F_id = id;
			}
			if (date) {
				fieldvals.F_date = date;
			}
			else {
				$error.html('请填写日期');
				return false;
			}
			if (time) {
				fieldvals.F_time = time;
			}
			if (type) {
				fieldvals.F_type = type;
			}
			else {
				$error.html('请选择收支类型');
				return false;
			}
			if (subtype) {
				fieldvals.F_subtype = subtype;
			}
			else {
				$error.html('请选择收支类别');
				return false;
			}
			if (money) {
				fieldvals.F_money = money;
			}
			else {
				$error.html('请填写金额');
				return false;
			}
			if (target) {
				fieldvals.F_target = target;
			}
			if (place) {
				fieldvals.F_place = place;
			}
			if (note) {
				fieldvals.F_note = note;
			}

			var reqData = { requery: 1, fieldvals: fieldvals};
			var req = {data: reqData, sess: $DD.Login.reqSess()};

			// 填了 id 表示修改，否则新增
			if (id) {
				var rold = $DD.getRow(id);
				if (!rold) {
					$error.html('不存在的帐单id');
					return false;
				}
				if ($DD.Fun.objin(fieldvals, rold)) {
					$error.html('未修改任何资料');
					return false;
				}
				req.api = 'modify';
				$DJ.reqModify(req);
			}
			else {
				req.api = 'create';
				$DJ.reqAppend(req);
			}

			// 检测成功
			$error.html('');
			return false;// 测试不提交
		},

		// 避免最后一个逗号
		LAST_PRETECT: 0
	},

	// 登陆界面
	Login: {
		formSID: '#formLogin',

		onSubmit: function() {
			var user = $('#formLogin input[name=loginuid]').val();
			var key  = $('#formLogin input[name=loginkey]').val();
			if (!user || !key) {
				return;
			}
			var reqData = {};
			var id = parseInt(user);
			if (!id) {
				reqData.name = user;
			}
			else {
				reqData.id = user;
			}
			reqData.key = key;
			return $DJ.reqLogin(reqData);
		},

		// 登陆成功
		onSucc: function() {
			$(this.formSID).hide();
			$('#not-login').hide();
			$('#has-login').show();
			var link = $DV.Fun.linktoPerson($DD.Table.Hash[$DD.Login.id]);
			var $link = $(link).click($DE.onSeePerson);
			$('#has-login span.data').html($link);
		},

	},

	LAST_PRETECT: true
};

