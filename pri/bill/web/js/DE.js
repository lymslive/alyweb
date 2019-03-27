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

			$form.find('input:radio[name=type]').change(function(_evt){
				$DV.Operate.onRadio(_evt);
			});

			$form.submit(function(_evt) {
				_evt.preventDefault();
				if (!$DD.Person.canOperate()) {
					return;
				}
				return $DV.Operate.submit(_evt);
			});

		},

		// 过滤表单
		Filter: function() {
			var $form = $('#formFilter');

			$('#filter-rollback').click(function() {
				$DV.Table.Filter.onReset();
			});

			// 表单上统一处理变动事件
			$form.change(function(_evt){
				$DV.Table.Filter.onChange(_evt);
			});

			// 添加最近月份 select option
			var $month = $form.find('select[name=month]');
			for (var i = 1; i <= 12; ++i) {
				var html = `<option value="${i}">最近${i}月</option>`;
				$month.append(html);
			}

			$form.submit(function(_evt) {
				_evt.preventDefault();
				$DV.Table.Filter.onSubmit();
			});

			$('#table-prev-page').click(function(_evt) {
				_evt.preventDefault();
				$DV.Table.Filter.doPrev();
			});
			$('#table-next-page').click(function(_evt) {
				_evt.preventDefault();
				$DV.Table.Filter.doNext();
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

		init: function() {
			this.Operate();
			this.Filter();
			this.Login();
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

	},

	LAST_PRETECT: true
};


