
// 数据
var $DD = {
	// 常量
	API_URL: '/pri/bill/japi.cgi',
	NULL: '',

	Tip: {
		operaCtrl: '只有以当前成员或其直系亲属登陆才有修改权限',
		ontLogin: '您没有登陆',
		modifyPasswdOnlySelf: '只能修改自己的密码',
		LAST_PRETECT: 1
	},

	Fun: {
		// 判断第一个 obj 是否全被包含在第二个 obj
		objin: function(_lhs, _rhs) {
			for (var f in _lhs) {
				if (_lhs.hasOwnProperty(f)) {
					if (!_rhs[f] || _rhs[f] != _lhs[f]) {
						return false;
					}
				}
			}
			return true;
		}
	},

	getRow: function(_id) {
		return this.Table.Hash[_id];
	},

	typeName: function(_type) {
		if (_type == 1) {
			return '收入';
		}
		else if (_type == -1) {
			return '支出';
		}
		else {
			console.log('错误的收支类类型');
			return '';
		}
	},

	subTypeName: function(_type) {
		if (_type > 0) {
			return this.Table.TypeIN[_type];
		}
		else if (_type < 0) {
			return this.Table.TypeOUT[Math.abs(_type)];
		}
		else {
			console.log('错误的收支类类型');
			return '';
		}
	},

	// 从服务器查得的数据表
	Table: {
		Title: ['流水', '日期', '时间', '收支', '类别', '金额', '目标', '地点', '备注'],
		Hash: {}, // 尽可能缓存从服务端查询的记录，以 id 为键
		List: [], // 当前页列表
		TypeIN: ['收入'], // 收入类别
		TypeOUT: ['支出'], // 支出类别

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

		// 完成查询类别配置
		doneConfig: function(_resData, _reqData) {
			var records = _resData.records;
			for (var i = 0; i < records.length; ++i) {
				var re = records[i];
				if (re.F_subtype > 0) {
					this.TypeIN[re.F_subtype] = re.F_typename;
				}
				else if (re.F_subtype < 0) {
					this.TypeOUT[-re.F_subtype] = re.F_typename;
				}
			}
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

		LAST_PRETECT: true
	},

	LAST_PRETECT: true
};

