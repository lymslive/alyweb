// 表观
var $DV = {
	Page: {
		curid: '',

		// 自动选择第一页
		init: function() {
			var $curMenu = $('#menu-bar>ul>li').first();
			$curMenu.addClass('curr-page');
			// this.curid = '#pg1-table';
			var curid = $curMenu.find('>a').attr('href');
			if (curid) {
				this.see(curid);
			}
		},

		// 只看某页，传入 #id
		see: function(_toid){
			if (this.curid == _toid) {
				return false;
			}
			$('div.page').hide();
			$(_toid).show();
			this.curid = _toid;
			return true;
		}
	},

	// 主表格
	Table: {
		domid: '#tabMember',
		rows: 0,
		rowcss: 'rowdata',

		// 10 行以上额外加底部标题行
		but_limit: 10,
		butid: '#butTH',

		// 创建单元格与行的 jq 对象
		htd: function(content) {
			return $('<td></td>').append(content);
		},
		htr: function(tds,rid) {
			var tr = $('<tr></tr>').attr('id', rid);
			for (var i=0; i < tds.length; i++) {
				tr.append(tds[i]);
			}
			return tr;
		},
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
			$(this.butid).remove();
		},

		fill: function(data) {
			if (data.length <= 0) {
				return;
			}
			if (this.rows) {
				empty();
			}
			console.log('将填充表格数据行：' + data.length);
			for (var i=0; i<data.length; i++) {
				$(this.domid).append(this.formatRow(data[i]));
			}
			if (data.length > this.but_limit) {
				$(this.domid).append(this.hth());
			}
		},

		formatRow: function(jrow) {
			var id = jrow.F_id;
			var name = jrow.F_name;
			var sex = $DD.SEX[jrow.F_sex];
			var level = jrow.F_level > 0 ? '+' + jrow.F_level : '' + jrow.F_level;
			var father = jrow.F_father || $DD.NULL;
			var mother = jrow.F_mother || $DD.NULL;
			var partner = jrow.F_partner || $DD.NULL;
			var birthday = jrow.F_birthday || $DD.NULL;
			var deathday = jrow.F_deathday || $DD.NULL;

			if (father && $DD.Mapid[father]) {
				father = $DD.Mapid[father];
			}
			if (mother && $DD.Mapid[mother]) {
				mother = $DD.Mapid[mother];
			}
			if (partner && $DD.Mapid[partner]) {
				partner = $DD.Mapid[partner];
			}

			var html = '';

			var $tr = $("<tr></tr>\n")
				.attr('id', 'r' + id)
				.attr('class', this.rowcss)
			;

			var $td = $("<td></td>\n");
			var $link = $('<a></a>')
				.html(id)
				.attr('id', 'm' + id)
				.attr('href', '#')
				.attr('class', 'rowid')
				.appendTo($td);
			$tr.append($td);

			$td = $('<td></td>').html(name);
			$tr.append($td);

			$td = $('<td></td>').html(sex);
			$tr.append($td);

			$td = $('<td></td>').html(level);
			$tr.append($td);

			$td = $('<td></td>').html(father);
			$tr.append($td);

			$td = $('<td></td>').html(mother);
			$tr.append($td);

			$td = $('<td></td>').html(partner);
			$tr.append($td);

			$td = $('<td></td>').html(birthday);
			$tr.append($td);

			$td = $('<td></td>').html(deathday);
			$tr.append($td);

			return $tr;
		},

		modify: function(_resData, _reqData) {
			var id = _reqData.id;
		}
	},

	// 操作表单在某行数据行下展开
	Operate: {
		refid: 0, // 记录上行参照的成员id

		fold: function(row) {
			// 不传参时，根据保存的 refid 获取上一行
			if (!row) {
				if (!this.refid) {
					console.log('逻辑错误：只应在某数据行下展开');
					return;
				}
				var rid = 'r' + this.refid;
				row = $('#' + rid);
			}
			else {
				// 在不同行上点击，关闭原来行下的表单
				var rid = row.attr('id');
				if (this.refid && this.refid != rid.substring(1)) {
					this.fold(0);
				}
			}

			if (this.refid) {
				$('#divOperate div.operate-tips').hide();
				$('#oper-detail').hide();
				$('#divOperate').hide();
				$('#formOperate input:radio[name=sex]').attr('checked',false);
				$('#formOperate input:radio[name=operate]').attr('checked',false);
				$('#formOperate input:radio[name=operate]').parent('label').removeClass('radio-checked');
				$('#oper-error').html('');
				this.refid = 0;

				// 隐藏表单并移至末尾
				$('#divOperate').insertAfter($('#debug-log'));
				row.next().remove();
			}
			else {
				// 在指定行下面呈现表单
				$('#divOperate').show();
				var operate = $('#divOperate').detach();
				var td = $('<td colspan="9"></td>');
				td.append(operate);
				var tr = $('<tr id="roperater"></tr>');
				tr.append(td);
				tr.insertAfter(row);
				// 取出 id ，r10025 => 10025
				var rid = row.attr('id');
				this.refid = rid.substring(1);
			}
		},

		// modify append remove 三个单选按钮，只显示相应的 tips
		showOnly: function(op) {
			$('#divOperate div.operate-tips').hide();
			$('#formOperate input:radio[name=operate]').parent('label').removeClass('radio-checked');
			var tip = '#tip-' + op;
			var radio = '#to-' + op;
			$(tip).show();
			$(radio).parent('label').addClass('radio-checked');
		},

		tip: function(op) {
			this.showOnly(op);
			$('#formOperate input:text').val('');
			// $('#formOperate input:date').attr('value', '');
			if (op == 'modify') {
				$('#oper-detail').show();
				$('#formOperate input:submit').attr('value', '修改资料');

				// 自动填写部分表单
				this.lock($('#formOperate input:text[name=mine_id]'), this.refid);
				var rowdata = $DD.getRow(this.refid);
				if (rowdata.F_father) {
					var father = rowdata.F_father;
					var id = $DD.getRow(father).F_id;
					var name = $DD.getRow(father).F_name;
					var value = id + '/' + name;
					this.lock($('#formOperate input:text[name=father]'), value);
				}
				else {
					this.unlock($('#formOperate input:text[name=father]'));
				}
				if (rowdata.F_mother) {
					var mother = rowdata.F_mother;
					var id = $DD.getRow(mother).F_id;
					var name = $DD.getRow(mother).F_name;
					var value = id + '/' + name;
					this.lock($('#formOperate input:text[name=mother]'), value);
				}
				else {
					this.unlock($('#formOperate input:text[name=mother]'));
				}
				if (rowdata.F_partner) {
					var partner = rowdata.F_partner;
					var id = $DD.getRow(partner).F_id;
					var name = $DD.getRow(partner).F_name;
					var value = id + '/' + name;
					this.lock($('#formOperate input:text[name=partner]'), value);
				}
				else {
					this.unlock($('#formOperate input:text[name=partner]'));
				}
			}
			else if(op == 'append') {
				$('#oper-detail').show();
				$('#formOperate input:submit').attr('value', '添加子女');

				// 自动填表
				this.lock($('#formOperate input:text[name=mine_id]'), '');

				var rowdata = $DD.getRow(this.refid);
				if (rowdata.F_sex == 1) {
					var value = this.refid + '/' + rowdata.F_name;
					this.lock($('#formOperate input:text[name=father]'), value);
					if (rowdata.F_partner) {
						var mother = rowdata.F_partner;
						var id = $DD.getRow(mother).F_id;
						var name = $DD.getRow(mother).F_name;
						var value = id + '/' + name;
						this.lock($('#formOperate input:text[name=mother]'), value);
					}
					else {
						this.unlock($('#formOperate input:text[name=mother]'));
					}
				}
				else if (rowdata.F_sex == 0) {
					var value = this.refid + '/' + rowdata.F_name;
					this.lock($('#formOperate input:text[name=mother]'), value);
					if (rowdata.F_partner) {
						var father = rowdata.F_partner;
						var id = $DD.getRow(father).F_id;
						var name = $DD.getRow(father).F_name;
						var value = id + '/' + name;
						this.lock($('#formOperate input:text[name=father]'), value);
					}
					else {
						this.unlock($('#formOperate input:text[name=father]'));
					}
				}
				else {
					console.log('男1女0，错误性别：' + rowdata.F_sex);
				}

				this.unlock($('#formOperate input:text[name=partner]'));
			} 
			else if(op == 'remove') {
				$('#oper-detail').hide();
			}
			else {
				console.log('未定义操作');
			}
		},

		// 锁定某些表单域
		lock: function($input, value) {
			$input.val(value);
			$input.attr('readonly', true);
			// $input.parent().addClass('input-lock');
			$input.addClass('input-lock');
		},

		unlock: function($input) {
			$input.attr('readonly', false);
			// $input.parent().removeClass('input-lock');
			$input.removeClass('input-lock');
		},

		submit: function(evt) {
			if (!this.refid) {
				console.log('逻辑错误：不在参照行下展开表单？');
				return false;
			}

			var $form = $('#formOperate');
			var op = $form.find('input:radio[name=operate]:checked').val();
			var operkey = $form.find('input[name=operkey]').val();
			var mine_id = $form.find('input[name=mine_id]').val();
			var mine_name = $form.find('input[name=mine_name]').val();
			var sex = $form.find('input:radio[name=sex]:checked').val();
			var father = $form.find('input[name=father]').val();
			var mother = $form.find('input[name=mother]').val();
			var partner = $form.find('input[name=partner]').val();
			var birthday = $form.find('input[name=birthday]').val();
			var deathday = $form.find('input[name=deathday]').val();

			var reqData = {};
			var req = {};
			var $error = $('#oper-error');
			if (op == 'modify') {
				if (!mine_id || mine_id != this.refid) {
					console.log('id 不匹配');
					$error.html('id 不匹配');
					return false;
				}
				reqData.id = mine_id;
				var jold = $DD.getRow(this.refid);
				if (mine_name && jold.F_name != mine_name) {
					reqData.name = mine_name;
				}
				if (sex && sex != jold.F_sex) {
					reqData.sex = sex;
				}
				if (!jold.F_father && father) {
					var father_id = parseInt(father);
					if (isNaN(father_id)) {
						reqData.father_name = father;
					}
					else {
						reqData.father_id = father_id;
					}
				}
				if (!jold.F_mother && mother) {
					var mother_id = parseInt(mother);
					if (isNaN(mother_id)) {
						reqData.mother_name = mother;
					}
					else {
						reqData.mother_id = mother_id;
					}
				}
				// 配偶允许多个
				if (partner) {
					var partner_id = parseInt(partner);
					if (isNaN(partner_id)) {
						reqData.partner_name = partner;
					}
					else {
						if (jold.F_partner != partner_id) {
							reqData.partner_id = partner_id;
						}
					}
				}
				if (birthday) {
					reqData.birthday = birthday;
				}
				if (deathday) {
					reqData.deathday = deathday;
				}

				if (Object.keys(reqData).length <= 1) {
					console.log('没有更新任何资料 keys');
					$error.html('没有更新任何资料 keys');
					return false;
				}

				req.api = 'modify';
				req.data = reqData;
				console.log(req);
				$DV.log(req);
				$DJ.reqModify(req);
			}
			else if (op == 'append') {
				if (mine_name) {
					reqData.name = mine_name;
				}
				else {
					console.log('新增后代必须填姓名');
					$error.html('新增后代必须填姓名');
					return false;
				}
				if (sex) {
					reqData.sex = sex;
				}
				else {
					console.log('新增后代必须选性别');
					$error.html('新增后代必须选性别');
					return false;
				}

				if (father) {
					var father_id = parseInt(father);
					if (isNaN(father_id)) {
						reqData.father_name = father;
					}
					else {
						reqData.father_id = father_id;
					}
				}
				if (mother) {
					var mother_id = parseInt(mother);
					if (isNaN(mother_id)) {
						reqData.mother_name = mother;
					}
					else {
						reqData.mother_id = mother_id;
					}
				}
				if (!father && !mother) {
					console.log('新增后代必须指定父母之一');
					$error.html('新增后代必须指定父母之一');
					return false;
				}

				if (partner) {
					var partner_id = parseInt(partner);
					if (isNaN(partner_id)) {
						reqData.partner_name = partner;
					}
					else {
						reqData.partner_id = partner_id;
					}
				}
				if (birthday) {
					reqData.birthday = birthday;
				}
				if (deathday) {
					reqData.deathday = deathday;
				}

				req.api = 'create';
				req.data = reqData;
				console.log(req);
			}
			else {
				console.log('只有修改或增加后代需提交数据');
			}

			// 检测成功
			$error.html('');
			return false;// 测试不提交
		},

		// 避免最后一个逗号
		LAST_PRETECT: 0
	},

	log: function(_msg) {
		if (typeof(_msg) == 'object') {
			_msg = JSON.stringify(_msg);
		}
		$('#debug-log').append("<p>" + _msg + "</p>");
	},
	LAST_PRETECT: true
};


