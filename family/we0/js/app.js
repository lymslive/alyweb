var $DD = {
API_URL: '/family/japi.cgi',
HELP_URL: '/family/web/doc/help.htm',
TAN: '谭',
LEVEL: ['辈份', '年', '芳', '和', '积', '祥', '生'],
SEX: ['女♀', '男♂'],
NULL: '',
OPERATE_KEY: 'Tan@2019',
LOGIN_KEY: '123456',
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
Mapid: {},
getName: function(id) {
return this.Mapid[id];
},
getRow: function(id) {
return this.Table.Hash[id];
},
Table: {
Title: ['编号', '姓名', '性别', '代际', '父亲', '母亲', '配偶', '生日', '忌日'],
Hash: {},
List: [],
Pager: {
Hist: [],
curidx: 0,
where: null,
fresh: false,
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
load: function(_resData) {
this.List = _resData.records;
for (var i = 0; i < this.List.length; ++i) {
var id = this.List[i].F_id;
var name = this.List[i].F_name;
$DD.Mapid[id] = name;
this.Hash[id] = this.List[i];
if (this.List[i].F_level == 1) {
$DD.Person.DEFAULT = id;
}
}
this.Pager.page = _resData.page;
this.Pager.perpage = _resData.perpage;
if (_resData.page <= 1) {
this.Pager.total = _resData.total;
this.Pager.pagemax = Math.ceil(this.Pager.total/this.Pager.perpage);
}
this.Pager.saveList(this.List);
},
modify: function(_resData, _reqData) {
if (_resData.modified) {
if (!_resData.id || !_reqData.id || _resData.id != _reqData.id) {
console.log('请求响应数据不对');
return;
}
}
var id = _resData.id;
var partner_id = _resData.partner_id;
var mine, partner;
_resData.records.forEach(function(_item, _idx) {
if (_item.F_id == id) {
mine = _item;
}
else if (partner_id && partner_id == _item.F_id) {
partner = _item;
}
});
if (partner) {
this.store(partner);
}
if (mine) {
this.store(mine);
}
else {
console.log('逻辑错误：没有返回自己的信息');
return;
}
if (partner) {
$DV.Table.updateRow(partner);
}
if (mine) {
$DV.Table.updateRow(mine);
}
if ($DD.Person.curid == id) {
$DD.Person.fromServer({
"id": id,
"mine": mine,
"partner": partner
});
$DV.Person.update();
}
else if ($DD.Person.curid == mine.F_father || $DD.Person.curid == mine.F_mother) {
$DD.Person.fromServer({
"id": $DD.Person.curid,
"children": mine
});
$DV.Person.update();
$DV.Person.Table.expandDown();
}
$DV.Operate.resetNolock();
},
store: function(_row) {
var id = _row.F_id;
if (!id) {
console.log('数据行不存在 id?');
return;
}
this.Hash[id] = _row;
if (_row.F_name) {
$DD.Mapid[id] = _row.F_name;
}
if (_row.F_level < 0) {
console.log('旁系配偶只内部保存，不列出：' + id + _row.F_name);
return;
}
var bFound = false;
for (var i = 0; i < this.List.length; ++i) {
if (this.List[i].F_id == id) {
this.List[i] = _row;
bFound = true;
break;
}
}
if (!bFound) {
this.List.push(_row);
}
},
storePartner: function(_resData, _reqData) {
var that = this;
console.log('将保存配偶信息：' + _resData.records.length);
_resData.records.forEach(function(_item, _idx) {
var id = _item.F_id;
var name = _item.F_name;
$DD.Mapid[id] = name;
that.Hash[id] = _item;
});
if ($DD.Person.curid && $DD.Person.mine) {
var partner_id = $DD.Person.mine.F_partner;
if (this.Hash[partner_id]) {
var partner = this.Hash[partner_id];
if (partner != $DD.Person.partner) {
$DD.Person.fromServer({
"id": $DD.Person.curid,
"partner": parnter
});
$DV.Person.update();
}
}
}
},
getIdByName: function(name) {
var id;
for (id in this.Hash){
if (this.Hash.hasOwnProperty(id) && this.Hash[id].F_name == name) {
return id;
}
}
},
LAST_PRETECT: 0
},
Person: {
DEFAULT: 10001,
curid: 0,
mine: null,
partner: null,
children: null,
parents: null,
sibling: null,
brief: '',
update: 0,
MINE: 1,
PARTNER: 1<<1,
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
this.partner = null;
this.children = null;
this.parents = null;
this.sibling = null;
this.brief = '';
this.clearUpdate();
},
lookinTable: function(_id) {
if (_id != this.curid && this.curid) {
this.reset(_id);
}
this.curid = _id;
if ($DD.Table.Hash[_id]) {
this.mine = $DD.Table.Hash[_id];
this.markUpdate(this.MINE);
}
var mine = this.mine;
if (!mine) {
return this.update;
}
var partner_id = this.mine.F_partner;
if ($DD.Table.Hash[partner_id]) {
this.partner = $DD.Table.Hash[partner_id];
this.markUpdate(this.PARTNER);
}
var children = [];
var _fid, _frow;
for (_fid in $DD.Table.Hash){
if ($DD.Table.Hash.hasOwnProperty(_fid)) {
_frow = $DD.Table.Hash[_fid];
if (mine.F_sex == 1 && _frow.F_father == mine.F_id) {
children.push(_frow);
}
else if (mine.F_sex == 0 && _frow.F_mother == mine.F_id) {
children.push(_frow);
}
}
}
if (children.length > 0) {
this.children = children;
this.markUpdate(this.CHILDREN);
}
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
if (parents.length > 0) {
var parent_one = parents[0];
var sibling = [];
for (_fid in $DD.Table.Hash){
if ($DD.Table.Hash.hasOwnProperty(_fid)) {
_frow = $DD.Table.Hash[_fid];
if (parent_one.F_sex == 1 && _frow.F_father == parent_one.F_id && _frow.F_id != mine.F_id) {
sibling.push(_frow);
}
else if (parent_one.F_sex == 0 && _frow.F_mother == parent_one.F_id && _frow.F_id != mine.F_id) {
sibling.push(_frow);
}
}
}
if (sibling.length > 0) {
this.sibling = sibling;
this.markUpdate(this.SIBLING);
}
}
if (mine.F_text) {
this.brief = mine.F_text;
this.markUpdate(this.BRIEF);
}
else {
$DJ.reqBrief({api: 'query_brief',
data: {id: _id},
});
}
return this.update;
},
notinTable: function() {
return {
mine: this.canUpdate(this.MINE) ? 0 : 1,
partner: this.canUpdate(this.PARTNER) ? 0 : 1,
children: this.canUpdate(this.CHILDREN) ? 0 : 1,
parents: this.canUpdate(this.PARENTS) ? 0 : -1,
sibling: this.canUpdate(this.SIBLING) ? 0 : 1,
brief: this.canUpdate(this.BRIEF) ? 0 : 1,
};
},
fromServer: function(_resData) {
if (this.curid != _resData.id) {
return 0;
}
if (_resData.mine) {
this.mine = _resData.mine;
this.markUpdate(this.MINE);
}
if (_resData.partner) {
this.partner = _resData.partner;
this.markUpdate(this.PARTNER);
}
if (_resData.children) {
this.children = _resData.children;
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
if (this.isPartner(user)) {
return true;
}
return false;
},
isParent: function(_user) {
if (this.parents && this.parents[0] && this.parents[0].F_id == _user) {
return true;
}
return false;
},
isPartner: function(_user) {
if (this.partner && this.partner.F_id == _user) {
return true;
}
return false;
},
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
Login: {
id: 0,
token: '',
loginKey: '',
operaKey: '',
callback: function(_resData, _reqData) {
this.id = _resData.id;
this.token = _resData.token;
$DD.Table.Hash[this.id] = _resData.mine;
$DV.Login.onSucc();
},
reqSess: function(_key) {
var key = _key || this.operaKey;
return {
id: this.id,
token: this.token,
opera_key: key
};
},
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
var $DV = {
Fun: {
linktoPerson: function(_row, _suffix) {
var id = _row.F_id;
var name = _row.F_name;
var sex = _row.F_sex;
if (_suffix && sex < 2) {
name += $DD.SEX[sex].substring(1);
}
var html = `<a href="#p${id}" title="${id}" class="toperson">${name}</a>`;
return html;
},
linktoPid: function(_id) {
var name = _id;
var title = _id;
var css = 'toperson';
if ($DD.Mapid[_id]) {
name = $DD.Mapid[_id];
}
else {
title = '点击查找姓名';
css += ' qname';
}
var html = `<a href="#p${_id}" title="${title}" class="${css}">${name}</a>`;
return html;
},
jumpLink: function(_sid) {
location.href = _sid;
},
quickLoginLink: function(_id) {
var html = `<a href="#" class="quicklogin" title="点击用此id登陆">${_id}</a>`;
return html;
}
},
Page: {
curid: '',
init: function() {
var $curMenu = $('#menu-bar>ul>li').first();
$curMenu.addClass('curr-page');
var curid = $curMenu.find('>a').attr('href');
if (curid) {
this.see(curid);
}
},
see: function(_toid, _hasperson){
if (this.curid == _toid) {
return false;
}
$('div.page').hide();
$(_toid).show();
this.curid = _toid;
$('#menu-bar li.page-menu').each(function() {
if ($(this).find('a').attr('href') == _toid) {
$(this).addClass('curr-page');
}
else {
$(this).removeClass('curr-page');
}
});
if (_toid == '#pg2-person' && !_hasperson) {
if ($DD.Login.id) {
this.checkPerson($DD.Login.id);
}
else if (!$DD.Person.curid) {
this.checkPerson($DD.Person.DEFAULT);
}
}
else if (_toid == '#pg3-help') {
$DV.Help.showdoc();
}
return true;
},
checkPerson: function(_id) {
if (this.curid != '#pg2-person') {
this.see('#pg2-person', true);
}
return $DV.Person.checkout(_id);
},
LAST_PRETECT: true
},
Table: {
domid: '#tabMember',
rows: 0,
rowcss: 'rowdata',
but_limit: 10,
butid: 'butTH',
htd: function(content) {
return $('<td></td>').append(content);
},
htr: function(tds,rid) {
var tr = $('<tr></tr>').attr('id', rid);
for (var i=0; i < tds.length; i++) {
tr.append(tds[i]);
}
return tr;
},
hth: function(rid) {
var $tr = $("<tr></tr>\n");
if (rid) {
$tr.attr('id', rid);
}
else {
$tr.attr('id', this.butid);
}
var title = $DD.Table.Title;
for (var i=0; i<title.length; i++) {
var $th = $("<th></th>\n").html(title[i]);
$tr.append($th);
}
return $tr;
},
empty: function() {
if (this.rows <= 0) {
return;
}
console.log('将清空表格数据行：' + this.rows);
$(this.domid).find('.' + this.rowcss).remove();
$('#' + this.butid).remove();
this.rows = 0;
},
fill: function() {
var data = $DD.Table.List;
if (data.length <= 0) {
return;
}
if (this.rows) {
this.empty();
}
console.log('将填充表格数据行：' + data.length);
for (var i=0; i<data.length; i++) {
if (!this.Filter.checkTan(data[i])) {
continue;
}
if (!this.Filter.checkMan(data[i])) {
continue;
}
if (!this.Filter.checkLevel(data[i])) {
continue;
}
var $tr = this.formatRow(data[i]);
this.rows++;
if (this.rows % 2 == 0) {
$tr.addClass("even");
}
$(this.domid).append($tr);
}
if (this.rows > this.but_limit) {
$(this.domid).append(this.hth());
}
var Pager = $DD.Table.Pager;
var sumary = [Pager.curidx+1, Pager.pagemax, Pager.total];
$('#tabSumary span.data').each(function(_idx, _ele) {
$(this).html(sumary[_idx]);
});
},
formatRow: function(jrow) {
var id = jrow.F_id;
var name = jrow.F_name;
var sex = $DD.SEX[jrow.F_sex];
var level = jrow.F_level > 0 ? '+' + jrow.F_level : '' + jrow.F_level;
var father = jrow.F_father || $DD.NULL;
var mother = jrow.F_mother || $DD.NULL;
var partner = jrow.F_partner || $DD.NULL;
var birthday = jrow.F_birthday || $DD.NULL;
var deathday = jrow.F_deathday || $DD.NULL;
var html = '';
var $tr = $("<tr></tr>\n")
.attr('id', 'r' + id)
.attr('class', this.rowcss)
;
var $td = $("<td></td>\n");
var $link = $($DV.Fun.quickLoginLink(id))
.appendTo($td);
$tr.append($td);
name = $DV.Fun.linktoPerson(jrow);
$td = $('<td></td>').html(name);
$tr.append($td);
$td = $('<td></td>').html(sex);
$tr.append($td);
$td = $('<td></td>').html(level);
$tr.append($td);
if (father) {
if ($DD.Table.Hash[father]) {
father = $DV.Fun.linktoPerson($DD.Table.Hash[father]);
}
else {
father = $DV.Fun.linktoPid(father);
}
}
$td = $('<td></td>').html(father);
$tr.append($td);
if (mother) {
if ($DD.Table.Hash[mother]) {
mother = $DV.Fun.linktoPerson($DD.Table.Hash[mother]);
}
else {
mother = $DV.Fun.linktoPid(mother);
}
}
$td = $('<td></td>').html(mother);
$tr.append($td);
if (partner) {
if ($DD.Table.Hash[partner]) {
partner = $DV.Fun.linktoPerson($DD.Table.Hash[partner]);
}
else {
partner = $DV.Fun.linktoPid(partner);
}
}
$td = $('<td></td>').html(partner);
$tr.append($td);
$td = $('<td></td>').html(birthday);
$tr.append($td);
$td = $('<td></td>').html(deathday);
$tr.append($td);
$tr.find('td a.toperson').click(function(_evt) {
$DE.gotoPerson($(this));
_evt.preventDefault();
});
$tr.find('td a.quicklogin').click($DE.onQuickLogin);
$tr.mouseover(function() {
$(this).addClass("over");
});
$tr.mouseout(function() {
$(this).removeClass("over");
});
return $tr;
},
updateRow: function(_row) {
var id = _row.F_id;
var rid = '#r' + id;
var $old = $(rid);
var $tr = this.formatRow(_row);
if ($old.length > 0) {
if ($old.hasClass('even')) {
$tr.addClass('even');
}
$old.replaceWith($tr);
}
else {
this.rows++;
if (this.rows % 2 == 0) {
$tr.addClass("even");
}
$(this.domid).append($tr);
}
},
updateName: function() {
$('td a.qname').each(function(_idx, _element) {
var id = $(this).html();
var name = $DD.Mapid[id];
if (name) {
$(this).html(name).attr('title', id);
}
});
},
Filter: {
tan: false,
man: false,
levelFrom: 0,
levelTo: 0,
onCheckbox: function() {
var $checkbox = $('#formFilter input:checkbox[name=filter]');
this.tan = $checkbox[0].checked;
this.man = $checkbox[1].checked;
$DV.Table.fill();
this.showCount(true);
},
onSelection: function() {
var $levelFrom = $('#formFilter select[name=level-from]');
var $levelTo = $('#formFilter select[name=level-to]');
this.levelFrom = parseInt($levelFrom.val());
this.levelTo = parseInt($levelTo.val());
$DV.Table.fill();
this.showCount(true);
},
showCount: function(_filtered) {
if (!_filtered) {
$('#formFilter div.operate-warn').html('');
}
else {
var msg = '当前页筛选：' + $DV.Table.rows + '/' + $DD.Table.List.length + '成员';
$('#formFilter div.operate-warn').html(msg);
}
},
checkTan: function(_row) {
return !this.tan || (_row.F_name && _row.F_name.indexOf($DD.TAN) == 0);
},
checkMan: function(_row) {
return !this.man || _row.F_sex == 1;
},
checkLevel: function(_row) {
if (!this.levelFrom && !this.levelTo) {
return true;
}
if (this.levelFrom && !this.levelTo) {
return this.levelFrom == _row.F_level;
}
if (!this.levelFrom && this.levelTo) {
return this.levelTo == _row.F_level;
}
return (_row.F_level - this.levelFrom) * (_row.F_level - this.levelTo) <= 0;
},
onReset: function() {
if (this.tan || this.man || this.levelFrom || this.levelTo) {
this.tan = this.man = false;
this.levelFrom = this.levelTo = 0;
$DV.Table.fill();
this.showCount(false);
$('#formFilter').trigger('reset');
}
},
onSubmit: function() {
}
},
Pager: {
onSubmit: function() {
var $form = $('#formQuery');
var where = {};
var id = $form.find('input:text[name=id]').val();
if (id) {
where.id = id;
}
var name  = $form.find('input:text[name=name]').val();
if (name) {
where.name = name;
}
var sex = $form.find('select[name=sex]').val();
if (sex) {
where.sex = parseInt(sex);
}
var $levelFrom = $form.find('select[name=level-from]');
var $levelTo = $form.find('select[name=level-to]');
var levelFrom = parseInt($levelFrom.val());
var levelTo = parseInt($levelTo.val());
if (levelFrom && !levelTo) {
where.level = levelFrom;
}
else if (!levelFrom && levelTo) {
where.level = levelTo;
}
else if (levelFrom && levelTo) {
if (levelFrom < levelTo) {
where.level = {'-between': [levelFrom, levelTo]};
}
else if (levelFrom > levelTo) {
where.level = {'-between': [levelTo, levelFrom]};
}
else {
where.level = levelFrom;
}
}
var birthdayFrom  = $form.find('input[name=birthday-from]').val();
var birthdayTo  = $form.find('input[name=birthday-to]').val();
if (birthdayFrom && !birthdayTo) {
where.birthday = {'>=': birthdayFrom};
}
else if (!birthdayFrom && birthdayTo) {
where.birthday = {'<=': birthdayTo};
}
else if (birthdayFrom && birthdayTo) {
where.birthday = {'-between': [birthdayFrom, birthdayTo]};
}
if (!where.birthday) {
var ageTo = $form.find('input:text[name=age-to]').val();
var ageFrom = $form.find('input:text[name=age-from]').val();
ageTo = parseInt(ageTo);
ageFrom = parseInt(ageFrom);
if (ageFrom && ageTo) {
where.age = [ageFrom, ageTo];
}
else if (!ageFrom && ageTo) {
where.age = ageTo;
}
else if (ageFrom && !ageTo) {
where.age = [ageFrom, 100];
}
}
var that = $DD.Table.Pager;
that.where = where;
that.fresh = true;
var page  = $form.find('input[name=page]').val();
page = parseInt(page);
if (page) {
that.page = page;
}
var perpage  = $form.find('input[name=perpage]').val();
perpage = parseInt(perpage);
if (perpage) {
that.perpage = perpage;
}
return this.doQuery();
},
doQuery: function() {
var that = $DD.Table.Pager;
var req = {api: 'query'};
req.data = {page: that.page, perpage: that.perpage};
if (that.where && Object.keys(that.where).length > 0) {
req.data.filter = that.where;
}
else {
req.data.all = 1;
}
return $DJ.reqQuery(req);
},
doneQuery: function(_resData) {
$DD.Table.load(_resData);
$DV.Table.fill();
location.href='#pg1-table';
},
doNext: function() {
var flag = $DD.Table.Pager.next();
if (!flag) {
return;
}
if (flag == 'fill') {
return $DV.Table.fill();
}
if (flag == 'query') {
return this.doQuery();
}
},
doPrev: function() {
if ($DD.Table.Pager.prev()) {
$DV.Table.fill();
}
},
onCheckbox: function(_checkbox) {
var val = _checkbox.value;
if (val == 'tan') {
if (_checkbox.checked) {
$('#formQuery input:text[name=name]').val($DD.TAN + '%');
}
else {
$('#formQuery input:text[name=name]').val('');
}
}
else if (val == 'partner') {
}
},
LAST_PRETECT: true
},
LAST_PRETECT: true
},
Person: {
onSearch: function() {
$('#formPerson span.operate-warn').html('');
var idname = $('#formPerson input[name=mine]').val();
var id = parseInt(idname);
if (isNaN(id)) {
var idInHash = $DD.Table.getIdByName(idname);
if (idInHash) {
id = idInHash;
}
}
if (id && $DD.Table.Hash[id]) {
this.checkout(id);
}
else {
var msg = '查找失败，请检查编号或姓名是否正确';
$('#formPerson span.operate-warn').html(msg);
}
},
checkout: function(_id) {
var Data = $DD.Person;
if (Data.curid == _id) {
return false;
}
$DV.Operate.close();
if ($('#modify-brief').css('display') != 'none') {
$('a[href=#modify-brief]').click();
}
Data.lookinTable(_id);
var lackoff = $DD.Person.notinTable();
this.update(true);
},
update: function(_force) {
var Data = $DD.Person;
if (!Data.update && !_force) {
console.log('没有标记更新');
return false;
}
if (!Data.mine) {
console.log('缺少个人基本数据');
return false;
}
if (_force || Data.canUpdate(Data.MINE)) {
var id = Data.mine.F_id;
var name = Data.mine.F_name;
var sex = Data.mine.F_sex;
var level = Data.mine.F_level;
if (sex < 2) {
name += $DD.SEX[sex].substring(1);
}
if (level > 0) {
level = '第 +' + level + ' 代直系';
}
else {
level = '第 ' + level + ' 代旁系';
}
var idLink = $DV.Fun.quickLoginLink(id);
var text = idLink + ' | ' + name + ' | ' + level;
$('#mine-info').html(text)
.find('a.quicklogin').click($DE.onQuickLogin);
if (Data.mine.F_birthday) {
var text = '';
var birthDate = new Date(Data.mine.F_birthday); 
if (Data.mine.F_deathday) {
var deathDate = new Date(Data.mine.F_deathday); 
var life = deathDate.getFullYear() - birthDate.getFullYear() + 1;
text = Data.mine.F_birthday + ' ~ ' + Data.mine.F_deathday + '（' + life + '寿）';
}
else {
var nowDate = new Date(); 
var age = nowDate.getFullYear() - birthDate.getFullYear() + 1;
text = Data.mine.F_birthday + ' ~ ?' + '（' + age + '岁）';
}
$('#mine-dates span.data').html(text);
$('#mine-dates').show();
}
else {
$('#mine-dates').hide();
}
}
if (_force || Data.canUpdate(Data.PARTNER)) {
if (Data.mine.F_partner && Data.partner) {
var html = $DV.Fun.linktoPerson(Data.partner, 1);
$('#mine-partner span.data').html(html);
$('#mine-partner').show();
}
else {
$('#mine-partner').hide();
$('#mine-children').hide();
}
}
if (_force || Data.canUpdate(Data.CHILDREN)) {
if (Data.children && Data.children.length > 0) {
var html = '';
Data.children.forEach(function(_item, _idx) {
var child = $DV.Fun.linktoPerson(_item, 1);
if (html) {
html += ' ↔ ' + child;
}
else {
html = child;
}
});
$('#mine-children span.data').html(html);
$('#mine-children').show();
}
else {
$('#mine-children').hide();
}
}
if (_force || Data.canUpdate(Data.PARENTS)) {
if (Data.mine.F_level > 1 && Data.parents) {
var html = '';
Data.parents.forEach(function(_item, _idx) {
var parent_one = $DV.Fun.linktoPerson(_item, 1);
if (html) {
html += ' ➜ ' + parent_one;
}
else {
html = parent_one;
}
});
$('#mine-parents span.data').html(html);
}
else if (Data.mine.F_level == 1) {
var text = '己是入库的始祖了，有需要请联系管理员升级！';
$('#mine-parents span.data').html(text);
}
else if (Data.mine.F_level < 0) {
var text = '旁系配偶不入库！';
$('#mine-parents span.data').html(text);
}
}
if (_force || Data.canUpdate(Data.SIBLING)) {
if (Data.mine.F_level > 1 && Data.sibling && Data.sibling.length > 0) {
var html = '';
Data.sibling.forEach(function(_item, _idx) {
var sibling = $DV.Fun.linktoPerson(_item, 1);
if (html) {
html += ' ↔ ' + sibling;
}
else {
html = sibling;
}
});
$('#mine-sibling span.data').html(html);
$('#mine-sibling').show();
}
else {
$('#mine-sibling').hide();
}
}
if (_force || Data.canUpdate(Data.BRIEF)) {
$('#member-brief>p').first().html(Data.brief);
}
this.Table.fill();
Data.clearUpdate();
$DE.onPersonUpdate();
return true;
},
Table: {
Filled: {
mine: false,
partner: false,
parents: false,
children: false,
count_up: 0,
count_down: 0,
empty: function() {
$('#tabMine tr.rowdata').remove();
this.mine = this.partner = this.parents = this.children = false;
this.count_up = this.count_down = 0;
}
},
fill: function() {
this.Filled.empty();
var Data = $DD.Person;
if (Data.mine) {
var $tr = $DV.Table.formatRow(Data.mine);
$tr.addClass('mine');
$('#tabMine').append($tr);
this.Filled.mine = true;
}
else {
return false;
}
if (Data.partner) {
var $tr = $DV.Table.formatRow(Data.partner);
$tr.addClass('mine');
$('#tabMine').append($tr);
this.Filled.partner = true;
}
return true;
},
expandUp: function() {
if (this.Filled.parents) {
return;
}
var that = this;
var Data = $DD.Person;
if (Data.parents) {
var $th = $('#tabMine tr').first();
Data.parents.forEach(function(_item, _idx) {
var $tr = $DV.Table.formatRow(_item);
if (++that.Filled.count_up % 2 == 0) {
$tr.addClass('even');
}
$tr.insertAfter($th);
});
that.Filled.parents = true;
return true;
}
},
expandDown: function() {
if (this.Filled.children) {
return;
}
var that = this;
var Data = $DD.Person;
if (Data.children) {
var $table = $('#tabMine');
Data.children.forEach(function(_item, _idx) {
var $tr = $DV.Table.formatRow(_item);
if (++that.Filled.count_down % 2 == 0) {
$tr.addClass('even');
}
$table.append($tr);
});
that.Filled.children = true;
return true;
}
},
LAST_PRETECT: true
},
LAST_PRETECT: true
},
Operate: {
refid: 0,
close: function() {
if ($('#divOperate').css('display') == 'none') {
return;
}
$('#formOperate').trigger('reset');
$('#divOperate div.operate-tips').hide();
$('#formOperate input:radio[name=operate]').parent('label').removeClass('radio-checked');
$('#formOperate div.operate-warn').html('');
$('a[href=#divOperate]').click();
this.refid = 0;
},
change: function() {
$('#divOperate div.operate-tips').hide();
$('#formOperate input:radio[name=operate]').parent('label').removeClass('radio-checked');
var op = $('#formOperate input:radio[name=operate]:checked').val();
if (!op) {
return;
}
var tip = '#tip-' + op;
var radio = '#to-' + op;
$(tip).show();
$(radio).parent('label').addClass('radio-checked');
this.select(op);
},
select: function(op) {
this.refid = $DD.Person.curid;
if (!this.refid) {
console.log('个人资料获取失败，无法自动填写表单');
return;
}
$('#formOperate input:text').val('');
if (op == 'modify') {
this.lock($('#formOperate input:text[name=mine_id]'), this.refid);
var rowdata = $DD.getRow(this.refid);
if (rowdata.F_father) {
var father = rowdata.F_father;
var id = $DD.getRow(father).F_id;
var name = $DD.getRow(father).F_name;
var value = id + '/' + name;
this.lock($('#formOperate input:text[name=father]'), value);
}
else {
this.unlock($('#formOperate input:text[name=father]'));
}
if (rowdata.F_mother) {
var mother = rowdata.F_mother;
var id = $DD.getRow(mother).F_id;
var name = $DD.getRow(mother).F_name;
var value = id + '/' + name;
this.lock($('#formOperate input:text[name=mother]'), value);
}
else {
this.unlock($('#formOperate input:text[name=mother]'));
}
if (rowdata.F_partner) {
var partner = rowdata.F_partner;
var id = $DD.getRow(partner).F_id;
var name = $DD.getRow(partner).F_name;
var value = id + '/' + name;
this.lock($('#formOperate input:text[name=partner]'), value);
}
else {
this.unlock($('#formOperate input:text[name=partner]'));
}
}
else if(op == 'append') {
this.lock($('#formOperate input:text[name=mine_id]'), '');
var rowdata = $DD.getRow(this.refid);
if (rowdata.F_sex == 1) {
var value = this.refid + '/' + rowdata.F_name;
this.lock($('#formOperate input:text[name=father]'), value);
if (rowdata.F_partner) {
var mother = rowdata.F_partner;
var id = $DD.getRow(mother).F_id;
var name = $DD.getRow(mother).F_name;
var value = id + '/' + name;
this.lock($('#formOperate input:text[name=mother]'), value);
}
else {
this.unlock($('#formOperate input:text[name=mother]'));
}
}
else if (rowdata.F_sex == 0) {
var value = this.refid + '/' + rowdata.F_name;
this.lock($('#formOperate input:text[name=mother]'), value);
if (rowdata.F_partner) {
var father = rowdata.F_partner;
var id = $DD.getRow(father).F_id;
var name = $DD.getRow(father).F_name;
var value = id + '/' + name;
this.lock($('#formOperate input:text[name=father]'), value);
}
else {
this.unlock($('#formOperate input:text[name=father]'));
}
}
else {
console.log('男1女0，错误性别：' + rowdata.F_sex);
}
this.unlock($('#formOperate input:text[name=partner]'));
} 
else if(op == 'remove') {
console.log('已禁删除操作不该至此');
}
else {
console.log('未定义操作');
}
},
lock: function($input, value) {
$input.val(value);
$input.attr('readonly', true);
$input.addClass('input-lock');
},
unlock: function($input) {
$input.attr('readonly', false);
$input.removeClass('input-lock');
},
resetNolock: function() {
$('#formOperate input:text').each(function(_idx, _ele) {
if (!$(this).attr('readonly')) {
$(this).val('')
}
});
$('#formOperate input[type=date]').val('');
},
submit: function(evt) {
if (!this.refid) {
console.log('逻辑错误：没有参考个人信息');
return false;
}
var $form = $('#formOperate');
var op = $form.find('input:radio[name=operate]:checked').val();
var operkey = $form.find('input[name=operkey]').val();
var mine_id = $form.find('input[name=mine_id]').val();
var mine_name = $form.find('input[name=mine_name]').val();
var sex = $form.find('input:radio[name=sex]:checked').val();
var father = $form.find('input[name=father]').val();
var mother = $form.find('input[name=mother]').val();
var partner = $form.find('input[name=partner]').val();
var birthday = $form.find('input[name=birthday]').val();
var deathday = $form.find('input[name=deathday]').val();
var reqData = {};
var req = {};
var $error = $form.find('div.operate-warn');
if (op == 'modify') {
if (!mine_id || mine_id != this.refid) {
console.log('id 不匹配');
$error.html('id 不匹配');
return false;
}
reqData.id = mine_id;
var jold = $DD.getRow(this.refid);
if (mine_name && jold.F_name != mine_name) {
reqData.name = mine_name;
}
if (sex && sex != jold.F_sex) {
reqData.sex = sex;
}
if (!jold.F_father && father) {
var father_id = parseInt(father);
if (isNaN(father_id)) {
reqData.father_name = father;
}
else {
reqData.father_id = father_id;
}
}
if (!jold.F_mother && mother) {
var mother_id = parseInt(mother);
if (isNaN(mother_id)) {
reqData.mother_name = mother;
}
else {
reqData.mother_id = mother_id;
}
}
if (partner) {
var partner_id = parseInt(partner);
if (isNaN(partner_id)) {
reqData.partner_name = partner;
}
else {
if (jold.F_partner != partner_id) {
reqData.partner_id = partner_id;
}
}
}
if (birthday && birthday != jold.F_birthday) {
reqData.birthday = birthday;
}
if (deathday && deathday != jold.F_deathday) {
reqData.deathday = deathday;
}
if (Object.keys(reqData).length <= 1) {
console.log('没有更新任何资料');
$error.html('没有更新任何资料');
return false;
}
reqData.requery = 1;
req.api = 'modify';
req.data = reqData;
$DJ.reqModify(req);
}
else if (op == 'append') {
if (mine_name) {
reqData.name = mine_name;
if ($DD.Person.hasChildName(mine_name)) {
$error.html('已经有重名孩子，请确认不要重复输入');
return false;
}
}
else {
console.log('新增后代必须填姓名');
$error.html('新增后代必须填姓名');
return false;
}
if (sex) {
reqData.sex = sex;
}
else {
console.log('新增后代必须选性别');
$error.html('新增后代必须选性别');
return false;
}
if (father) {
var father_id = parseInt(father);
if (isNaN(father_id)) {
reqData.father_name = father;
}
else {
reqData.father_id = father_id;
}
}
if (mother) {
var mother_id = parseInt(mother);
if (isNaN(mother_id)) {
reqData.mother_name = mother;
}
else {
reqData.mother_id = mother_id;
}
}
if (!father && !mother) {
console.log('新增后代必须指定父母之一');
$error.html('新增后代必须指定父母之一');
return false;
}
if (partner) {
var partner_id = parseInt(partner);
if (isNaN(partner_id)) {
reqData.partner_name = partner;
}
else {
reqData.partner_id = partner_id;
}
}
if (birthday) {
reqData.birthday = birthday;
}
if (deathday) {
reqData.deathday = deathday;
}
reqData.requery = 1;
req.api = 'create';
req.data = reqData;
$DJ.reqAppend(req);
}
else {
console.log('只有修改或增加后代需提交数据');
}
$error.html('');
return false;
},
submitBrief: function() {
if (!$DD.Person.curid) {
return false;
}
var text = $('#formBrief textarea').val();
if (text == $DD.Person.brief) {
console.log('没有修改简介内容');
return false;
}
var id = $DD.Person.curid;
var create = 0;
if (!$DD.Person.brief) {
create = 1;
}
var key = $('#formBrief input:password').val();
if (!key) {
return;
}
$DJ.reqBrief({api: 'modify_brief',
data: {id: id, text: text, create: create},
sess: $DD.Login.reqSess(key)
});
},
closeBrief: function(_succ) {
if ($('#formBrief textarea').val()) {
$('#formBrief textarea').val('');
}
if ($('#modify-brief').css('display') != 'none') {
$('a[href=#modify-brief]').click();
}
},
submitPasswd: function() {
var $form = $('#formPasswd');
var keytype = $form.find('input:radio[name=keytype]:checked').val();
if (!keytype) {
return;
}
var id = $form.find('input[name=mine_id]').val();
var oldkey = $form.find('input[name=oldkey]').val();
var newkey = $form.find('input[name=newkey]').val();
var seckey = $form.find('input[name=seckey]').val();
if (newkey != seckey) {
$('#divPasswd div.operate-warn').html('新密码与确认密码不相同，请核查');
return;
}
if (newkey == oldkey) {
$('#divPasswd div.operate-warn').html('新密码与旧密码相同，没有修改');
return;
}
$DJ.reqPasswd({api: 'modify_passwd',
data: {
id: id,
keytype: keytype,
oldkey: oldkey,
newkey: newkey
},
sess: $DD.Login.reqSess()
});
},
closePasswd: function() {
$('#formPasswd').trigger('reset');
if ($('#divPasswd').css('display') != 'none') {
$('a[href=#divPasswd]').click();
}
},
LAST_PRETECT: 0
},
Help: {
pulled: false,
showdoc: function(res) {
if (res) {
console.log('get help doc');
$('#article').html(res);
this.pulled = true;
}
if (!this.pulled) {
$DJ.reqHelp();
}
},
},
Login: {
formSID: '#formLogin',
onSubmit: function() {
var user = $('#formLogin input[name=loginuid]').val();
var key  = $('#formLogin input[name=loginkey]').val();
if (!user || !key) {
return;
}
var reqData = {};
var id = parseInt(user) || 0;
if (!id) {
reqData.name = user;
}
else {
reqData.id = user;
}
reqData.key = key;
return $DJ.reqLogin(reqData);
},
onSucc: function() {
$(this.formSID).hide();
$('#not-login').hide();
$('#has-login').show();
var link = $DV.Fun.linktoPerson($DD.Table.Hash[$DD.Login.id]);
var $link = $(link).click($DE.onSeePerson);
$('#has-login span.data').html($link);
},
quick: function(_id) {
if (!_id) {
return;
}
if ($DD.Login.id && $DD.Login.id == _id) {
return;
}
$('#formLogin input[name=loginuid]').val(_id);
$('#formLogin').show();
$('#formLogin input[name=loginkey]').val('').focus();
$DV.Fun.jumpLink('#login-bar');
}
},
LAST_PRETECT: true
};
var $DE = {
initFold: function() {
var onClick = function(_evt) {
var href = $(this).attr('href');
var foldin = $(href);
var display = foldin.css('display');
if (display == 'none') {
foldin.show();
$(this).removeClass('foldClose');
$(this).addClass('foldOpen');
if (href == '#divOperate') {
if ($DD.Person.canOperate()) {
$('#divOperate div.operate-warn').html('');
$('#to-modify').click();
}
else {
$('#divOperate div.operate-warn').html($DD.Tip.operaCtrl);
}
}
else if (href == '#modify-brief') {
if ($DD.Person.canOperate()) {
$('#modify-brief div.operate-warn').html('');
$('#formBrief textarea').val($DD.Person.brief);
}
else {
$('#modify-brief div.operate-warn').html($DD.Tip.operaCtrl);
}
}
else if (href == '#divPasswd') {
if ($DD.Person.canOperate('only_self')) {
$('#divPasswd div.operate-warn').html('');
$DV.Operate.lock($('#formPasswd input:text[name=mine_id]'), $DD.Login.id);
}
else {
$('#divPasswd div.operate-warn').html($DD.Tip.modifyPasswdOnlySelf);
}
}
}
else {
foldin.hide();
$(this).removeClass('foldOpen');
$(this).addClass('foldClose');
}
_evt.preventDefault();
};
var $open = $('a.foldOpen');
$open.each(function(_idx, _ele) {
var href = $(this).attr('href');
$(href).show();
$(this).click(onClick);
$(this).attr('title', '折叠/展开');
});
var $close = $('a.foldClose');
$close.each(function(_idx, _ele) {
var href = $(this).attr('href');
$(href).hide();
$(this).click(onClick);
$(this).attr('title', '折叠/展开');
});
var loginFold = function(_evt) {
_evt.preventDefault();
var href = $(this).attr('href');
var foldin = $(href);
var display = foldin.css('display');
if (display == 'none') {
foldin.show();
$('#formLogin input:text[name=loginuid]').focus();
$('#formLogin div.operate-warn').html('');
return 'show';
}
else {
foldin.hide();
return 'hide';
}
};
$('#not-login>a.to-login').click(loginFold);
$('#has-login>a.to-login').click(loginFold);
},
Form: {
Operate: function() {
var $form = $('#formOperate');
$form.find('input:radio[name=operate]').change(function(_evt){
$DV.Operate.change();
});
$('#oper-close').click(function() {
$DV.Operate.close();
});
$form.submit(function(_evt) {
_evt.preventDefault();
if (!$DD.Person.canOperate()) {
return;
}
return $DV.Operate.submit(_evt);
});
$form.find('a.input-unlock').click({form: $form}, this.unlockInput);
},
unlockInput: function(_evt) {
_evt.preventDefault();
var $form = _evt.data.form;
var href = $(this).attr('href');
var name = href.substring(1);
var $input = $form.find(`input:text[name=${name}]`);
$DV.Operate.unlock($input);
},
Filter: function() {
var $form = $('#formFilter');
$form.submit(function(_evt) {
_evt.preventDefault();
$DV.Table.Filter.onSubmit();
return false;
});
$('#filter-rollback').click(function() {
$DV.Table.Filter.onReset();
});
$form.find('input:checkbox[name=filter]').change(function(_evt){
$DV.Table.Filter.onCheckbox();
});
$form.find('select').change(function(_evt){
$DV.Table.Filter.onSelection();
});
this.fillLevel($form);
},
fillLevel: function($form) {
var $levelFrom = $form.find('select[name=level-from]');
var $levelTo = $form.find('select[name=level-to]');
$DD.LEVEL.forEach(function(_item, _idx) {
var item = _idx > 0 ? (_idx + ' ' + _item) : _item;
var html = `<option value="${_idx}">${item}</option>`;
$levelFrom.append(html);
$levelTo.append(html);
});
},
Query: function() {
var $form = $('#formQuery');
$form.submit(function(_evt) {
_evt.preventDefault();
$DV.Table.Pager.onSubmit();
});
$('#table-prev-page').click(function(_evt) {
_evt.preventDefault();
$DV.Table.Pager.doPrev();
});
$('#table-next-page').click(function(_evt) {
_evt.preventDefault();
$DV.Table.Pager.doNext();
});
$form.find('input:checkbox[name=filter]').change(function(_evt){
$DV.Table.Pager.onCheckbox(this);
});
this.fillLevel($form);
},
Login: function() {
var $form = $('#formLogin');
$form.submit(function(_evt) {
_evt.preventDefault();
return $DV.Login.onSubmit();
});
$form.find('input[name=close]').click(function(_evt) {
$('#formLogin').hide();
});
},
Passwd: function() {
var $form = $('#formPasswd');
$form.submit(function(_evt) {
if (!$DD.Person.canOperate('only_self')) {
return;
}
_evt.preventDefault();
return $DV.Operate.submitPasswd();
});
$form.find('input[name=close]').click(function() {
$DV.Operate.closePasswd();
});
$form.find('a.input-unlock').click({form: $form}, this.unlockInput);
},
Person: function() {
$('#formPerson').submit(function(_evt) {
_evt.preventDefault();
return $DV.Person.onSearch(_evt);
});
},
Brief: function() {
$('#formBrief').submit(function(_evt) {
_evt.preventDefault();
if (!$DD.Person.canOperate()) {
return;
}
return $DV.Operate.submitBrief();
});
},
init: function() {
this.Operate();
this.Filter();
this.Query();
this.Login();
this.Passwd();
this.Person();
this.Brief();
},
LAST_PRETECT: true
},
onLoad: function() {
$('li.page-menu>a').click(function(_evt) {
var href = $(this).attr('href');
$DV.Page.see(href);
_evt.preventDefault();
});
this.initFold();
this.Form.init();
$('#tabMine-exup>a').click(function(_evt) {
$DV.Person.Table.expandUp();
_evt.preventDefault();
});
$('#tabMine-exdp>a').click(function(_evt) {
$DV.Person.Table.expandDown();
_evt.preventDefault();
});
},
onPersonUpdate: function() {
var that = this;
$('#member-relation li a.toperson').click(function(_evt) {
that.gotoPerson($(this));
_evt.preventDefault();
});
},
onQuickLogin: function(_evt) {
$DV.Login.quick($(this).html());
_evt.preventDefault();
},
onSeePerson: function(_evt) {
$DE.gotoPerson($(this));
_evt.preventDefault();
},
gotoPerson: function($_emt) {
var href = $_emt.attr('href');
var rem = href.match(/#p(\d+)/);
if (rem) {
var id = rem[1];
$DV.Page.checkPerson(id);
}
},
LAST_PRETECT: true
};
var $DJ = {
Config: {
formMsg: 'operate-warn',
LAST_PRETECT: true
},
reqOption: function(_req) {
var opt = {
method: "POST",
contentType: "application/json",
dataType: "json",
data: JSON.stringify(_req)
};
return opt;
},
requestAPI: function(_req, _callback, _form, _msg) {
var opt = this.reqOption(_req);
$LOG('api req = ' + opt.data);
var form = _form || 'formNULL';
var $form = $('#' + form);
var $msg = $form.find('div.' + $DJ.Config.formMsg);
var $submit = $form.find('input:submit');
var ajx = $.ajax($DD.API_URL, opt)
.done(function(_res, _textStatus, _jqXHR) {
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
if (_form) {
$submit.removeAttr('disabled');
}
});
if (_form) {
$msg.html('正在请求服务器通讯……');
$submit.attr('disabled', 'disabled');
}
return ajx;
},
resError: function(_res, _req) {
},
resFail: function(jqXHR, textStatus, errorThrown) {
alert('从服务器获取数据失败'  +  jqXHR.status + textStatus);
},
resAlways: function(data, textStatus, jqXHR) {
console.log('ajax finish with status: ' + textStatus);
},
requestAll: function() {
var req = {"api":"query","data":{"all":1}};
this.query = this.requestAPI(req, function(_resData, _reqData) {
$DV.Table.Pager.doneQuery(_resData);
$DJ.reqPartnerAll();
});
},
reqPartnerAll: function() {
var req = {"api":"query",
"data":{
"filter":{
"level":{"<":0},
"partner":{">":0},
}
}
};
this.partner = this.requestAPI(req, function(_resData, _reqData) {
$DD.Table.storePartner(_resData, _reqData);
$DV.Table.updateName();
});
},
reqQuery: function(_req) {
if (!_req.api || _req.api != 'query') {
console.log('请求参数不对');
return false;
}
var form = 'formQuery';
var msg = {suc: '查询完成，结果列于上表'};
this.query = this.requestAPI(_req, function(_resData, _reqData) {
$DV.Table.Pager.doneQuery(_resData);
}, form, msg);
},
reqModify: function(_req) {
if (!_req.api || _req.api != 'modify') {
console.log('请求参数不对');
return false;
}
var form = 'formOperate';
var msg = {suc: '修改资料成功', err: '修改资料失败'};
this.modify = this.requestAPI(_req, function(_resData, _reqData) {
$DD.Table.modify(_resData, _reqData);
}, form, msg);
},
reqAppend: function(_req) {
if (!_req.api || _req.api != 'create') {
console.log('请求参数不对');
return false;
}
var form = 'formOperate';
var msg = {suc: '添加子女成功', err: '添加子女失败'};
this.create = this.requestAPI(_req, function(_resData, _reqData) {
$DD.Table.modify(_resData, _reqData);
}, form, msg);
},
reqHelp: function() {
var ajx = $.get($DD.HELP_URL)
.done(function(res, textStatus, jqXHR) {
$DV.Help.showdoc(res);
})
.fail(this.resFail)
.always(this.resAlways);
this.doc = ajx;
return ajx;
},
reqBrief: function(_req) {
var form, msg;
if (_req.api == 'modify_brief') {
form = 'formBrief';
msg = {suc: '修改简介成功', err: '修改简介失败'};
}
this.brief = this.requestAPI(_req, function(_resData, _reqData) {
$DD.Person.onBriefRes(_resData, _reqData);
}, form, msg);
},
reqLogin: function(_reqData) {
var req = {
api: 'login',
data: _reqData
};
var form = 'formLogin';
var msg = {err: '登陆失败，请检查id或姓名是否存在，或是否重名'};
this.login = this.requestAPI(req, function(_resData, _reqData) {
$DD.Login.callback(_resData, _reqData);
}, form, msg);
},
reqPasswd: function(_req) {
var form = 'formPasswd';
var msg = {err: '修改密码失败', suc: '修改密码成功，请牢记'};
this.brief = this.requestAPI(_req, function(_resData, _reqData) {
$DD.Login.onModifyPasswd(_resData, _reqData);
}, form, msg);
},
LAST_PRETECT: true
};
var $DOC = {
DATA: $DD,
VIEW: $DV, 
EVENT: $DE,
AJAX: $DJ,
divLog: '#debug-log',
INIT: function() {
$LOG.init(this.divLog);
this.EVENT.onLoad();
this.VIEW.Page.init();
this.AJAX.requestAll();
}
};
var $LOG = function(_msg) {
if (typeof(_msg) == 'object') {
_msg = JSON.stringify(_msg);
}
if (!$LOG.div) {
$LOG.div = 'body';
}
$($LOG.div).append("<p>" + _msg + "</p>");
console.log(_msg);
};
$LOG.init = function(_div) {
this.div = _div;
};
$LOG.open = function() {
if (this.div !== 'body') {
$(this.div).show();
}
};
$LOG.close = function() {
if (this.div !== 'body') {
$(this.div).hide();
}
};
$(document).ready(function() {
$DOC.INIT();
});
