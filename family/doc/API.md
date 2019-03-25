# 家谱系统 JSON API 文档

## 综述

* API 地址：http://lymslive.top/family/japi.cgi
* 开发版 API 地址：http://lymslive.top/dev/family/japi.cgi
* 请求方式：post
* 数据格式：json，请求出响应数据格式均为 json

### 请求的一般格式

请求是一个 json 对象，其基本格式为：
```
{"api":"api_name","data":{...}, sess:{...}}
```

* `api` 为接口名称，字符串
* `data` 为具体接口参数，嵌套 json 对象，根据不同接口名而不同，见具体接口的文档
* `sess` 为与会话有关的信息

会话对象 sess 在会涉及修改数据库时必需，在查询与登陆时可不提供。允许字段：

* `id` 登陆者 id
* `token` 会话标记
* `opera_key` 操作密码

其中 token 在登陆时获得。

示例，查询所有数据：
```
curl -d '{"api":"query","data":{"all":1}}'
```

### 响应的一般格式

响应也是一个 json 对象，其基本格式为：
```
{"error":0,"errmsg":"","data":{}}
```

* `error` 如果 api 操作出错，返回错误码（英文标识符），成功返回 0
* `errmsg` 如果出错，errmsg 额外给出用户友好的错误消息字符串
* `data` 如果成功，返回具体的数据对象，由具体接口决定

## 接口

支持的接口有：

* query
* create
* modify
* remove
* member_relations
* query_brief
* create_brief
* modify_brief
* remove_brief
* login
* modify_passwd

其中，前面四个单个词的接口名基本增删改查接口。后面两个单词的为扩展接口，为方便
业务而专门提供的。

本节描述的接口参数，主要是上节描述的请求 data 与响应 data 的具体字段。
（部分接口，尤其是支持参数可能开发不完全，各有备注）

### 查询接口 query

#### 请求参数：req.data

* `all` 值为 `1` 时全部选择，忽略 `filter` 筛选条件，按默认选择有效数据
* `filter` 筛选条件，嵌套对象，当不存在 `all` 或为 `0` 时生效
* `page` 数值，查询第几页，默认 1
* `perpage` 数值，每页几条数据，默认 100
* `fields` 列名字符串数组，指定要查询哪些列，或默认大部分有效字段

当数组量大时，应该指定 `page` 与 `perpage` 。

默认查询字段为（另见数据库设计）：

1. `F_id` 自增编号
2. `F_name` 姓名
3. `F_sex` 性别，男 1 女 0
4. `F_level` 代际，始祖为 1 代，逐代递增，负数为配偶旁系
5. `F_father` 父亲，引用编号 id
6. `F_sibold` 兄弟排行
7. `F_partner` 配偶姓名
8. `F_birthday` 生日，日期类型，yyyy-mm-dd 格式
9. `F_deathday` 忌日，日期类型，yyyy-mm-dd 格式

支持的 filter 筛选条件与数据库字段名基本类似，只是命名上没有 `F_` 前缀，且有更
多扩展：

* `id` 数值或数值数组，指定单个 id 或一组 id
* `name` 姓名
* `sex` 性别，男 1 女 0
* `level` 代际
* `father` 父亲 id
* `sibold` 兄弟排行
* `partner` 配偶姓名

计划支持的扩展条件：

* `birthday` 日期范围，在此区间出生的，若单数值指在此之后出生的
* `deathday` 日期范围，在此区间过世的，若单数值指在此之前过世的
* `age` 年龄范围，到今天的年龄范围，若单数值指小于多少岁的
* `life` 寿命范围，特指过世的先人，若单数值指大于多少寿命的（难）

#### 响应参数：res.data

* `total` 总记录数
* `page` 当前第几页，按请求原样返回
* `perpage` 每页记录数，按请求原样返回
* `records` 查询结果 `[{}]`，记录数组，每个元素是对象，只有一条记录也是数组

默认按代际排序。在默认请求 `all` 的情况下，不会选出 `name` 为字符串 '0' 与
`level` 小于 0 的数据。前者用于标记删除，后者用于标记旁系配偶。但如果确实要选
出这类数据，可以在 `filter` 参数传入，并且不传 `all` 。

### 新建接口 create

#### 请求参数：req.data

* `id` 写定编号，否则按默认自增
* `name` 姓名
* `sex` 性别
* `father_name` 父亲姓名，通过姓名查 id，有重名或查不到时报错
* `father_id` 直接指定父亲 id ，优先级比姓名高
* `partner` 提供配偶姓名，同时为配偶增加一条记录
* `sibold` 指定第几个孩子
* `birthday` 生日
* `deathday` 忌日
* `requery` 重新查询插入的数据，如果请求参数含配偶信息，也返回配偶的记录

新建家庭成员记录时，必须指定一个父亲或母亲的信息，所依父/母的 id 必须先存在，
指定姓名时不应有重名。依据父母信息确定代际。

此外必须指定新增成员的姓名与性别。一般地，可同时提供配偶的姓名，则会一起将配偶
入库。若提供配偶 id ，该 id 也须事先入库，此用法只为兼容，不鼓励用，旁系配偶应
该随直系成员一起入库。也可插入新成员后再修改配偶信息，只提供配偶姓名时也会新插
入配偶记录，详见下方修改接口。

一般也无须指定新成员 id ，按默认自增即可，有特殊需求时可指定 id ，但不能与已存
在的 id 重复。

#### 响应参数：res.data

* `created` 新建插入的行数
* `id` 新插入成员的 id
* `mine` 在请求了 `requery` 时返回重查的数据

### 修改接口 modify

#### 请求参数：req.data

修改的请求参数与新建类似，不过 id 为必选项，根据 id 修改一条记录

* `id` 指定编号
* `name` 姓名
* `sex` 性别
* `father_name` 父亲姓名，通过姓名查 id，有重名或查不到时报错
* `father_id` 直接指定父亲 id ，优先级比姓名高
* `partner` 提供配偶姓名，同时为配偶增加一条记录
* `sibold` 指定第几个孩子
* `birthday` 生日
* `deathday` 忌日
* `requery` 重新查询插入的数据，如果请求参数含配偶信息，也返回配偶的记录

#### 响应参数：res.data

* `modified` 修改影响的行数
* `id` 原样返回被修改成员的 id
* `mine` 在请求了 `requery` 时返回重查的数据

如果请求中不修改配偶，则也不返回 `partner_id` ，`records` 中也不包含配偶。

### 删除接口 remove

#### 请求参数：req.data

* `id` 指定编号，待删除的成员 id

#### 响应参数：res.data

* `removed` 被删除的行数，一般只请求删除一条记录的话，成功时返回 1 。

### 关系接口 member_relations

用于查询与一个成员的有亲缘关系的其他成员。

#### 请求参数：req.data

* `id` 指定基准成员 id 必填项；
* `mine` 是否查询结果也要求包含自身资料；
* `parents` 直系父（母）辈，数值表示最多上溯查多少代，-1 表示上溯到最顶层，也
  即自身代际 -1 层；
* `children` 是否查询所有直接后代，儿子或女儿
* `sibling` 是否查询同父或同母（取决于哪方是直系）的兄弟姐妹

请求参数值中，用 1/0 表示是否，0 （或不提供该参数）表示不查询这种关系。

#### 响应参数：res.data

参数字段原名返回，但除 id 外，其他指所查的记录数组，相当于查询接口的 records 。

* `id` 原样返回自身 id ；
* `mine` 一条记录的数组，自身资料；
* `parents` 记录数组，依次表示上溯祖辈的资料；
* `children` 记录数组，由自身的孩子组成；
* `partner` 记录数组，一般是一条记录，但也可能入库多次婚配的情况；
* `sibling` 记录数组，由同系兄弟姐妹组成；

### 查询简介 query_brief

简介设计为在另一个表存储，故而提供另一套接口。
简介文本在数据库设计最多保存 1024 字节，汉字约 340 个。

#### 请求参数 req.data

* `id` 成员 id，根据 id 查询简介

#### 响应参数 res.data

* `F_id` 原样返回请求的 `id`
* `F_text` 简介文本

### 创建简介 create_brief

#### 请求参数 req.data

* `id` 成员 id
* `text` 成员简介

#### 响应参数 res.data

* `F_id` 原样返回请求的 `id`
* `affected` 提示数据库操作影响的行

### 修改简介 modify_brief

#### 请求参数 req.data
* `id` 成员 id
* `text` 成员简介
* `create` 如果提供这个值，当不存在简介时也直接创建

#### 响应参数 res.data
* `F_id` 原样返回请求的 `id`
* `affected` 提示数据库操作影响的行

### 删除简介 remove_brief

#### 请求参数 req.data
* `id` 成员 id

#### 响应参数 res.data
* `F_id` 原样返回请求的 `id`
* `affected` 提示数据库操作影响的行

### 登陆接口 login

#### 请求参数 req.data
* `id` 按成员 id 登陆
* `name` 按成员姓名登陆，存在重名时会失败
* `key` 登陆密码

如果首次登陆，初始登陆密码与操作密码都假设为与 id 相同。

#### 响应参数 res.data
* `id` 原样返回 id 或按 name 查询的 id
* `token` 作为会话标记的 token
* `mine` 自己的一行数据

### 修改密码 modify_passwd

#### 请求参数 req.data

* `id` 成员 id
* `keytype` 密码类型，字符串，loginkey 或 operakey ，登陆或操作密码
* `oldkdy` 旧密码
* `newkey` 新密码

#### 响应参数 res.data
* `id` 原样返回请求的 `id`
* `affected` 提示数据库操作影响的行，可表示修改是否成功
