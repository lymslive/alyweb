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
	},

	// 加载页面时注册事件
	onLoad: function() {
		// 页签功能
		$('li.page-menu>a').click(function(_evt) {
			var href = $(this).attr('href');
			$DV.Page.see(href);
			_evt.preventDefault();
		});

		// 折叠链接功能
		this.initFold();

		// 修改表单事件
		$('#formOperate input:radio[name=operate]').change(function(_evt){
			$DV.Operate.change();
		});

		$('#oper-close').click(function() {
			$DV.Operate.close();
			// $('a[href=#divOperate]').click();
		});

		$('#formOperate').submit(function(_evt) {
			_evt.preventDefault();
			return $DV.Operate.submit(_evt);
		});

		$('#test-toggle').click(function() {
			// $DOC.VIEW.Operate.fold();
		});

		$('#remarry').click(function(_evt) {
			var $partner = $('#formOperate input:text[name=partner]');
			$DV.Operate.unlock($partner);
			_evt.preventDefault();
		});
	},

	// 填充完表格注册事件
	onFillTable: function() {
		$("tr").mouseover(function() {
			$(this).addClass("over");
		});

		$("tr").mouseout(function() {
			$(this).removeClass("over");
		});

		$("tr:even").addClass("even");

		$('td a.rowid').click(function(_evt) {
			_evt.preventDefault();
		});

		$('#tabSumary').show();
		$('#table-prev-page').click(function(_evt) {
			_evt.preventDefault();
		});
		$('#table-next-page').click(function(_evt) {
			_evt.preventDefault();
		});

	},

	onModifyRow: function() {
		if ($DV.Operate.refid) {
			$DV.Operate.fold(0);
		}
	},

	LAST_PRETECT: true
};


