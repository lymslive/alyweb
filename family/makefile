# 自动预转文档等处理
WEB_DIR = ./web

JS_DIR = ./web/js
JS_APP = $(JS_DIR)/app.js
# JS_SRC = $(wildcard $(JS_DIR:%=%/*.js))
# js 文件有顺序的，不能用通配符
JS_FILE = DD.js DV.js DE.js DJ.js
JS_SRC = $(addprefix $(JS_DIR)/,$(JS_FILE))

# 目标简写
.PHONY: js doc test
js : $(JS_APP)
doc : $(WEB_DIR)/doc/help.htm

# $< 为第一个依赖，$^ 为所有依赖
$(WEB_DIR)/doc/help.htm : ./doc/help.md
	markdown $< > $@

# 合并 js 代码文件
$(JS_APP) : $(JS_SRC)
	./mergejs.pl $^ > $@

test:
	echo $(JS_APP)
	echo $(JS_SRC)
