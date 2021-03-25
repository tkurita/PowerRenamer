//version 1.0
function navibarJump(select_form){
	//window.alert("aaa");
	window.location.hash = select_form.options[select_form.selectedIndex].value;
	window.scrollBy(0, -1*select_form.parentNode.clientHeight);
	return true;
}