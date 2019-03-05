// 验证修改资料表单
function ValidateForm()
{
	let form = document.forms["operate-form"];
	let operkey = form['operkey'].value;
	if (!operkey) {
		alert('需要操作密码');
		return false;
	}

	let operate = form['operate'].value;
	let id = form['mine_id'].value;
	let name = form['mine_name'].value;
	let sex = form['sex'].value;
	let partner = form['partner'].value;
	let mother = form['mother'].value;
	let father = form['father'].value;
	let birthday = form['birthday'].value;
	let deathday = form['deathday'].value;

	if (operate == 'create')
	{
		if (!name || !sex || (!father && !mother)) {
			alert('新增人员须指定：姓名、性别与父/母之一');
			return false;
		}
	}
	else if (operate == 'modify') {
		if (!id) {
			alert('修改资料须指定：编号id');
			return false;
		}
		if (!name && !sex && !partner && !father && !mother && !birthday && !deathday)
		{
			alert('没有改动任何资料');
			return false;
		}
	}

	return true;
}

