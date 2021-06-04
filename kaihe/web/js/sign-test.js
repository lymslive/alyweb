// 全局对象
var $DOC = {
	TableID: "#maintbl",
	TableSrc: null,
	State_Que: 0,
	State_Dao: 2,
	State_Zhu: 1,
	Sign_Que: "缺",
	Sign_Dao: "到",
	Sign_Zhu: "助",
	Version: '',
	Submitting: false,
	SubmitData: null,

	INIT: function() {
		this.Version = $('#version').html();
		this.GetRooms();
		this.InitForm();
	},

	GetRooms: function() {
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
			$("<td></td>").appendTo($tr)
				.html($DOC.Sign_Que).addClass('que')
				.attr("id", _item.id);
				
			$("<td></td>").append($DOC.SignLink(_item.id)).appendTo($tr);
			$("<td></td>").html(_item.name).appendTo($tr);
			$("<td></td>").html(_item.telephone).appendTo($tr);
		}, this);
	},

	SignLink: function(id) {
		var $a = $("<a></a>").html(id).attr("href", "#" + id);
		$a.addClass("room-id");
		$a.click(function(_evt) {
			_evt.preventDefault();
			var href = $(this).attr('href');
			$DOC.ChangeSign(href);
		});
		return $a;
	},

	ChangeSign: function(id) {
		var $sign = $(id);
		var sold = $sign.html();
		var snew = "";
		if (sold == this.Sign_Que) {
			snew = this.Sign_Dao
			$sign.removeClass('que');
			$sign.addClass('dao');
		}
		else if (sold == this.Sign_Dao) {
			snew = this.Sign_Zhu
			$sign.removeClass('dao');
			$sign.addClass('zhu');
		}
		else {
			snew = this.Sign_Que;
			$sign.removeClass('zhu');
			$sign.addClass('que');
		}
		$sign.html(snew);
	},

	ResetSign: function() {
		if (!this.TableSrc) {
			return false;
		}
		this.TableSrc.forEach(function(_item, _idx) {
			var $sign = $("#" + _item.id);
			var sold = $sign.html();
			if (sold == this.Sign_Zhu) {
				$sign.removeClass('zhu');
			}
			else if (sold == this.Sign_Dao) {
				$sign.removeClass('dao');
			}
			else {
				return;
			}
			$sign.html(this.Sign_Que);
			$sign.addClass('que');
		}, this);
	},

	SaveSign: function() {
		if (!this.TableSrc) {
			return false;
		}

		var sign_array = [];
		this.TableSrc.forEach(function(_item, _idx) {
			var $sign = $("#" + _item.id);
			var sval = $sign.html();
			var ival = this.State_Que;
			if (sval == this.Sign_Zhu) {
				ival = this.State_Zhu;
			}
			else if (sval == this.Sign_Dao) {
				ival = this.State_Dao;
			}
			if (ival != this.State_Que) {
				var signed = {"room": _item.id, "state": ival};
				sign_array.push(signed);
			}
		}, this);

		var date = $('#date').val();
		var shortDesc = $('#short-desc').val();
		var longDesc = $('#long-desc').val();

		var data = {"date": date, "short": shortDesc, "long": longDesc, "signed": sign_array};
		return data;
	},

	InitForm: function() {
		$('#date').val(this.Today());
		$('#reset').click(function(_evt) {
			$DOC.ResetSign();
			$('#date').val(this.Today());
		});
		$('#submit').click(function(_evt) {
			_evt.preventDefault();
			var data = $DOC.SaveSign();
			$DOC.SubmitData = data;
			$('#debug').html(JSON.stringify(data));
		});
	},

	Today: function() {
		var today = new Date();
		var y = today.getFullYear();
		var m = today.getMonth() + 1;
		var d = today.getDate();

		return y + '-' + (m < 10 ? '0' + m : m) + '-' + (d < 10 ? '0' + d : d);
	},
	__LAST__: true
};

$(document).ready(function() {
	$DOC.INIT();
});
