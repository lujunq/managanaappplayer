/**
 * Managana remote control javascript API.
 * License: GNU LGPL version 3
 * The Managana remote control API provides methods to interact with the Managana APP player using javascript built into HTML5 pages. The API relies on the WebSocket capability of modern web browsers. To use it on a HTML page, you must always include the websocket.js configuration file that is dynamically created by the Managana APP when it is initialized at the root of the webserver folder. At the HTML header, include:
 * <script type="text/javascript" src="/websocket.js"></script>
 *
 * @author Lucas Junqueira - lucas@ciclope.art.br
 */

// VARIABLES

/**
 * The WebSocket connection.
 */
var wsconn;

// METHODS

/**
 * Open a WebSocket connection to the Managana APP player.
 */
function startConnection() {
	if ("WebSocket" in window) {
		wsconn = new WebSocket(webSocketAddress);
		wsconn.onopen = wsOnOpen;
		wsconn.onmessage = wsOnMessage;
		wsconn.onclose = wsOnClose;
	} else {
		alert("Sorry: your browser is not capable of running this web application. Try alternative browsers like Mozilla Firefox or Google Chrome.");
	}
}

/**
 * The WebSocket connection is established.
 */
function wsOnOpen() {
	alert ('connection open');
}

function wsOnMessage(evt) {
	var received_msg = evt.data;
	
	alert ('meessage received ' + received_msg);
}

function wsOnClose() {
	alert ('connection closed');
}

function wsSend(message) {
	wsconn.send(message);
}
	
function wsSendObject(obj) {
	wsconn.send(JSON.stringify(obj));
}



function sendBee(height, total) {
	wsSendObject({ "ac":"bee", "height":height, "total":total });
}

function setZoom(pos, total, thescreen) {
	wsSendObject({ "ac":"setzoom", "pos":pos, "total":total, "thescreen":thescreen });
}

function setSide(pos, total, thescreen) {
	wsSendObject({ "ac":"setside", "pos":pos, "total":total, "thescreen":thescreen });
}

function setHeight(pos, total, thescreen) {
	wsSendObject({ "ac":"setheight", "pos":pos, "total":total, "thescreen":thescreen });
}

function setSpeed(pos, total, thescreen) {
	wsSendObject({ "ac":"setspeed", "pos":pos, "total":total, "thescreen":thescreen });
}

function setFont(thescreen) {
	wsSendObject({ "ac":"setfont", "thescreen":thescreen });
}

function setColor(thescreen) {
	wsSendObject({ "ac":"setcolor", "thescreen":thescreen });
}

function bang(thescreen) {
	wsSendObject({ "ac":"bang" });
}