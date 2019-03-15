// 来自 json 作者的书例代码：js 精粹

// 创建对象
if (typeof Object.beget !== 'function') {
	Object.create = function(o) {
		var F = function() {};
		F.prototype = o;
		return new F();
	};
}

// 添加方法
Function.prototype.method = function(name, func) {
	this.prototype[name] = func;
	return this;
};

// 函数里化，绑定参数
Function.method('curry', function() {
	var slice = Array.prototype.slice,
		args = slice.apply(arguments),
		that = this;
	return function () {
		return that.apply(null, args.concat(slice.apply(arguments)));
	};
});

// 记忆化递归优化公式计算
// 可用于计算斐波那契数据与阶乘
var memoizer = function(memo, formula) {
	var recur = function(n) {
		var result = memo[n];
		if (typeof result !== 'number') {
			result = formula(recur, n);
			memo[n] = result;
		}
	};
	return recur;
};

// 获取父类方法
Object.method('superior', function(name) {
	var that = this,
		method = that[name];
	return function() {
		return method.apply(that, arguments);
	};
});
