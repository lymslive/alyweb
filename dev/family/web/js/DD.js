
// 数据
var $DD = {
	// 常量
	API_URL: '/dev/family/japi.cgi',
	HELP_URL: '/dev/family/web/doc/help.htm',
	TAN: '谭',
	LEVEL: ['辈份', '礼', '让', '万', '年', '芳', '和', '积', '祥', '生'],
	SEX: ['性别', '男♂', '女♀'],
	SEX_MALE: 1, SEX_FEMALE: 2,
	NULL: '',
	OPERATE_KEY: 'Tan@2019',
	LOGIN_KEY: '123456',
	ROOT: 10001, // 根祖先

	Tip: {
		operaCtrl: '只有以当前成员或其直系亲属登陆才有修改权限',
		ontLogin: '您没有登陆',
		modifyPasswdOnlySelf: '只能修改自己的密码',
		LAST_PRETECT: 1
	},

	Fun: {
		objcmp: function(_lhs, _rhs) {
			return true;
		}
	},

	getName: function(_id) {
		var row = getRow(_id);
		return row ? row.F_name : '';
	},
	getRow: function(_id) {
		return this.Table.Hash[_id];
	},

	// 从服务器查得的数据表
	Table: {
		Title: ['编号', '姓名', '性别', '辈份', '父亲', '配偶', '生日'],
		Hash: {}, // 尽可能缓存从服务端查询的记录，以 id 为键
		List: [], // 当前页列表

		// 更新 Hash
		hashed: 0,
		saveHash: function(_row) {
			var id = _row.F_id;
			if (!this.Hash[id]) {
				this.Hash[id] = _row;
				this.hashed += 1;
				return _row;
			}
			else {
				var rold = this.Hash[id];
				for (var field in _row){
					if (_row.hasOwnProperty(field) && _row[field] !== rold[field]) {
						rold[field] = _row[field];
					}
				}
				return rold;
			}
		},

		// 分页查询管理
		Pager: {
			Hist: [],   // 分页历史保存
			curidx: 0, // 当前显示第几页
			where: null,  // 当前分页查询条件
			fresh: false, // 开始按新条件查询

			// 服务器返回的统计信息
			total: 0,
			page: 0,
			perpage: 0,
			pagemax: 1,

			saveList: function(_list) {
				if (this.fresh) {
					this.Hist = null;
					this.Hist = [_list];
					this.fresh = false;
				}
				else {
					this.Hist.push(_list);
				}
				this.curidx = this.Hist.length - 1;
			},

			// 下一页，分三种情况返回字符串指示：
			// fill: 前端内存直接可填充
			// qurey: 可向后端异步查询下一页
			// '': 没有更多页了
			next: function() {
				this.curidx += 1;
				if (this.curidx < this.Hist.length) {
					$DD.Table.List = this.Hist[this.curidx];
					return 'fill';
				}
				this.curidx -= 1;

				if (this.page < this.pagemax) {
					this.page += 1;
					return 'query';
				}

				return '';
			},

			// 前一页，返回能否切到之前查过的前一页
			prev: function() {
				if (this.curidx > 0) {
					this.curidx -= 1;
					$DD.Table.List = this.Hist[this.curidx];
					return true;
				}
				return false;
			},

			LAST_PRETECT: true
		},

		// 重新加载从服务端返回的一页数据
		load: function(_resData) {
			this.List = _resData.records;
			for (var i = 0; i < this.List.length; ++i) {
				var saved = this.saveHash(this.List[i]);
				if (saved && this.List[i] !== saved) {
					this.List[i] = saved;
				}

				// 设置顶级祖先为详情页默认查看对象
				if (this.List[i].F_level == 1) {
					$DD.ROOT = this.List[i].F_id;
				}
			}

			this.Pager.page = _resData.page;
			this.Pager.perpage = _resData.perpage;
			if (_resData.page <= 1) {
				this.Pager.total = _resData.total;
				this.Pager.pagemax = Math.ceil(this.Pager.total/this.Pager.perpage);
			}

			// 保存页历史
			this.Pager.saveList(this.List);
		},

		// 更新服务器数据回调，包含修改自己与增加子女
		modify: function(_resData, _reqData) {
			if (_resData.modified) {
				if (!_resData.id || !_reqData.id || _resData.id != _reqData.id) {
					console.log('修改资料请求响应数据不对');
					return;
				}
			}

			var id = _resData.id;
			var mine = _resData.mine;
			if (mine) {
				this.store(mine);
			}
			else {
				console.log('逻辑错误：没有返回自己的信息');
				return;
			}

			// 更新页面表
			if (mine) {
				$DV.Table.updateRow(mine);
			}

			// 更新个人详情页的小表
			if ($DD.Person.curid == id) {
				$DD.Person.fromServer({
					"id": id,
					"mine": mine,
				});
				$DV.Person.update();
			}
			else if ($DD.Person.curid == mine.F_father) {
				$DD.Person.fromServer({
					"id": $DD.Person.curid,
					"children": [mine]
				});
				$DV.Person.update();
				$DV.Person.Table.expandDown();
			}

			// 重置未锁定的输入域
			$DV.Operate.resetNolock();
		},

		// 增量修改或存储一行数据
		store: function(_row) {
			var id = _row.F_id;
			if (!id) {
				console.log('数据行不存在 id?');
				return;
			}
			var saved = this.saveHash(_row);

			var bFound = false;
			for (var i = 0; i < this.List.length; ++i) {
				if (this.List[i].F_id == id) {
					if (saved && this.List[i] !== saved) {
						this.List[i] = saved;
					}
					bFound = true;
					break;
				}
			}
			if (!bFound) {
				this.List.push(_row);
			}
		},

		// 在前端内存中查看名字是否有对应 id
		getIdByName: function(name) {
			for (var id in this.Hash){
				if (this.Hash.hasOwnProperty(id) && this.Hash[id].F_name === name) {
					return id;
				}
			}
			return 0;
		},

		LAST_PRETECT: 0
	},

	// 要查看的个人详情
	Person: {
		curid: 0,
		mine: null,
		children: null,
		parents: null,
		sibling: null,
		brief: '',

		// 更新码
		update: 0,
		MINE: 1,
		// PARTNER: 1<<1,
		CHILDREN: 1<<2,
		PARENTS: 1<<3,
		SIBLING: 1<<4,
		BRIEF: 1<<5,

		markUpdate: function(_bit) {
			this.update |= _bit;
		},
		canUpdate: function(_bit) {
			return this.update & _bit;
		},
		clearUpdate: function() {
			this.update = 0;
		},

		reset: function(_id) {
			this.mine = null;
			this.children = null;
			this.parents = null;
			this.sibling = null;
			this.brief = '';
			this.clearUpdate();
		},

		// 先从前端表中查找
		lookinTable: function(_id) {
			if (_id != this.curid && this.curid) {
				this.reset(_id);
			}
			this.curid = _id;

			// 自己
			if ($DD.Table.Hash[_id]) {
				this.mine = $DD.Table.Hash[_id];
				this.markUpdate(this.MINE);
			}
			var mine = this.mine;
			if (!mine) {
				return this.update;
			}

			// 子女
			var children = [];
			var _fid, _frow;
			for (_fid in $DD.Table.Hash){
				if ($DD.Table.Hash.hasOwnProperty(_fid)) {
					_frow = $DD.Table.Hash[_fid];
					if (mine.F_sex == 1 && _frow.F_father == mine.F_id) {
						children.push(_frow);
					}
				}
			}
			if (children.length > 0) {
				this.children = children;
				this.markUpdate(this.CHILDREN);
			}

			// 先辈
			var parents = [];
			var row = mine;
			while (row) {
				var father_id = row.F_father;
				var parent_one = null;
				if ($DD.Table.Hash[father_id]) {
					parent_one = $DD.Table.Hash[father_id];
				}
				if (parent_one) {
					parents.push(parent_one);
					row = parent_one;
				}
				else {
					row = null;
					break;
				}
			}
			if (parents.length > 0) {
				this.parents = parents;
				this.markUpdate(this.PARENTS);
			}

			// 兄弟
			if (parents.length > 0) {
				var parent_one = parents[0];
				var sibling = [];
				for (_fid in $DD.Table.Hash){
					if ($DD.Table.Hash.hasOwnProperty(_fid)) {
						_frow = $DD.Table.Hash[_fid];
						if (parent_one.F_sex == 1 && _frow.F_father == parent_one.F_id && _frow.F_id != mine.F_id) {
							sibling.push(_frow);
						}
					}
				}
				if (sibling.length > 0) {
					this.sibling = sibling;
					this.markUpdate(this.SIBLING);
				}
			}

			// 简介
			if (mine.F_text) {
				this.brief = mine.F_text;
				this.markUpdate(this.BRIEF);
			}
			else {
				// 直接请求查询简介了
				$DJ.reqBrief({api: 'query_brief',
					data: {id: _id},
				});
			}

			return this.update;
		},

		// 获得未在本地表中查得的数据关系，需要向服务端查询
		notinTable: function() {
			return {
				mine: this.canUpdate(this.MINE) ? 0 : 1,
				children: this.canUpdate(this.CHILDREN) ? 0 : 1,
				parents: this.canUpdate(this.PARENTS) ? 0 : -1,
				sibling: this.canUpdate(this.SIBLING) ? 0 : 1,
				brief: this.canUpdate(this.BRIEF) ? 0 : 1,
			};
		},

		// 强制从服务端返回数据刷新
		fromServer: function(_resData) {
			if (this.curid != _resData.id) {
				return 0;
			}
			if (_resData.mine) {
				this.mine = _resData.mine;
				this.markUpdate(this.MINE);
			}
			if (_resData.children) {
				if (!this.children) {
					this.children = _resData.children;
				}
				else {
					var that = this;
					_resData.children.forEach(function(_item, _idx) {
						if (!$DD.Person.isChild(_item.F_id)) {
							that.children.push(_item);
						}
					});
				}
				this.markUpdate(this.CHILDREN);
			}
			if (_resData.parents) {
				this.parents = _resData.parents;
				this.markUpdate(this.PARENTS);
			}
			if (_resData.sibling) {
				this.sibling = _resData.sibling;
				this.markUpdate(this.SIBLING);
			}
			return this.update;
		},

		// 查询和修改简介成功回调
		onBriefRes: function(_resData, _reqData) {
			var id = _resData.F_id;
			var text = _resData.F_text;
			var affected = _resData.affected;

			if (!text && affected) {
				console.log('修改简介返回');
				text = _reqData.text;
			}

			if (text) {
				var row = $DD.Table.Hash[id];
				if (row) {
					row.F_text = text;
				}
				if (this.curid == id) {
					this.brief = text;
					this.markUpdate(this.BRIEF);
					$DV.Person.update();
					$DV.Operate.closeBrief(true);
				}
			}
			else {
				console.log('查询简介失败，可能不存在');
			}
		},

		// 检查是否有修改权限
		canOperate: function(_only_self) {
			var person = this.curid;
			var user = $DD.Login.id;
			if (!user || !person) {
				return false;
			}
			if (user == person) {
				return true;
			}
			if (_only_self) {
				return false;
			}
			if (this.isParent(user)) {
				return true;
			}
			if (this.isChild(user)) {
				return true;
			}
			return false;
		},

		// 检查是否直接父母
		isParent: function(_user) {
			if (this.parents && this.parents[0] && this.parents[0].F_id == _user) {
				return true;
			}
			return false;
		},

		// 检查是否其中一个孩子
		isChild: function(_user) {
			if (this.children) {
				for (var i = 0; i < this.children.length; ++i) {
					if (this.children[i].F_id == _user) {
						return true;
					}
				}
			}
			return false;
		},

		// 检查是否其中一个孩子
		hasChildName: function(_name) {
			if (this.children) {
				for (var i = 0; i < this.children.length; ++i) {
					if (this.children[i].F_name == _name) {
						return true;
					}
				}
			}
			return false;
		},

		LAST_PRETECT: true
	},

	// 登陆信息
	Login: {
		id: 0,
		token: '',
		loginKey: '',
		operaKey: '',

		// 登陆成功回调
		callback: function(_resData, _reqData) {
			this.id = _resData.id;
			this.token = _resData.token;
			$DD.Table.Hash[this.id] = _resData.mine;
			$DV.Login.onSucc();
		},

		// 打包会话信息，用于其他 api 请求
		reqSess: function(_key) {
			var key = _key || this.operaKey;
			return {
				id: this.id,
				token: this.token,
				opera_key: key
			};
		},

		// 修改密码回调
		onModifyPasswd: function(_resData, _reqData) {
			if (_resData.id == this.id) {
				if (_reqData.keytype == 'loginkey') {
					this.loginKey = _reqData.newkey;
				}
				else if (_reqData.keytype == 'operakey') {
					this.operaKey = _reqData.newkey;
				}
				else {
					console.log('密码类型不对');
				}
			}
			$('#formPasswd').trigger('reset');
		},

		_: 1
	},

	LAST_PRETECT: true
};

