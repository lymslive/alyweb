# 个人博客日记

## 页面布局

顶部导航
列表或文章显示其一
文章分标题、正文、评论三部分

## ajax 接口

* topic 请求各分类列表
* article 请求单篇文章 markdown
* discuss 加载评论
* postDiscuss 添加评论

还是全用 json 吧，单文也 json 编码，服务端简单解析一下标题、标签与正文
