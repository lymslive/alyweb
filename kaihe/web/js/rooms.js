// 全局对象
var $DOC = {
	TableID: "#maintbl",
	TableSrc: null,

	INIT: function() {
		var url = 'rooms.json';
		var opt = {
			method: "get",
			contentType: "application/json",
			dataType: "json",
		};
		var ajx = $.ajax(url, opt)
			.done(function(_res, _textStatus, _jqXHR) {
				if (_res.error) {
					console.log('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
				}
				else {
					$DOC.Tablefy(_res);
				}
			})
			.fail(function(_jqXHR, _textStatus, _errorThrown) {
				console.log('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
			})
			.always(function(_data, _textStatus, _jqXHR) {
				console.log('ajax finish with status: ' + _textStatus);
			});
	},

	Tablefy: function(res) {
		this.TableSrc = res;
		var $table = $(this.TableID);
		res.forEach(function(_item, _idx) {
			var $tr = $("<tr></tr>").appendTo($table);
			$("<td></td>").html(_item.id).appendTo($tr);
			$("<td></td>").html(_item.name).appendTo($tr);
			$("<td></td>").html(_item.telephone).appendTo($tr);
		}, this);
	}
};

$(document).ready(function() {
	$DOC.INIT();
});
