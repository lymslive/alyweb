
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

		// 重新加载全表数据
		load: function(resData) {
			this.List = resData;
			this.Hash = {};
			for (var i = 0; i < resData.length; ++i) {
				var id = resData[i].F_id;
				var name = resData[i].F_name;
				$DD.Mapid[id] = name;
				this.Hash[id] = resData[i];
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

