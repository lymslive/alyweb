"use strict";

var $DD = {
	API_URL: '/pub/blog/japi.cgi',
	TITLE: '七阶子博客',
	TOPIC: {
		misc: "随笔杂文",
		game: "游戏娱乐",
		opera: "戏曲戏剧",
		snake: "白蛇研究",
		art: "文学艺术",
		code: "程序生涯",
		recent: "最近文章",
		search: "搜索结果",
		hot: "重点推荐"
	},
	
	// 博客分类
	Topic: {
		hash: {},
		current: '',
		notelist: [],

		doneQuery: function(_resData) {
			this.current = _resData.tag;
			this.notelist = _resData.list;
			if (this.current !== 'recent') {
				this.notelist.reverse();
			}
			this.hash[this.current] = this.notelist;
		},

		tosee: function(_topic) {
			if (this.hash[_topic]) {
				this.current = _topic;
				this.notelist = this.hash[_topic];
				return true;
			}
			else if (_topic === 'search') {
				this.current = _topic;
				this.notelist = [];
				return true;
			}
			else {
				$DJ.reqTopic(_topic);
				return false;
			}
		},

		parseTagline: function(_tagline, _tagArray) {
			var linepart = _tagline.split("\t");
			var noteid = linepart[0];
			var notetitle = linepart[1];
			var notetags = linepart[2];
			var datestr = noteid.split('_')[0];
			var date_str = datestr.substring(0, 4) + '-' + datestr.substring(4, 6) + '-' + datestr.substring(6);
			if (_tagArray) {
				notetags = notetags.substring(1, notetags.length - 1);
				notetags = notetags.split('|');
			}
			return {
				id: noteid,
				title: notetitle,
				date: date_str,
				tags: notetags
			};
		},

		ajacentNote: function(_topic, _id) {
			var list = this.hash[_topic];
			if (!list) {
				return {};
			}
			var ret = {prev: '', next: ''};
			var idx = -1;
			for (var i = 0; i < list.length; ++i) {
				if (list[i].indexOf(_id) == 0) {
					idx = i;
					break;
				}
			}
			if (idx != -1) {
				if (idx > 0) {
					ret.prev = list[idx-1];
				}
				if (idx < list.length - 1) {
					ret.next = list[idx+1];
				}
			}
			return ret;
		},

		LAST_PRETECT: true
	},

	// 博客文章
	Article: {
		hash: {},
		currentId: '',
		hashedCount: 0,

		doneQuery: function(_resData) {
			var note = {};
			note.id = _resData.id;
			note.topic = _resData.topic;
			note.tags = _resData.tags;
			note.title = _resData.title;
			note.date = _resData.date;
			note.url = _resData.url;
			note.author = _resData.author;
			note.content = _resData.content;

			if (!this.hash[note.id]) {
				this.hashedCount += 1;
			}
			this.hash[note.id] = note;
			this.currentId = note.id;
		},

		getArticle: function(_id) {
			var id = _id || this.currentId;
			return this.hash[id];
		},

		tosee: function(_id) {
			if (this.hash[_id]) {
				this.currentId = _id;
				return true;
			}
			else {
				$DJ.reqArticle(_id);
				return false;
			}
		},

		LAST_PRETECT: true
	},

	LAST_PRETECT: true
};

var $DV = {
	PAGE: '',

	Topic: {
		domid: '#blog-list',

		show: function() {
			if ($DV.PAGE !== 'topic') {
				$($DV.Topic.domid).show();
				$($DV.Article.domid).hide();
				$DV.PAGE = 'topic';
				var topic = $DD.TOPIC[$DD.Topic.current];
				if (topic) {
					document.title = $DD.TITLE + '：' + topic;
				}
			}
			return this;
		},

		fillList: function() {
			var data = $DD.Topic;
			if (!data.current) {// || data.notelist.length <= 0
				return this;
			}

			if (data.current === 'search') {
				$('#divSearch').show();
			}
			else {
				$('#divSearch').hide();
			}

			var $ol = $('<ol></ol>');
			for (var i = 0; i < data.notelist.length; ++i) {
				var oTagline = data.parseTagline(data.notelist[i]);
				var $date = $('<span class="list-date"/>').html(oTagline.date + ' ');
				var $link = $('<a/>').attr('href', '#n=' + oTagline.id).html(oTagline.title);
				var $title = $('<span/>').append($link);
				var $li = $('<li/>').append($date).append($title);
				$ol.append($li);
			}

			var $list = $('#note-list');
			$list.children().remove();
			// var $listHead = $('<div id="list-title"/>').html('文章列表：' + $DD.TOPIC[data.current]);
			// $list.append($listHead);
			$list.append($ol);

			this.markTopic(data.current);
			return this;
		},

		tosee: function(_topic) {
			var dTopic = $DD.Topic;
			if (_topic === dTopic.current) {
				return this.show();
			}
			if (dTopic.tosee(_topic)) {
				return this.fillList().show();
			}
		},

		markTopic: function(_topic) {
			var $head = $('#blog-head');
			$head.find('a.topic-now').removeClass('topic-now');
			$head.find(`a[href="#p=${_topic}"]`).addClass('topic-now');
		},

		submit: function() {
			var $form = $('#formSearch');
			var query = $form.find('input[name=q]').val();
			$DJ.reqTopic('search', query);
		},

		LAST_PRETECT: true
	},

	Article: {
		domid: '#blog-article',
		show: function() {
			if ($DV.PAGE !== 'article') {
				$($DV.Topic.domid).hide();
				$($DV.Article.domid).show();
				$DV.PAGE = 'article';
				var article = $DD.Article.getArticle();
				if (article) {
					document.title = $DD.TITLE + '：' + article.title;
				}
			}
			return this;
		},

		tosee: function(_id) {
			if (_id === $DD.Article.currentId) {
				return this.show();
			}
			if ($DD.Article.tosee(_id)) {
				return this.fill().show();
			}
		},

		fill: function() {
			var article = $DD.Article.getArticle();
			if (article) {
				var $blog = $(this.domid);
				var $title = $('<h1/>').html(article.title);
				var $audate = $('<div id="article-audate"/>').html(article.author + ' / ' + article.date);
				var htmd = marked(article.content);
				var $content = $('<div id="article-content"/>').html(htmd);
				$blog.children().remove();
				$blog.append($title).append($audate).append($content);

				if (article.topic && $DD.TOPIC[article.topic]) {
					var topicName = $DD.TOPIC[article.topic];
					var dTopic = $DD.Topic;
					var ajacent = dTopic.ajacentNote(article.topic, article.id);
					var $foot = $('<div id="article-footer"/>');
					var link = `<a href="#p=${article.topic}">${topicName}</a>`;
					var $index = $('<div/>').html('博客栏：' + link);
					var $prev = $('<div/>'), $next = $('<div/>');
					if (ajacent.prev) {
						var oTagline = dTopic.parseTagline(ajacent.prev);
						link = `<a href="#n=${oTagline.id}">${oTagline.title}</a>`;
						$prev.html('前一篇：' + link);
					}
					else {
						$prev.html('前一篇：无');
					}
					if (ajacent.next) {
						var oTagline = dTopic.parseTagline(ajacent.next);
						link = `<a href="#n=${oTagline.id}">${oTagline.title}</a>`;
						$next.html('后一篇：' + link);
					}
					else {
						$next.html('后一篇：无');
					}
					$foot.append($index).append($prev).append($next);
					var $hr = $("<hr>");
					$blog.append($hr).append($foot);
				}
				$blog[0].scrollIntoView(true);
			}
			return this;
		},

		LAST_PRETECT: true
	},

	LAST_PRETECT: true
};

var $DE = {
	linkto: function(_target) {
		var hrefPart = _target.href.split('#');
		if (hrefPart.length < 2) {
			return false
		}
		var href = hrefPart[hrefPart.length - 1];
		if (href.match(/^n-\w+$/)) {
			var noteid = href.substring(2);
			$DV.Article.tosee(noteid);
			return true;
		}
		else if (href.match(/^p-\w+$/)) {
			var topic = href.substring(2);
			$DV.Topic.tosee(topic);
			return true;
		}
		return false;
	},

	onLoad: function() {
		window.addEventListener('hashchange', function (_evt) {
			_evt.preventDefault();
			$DE.hashChange();
		});

		var $form = $('#formSearch');
		$form.submit(function(_evt) {
			_evt.preventDefault();
			return $DV.Topic.submit();
		});

		var $body = $('body');
		$body.click(function(_evt){
			var target = _evt.target;
			if (0 && target.tagName === 'A') {
				if ($DE.linkto(target)) {
					_evt.preventDefault();
				}
			}
		});
	},

	hashChange: function() {
		var hash = location.hash.slice(1);
		if (!hash) {
			return;
		}

		var uri = hash.split('#');
		var search = uri[0], anchor = '';

		if (uri.length > 1) {
			anchor = uri[1];
		}

		if (!search.match(/=/)) {
			anchor = search;
			search = '';
		}

		var params = $FU.paramSplit(search);
		if (params.p) {
			var topic = params.p;
			$DV.Topic.tosee(topic);
		}
		if (params.n) {
			var noteid = params.n;
			$DV.Article.tosee(noteid);
		}

		if (anchor) {
			$('#' + anchor)[0].scrollIntoView(true);
		}

		// history.replaceState('', document.title, '#' + hash);
	},

	LAST_PRETECT: true
};

var $FU = {
	// split key=val&key2=val2
	paramSplit: function(_qstring) {
		if (_qstring < 1) {
			return {};
		}
		var param = _qstring.split('&');
		var res = {};
		for (var i = 0; i < param.length; ++i) {
			var kv = param[i].split('=');
			if (kv.length > 1) {
				res[kv[0]] = kv[1];
			}
			else if (kv.length > 0) {
				res[kv[0]] = true;
			}
		}
		return res;
	},

	hasLog: function() {
		var param = this.paramSplit(location.search.slice(1));
		return param && param['log'];
	},

	LAST_PRETECT: true
};

// ajax 请求
var $DJ = {
	Config: {
		formMsg: 'operate-warn', // 表单操作错误消息区的 div class
		LAST_PRETECT: true
	},

	// 组装请求参数
	reqOption: function(_req) {
		var opt = {
			method: "POST",
			contentType: "application/json",
			dataType: "json",
			data: JSON.stringify(_req)
			// data: req // 会发送 api=query& 而不是 json 串
		};
		return opt;
	},

	// 封装请求服务端 api
	// _req: 为请求 api json 对象
	// _callback: 是成功时回调，可接收参数为(_res.data, _req.data, _res, _req)
	//   大多情况下只要处理返回的实际 data 部分
	// _form 与此请求相关联的 from id , 将自动处理重复提交
	// _msg 在请求返回时在页面给用户的友好提示，包括 .err 与 .suc 两种提示
	requestAPI: function(_req, _callback, _form, _msg) {
		if ($FU.hasLog()) {
			_req.log = 1;
		}
		var opt = this.reqOption(_req);
		$LOG('api req = ' + opt.data);

		var form = _form || 'formNULL';
		var $form = $('#' + form);
		var $msg = $form.find('div.' + $DJ.Config.formMsg);
		var $submit = $form.find('input:submit');

		var ajx = $.ajax($DD.API_URL, opt)
			.done(function(_res, _textStatus, _jqXHR) {
				// api 返回的 res 直接解析为 json
				if (_res.error) {
					$LOG('api err = ' + _res.error + '; errmsg = ' + _res.errmsg);
					if (_form && _msg && _msg.err) {
						$msg.html(_msg.err);
					}
				}
				else {
					if (_form && _msg && _msg.suc) {
						$msg.html(_msg.suc);
					}
					_callback(_res.data, _req.data, _res, _req);
				}
			})
			.fail(function(_jqXHR, _textStatus, _errorThrown) {
				console.log('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
				if (_form) {
					$msg.html('请求服务器失败，可能服务器或网络故障');
				}
			})
			.always(function(_data, _textStatus, _jqXHR) {
				console.log('ajax finish with status: ' + _textStatus);
				if (_data.log) {
					console.log(_data.log);
				}
				if (_form) {
					$submit.removeAttr('disabled');
				}
			});

		// 禁止重复提交表单
		if (_form) {
			$msg.html('正在请求服务器通讯……');
			$submit.attr('disabled', 'disabled');
		}
		return ajx;
	},

	// 拉取分类文章列表
	reqTopic: function(_tag, _input) {
		if (!_tag) {
			return;
		}
		var req = {"api":"topic","data":{"tag":_tag}};
		if (_input) {
			req.data.input = _input;
		}
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DD.Topic.doneQuery(_resData, _reqData);
			$DV.Topic.fillList().show();
		});
	},

	// 请求博客文章
	reqArticle: function(_id) {
		var req = {"api":"article","data":{"id":_id}};
		var topic = $DD.Topic.current;
		if (topic) { // && topic !== 'recent' && topic != 'search'
			req.data.topic = topic;
		}
		this.query = this.requestAPI(req, function(_resData, _reqData) {
			$DD.Article.doneQuery(_resData);
			$DV.Article.fill().show();
		});
	},

	LAST_PRETECT: true
};

// 全局对象
var $DOC = {
	DATA: $DD,
	VIEW: $DV, 
	EVENT: $DE,
	AJAX: $DJ,

	INIT: function() {
		this.EVENT.onLoad();
		// this.VIEW.Page.init();
		if (location.hash) {
			$DE.hashChange();
		}
		else {
			this.AJAX.reqTopic('hot');
		}
	}
};

var $LOG = function(_msg) {
	console.log(_msg);
};

$(document).ready(function() {
	$DOC.INIT();
});

