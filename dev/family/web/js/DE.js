// 事件
var $DE = {
	// 折叠功能
	initFold: function() {
		// 切换显示隐藏
		var onClick = function(_evt) {
			var href = $(this).attr('href');
			var foldin = $(href);
			var display = foldin.css('display');
			if (display == 'none') {
				foldin.show();
				$(this).removeClass('foldClose');
				$(this).addClass('foldOpen');

				// 特殊处理显示表单的情况
				// 操作表单自动选择第一个
				if (href == '#divOperate') {
					if ($DD.Person.canOperate()) {
						$('#divOperate div.operate-warn').html('');
						$('#to-modify').click();
					}
					else {
						$('#divOperate div.operate-warn').html($DD.Tip.operaCtrl);
					}
				}
				// 修改简介时，自动载入原简介
				else if (href == '#modify-brief') {
					if ($DD.Person.canOperate()) {
						$('#modify-brief div.operate-warn').html('');
						$('#formBrief textarea').val($DD.Person.brief);
					}
					else {
						$('#modify-brief div.operate-warn').html($DD.Tip.operaCtrl);
					}
				}
				// 修改密码时，自动填入id
				else if (href == '#divPasswd') {
					if ($DD.Person.canOperate('only_self')) {
						$('#divPasswd div.operate-warn').html('');
						$DV.Operate.lock($('#formPasswd input:text[name=mine_id]'), $DD.Login.id);
					}
					else {
						$('#divPasswd div.operate-warn').html($DD.Tip.modifyPasswdOnlySelf);
					}
				}
			}
			else {
				foldin.hide();
				$(this).removeClass('foldOpen');
				$(this).addClass('foldClose');
			}
			_evt.preventDefault();
		};

		// 初始化显隐
		var $open = $('a.foldOpen');
		$open.each(function(_idx, _ele) {
			var href = $(this).attr('href');
			$(href).show();
			$(this).click(onClick);
			$(this).attr('title', '折叠/展开');
		});
		var $close = $('a.foldClose');
		$close.each(function(_idx, _ele) {
			var href = $(this).attr('href');
			$(href).hide();
			$(this).click(onClick);
			$(this).attr('title', '折叠/展开');
		});

		// 登陆表单简单折叠，不必修改链接的样式
		var loginFold = function(_evt) {
			_evt.preventDefault();
			var href = $(this).attr('href');
			var foldin = $(href);
			var display = foldin.css('display');
			if (display == 'none') {
				foldin.show();
				$('#formLogin input:text[name=loginuid]').focus();
				$('#formLogin div.operate-warn').html('');
				return 'show';
			}
			else {
				foldin.hide();
				return 'hide';
			}
		};

		// 显示登陆表单时自己聚焦
		$('#not-login>a.to-login').click(loginFold);
		$('#has-login>a.to-login').click(loginFold);
	},

	// 表单事件
	Form: {
		// 修改表单
		Operate: function() {
			var $form = $('#formOperate');

			$form.find('input:radio[name=operate]').change(function(_evt){
				$DV.Operate.change();
			});

			$('#oper-close').click(function() {
				$DV.Operate.close();
			});

			$form.submit(function(_evt) {
				_evt.preventDefault();
				if (!$DD.Person.canOperate()) {
					return;
				}
				return $DV.Operate.submit(_evt);
			});

			// 强制解锁已自动填充的表单域
			$form.find('a.input-unlock').click({form: $form}, this.unlockInput);
		},

		unlockInput: function(_evt) {
			_evt.preventDefault();
			var $form = _evt.data.form;
			var href = $(this).attr('href');
			var name = href.substring(1);
			var $input = $form.find(`input:text[name=${name}]`);
			$DV.Operate.unlock($input);
		},

		// 过滤表单
		Filter: function() {
			var $form = $('#formFilter');

			$('#filter-rollback').click(function() {
				$DV.Table.Filter.onReset();
			});

			$form.find('input:checkbox[name=filter]').change(function(_evt){
				$DV.Table.Filter.onCheckbox();
			});

			$form.find('select').change(function(_evt){
				$DV.Table.Filter.onSelection();
			});

			// 添加辈份选项
			this.fillLevel($form);
		},

		fillLevel: function($form) {
			var $levelFrom = $form.find('select[name=level-from]');
			var $levelTo = $form.find('select[name=level-to]');
			$DD.LEVEL.forEach(function(_item, _idx) {
				var item = _idx > 0 ? (_idx + ' ' + _item) : _item;
				var html = `<option value="${_idx}">${item}</option>`;
				$levelFrom.append(html);
				$levelTo.append(html);
			});
		},

		// 高级查询表单
		Query: function() {
			// var $form = $('#formQuery');
			var $form = $('#formFilter');
			$form.submit(function(_evt) {
				_evt.preventDefault();
				$DV.Table.Pager.onSubmit();
			});

			$('#table-prev-page').click(function(_evt) {
				_evt.preventDefault();
				$DV.Table.Pager.doPrev();
			});
			$('#table-next-page').click(function(_evt) {
				_evt.preventDefault();
				$DV.Table.Pager.doNext();
			});

		},

		// 登陆表单
		Login: function() {
			var $form = $('#formLogin');
			$form.submit(function(_evt) {
				_evt.preventDefault();
				return $DV.Login.onSubmit();
			});

			$form.find('input[name=close]').click(function(_evt) {
				$('#formLogin').hide();
			});
		},

		// 修改密码表单
		Passwd: function() {
			var $form = $('#formPasswd');
			$form.submit(function(_evt) {
				if (!$DD.Person.canOperate('only_self')) {
					return;
				}
				_evt.preventDefault();
				return $DV.Operate.submitPasswd();
			});

			$form.find('input[name=close]').click(function() {
				$DV.Operate.closePasswd();
			});

			$form.find('a.input-unlock').click({form: $form}, this.unlockInput);
		},

		// 快捷搜索成员表单
		Person: function() {
			$('#formPerson').submit(function(_evt) {
				_evt.preventDefault();
				return $DV.Person.onSearch(_evt);
			});
		},

		// 简介表单
		Brief: function() {
			$('#formBrief').submit(function(_evt) {
				_evt.preventDefault();
				if (!$DD.Person.canOperate()) {
					return;
				}
				return $DV.Operate.submitBrief();
			});
		},

		init: function() {
			this.Operate();
			this.Filter();
			this.Query();
			this.Login();
			this.Passwd();
			this.Person();
			this.Brief();
		},
		LAST_PRETECT: true
	},

	// 加载页面时注册事件
	onLoad: function() {
		// 页签功能
		$('li.page-menu>a').click(function(_evt) {
			var href = $(this).attr('href');
			$DV.Page.see(href);
			_evt.preventDefault();
		});

		this.initFold(); // 定制折叠
		this.Form.init(); // 定制表单

		// 扩展支表
		$('#tabMine-exup>a').click(function(_evt) {
			$DV.Person.Table.expandUp();
			_evt.preventDefault();
		});
		$('#tabMine-exdp>a').click(function(_evt) {
			$DV.Person.Table.expandDown();
			_evt.preventDefault();
		});

	},

	// 个人详情填充完毕注册事件
	onPersonUpdate: function() {
		var that = this;
		$('#member-relation li a.toperson').click(function(_evt) {
			that.gotoPerson($(this));
			_evt.preventDefault();
		});
	},

	// 快速登陆链接 id
	onQuickLogin: function(_evt) {
		$DV.Login.quick($(this).html());
		_evt.preventDefault();
	},

	// 查看详情人名链接
	onSeePerson: function(_evt) {
		$DE.gotoPerson($(this));
		_evt.preventDefault();
	},

	// 根据超链接跳到转指定个人详情
	gotoPerson: function($_emt) {
		var href = $_emt.attr('href');
		var rem = href.match(/#p(\d+)/);
		if (rem) {
			var id = rem[1];
			$DV.Page.checkPerson(id);
		}
	},

	LAST_PRETECT: true
};


