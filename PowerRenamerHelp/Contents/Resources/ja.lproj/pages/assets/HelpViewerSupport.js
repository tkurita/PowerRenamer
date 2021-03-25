function helpViewerSupport() {
	if (navigator.userAgent.indexOf("Help Viewer") >= 0 ){
		document.forms["paypal"].action="http://homepage.mac.com/tkurita/scriptfactory/donationproxy.html";
		document.forms["paypal"].target="_blank";
		for (i = 0; i<document.links.length; i++) {
			if (document.links[i].title == "_abs" ) {
				document.links[i].target = "_blank";
			}
		}
	}
}
window.onload=helpViewerSupport;