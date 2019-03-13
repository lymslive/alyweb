// 表观
var $DV = {
	// 通用函数
	Fun: {
		// 构造指向某个人的超链接，入参为一行记录，出参数为 html 字符串
		linktoPerson: function(_row, _suffix) {
			var id = _row.F_id;
			var name = _row.F_name;
			var sex = _row.F_sex;
			if (_suffix && sex < 2) {
				name += $DD.SEX[sex].substring(1);
			}
			// var html = '<a href="#p' + id + '" title="' + id + '">' + name + '</a>';
			var html = `<a href="#p${id}" title="${id}" class="toperson">${name}</a>`;
			return html;
		},

		// 为成员 id 构造超链接，未加载该行记录，可能无法显示姓名
		linktoPid: function(_id) {
			var name = _id;
			var title = _id;
			var css = 'toperson';
			if ($DD.Mapid[_id]) {
				name = $DD.Mapid[_id];
			}
			else {
				title = '点击查找姓名';
				css += ' qname';
			}
			// var html = '<a href="#p' + _id + '" title="' + title + '">' + name + '</a>';
			var html = `<a href="#p${_id}" title="${title}" class="${css}">${name}</a>`;
			return html;
		},
	},

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
			$('#menu-bar li.page-menu').each(function() {
				if ($(this).find('a').attr('href') == _toid) {
					$(this).addClass('curr-page');
				}
				else {
					$(this).removeClass('curr-page');
				}
			});

			// 首次进入个人详情页，默认展示顶级祖先
			if (_toid == '#pg2-person') {
				if (!$DD.Person.curid) {
					this.checkPerson($DD.Person.DEFAULT);
				}
			}
			else if (_toid == '#pg3-help') {
				$DV.Help.showdoc();
			}
			return true;
		},

		// 查看某个人详情
		checkPerson: function(_id) {
			if (this.curid != '#pg2-person') {
				this.see('#pg2-person');
			}
			return $DV.Person.checkout(_id);
		},

		LAST_PRETECT: true
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
			this.rows = 0;
		},

		fill: function() {
			var data = $DD.Table.List;
			if (data.length <= 0) {
				return;
			}
			if (this.rows) {
				empty();
			}
			console.log('将填充表格数据行：' + data.length);
			for (var i=0; i<data.length; i++) {
				var $tr = this.formatRow(data[i]);
				this.rows++;
				if (this.rows % 2 == 0) {
					$tr.addClass("even");
				}
				$(this.domid).append($tr);
			}
			// this.rows = data.length;
			if (data.length > this.but_limit) {
				$(this.domid).append(this.hth());
			}

			var sumary = [$DD.Table.total, $DD.Table.page, Math.ceil($DD.Table.total/$DD.Table.perpage)];
			$('#tabSumary span.data').each(function(_idx, _ele) {
				$(this).html(sumary[_idx]);
			});
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

			var html = '';

			var $tr = $("<tr></tr>\n")
				.attr('id', 'r' + id)
				.attr('class', this.rowcss)
			;

			var $td = $("<td></td>\n");
			var $link = $('<a></a>')
				.html(id)
				.attr('id', 'm' + id)
				.attr('href', '#p' + id)
				.attr('class', 'rowid')
				.appendTo($td);
			$tr.append($td);

			name = $DV.Fun.linktoPerson(jrow);
			$td = $('<td></td>').html(name);
			$tr.append($td);

			$td = $('<td></td>').html(sex);
			$tr.append($td);

			$td = $('<td></td>').html(level);
			$tr.append($td);

			if (father) {
				if ($DD.Table.Hash[father]) {
					father = $DV.Fun.linktoPerson($DD.Table.Hash[father]);
				}
				else {
					father = $DV.Fun.linktoPid(father);
				}
			}
			$td = $('<td></td>').html(father);
			$tr.append($td);

			if (mother) {
				if ($DD.Table.Hash[mother]) {
					mother = $DV.Fun.linktoPerson($DD.Table.Hash[mother]);
				}
				else {
					mother = $DV.Fun.linktoPid(mother);
				}
			}
			$td = $('<td></td>').html(mother);
			$tr.append($td);

			if (partner) {
				if ($DD.Table.Hash[partner]) {
					partner = $DV.Fun.linktoPerson($DD.Table.Hash[partner]);
				}
				else {
					partner = $DV.Fun.linktoPid(partner);
				}
			}
			$td = $('<td></td>').html(partner);
			$tr.append($td);

			$td = $('<td></td>').html(birthday);
			$tr.append($td);

			$td = $('<td></td>').html(deathday);
			$tr.append($td);

			// 为当前行附加事件属性
			$tr.find('td a.toperson').click(function(_evt) {
				$DE.gotoPerson($(this));
				_evt.preventDefault();
			});

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

		// 更新链接中缺失名字的 id
		updateName: function() {
			$('td a.qname').each(function(_idx, _element) {
				var id = $(this).html();
				var name = $DD.Mapid[id];
				if (name) {
					$(this).html(name).attr('title', id);
				}
			});
		},

		LAST_PRETECT: true
	},

	// 个人详情页签
	Person: {
		checkout: function(_id) {
			var Data = $DD.Person;
			if (Data.curid == _id) {
				return false;
			}
			$DV.Operate.close();
			Data.lookinTable(_id);
			// todo: 未能先拉全表时？
			var lackoff = $DD.Person.notinTable();
			return this.update(true);
		},

		update: function(_force) {
			var Data = $DD.Person;
			if (!Data.update && !_force) {
				return false;
			}

			// 个人信息
			if (_force || Data.canUpdate(Data.MINE)) {
				var id = Data.mine.F_id;
				var name = Data.mine.F_name;
				var sex = Data.mine.F_sex;
				var level = Data.mine.F_level;
				if (sex < 2) {
					name += $DD.SEX[sex].substring(1);
				}
				if (level > 0) {
					level = '第 +' + level + ' 代直系';
				}
				else {
					level = '第 ' + level + ' 代旁系';
				}

				var text = id + ' | ' + name + ' | ' + level;
				$('#mine-info').html(text);

				if (Data.mine.F_birthday) {
					var text = '';
					var birthDate = new Date(Data.mine.F_birthday); 
					if (Data.mine.F_deathday) {
						var deathDate = new Date(Data.mine.F_deathday); 
						var life = deathDate.getFullYear() - birthDate.getFullYear() + 1;
						text = Data.mine.F_birthday + ' ~ ' + Data.mine.F_deathday + '（' + life + '寿）';
					}
					else {
						var nowDate = new Date(); 
						var age = nowDate.getFullYear() - birthDate.getFullYear() + 1;
						text = Data.mine.F_birthday + ' ~ ?' + '（' + age + '岁）';
					}
					$('#mine-dates span.data').html(text);
					$('#mine-dates').show();
				}
				else {
					$('#mine-dates').hide();
				}

			}

			// 配偶信息
			if (_force || Data.canUpdate(Data.PARTNER)) {
				if (Data.mine.F_partner && Data.partner) {
					var html = $DV.Fun.linktoPerson(Data.partner, 1);
					$('#mine-partner span.data').html(html);
					$('#mine-partner').show();
				}
				else {
					$('#mine-partner').hide();
					$('#mine-children').hide();
				}
			}

			// 后代
			if (_force || Data.canUpdate(Data.CHILDREN)) {
				if (Data.children && Data.children.length > 0) {
					var html = '';
					Data.children.forEach(function(_item, _idx) {
						var child = $DV.Fun.linktoPerson(_item, 1);
						if (html) {
							html += ' ↔ ' + child;
						}
						else {
							html = child;
						}
					});
					$('#mine-children span.data').html(html);
					$('#mine-children').show();
				}
				else {
					$('#mine-children').hide();
				}
			}

			// 先祖
			if (_force || Data.canUpdate(Data.PARENTS)) {
				if (Data.mine.F_level > 1 && Data.parents) {
					var html = '';
					Data.parents.forEach(function(_item, _idx) {
						var parent_one = $DV.Fun.linktoPerson(_item, 1);
						if (html) {
							html += ' ➜ ' + parent_one;
						}
						else {
							html = parent_one;
						}
					});
					$('#mine-parents span.data').html(html);
				}
				else if (Data.mine.F_level == 1) {
					var text = '己是入库的始祖了，有需要请联系管理员升级！';
					$('#mine-parents span.data').html(text);
				}
				else if (Data.mine.F_level < 0) {
					var text = '旁系配偶不入库！';
					$('#mine-parents span.data').html(text);
				}
			}

			// 兄弟
			if (_force || Data.canUpdate(Data.SIBLING)) {
				if (Data.mine.F_level > 1 && Data.sibling && Data.sibling.length > 0) {
					var html = '';
					Data.sibling.forEach(function(_item, _idx) {
						var sibling = $DV.Fun.linktoPerson(_item, 1);
						if (html) {
							html += ' ↔ ' + sibling;
						}
						else {
							html = sibling;
						}
					});
					$('#mine-sibling span.data').html(html);
					$('#mine-sibling').show();
				}
				else {
					$('#mine-sibling').hide();
				}
			}

			this.Table.fill();
			Data.clearUpdate();
			$DE.onPersonUpdate();
			return true;
		},

		// 详情页的个人可扩展表
		Table: {
			Filled: {
				mine: false,
				partner: false,
				parents: false,
				children: false,
				count_up: 0,
				count_down: 0,

				// 清空原数据
				empty: function() {
					$('#tabMine tr.rowdata').remove();
					this.mine = this.partner = this.parents = this.children = false;
					this.count_up = this.count_down = 0;
				}
			},

			// 先只填充自己与配偶行
			fill: function() {
				this.Filled.empty();
				var Data = $DD.Person;
				if (Data.mine) {
					var $tr = $DV.Table.formatRow(Data.mine);
					$tr.addClass('mine');
					$('#tabMine').append($tr);
					this.Filled.mine = true;
				}
				else {
					return false;
				}
				if (Data.partner) {
					var $tr = $DV.Table.formatRow(Data.partner);
					$tr.addClass('mine');
					$('#tabMine').append($tr);
					this.Filled.partner = true;
				}
				return true;
			},

			// 向上填充祖先
			expandUp: function() {
				if (this.Filled.parents) {
					return;
				}
				var that = this;
				var Data = $DD.Person;
				if (Data.parents) {
					var $th = $('#tabMine tr').first();
					Data.parents.forEach(function(_item, _idx) {
						var $tr = $DV.Table.formatRow(_item);
						if (++that.Filled.count_up % 2 == 0) {
							$tr.addClass('even');
						}
						$tr.insertAfter($th);
					});
					that.Filled.parents = true;
					return true;
				}
			},

			// 向下填充后代
			expandDown: function() {
				if (this.Filled.children) {
					return;
				}
				var that = this;
				var Data = $DD.Person;
				if (Data.children) {
					var $table = $('#tabMine');
					Data.children.forEach(function(_item, _idx) {
						var $tr = $DV.Table.formatRow(_item);
						if (++that.Filled.count_down % 2 == 0) {
							$tr.addClass('even');
						}
						$table.append($tr);
					});
					that.Filled.children = true;
					return true;
				}
			},

			LAST_PRETECT: true
		},

		LAST_PRETECT: true
	},

	// 操作表单在某行数据行下展开
	Operate: {
		refid: 0, // 记录上行参照的成员id

		// 关闭所有
		close: function() {
			if (!this.refid) {
				return;
			}
			$('#formOperate').trigger('reset');
			$('#divOperate div.operate-tips').hide();
			$('#formOperate input:radio[name=operate]').parent('label').removeClass('radio-checked');
			$('#oper-error').html('');
			$('a[href=#divOperate]').click();
			this.refid = 0;
		},

		// 单选择发生变化
		// modify append remove 三个单选按钮，只显示相应的 tips
		change: function() {
			$('#divOperate div.operate-tips').hide();
			$('#formOperate input:radio[name=operate]').parent('label').removeClass('radio-checked');
			var op = $('#formOperate input:radio[name=operate]:checked').val();
			if (!op) {
				return;
			}
			// console.log('操作单选发生变化：' + op); // reset 时似乎不会调到
			var tip = '#tip-' + op;
			var radio = '#to-' + op;
			$(tip).show();
			$(radio).parent('label').addClass('radio-checked');
			this.select(op);
		},

		// 选择操作后自动填写部分表单
		select: function(op) {
			this.refid = $DD.Person.curid;
			if (!this.refid) {
				console.log('个人资料获取失败，无法自动填写表单');
				return;
			}
			$('#formOperate input:text').val('');
			if (op == 'modify') {
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
				console.log('已禁删除操作不该至此');
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
				console.log('逻辑错误：没有参考个人信息');
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

				reqData.requery = 1;
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

				reqData.requery = 1;
				req.api = 'create';
				req.data = reqData;
				console.log(req);
				$DV.log(req);
				$DJ.reqAppend(req);
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

	// 帮助页
	Help: {
		pulled: false,
		
		// 显示帮助页
		showdoc: function(res) {
			if (res) {
				console.log('get help doc');
				$('#article').html(res);
				this.pulled = true;
			}
			if (!this.pulled) {
				$DJ.reqHelp();
			}
		},
	},

	log: function(_msg) {
		if (typeof(_msg) == 'object') {
			_msg = JSON.stringify(_msg);
		}
		$('#debug-log').append("<p>" + _msg + "</p>");
	},
	LAST_PRETECT: true
};

