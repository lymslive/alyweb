// 事件
var $DE = {
	// 加载页面时注册事件
	onLoad: function() {
		$('li.page-menu>a').click(function(_evt) {
			var href = $(this).attr('href');
			if ($DV.Page.see(href)) {
				$('li.page-menu').removeClass('curr-page');
				$(this).parent().addClass('curr-page');
			}
			_evt.preventDefault();
		});

		$('#to-modify').click(function() {
			$DV.Operate.tip('modify');
		});
		$('#to-append').click(function() {
			$DV.Operate.tip('append');
		});
		$('#to-remove').click( function() {
			$DV.Operate.tip('remove');
		});

		$('#oper-close').click(function() {
			$DV.Operate.fold(0);
		});

		$('#formOperate').submit(function(_evt) {
			_evt.preventDefault();
			return $DV.Operate.submit(_evt);
		});

		$('#test-toggle').click(function() {
			// $DOC.VIEW.Operate.fold();
		});

		// 自动查询折叠链接
		$('div a.fold').click(function(_evt) {
			var foldin = $(this).next('div');
			var display = foldin.css('display');
			if (display == 'none') {
				foldin.show();
			}
			else {
				foldin.hide();
			}
			_evt.preventDefault();
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
			var $row = $(this).parent().parent();
			// var aid = $(this).attr('id');
			$DV.Operate.fold($row);
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


