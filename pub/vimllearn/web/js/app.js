"use strict";

var $DD = {
	BOOK_ROOT: '/book/vimllearn',
	BOOK_TOC: 'content.md',
	BOOK_DIR: 'z',
	BOOK_NAME: '《VimL 语言编程指北路》',
	
	Book: {
		current: '',
		page: {},
		torder: [],
		toc: '',

		init: function() {
			this.reBookName = new RegExp('^\\s*#\\s*' + $DD.BOOK_NAME);
			this.reTagLine = new RegExp('`.*`\\s*\\n');
		},

		gotToc: function(_mdString) {
			var md = _mdString.replace(/z\/(\d+_\d+\.md)/g, '#/$1');
			md = md.replace(this.reBookName, '# ');
			this.toc = md;
			var lines = md.split("\n");
			var regNote = /#\/(\d+_\d+)\.md/;
			var match;
			for (var i = 0; i < lines.length; ++i) {
				if ((match = regNote.exec(lines[i])) !== null) {
					var noteid = match[1];
					this.torder.push(noteid);
				}
			}
			$DE.sawToc();
		},

		gotPage: function(_id, _mdString) {
			if (_id && _mdString) {
				var md = _mdString.replace(this.reBookName, '# ');
				md = md.replace(this.reTagLine, '');
				this.page[_id] = md;
				this.current = _id;
			}
		},

		adjPage: function(_id) {
			var np = {};
			for (var i = 0; i < this.torder.length; ++i) {
				if (this.torder[i] === _id) {
					if (i > 0) {
						np.prev = this.torder[i-1];
					}
					if (i < this.torder.length - 1) {
						np.next = this.torder[i+1];
					}
					break;
				}
			}
			return np;
		},

		seePage: function(_id) {
			this.current = _id;
		},

		LAST_PRETECT: true
	},

	LAST_PRETECT: true
};

var $DV = {

	Book: {
		seePage: function(_id) {
			var dBook = $DD.Book;
			if (_id !== dBook.current) {
				if (dBook.page[_id]) {
					dBook.seePage(_id);
					this.fillPage();
				}
				else {
					$DJ.reqPage(_id);
				}
			}
			return this;
		},

		fillPage: function() {
			var dBook = $DD.Book;
			var id = dBook.current;
			if (id && dBook.page[id]) {
				var md = marked(dBook.page[id]);
				$('#page-body').html(md);
				this.markPage(id);

				$('#page-foot').children().remove();
				var adj = dBook.adjPage(id);
				var html = '';
				if (adj && adj.prev) {
					html = `<a href="#/${adj.prev}.md">上一页</a><br/>`;
				}
				if (adj && adj.next) {
					html += `<a href="#/${adj.next}.md">下一页</a>`;
				}
				$('#page-foot').html(html);
			}
			return this;
		},

		fillToc: function() {
			if ($DD.Book.toc) {
				var md = marked($DD.Book.toc);
				$('#book-toc').html(md);
			}
			return this;
		},
		
		markPage: function(_id) {
			var $toc = $('#book-toc');
			$toc.find('a.page-now').removeClass('page-now');
			$toc.find(`a[href="#/${_id}.md"]`).addClass('page-now');
		},

		LAST_PRETECT: true
	},

	LAST_PRETECT: true
};

var $DE = {

	onLoad: function() {
		window.addEventListener('hashchange', function (_evt) {
			_evt.preventDefault();
			$DE.hashChange();
		});
	},

	hashChange: function() {
		var hash = location.hash.slice(1);
		if (!hash) {
			return;
		}

		var uri = hash.split('#');
		var page = uri[0], anchor = '';

		if (uri.length > 1) {
			anchor = uri[1];
		}

		var noteid = '';
		if (page[0] === '/') {
			page = page.slice(1);
			noteid = page.replace(/\.md$/, '');
			$DV.Book.seePage(noteid);
			$('#book-page')[0].scrollIntoView(true);
		}

		if (anchor) {
			$('#' + anchor)[0].scrollIntoView(true);
		}

		// history.replaceState('', document.title, '#' + hash);
	},

	sawToc: function() {
		if (location.hash) {
			$DE.hashChange();
		}
		else if ($DD.Book.torder[0]) {
			$DJ.reqPage($DD.Book.torder[0]);
		}
	},

	LAST_PRETECT: true
};

// ajax 请求
var $DJ = {

	// 请求目录页
	reqToc: function() {
		var url = $DD.BOOK_ROOT + '/' + $DD.BOOK_TOC;
		this.reqFile(url, function(_resData) {
			$DD.Book.gotToc(_resData);
			$DV.Book.fillToc();
		});
	},

	// 请求博客文章
	reqPage: function(_id) {
		var url = $DD.BOOK_ROOT + '/' + $DD.BOOK_DIR + '/' + _id + '.md';
		this.reqFile(url, function(_resData) {
			$DD.Book.gotPage(_id, _resData);
			$DV.Book.fillPage();
		});
	},

	// 请求文档
	reqFile: function(_url, _callback) {
		console.log("reqFile: " + _url);
		var ajx = $.get(_url)
			.done(function(_res, _textStatus, _jqXHR) {
				_callback(_res);
			})
			.fail(function(_jqXHR, _textStatus, _errorThrown) {
				console.log('从服务器获取数据失败'  +  _jqXHR.status + _textStatus);
				if (_form) {
					$msg.html('请求服务器失败，可能服务器或网络故障');
				}
			});
		this.doc = ajx;
		return ajx;
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
		this.DATA.Book.init();
		this.EVENT.onLoad();
		// this.VIEW.Page.init();
		this.AJAX.reqToc();
	}
};

$(document).ready(function() {
	$DOC.INIT();
});

