let API_URL = '/dev/family/japi.cgi';
let SEX = ['女♀', '男♂'];
let NULL = '';

// 全局对象
var $DOC = {VIEW:{}, DATA:{}};

function INIT()
{
	$DOC.DATA.mapid = {};

	// 操作表单在某行数据行下展开
	$DOC.VIEW.Operate = {
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

			if (this.refid) {
				$('#divOperate').hide();
				$('#oper-detail').hide();
				$('#tip-modify').hide();
				$('#tip-append').hide();
				$('#tip-remove').hide();
				$('#formOperate input:radio[name=operate]').attr('checked',false);
				$('#formOperate input:radio[name=sex]').attr('checked',false);
				$('#formOperate input:radio[name=operate]').parent('label').removeClass('radio-checked');
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
				var rowdata = $DOC.DATA.members[this.refid];
				if (rowdata.F_father) {
					var father = rowdata.F_father;
					var id = $DOC.DATA.members[father].F_id;
					var name = $DOC.DATA.members[father].F_name;
					var value = id + '/' + name;
					this.lock($('#formOperate input:text[name=father]'), value);
				}
				else {
					this.unlock($('#formOperate input:text[name=father]'));
				}
				if (rowdata.F_mother) {
					var mother = rowdata.F_mother;
					var id = $DOC.DATA.members[mother].F_id;
					var name = $DOC.DATA.members[mother].F_name;
					var value = id + '/' + name;
					this.lock($('#formOperate input:text[name=mother]'), value);
				}
				else {
					this.unlock($('#formOperate input:text[name=mother]'));
				}
				if (rowdata.F_partner) {
					var partner = rowdata.F_partner;
					var id = $DOC.DATA.members[partner].F_id;
					var name = $DOC.DATA.members[partner].F_name;
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

				var rowdata = $DOC.DATA.members[this.refid];
				if (rowdata.F_sex == 1) {
					var value = this.refid + '/' + rowdata.F_name;
					this.lock($('#formOperate input:text[name=father]'), value);
					if (rowdata.F_partner) {
						var mother = rowdata.F_partner;
						var id = $DOC.DATA.members[mother].F_id;
						var name = $DOC.DATA.members[mother].F_name;
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
						var id = $DOC.DATA.members[father].F_id;
						var name = $DOC.DATA.members[father].F_name;
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
		}
	};
}

$(document).ready(function() {
	INIT();
	regEvent();
	loadPage();
});

function regEvent()
{
	$('#to-modify').click(
		function(){
			$DOC.VIEW.Operate.tip('modify');
		}
	);
	$('#to-append').click(
		function(){
			$DOC.VIEW.Operate.tip('append');
		}
	);
	$('#to-remove').click(
		function(){
			$DOC.VIEW.Operate.tip('remove');
		}
	);

	$('#oper-close').click(
		function(){
			$DOC.VIEW.Operate.fold();
		}
	);

	$('#test-toggle').click(
		function(){
			// $DOC.VIEW.Operate.fold();
		}
	);

	// 自动查询折叠链接
	$('div a.fold').click(function(evt) {
		var foldin = $(this).next('div');
		var display = foldin.css('display');
		if (display == 'none') {
			foldin.show();
		}
		else {
			foldin.hide();
		}
		evt.preventDefault();
	});

	$('#remarry').click(function(evt) {
		var $partner = $('#formOperate input:text[name=partner]');
		$DOC.VIEW.Operate.unlock($partner);
		evt.preventDefault();
	});
}

function loadPage()
{
	// var req = {"api":"query","data":{"filter":{"id":10025}}};
	var req = {"api":"query","data":{"all":1}};

	var opt = {
		method: "POST",
		contentType: "application/json",
		dataType: "json",
		data: JSON.stringify(req)
		// data: req // 会发送 api=query& 而不是 json 串
	};

	jqxhr = $.ajax(API_URL, opt)
		.done(resDone)
		.fail(resFail)
		.always(resAlways);
}

function resDone(res)
{
	// $('#debug-log').append("<p>" + res + "</p>");

	// 记录日志
	var str = JSON.stringify(res);
	$('#debug-log').append("<p>" + str + "</p>");

	// 添加表行
	// $('#tabMember').append(formatRow(res.data[0]));
	if (res.error) {
		$('#debug-log').append("<p>" + res.error + "</p>");
	}
	else {
		addtoTable(res.data);
		formatTable();
	}
}

function addtoTable(data)
{
	// 将数组转为 hash, 用 id 索引一行
	$DOC.DATA.members = {};

	for (var i = 0; i < data.length; ++i) {
		var id = data[i].F_id;
		var name = data[i].F_name;
		$DOC.DATA.mapid[id] = name;
		$DOC.DATA.members[id] = data[i];
	}
	for (var i = 0; i < data.length; ++i) {
		$('#tabMember').append(formatRow(data[i]));
	}

	// 添加底部标题行
	if (data.length > 10) {
		var th = `
		<tr id="butTH">
			<th>编号</th>
			<th>姓名</th>
			<th>性别</th>
			<th>代际</th>
			<th>父亲</th>
			<th>母亲</th>
			<th>配偶</th>
			<th>生日</th>
			<th>忌日</th>
		</tr>
		`;
		$('#tabMember').append(th);
	}
}

function formatRow(jrow)
{
	var id = jrow.F_id;
	var name = jrow.F_name;
	var sex = SEX[jrow.F_sex];
	var level = jrow.F_level > 0 ? '+' + jrow.F_level : '' + jrow.F_level;
	var father = jrow.F_father || NULL;
	var mother = jrow.F_mother || NULL;
	var partner = jrow.F_partner || NULL;
	var birthday = jrow.F_birthday || NULL;
	var deathday = jrow.F_deathday || NULL;

	if (father && $DOC.DATA.mapid[father]) {
		father = $DOC.DATA.mapid[father];
	}
	if (mother && $DOC.DATA.mapid[mother]) {
		mother = $DOC.DATA.mapid[mother];
	}
	if (partner && $DOC.DATA.mapid[partner]) {
		partner = $DOC.DATA.mapid[partner];
	}

	var html = '';

	var rid = 'r' + id;
	var aid = `<a id="m${id}" href="#" class="rowid">${id}</a>`;
	html += "<td>" + aid + "</td>\n";
	html += "<td>" + name + "</td>\n";
	html += "<td>" + sex + "</td>\n";
	html += "<td>" + level + "</td>\n";
	html += "<td>" + father + "</td>\n";
	html += "<td>" + mother + "</td>\n";
	html += "<td>" + partner + "</td>\n";
	html += "<td>" + birthday + "</td>\n";
	html += "<td>" + deathday + "</td>\n";

	return `<tr id="${rid}">\n${html}</tr>\n`;
}

function resFail(jqXHR, textStatus)
{
	alert('ajax fails!'  +  jqXHR.status + textStatus);
}

function resAlways()
{
	// alert('ajax finish!');
}

function formatTable()
{
	$("tr").mouseover(function() {
		$(this).addClass("over");
	});

	$("tr").mouseout(function() {
		$(this).removeClass("over");
	});

	$("tr:even").addClass("even");

	/* 排序似乎有无效果
	$("#tabMember").tablesorter({
		sortList:[[3,0]],
		cssAsc: "sortUp",
		cssDesc: "sortDown",
		widgets: ["zebra"]
	});
	*/

	$('td a.rowid').click(function(evt) {
		var row = $(this).parent().parent();
		// var aid = $(this).attr('id');
		$DOC.VIEW.Operate.fold(row);
		evt.preventDefault();
	});
}

/* 笔记
 * 将操作表单移动 $('#divOperate').insertAfter($('#debug-log'))
 * */
