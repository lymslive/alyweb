let API_URL = 'http://lymslive.top/family/japi.cgi';

$(document).ready(function() {
	loadPage();
});

function loadPage()
{
	var req = {"api":"query","data":{"filter":{"id":10025}}};

	var opt = {
		method: "POST",
		contentType: "application/json",
		data: req,
		dataType: "json"
	};

	var jqxhr = $.ajax(API_URL, opt)
		.done(resDone)
		.fail(resFail)
		.always(resAlways);
}

function resDone(res)
{
	// 记录日志
	var str = JSON.stringify(res);
	$('#debug-log').append("<p>" + str + "</p>");

	// 添加表行
	$('$tabMember').append(formatRow(res.data[0]));
}

function formatRow(jrow)
{
	var html = '';
	html .= "<td>" + jrow.F_id + "</td>\n";
	html .= "<td>" + jrow.F_name + "</td>\n";
	html .= "<td>" + jrow.F_sex + "</td>\n";
	html .= "<td>" + jrow.F_level + "</td>\n";
	html .= "<td>" + jrow.F_father + "</td>\n";
	html .= "<td>" + jrow.F_mother + "</td>\n";
	html .= "<td>" + jrow.F_partner + "</td>\n";
	html .= "<td>" + jrow.F_birthday + "</td>\n";
	html .= "<td>" + jrow.F_deathday + "</td>\n";
	return "<tr>\n" + html + "</tr>\n";
}

function resFail(data)
{
	alert('ajax fails!');
}

function resAlways()
{
	alert('ajax finish!');
}
