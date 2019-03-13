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
				// 特殊处理，表单自动选择第一个
				if (href == '#divOperate') {
					$('#to-modify').click();
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

		// 扩展支表
		$('#tabMine-exup>a').click(function(_evt) {
			$DV.Person.Table.expandUp();
			_evt.preventDefault();
		});
		$('#tabMine-exdp>a').click(function(_evt) {
			$DV.Person.Table.expandDown();
			_evt.preventDefault();
		});

		// 修改表单事件
		$('#formOperate input:radio[name=operate]').change(function(_evt){
			$DV.Operate.change();
		});

		$('#oper-close').click(function() {
			$DV.Operate.close();
		});

		$('#formOperate').submit(function(_evt) {
			_evt.preventDefault();
			return $DV.Operate.submit(_evt);
		});

		// 强制解锁已自动填充的表单域
		$('#formOperate a.input-unlock').click(function(_evt) {
			var href = $(this).attr('href');
			var name = href.substring(1);
			var $input = $(`#formOperate input:text[name=${name}]`);
			$DV.Operate.unlock($input);
			_evt.preventDefault();
		});

		// 快捷搜索成员表单
		$('#formPerson').submit(function(_evt) {
			_evt.preventDefault();
			return $DV.Person.onSearch(_evt);
		});

		// 过滤表单
		$('#formFilter').submit(function(_evt) {
			_evt.preventDefault();
			$DV.Table.Filter.onSubmit();
			return false;
		});

		$('#filter-rollback').click(function() {
			$DV.Table.Filter.onReset();
		});

		$('#formFilter input:checkbox[name=filter]').change(function(_evt){
			$DV.Table.Filter.onCheckbox();
		});

		$('#formFilter select').change(function(_evt){
			$DV.Table.Filter.onSelection();
		});

		// 添加辈份选项
		var $levelFrom = $('#formFilter select[name=level-from]');
		var $levelTo = $('#formFilter select[name=level-to]');
		$DD.LEVEL.forEach(function(_item, _idx) {
			var html = `<option value="${_idx}">${_item}</option>`;
			$levelFrom.append(html);
			$levelTo.append(html);
		});

		// 登陆表单
		$('#formLogin').submit(function(_evt) {
			_evt.preventDefault();
			$DV.Login.onSubmit();
			return false;
		});

	},

	// 填充完表格注册事件
	onFillTable: function() {
		var that = this;

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

		/*
		$("tr").mouseover(function() {
			$(this).addClass("over");
		});
		$("tr").mouseout(function() {
			$(this).removeClass("over");
		});
		$("tr:even").addClass("even");
		$('#tabMember td a.toperson').click(function(_evt) {
			that.gotoPerson($(this));
			_evt.preventDefault();
		});
		*/
	},

	// 个人详情填充完毕注册事件
	onPersonUpdate: function() {
		var that = this;
		$('#member-relation li a.toperson').click(function(_evt) {
			that.gotoPerson($(this));
			_evt.preventDefault();
		});
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

	onModifyRow: function() {
	},

	LAST_PRETECT: true
};


