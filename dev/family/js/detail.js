// 验证修改资料表单
function ValidateModifyForm()
{
	let form = document.forms["modify-mine"];
	let operkey = form['operkey'].value;
	if (!operkey) {
		alert('需要操作密码');
		return false;
	}

	let name = form['mine_name'].value;
	let sex = form['sex'].value;
	let partner = form['partner'].value;
	var father = '';
	if (form['father']) {
		father = form['father'].value;
	}
	var mother = '';
	if (form['mother']) {
		mother = form['mother'].value;
	}
	let birthday = form['birthday'].value;
	let deathday = form['deathday'].value;

	if (!name && !sex && !partner && !father && !mother && !birthday && !deathday)
	{
		alert('没有任何改动');
		return false;
	}

	return true;
}

// 验证添加子女的表单
function ValidateCreateChild()
{
	let form = document.forms["add-child"];
	let operkey = form['operkey'].value;
	if (!operkey) {
		alert('需要操作密码');
		return false;
	}

	let name = form["child_name"].value;
	if (name == null || name == '') {
		return false;
	}

	let sex  = form["child_sex"].value;
	if (sex == null || sex == '') {
		return false;
	}

	return true;
}
