
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

	LAST_PRETECT: true
};

