
// 数据
var $DD = {
	// 常量
	API_URL: '/dev/family/japi.cgi',
	SEX: ['女♀', '男♂'],
	NULL: '',

	Mapid: {},
	getName: function(id) {
		return this.Mapid[id];
	},
	getRow: function(id) {
		return this.Table.Hash[id];
	},

	Table: {
		Title: ['编号', '姓名', '性别', '代际', '父亲', '母亲', '配偶', '生日', '忌日'],
		List: [],
		Hash: {},

		// 服务器返回的统计信息
		total: 0,
		page: 0,
		perpage: 0,
		may_more: false,

		// 重新加载全表数据
		load: function(resData) {
			this.List = resData.records;
			this.Hash = {};
			for (var i = 0; i < this.List.length; ++i) {
				var id = this.List[i].F_id;
				var name = this.List[i].F_name;
				$DD.Mapid[id] = name;
				this.Hash[id] = this.List[i];
			}

			this.total = resData.total;
			this.page = resData.page;
			this.perpage = resData.perpage;
			if (this.total > this.perpage && this.total > (this.page-1) * this.perpage + this.List.length) {
				this.may_more = true;
			}
		},

		modify: function(_resData, _reqData) {
			var id = _reqData.id;
			var jold = $DD.getRow(id);
			if (_reqData.name) {
				jold.F_name = _reqData.name;
			}
			if (_reqData.sex) {
				jold.F_sex = _reqData.sex;
			}
			if (_reqData.father_id) {
				jold.F_father = _reqData.father_id;
			}
			else if (_reqData.father_name) {
				return;
			}
		},

		LAST_PRETECT: 0
	},

	// 要查看的个人详情
	Person: {
		DEFAULT: 10001,
		curid: 0,
		mine: null,
		partner: null,
		children: null,
		parents: null,
		sibling: null,
		brief: '',

		// 更新码
		update: 0,
		MINE: 1,
		PARTNER: 1<<1,
		CHILDREN: 1<<2,
		PARENTS: 1<<3,
		SIBLING: 1<<4,

		markUpdate: function(_bit) {
			this.update |= _bit;
		},
		canUpdate: function(_bit) {
			return this.update & _bit;
		},
		clearUpdate() {
			this.update = 0;
		},

		reset: function(_id) {
			this.mine = null;
			this.partner = null;
			this.children = null;
			this.parents = null;
			this.sibling = null;
			this.clearUpdate();
		},

		// 先从前端表中查找
		lookinTable: function(_id) {
			if (_id != this.curid && this.curid) {
				this.reset(_id);
			}
			this.curid = _id;
			if ($DD.Table.List.length < 1) {
				return this.update;
			}

			// 自己
			if ($DD.Table.Hash[_id]) {
				this.mine = $DD.Table.Hash[_id];
				this.markUpdate(this.MINE);
			}
			var mine = this.mine;
			if (!mine) {
				return this.update;
			}

			// 配偶
			var partner_id = this.mine.F_partner;
			if ($DD.Table.Hash[partner_id]) {
				this.partner = $DD.Table.Hash[partner_id];
				this.markUpdate(this.PARTNER);
			}

			// 子女
			var children = [];
			$DD.Table.List.forEach(function(_item, _idx) {
				if (mine.F_sex == 1 && _item.F_father == mine.F_id) {
					children.push(_item);
				}
				else if (mine.F_sex == 0 && _item.F_mother == mine.F_id) {
					children.push(_item);
				}
			});
			if (children.length > 0) {
				this.children = children;
				this.markUpdate(this.CHILDREN);
			}

			// 先辈
			var parents = [];
			var row = mine;
			while (row) {
				var father_id = row.F_father;
				var mother_id = row.F_mother;
				var parent_one = null;
				if ($DD.Table.Hash[father_id] && $DD.Table.Hash[father_id].F_level > 0) {
					parent_one = $DD.Table.Hash[father_id];
				}
				else if ($DD.Table.Hash[mother_id] && $DD.Table.Hash[mother_id].F_level > 0) {
					parent_one = $DD.Table.Hash[mother_id];
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
				$DD.Table.List.forEach(function(_item, _idx) {
					if (parent_one.F_sex == 1 && _item.F_father == parent_one.F_id && _item.F_id != mine.F_id) {
						sibling.push(_item);
					}
					else if (parent_one.F_sex == 0 && _item.F_mother == parent_one.F_id && _item.F_id != mine.F_id) {
						sibling.push(_item);
					}
				});
				if (sibling.length > 0) {
					this.sibling = sibling;
					this.markUpdate(this.SIBLING);
				}
			}

			return this.update;
		},

		// 获得未在本地表中查得的数据关系，需要向服务端查询
		notinTable: function() {
			return {
				mine: this.canUpdate(this.MINE) ? 0 : 1,
				partner: this.canUpdate(this.PARTNER) ? 0 : 1,
				children: this.canUpdate(this.CHILDREN) ? 0 : 1,
				parents: this.canUpdate(this.PARENTS) ? 0 : -1,
				sibling: this.canUpdate(this.SIBLING) ? 0 : 1,
			};
		},

		// 从服务端返回数据
		foundinServer: function(_resData) {
			if (this.curid != _resData.id) {
				return 0;
			}
			var bUpdate = 0;
			if (_resData.mine && !this.mine) {
				this.mine = _resData.mine;
				bUpdate++;
			}
			if (_resData.partner && !this.partner) {
				this.partner = _resData.partner;
				bUpdate++;
			}
			if (_resData.children
				&& (!this.children || this.children.length < _resData.children.length)) {
				this.children = _resData.children;
				bUpdate++;
			}
			if (_resData.parents
				&& (!this.parents || this.parents.length < _resData.parents.length)) {
				this.parents = _resData.parents;
				bUpdate++;
			}
			if (_resData.sibling
				&& (!this.sibling || this.sibling.length < _resData.sibling.length)) {
				this.sibling = _resData.sibling;
				bUpdate++;
			}
			return bUpdate;
		},

		// 强制从服务端返回数据刷新
		forceinServer: function(_resData) {
			if (this.curid != _resData.id) {
				return 0;
			}
			var bUpdate = 0;
			if (_resData.mine) {
				this.mine = _resData.mine;
				bUpdate++;
			}
			if (_resData.partner) {
				this.partner = _resData.partner;
				bUpdate++;
			}
			if (_resData.children) {
				this.children = _resData.children;
				bUpdate++;
			}
			if (_resData.parents) {
				this.parents = _resData.parents;
				bUpdate++;
			}
			if (_resData.sibling) {
				this.sibling = _resData.sibling;
				bUpdate++;
			}
			return bUpdate;
		},

		LAST_PRETECT: true
	},

	LAST_PRETECT: true
};

