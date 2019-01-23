// http://www.ruanyifeng.com/blog/2017/05/websocket.html
// http://websocketd.com/
var ws = new WebSocket("ws://lymslive.top:8081");

ws.onopen = function(evt) {
	console.log("Connection open ...");
	ws.send("Hello WebSocket!");
};

ws.onmessage = function(evt) {
	console.log("Received Message: " + evt.data);
	// ws.close();
};

ws.onclose = function(evt) {
	console.log("Connection colsed.");
};
