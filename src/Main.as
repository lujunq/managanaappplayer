package {
	
	// FLASH PACKAGES
	import art.ciclope.event.WebsocketEvent;
	import art.ciclope.managana.graphics.DebugWindow;
	import flash.desktop.NativeApplication;
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.events.*;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.filesystem.FileStream;
	import flash.net.URLStream;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.display.StageQuality;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	import flash.desktop.NativeApplication;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.desktop.SystemIdleMode;
	import flash.display.StageDisplayState;
	import flash.ui.Keyboard;
	import flash.display.Loader;
	import flash.system.Capabilities;
	
	// CICLOPE CLASSES
	import art.ciclope.managana.ManaganaPlayer;
	import art.ciclope.managana.ManaganaInterface;
	import art.ciclope.event.Message;
	import art.ciclope.event.DISLoad;
	import art.ciclope.managana.system.LinkManagerAIR;
	import art.ciclope.managana.graphics.MessageWindow;
	import art.ciclope.managana.graphics.CloseQRCode;
	import art.ciclope.display.GraphicSprite;
	import art.ciclope.managana.graphics.Target;
	import art.ciclope.managana.data.ConfigData;
	import art.ciclope.managana.system.HTMLBoxAIR;
	import art.ciclope.mobile.GPS;
	import art.ciclope.event.ReaderServerEvent;
	import art.ciclope.managana.graphics.WaitingGraphic;
	import art.ciclope.data.LeapData;
	import art.ciclope.event.LeapDataEvent;
	import art.ciclope.managana.data.RemoteTCPData;
	import art.ciclope.net.HTTPServer;
	import art.ciclope.net.TCPServer;
	import art.ciclope.mobile.QrCodeReader;
	import art.ciclope.managana.data.DISLoadProtocol;
	import art.ciclope.net.WebSocketsServer;
	
	/**
	 * <b>Availability:</b> CICLOPE AS3 Classes - www.ciclope.art.br<br>
	 * <b>License:</b> GNU LGPL version 3<br><br>
	 * This is the Managana app player main class.
	 * @author Lucas Junqueira - lucas@ciclope.art.br
	 */
	public class Main extends Sprite {
		
		// CONSTANTS
		
		/**
		 * Message for initialization error.
		 */
		private const INITIALERRORTEXT:String = "Application initialize error!";
		/**
		 * Access key for managana reader server.
		 */
		private const READERKEY:String = "managana";
		/**
		 * Reader server access method.
		 */
		private const READERMETHOD:String = "post";
		/**
		 * Reader server script ending.
		 */
		private const READERENDING:String = ".php";
		
		// STATIC VARIABLES
		
		/**
		 * Is managana being dragged?
		 */
		public static var dragging:Boolean = false;
		/**
		 * Managana drag interval.
		 */
		public static var drinterval:int = 0;
		/**
		 * Stage click interval.
		 */
		public static var clickinterval:int = 0;
		/**
		 * Was stage clicked recently?
		 */
		public static var recentclick:Boolean = false;
		/**
		 * The debug display window.
		 */
		public static var debugWindow:DebugWindow;
		
		// STATIC CONSTANTS
		
		/**
		 * Running in debug mode?
		 */
		public static const DEBUGGING:Boolean = false;
		
		// VARIABLES
		
		private var _managana:ManaganaPlayer;				// the player itself
		private var _interface:ManaganaInterface;			// player interface
		private var _linkmanager:LinkManagerAIR;			// a manager for external links
		private var _boxmanager:HTMLBoxAIR;					// a manager for html box
		private var _bg:Shape;								// background color
		private var _config:XML;							// application configuration
		private var _playActivate:Boolean;					// play content on activate?
		private var _framerate:uint;						// default frame rate
		private var _gps:GPS;								// geolocation
		private var _managanaConfig:ConfigData;				// system configuration
		private var _downloadFinish:Function;				// a function to call on download finish
		private var _downloadStream:FileStream;				// downloaded file stream
		private var _remoteStream:URLStream;				// remote file stream
		private var _downloadPos:uint;						// download current position
		private var _waiting:WaitingGraphic;				// an initial waiting feedback
		private var _leap:LeapData;							// leap motion data
		private var _system:Array;							// system specific controllers
		private var _webserver:HTTPServer;					// internal web server
		private var _websocket:WebSocketsServer;			// websocket server to listen to connected html/javascript remote controls
		private var _qrcode:QrCodeReader;					// qrcode reading interface
		
		/**
		 * App player main class constructor.
		 */
		public function Main():void {
			// debugging?
			if (Main.DEBUGGING) Main.debugWindow = new DebugWindow();
			// check stage
			if (this.stage != null) this.init();
				else this.addEventListener(Event.ADDED_TO_STAGE, onStage);
		}
		
		/**
		 * The stage became available.
		 */
		private function onStage(evt:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStage);
			this.init();
		}
		
		/**
		 * Initialize application.
		 */
		private function init():void {
			// set stage
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;
			this.stage.quality = StageQuality.HIGH;
			this.stage.addEventListener(Event.RESIZE, onResize);
			// show waiting graphic
			this._waiting = new WaitingGraphic();
			ManaganaInterface.setSize(this._waiting);
			this.addChild(this._waiting);
			this._waiting.x = this.stage.stageWidth / 2;
			this._waiting.y = this.stage.stageHeight / 2;
			// touch or gesture?
			if (Multitouch.supportsGestureEvents) {
				Multitouch.inputMode = MultitouchInputMode.GESTURE;
			}
			// load configuration
			this._managanaConfig = new ConfigData();
			this._managanaConfig.addEventListener(Event.COMPLETE, onConfigComplete);
			this._managanaConfig.addEventListener(Event.CANCEL, onConfigCancel);
		}
		
		/**
		 * System configuration load error: halt!
		 */
		private function onConfigCancel(evt:Event):void {
			this._managanaConfig.removeEventListener(Event.COMPLETE, onConfigComplete);
			this._managanaConfig.removeEventListener(Event.CANCEL, onConfigCancel);
			var message:MessageWindow;
			message = new MessageWindow(this.stage.stageWidth, this.stage.stageHeight, false);
			message.setText(this.INITIALERRORTEXT);
			this.addChild(message);
		}
		
		/**
		 * System configuration load complete.
		 */
		private function onConfigComplete(evt:Event):void {
			this._managanaConfig.removeEventListener(Event.COMPLETE, onConfigComplete);
			this._managanaConfig.removeEventListener(Event.CANCEL, onConfigCancel);
			// running on desktop computer?
			if (this._managanaConfig.getConfig("desktop") == "true") {
				this.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
				//this.addEventListener(Event.CLOSING, appClosing, false, 0, true);
				this.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
				this.stage.addEventListener(FullScreenEvent.FULL_SCREEN, displayStateChanged, false, 0, true);
			}
			// create documents folder
			var folder:File;
			// is the application running from external media on windows?
			if (this._managanaConfig.onRemovable) {
				// is the external media writable?
				folder = new File(File.applicationDirectory.nativePath + File.separator + "flashdrive.dat");
				try {
					var fstream:FileStream = new FileStream();
					fstream.open(folder, FileMode.WRITE);
					fstream.writeUTFBytes("flashdrive.dat");
					fstream.close();
					if (folder.exists) folder.deleteFile();
					folder = new File(File.applicationDirectory.nativePath + File.separator + "ManaganaPlayer");
					if (!folder.isDirectory) folder.createDirectory();
				} catch (e:Error) {
					// the app can't write on the removable media: switch to documents folder
					this._managanaConfig.setNoRemovable();
					folder = File.documentsDirectory.resolvePath("ManaganaPlayer");
					folder.preventBackup = true;
					if (!folder.isDirectory) folder.createDirectory();
				}
			} else {
				folder = File.documentsDirectory.resolvePath("ManaganaPlayer");
				folder.preventBackup = true;
				if (!folder.isDirectory) folder.createDirectory();
			}
			folder = filePath("");
			if (!folder.isDirectory) folder.createDirectory();
			folder = filePath("/community");
			if (!folder.isDirectory) folder.createDirectory();
			folder = filePath("/data");
			if (!folder.isDirectory) folder.createDirectory();
			folder = filePath("/data/online");
			if (!folder.isDirectory) folder.createDirectory();
			folder = filePath("/data/offline");
			if (!folder.isDirectory) folder.createDirectory();
			// create cache folder and copy cache files, including the web remote control
			folder = filePath("/cache");
			if (folder.isDirectory) {
				try {
					folder.deleteDirectory(true);
				} catch (e:Error) {
					trace ('erro aqui apagando pasta');
				}
			}
			if (!folder.isDirectory) folder.createDirectory();
			var cacheContents:File = File.applicationDirectory.resolvePath("webroot");
			cacheContents.copyToAsync(folder, true);
			// prepare download streams
			this._downloadStream = new FileStream();
			this._remoteStream = new URLStream();
			this._remoteStream.addEventListener(Event.COMPLETE, onRemoteStreamComplete);
			this._remoteStream.addEventListener(IOErrorEvent.IO_ERROR, onRemoteStreamError);
			this._remoteStream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onRemoteStreamError);
			this._remoteStream.addEventListener(ProgressEvent.PROGRESS, onRemoteStreamProgress);
			// background
			this._bg = new Shape();
			if (this._managanaConfig.isConfig('bgcolor')) {
				this._bg.graphics.beginFill(uint(this._managanaConfig.getConfig('bgcolor')));
			} else {
				this._bg.graphics.beginFill(0x000000);
			}
			this._bg.graphics.drawRect(0, 0, 100, 100);
			this._bg.graphics.endFill();
			this._bg.width = this.stage.stageWidth;
			this._bg.height = this.stage.stageHeight;
			this.addChild(this._bg);
			// prepare player
			var type:String = ManaganaPlayer.TYPE_MOBILE;
			if (this._managanaConfig.getConfig('desktop') == 'true') type = ManaganaPlayer.TYPE_DESKTOP;
			this._managana = new ManaganaPlayer(null, this.stage.stageWidth, this.stage.stageHeight, "landscape", 0, 0, false, "", false, false, type);
			this._managana.checkPath = this.checkLocal;
			this._managana.localUserData = this.localUserData;
			this._managana.x = this.stage.stageWidth / 2;
			this._managana.y = this.stage.stageHeight / 2;
			if (this._managanaConfig.isConfig('server')) {
				this._managana.serverurl = this._managanaConfig.getConfig('server');
				this._managana.addEventListener(Message.SHARE_FACEBOOK, onOpenURL);
				this._managana.addEventListener(Message.SHARE_TWITTER, onOpenURL);
				this._managana.addEventListener(Message.SHARE_GPLUS, onOpenURL);
			}
			this._managana.addEventListener(Message.OPENURL, onOpenURL);
			this._managana.addEventListener(Message.OPENHTMLBOX, onHTMLBox);
			this._managana.addEventListener(Message.MESSAGE, onGenericMessage);
			this.addChild(this._managana);
			// target mode
			if (this._managanaConfig.getConfig("desktop") == "true") {
				this._managana.targetMode = Target.INTERACTION_MOUSE;
			} else if (this._managanaConfig.isConfig('targetmode')) {
				if (this._managanaConfig.getConfig('targetmode') == "remote") {
					this._managana.targetMode = Target.INTERACTION_REMOTE;
				} else if (this._managanaConfig.getConfig('targetmode') == "none") {
					this._managana.targetMode = Target.INTERACTION_NONE;
				}
			}
			// reader server key
			var key:String = READERKEY;
			if (this._managanaConfig.isConfig('readerkey')) {
				key = this._managanaConfig.getConfig('readerkey');
			}
			// reader server access method
			var method:String = READERMETHOD;
			if (this._managanaConfig.isConfig('readermethod')) {
				method = this._managanaConfig.getConfig('readermethod');
			}
			// reader server script ending
			var ending:String = READERENDING;
			if (this._managanaConfig.isConfig('readerending')) {
				ending = this._managanaConfig.getConfig('readerending');
			}
			// reader server and interface
			var readerserver:String = "";
			var showinterface:Boolean = true;
			var showclock:Boolean = true;
			var showvote:Boolean = false;
			var showcomment:Boolean = false;
			var showrate:Boolean = false;
			var shownote:Boolean = false;
			var showzoom:Boolean = false;
			var showuser:Boolean = false;
			if (this._managanaConfig.isConfig('server')) readerserver = this._managanaConfig.getConfig('server');
			if (this._managanaConfig.isConfig('showinterface')) showinterface = (this._managanaConfig.getConfig('showinterface') == "true");
			if (this._managanaConfig.isConfig('showclock')) showclock = (this._managanaConfig.getConfig('showclock') == "true");
			if (this._managanaConfig.isConfig('showvote')) showvote = (this._managanaConfig.getConfig('showvote') == "true");
			if (this._managanaConfig.isConfig('showcomment')) showcomment = (this._managanaConfig.getConfig('showcomment') == "true");
			if (this._managanaConfig.isConfig('showrate')) showrate = (this._managanaConfig.getConfig('showrate') == "true");
			if (this._managanaConfig.isConfig('shownote')) shownote = (this._managanaConfig.getConfig('shownote') == "true");
			if (this._managanaConfig.isConfig('showzoom')) showzoom = (this._managanaConfig.getConfig('showzoom') == "true");
			if (this._managanaConfig.isConfig('showuser')) showuser = (this._managanaConfig.getConfig('showuser') == "true");
			this._interface = new ManaganaInterface(readerserver, key, method, ending, true, showinterface, showclock, showvote, true, showcomment, showrate, shownote, showzoom, showuser, this.saveOffline, this.getOffline);
			this._interface.addEventListener(Message.OPENURL, onOpenURL);
			this._interface.addEventListener(Message.MESSAGE, onGenericMessage);
			this._interface.addEventListener(ReaderServerEvent.SYSTEM_INFO, onSystemInfo);
			this._interface.addEventListener(ReaderServerEvent.NOSYSTEM, noSystem);
			this._interface.systemNotes = localNotes;
			this._interface.setTCP(new RemoteTCPData());
			if (readerserver != "") {
				this._interface.addEventListener(Message.SHARE_FACEBOOK, onOpenURL);
				this._interface.addEventListener(Message.SHARE_GPLUS, onOpenURL);
				this._interface.addEventListener(Message.SHARE_TWITTER, onOpenURL);
				this._interface.addEventListener(Message.AUTHENTICATE, onAuthenticate);
			}
			// ui setup
			this.addChild(this._interface);
			this._interface.player = this._managana;
			if (this._managanaConfig.isConfig('logo')) if (this._managanaConfig.getConfig('logo') != "") {
				this._interface.setLogo("./pics/" + this._managanaConfig.getConfig('logo'));
			}
			// remote control information available?
			if (this._managanaConfig.isConfig('remotegroup')) this._interface.remoteGroup = this._managanaConfig.getConfig('remotegroup');
			if (this._managanaConfig.isConfig('multicastip')) this._interface.multicastip = this._managanaConfig.getConfig('multicastip');
			if (this._managanaConfig.isConfig('multicastport')) this._interface.multicastport = this._managanaConfig.getConfig('multicastport');
			// public remote control?
			if (this._managanaConfig.isConfig('publicremote')) if (this._managanaConfig.getConfig('publicremote') != "") {
				this._interface.startPublicRemote(this._managanaConfig.getConfig('publicremote'), this._interface.remoteGroup, this._interface.cirrusKey);
			}
			// initial stream
			if (this._managanaConfig.isConfig('stream')) if (this._managanaConfig.getConfig('stream') != "") {
				this._managana.startStream = this._managanaConfig.getConfig('stream');
			}
			// gesture support
			if (Multitouch.inputMode == MultitouchInputMode.GESTURE) {
				this.stage.addEventListener(TransformGestureEvent.GESTURE_ZOOM, onZoom);
				this.stage.addEventListener(TransformGestureEvent.GESTURE_SWIPE, onSwipe);
			}
			// drag
			this.stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			this.stage.addEventListener(MouseEvent.CLICK, onStageClick);
			// link manager
			this._linkmanager = new LinkManagerAIR();
			this._linkmanager.addEventListener(Message.AUTHOK, onAuthOK);
			this._linkmanager.addEventListener(Message.AUTHERROR, onAuthERROR);
			this._linkmanager.addEventListener(Event.CLOSE, onLinkClose);
			this.addChild(this._linkmanager);
			// html box manager
			this._boxmanager = new HTMLBoxAIR();
			this._boxmanager.addEventListener(Event.CLOSE, onHTMLBoxClose);
			this.addChild(this._boxmanager);
			// application flow management
			this._playActivate = true;
			this._framerate = this.stage.frameRate;
			NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, onActivate);
			NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, onDeactivate);
			// geolocation
			this._gps = new GPS(this.gpsUpdate, 2000);
			// check extra fonts
			var fontsFolder:File = File.applicationDirectory.resolvePath("font");
			var fileList:Array = fontsFolder.getDirectoryListing();
			var loaderContext:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
			for (var ifont:uint = 0; ifont < fileList.length; ifont++) {
				var theFile:File = fileList[ifont] as File;
				if ((!theFile.isDirectory) && (theFile.extension == "swf")) {
					var fontLoader:Loader = new Loader();
					fontLoader.load(new URLRequest(theFile.url), loaderContext);
				}
			}
			// start leap data?
			if (this._managanaConfig.getConfig('desktop') == 'true') {
				this._leap = new LeapData(true);
				this._leap.addEventListener(LeapDataEvent.LEAP_CONNECT, onLeapConnect);
				this._leap.addEventListener(LeapDataEvent.LEAP_CALIBRATE, onLeapCalibrated);
				this._leap.addEventListener(LeapDataEvent.LEAP_FRAME, onLeapFrame);
				this._leap.addEventListener(LeapDataEvent.TYPE_SWIPE_NEXTX, onLeapNextX);
				this._leap.addEventListener(LeapDataEvent.TYPE_SWIPE_NEXTY, onLeapNextY);
				this._leap.addEventListener(LeapDataEvent.TYPE_SWIPE_NEXTZ, onLeapNextZ);
				this._leap.addEventListener(LeapDataEvent.TYPE_SWIPE_PREVX, onLeapPrevX);
				this._leap.addEventListener(LeapDataEvent.TYPE_SWIPE_PREVY, onLeapPrevY);
			}
			// internal webserver
			this._webserver = new HTTPServer();
			this._webserver.start(uint(this._managanaConfig.getConfig('webserverport')), this.filePath(''));
			// websockets server
			this._websocket = new WebSocketsServer();
			this._websocket.addEventListener(WebsocketEvent.NEWCLIENT, onWebsocketNew);
			this._websocket.addEventListener(WebsocketEvent.CLIENTCLOSE, onWebsocketClose);
			this._websocket.addEventListener(WebsocketEvent.RECEIVED, onWebsocketReceived);
			this._websocket.addEventListener(Event.COMPLETE, onWebsocketReady);
			this._websocket.bind(TCPServer.ipv4, uint(this._managanaConfig.getConfig('websocketport')));
			// system specific controllers (none yet)
			this._system = new Array();
			// qr code reading
			this._qrcode = new QrCodeReader(stage.stageWidth, stage.stageHeight, this._managana.pCodeParser, new CloseQRCode() as Sprite);
			this._qrcode.addEventListener(Event.CLOSE, onQRCodeClose);
			
			// show debug?
			if (Main.DEBUGGING) this.stage.addChild(Main.debugWindow);
		}
		
		/**
		 * System information received, start community load.
		 */
		private function onSystemInfo(evt:ReaderServerEvent):void {
			this._interface.removeEventListener(ReaderServerEvent.SYSTEM_INFO, onSystemInfo);
			this._interface.removeEventListener(ReaderServerEvent.NOSYSTEM, noSystem);
			this._managana.addEventListener(DISLoad.COMMUNITY_OK, onCommunityOK);
			this._managana.loadCommunity(this._managanaConfig.getConfig('community'));
		}
		
		/**
		 * No system information: check offline options.
		 */
		private function noSystem(evt:ReaderServerEvent):void {
			if (this._waiting != null) {
				this.removeChild(this._waiting);
				this._waiting.kill();
				this._waiting = null;
			}
			this._interface.removeEventListener(ReaderServerEvent.SYSTEM_INFO, onSystemInfo);
			this._interface.removeEventListener(ReaderServerEvent.NOSYSTEM, noSystem);
			// is the index community available offline?
			if (this.checkLocal(this._managanaConfig.getConfig('community')) != "") {
				this._managana.addEventListener(DISLoad.COMMUNITY_OK, onCommunityOK);
				this._managana.loadCommunity(this._managanaConfig.getConfig('community'));
				this._interface.workOffline();
			} else {
				// is there any offline content available?
				if (evt.message == "true") {
					// show offline content window
					this._managana.addEventListener(DISLoad.COMMUNITY_OK, onCommunityOK);
					this._interface.showOfflineOptions();
				} else {
					// no way, halt app
					this._interface.halt();
				}
			}
		}
		
		/**
		 * Prepare a file path to Managana offline content.
		 * @param	path	the original path to convert
		 * @return	a file reference to the offline file
		 */
		private function filePath(path:String):File {
			if (this._managanaConfig.onRemovable) {
				return (new File(File.applicationDirectory.nativePath + File.separator + this._managanaConfig.localStorage.replace(/\//gi, File.separator) + path.replace(/\//gi, File.separator)));
			} else {
				var file:File = File.documentsDirectory.resolvePath(this._managanaConfig.localStorage + path);
				file.preventBackup = true;
				return (file);
			}
		}
		
		/**
		 * Check if the requested community is available locally and return its path if so.
		 * @param	community	the community id
		 * @return	the community files path if it is available locally or an empty string if not
		 */
		private function checkLocal(community:String):String {
			// check cache directory
			var path:String = "";
			var check:File = filePath("/community/" + community + ".dis/dis.xml");
			if (check.exists) {
				check = filePath("/community/" + community + ".dis/downloading.dat");
				if (!check.exists) path = filePath("/community/" + community + ".dis").url;
			}
			if (path == "") {
				// check application directory
				check = File.applicationDirectory.resolvePath("community/" + community + ".dis/dis.xml");
				if (check.exists) path = File.applicationDirectory.resolvePath("community/" + community + ".dis").url;
			}
			return (path);
		}
		
		/**
		 * Access user variables data from disk.
		 * @param	ac	action: "save" or "load"
		 * @param	community	current community
		 * @param	strValues	string user values
		 * @param	numValues	number user values
		 * @return	an array with two string indexes: "strValues" and "numValues"
		 */
		private function localUserData(ac:String, community:String, strValues:String = null, numValues:String = null):Array {
			// prepare path and file
			var localData:File = filePath("/data/variables");
			localData.preventBackup = false;
			if (!localData.isDirectory) localData.createDirectory();
			localData = filePath("/data/variables/var_" + community + ".xml");
			localData.preventBackup = false;
			var localStream:FileStream = new FileStream();
			// check for first run
			if (!localData.exists) {
				localStream.open(localData, FileMode.WRITE);
				localStream.writeUTFBytes('<?xml version="1.0" encoding="utf-8"?><data><strValues><![CDATA[]]></strValues><numValues><![CDATA[]]></numValues></data>');
				localStream.close();
			}
			// open current data
			localStream.open(localData, FileMode.READ);
			var localDataText:String = localStream.readUTFBytes(localStream.bytesAvailable);
			localStream.close();
			var localXML:XML;
			try {
				localXML = new XML(localDataText);
			} catch (e:Error) {
				// corrupted data
				localXML = new XML('<?xml version="1.0" encoding="utf-8"?><data><strValues><![CDATA[]]></strValues><numValues><![CDATA[]]></numValues></data>');
			}
			// save data?
			if (ac == "save") {
				localDataText = '<?xml version="1.0" encoding="utf-8"?><data>';
				if (strValues == null) {
					localDataText += '<strValues><![CDATA[' + String(localXML.strValues) + ']]></strValues>';
				} else {
					localXML.strValues = strValues;
					localDataText += '<strValues><![CDATA[' + strValues + ']]></strValues>';
				}
				if (numValues == null) {
					localDataText += '<numValues><![CDATA[' + String(localXML.numValues) + ']]></numValues>';
				} else {
					localXML.numValues = numValues;
					localDataText += '<numValues><![CDATA[' + numValues + ']]></numValues>';
				}
				localDataText += '</data>';
				localStream.open(localData, FileMode.WRITE);
				localStream.writeUTFBytes(localDataText);
				localStream.close();
			}
			// return data
			var ret:Array = new Array();
			ret['strValues'] = String(localXML.strValues);
			ret['numValues'] = String(localXML.numValues);
			System.disposeXML(localXML);
			return (ret);
		}
		
		/**
		 * Access user variables data from disk.
		 * @param	ac	action: "save" or "load"
		 * @param	note	the notes information
		 * @param	user	the user (null for general notes)
		 * @return	the current notes information
		 */
		private function localNotes(ac:String, note:String = null, user:String = null):String {
			// prepare path and file
			var localData:File = filePath("/data/variables");
			localData.preventBackup = false;
			if (!localData.isDirectory) localData.createDirectory();
			if (user == null) {
				localData = filePath("/data/variables/notes.xml");
			} else {
				user = user.replace("@", ".");
				localData = filePath("/data/variables/notes_" + user + ".xml");
			}
			localData.preventBackup = false;
			var localStream:FileStream = new FileStream();
			// check for first run
			if (!localData.exists) {
				localStream.open(localData, FileMode.WRITE);
				localStream.writeUTFBytes('<?xml version="1.0" encoding="utf-8"?><data><note><![CDATA[]]></note></data>');
				localStream.close();
			}
			// open current data
			localStream.open(localData, FileMode.READ);
			var localDataText:String = localStream.readUTFBytes(localStream.bytesAvailable);
			localStream.close();
			var localXML:XML;
			try {
				localXML = new XML(localDataText);
			} catch (e:Error) {
				// corrupted data
				localXML = new XML('<?xml version="1.0" encoding="utf-8"?><data><note><![CDATA[]]></note></data>');
			}
			// save data?
			if (ac == "save") {
				localDataText = '<?xml version="1.0" encoding="utf-8"?><data>';
				if (note == null) {
					localDataText += '<note><![CDATA[' + String(localXML.note) + ']]></note>';
				} else {
					localXML.note = note;
					localDataText += '<note><![CDATA[' + note + ']]></note>';
				}
				localDataText += '</data>';
				localStream.open(localData, FileMode.WRITE);
				localStream.writeUTFBytes(localDataText);
				localStream.close();
			}
			// return data
			var ret:String = String(localXML.note);
			System.disposeXML(localXML);
			return (ret);
		}
		
		/**
		 * Save offline content.
		 * @param	what	what information to save
		 */
		private function saveOffline(what:Object):void {
			var file:File;
			var fstream:FileStream;
			switch (what.action) {
				case "savelist":
					file = filePath("/data/list.xml");
					fstream = new FileStream();
					fstream.open(file, FileMode.WRITE);
					fstream.writeUTFBytes('<?xml version="1.0" encoding="utf-8"?>' + what.data.toString());
					fstream.close();
					break;
				case "savefilelist":
					file = filePath("/data/online/filelist_" + what.community + ".xml");
					fstream = new FileStream();
					fstream.open(file, FileMode.WRITE);
					fstream.writeUTFBytes(what.filelist);
					fstream.close();
					break;
				case "savelocalfiles":
					file = filePath("/data/offline/filelist_" + what.community + ".xml");
					fstream = new FileStream();
					fstream.open(file, FileMode.WRITE);
					fstream.writeUTFBytes('<?xml version="1.0" encoding="utf-8"?>' + what.data.toString());
					fstream.close();
					break;
				case "downloadfile":
					if (this._managanaConfig.getConfig('desktop') != 'true') NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
					file = filePath("/community/" + what.community + ".dis/");
					this._downloadPos = 0;
					this._downloadFinish = what.endFunction;
					file = filePath("/community/" + what.community + ".dis/" + String(what.file).replace("./", ""));
					this._downloadStream.openAsync(file, FileMode.WRITE);
					this._remoteStream.load(new URLRequest(this._managanaConfig.getConfig("server") + "/community/" + what.community + ".dis/" + String(what.file).replace("./", "")));
					break;
				case "downloadstart":
					file = filePath("/community/" + what.community + ".dis/");
					if (!file.isDirectory) file.createDirectory();
					file = filePath("/community/" + what.community + ".dis/downloading.dat");
					fstream = new FileStream();
					fstream.open(file, FileMode.WRITE);
					fstream.writeUTFBytes("downloading");
					fstream.close();
					break;
				case "downloadfinish":
					file = filePath("/community/" + what.community + ".dis/downloading.dat");
					if (file.exists) file.deleteFile();
					if (this._managanaConfig.getConfig('desktop') != 'true') NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
					break;
				case "stopdownload":
					if (this._remoteStream.connected) {
						this._downloadFinish = null;
						try {
							this._remoteStream.close();
							this._downloadStream.close();
						} catch (e:Error) { }
					}
					break;
				case "delete":
					file = filePath("/community/temp_" + what.community + ".dis/");
					if (file.exists) {
						file.deleteDirectory(true);
					}
					file = filePath("/community/" + what.community + ".dis/");
					if (file.exists) {
						file.deleteDirectory(true);
					}
					file = filePath("/data/offline/filelist_" + what.community + ".xml");
					if (file.exists) {
						file.deleteFile();
					}
					file = filePath("/data/online/filelist_" + what.community + ".xml");
					if (file.exists) {
						file.deleteFile();
					}
					break;
			}
		}
		
		/**
		 * Error while downloading file for offline access.
		 */
		private function onRemoteStreamError(evt:Event):void {
			if (this._downloadFinish != null) this._downloadFinish(false);
		}
		
		/**
		 * File download finished.
		 */
		private function onRemoteStreamComplete(evt:Event):void {
			try {
				this._remoteStream.close();
				this._downloadStream.close();
			} catch (e:Error) { }
			if (this._downloadFinish != null) this._downloadFinish(true);
		}
		
		/**
		 * File download progress update.
		 */
		private function onRemoteStreamProgress(evt:ProgressEvent):void {
			var bytes:ByteArray = new ByteArray();
			var start:uint = this._downloadPos;
			this._downloadPos += this._remoteStream.bytesAvailable;
			this._remoteStream.readBytes(bytes, start);
			this._downloadStream.writeBytes(bytes, start);
		}
		
		/**
		 * Get offline content.
		 * @param	what	what information to get
		 * @return	the requested information
		 */
		private function getOffline(what:Object):String {
			var ret:String = "";
			var file:File;
			var fstream:FileStream;
			switch (what.action) {
				case "getlist":
					// is there an offline list?
					file = filePath("/data/list.xml");
					fstream = new FileStream();
					if (!file.exists) {
						// create an empty list file
						ret = '<?xml version="1.0" encoding="utf-8"?><data></data>';
						fstream.open(file, FileMode.WRITE);
						fstream.writeUTFBytes(ret);
					} else {
						// read current file
						fstream.open(file, FileMode.READ);
						ret = fstream.readUTFBytes(fstream.bytesAvailable);
						// is loaded data corrupted?
						try {
							var xml:XML = new XML(ret);
							System.disposeXML(xml);
						} catch (e:Error) {
							// reset list contents
							fstream.close();
							ret = '<?xml version="1.0" encoding="utf-8"?><data></data>';
							fstream.open(file, FileMode.WRITE);
							fstream.writeUTFBytes(ret);
						}
					}
					fstream.close();
					break;
				case "checkremotefiles":
					file = filePath("/data/online/filelist_" + what.community + ".xml");
					if (file.exists) ret = "ok";
						else ret = "error";
					break;
				case "getremotefiles":
					file = filePath("/data/online/filelist_" + what.community + ".xml");
					if (file.exists) {
						fstream = new FileStream();
						fstream.open(file, FileMode.READ);
						ret = fstream.readUTFBytes(fstream.bytesAvailable);
						fstream.close();
					} else {
						ret = "error";
					}
					break;
				case "getlocalfiles":
					file = filePath("/data/offline/filelist_" + what.community + ".xml");
					fstream = new FileStream();
					if (file.exists) {
						fstream.open(file, FileMode.READ);
						ret = fstream.readUTFBytes(fstream.bytesAvailable);
					} else {
						ret = '<?xml version="1.0" encoding="utf-8"?><filelist></filelist>';
						fstream.open(file, FileMode.WRITE);
						fstream.writeUTFBytes(ret);
					}
					fstream.close();
					break;
			}
			return (ret);
		}
		
		/**
		 * The community is ready.
		 */
		private function onCommunityOK(evt:DISLoad):void {
			if (this._waiting != null) {
				this.removeChild(this._waiting);
				this._waiting.kill();
				this._waiting = null;
			}
			this.onResize();
		}
		
		/**
		 * Open an URL sent from managana player.
		 */
		private function onOpenURL(evt:Message):void {
			this.stage.frameRate = 10;
			this._playActivate = this._managana.playing;
			this._managana.pause();
			this._linkmanager.setComSize(this._managana.currentCommunityWidth, this._managana.currentCommunityHeight);
			this._linkmanager.openURL(String(evt.param.value));
		}
		
		/**
		 * Open a HTML box over the Managana interface.
		 */
		private function onHTMLBox(evt:Message):void {
			this.stage.frameRate = 10;
			this._playActivate = this._managana.playing;
			this._managana.pause();
			this._boxmanager.setComSize(this._managana.currentCommunityWidth, this._managana.currentCommunityHeight);
			switch (this._managana.lastComProtocol) {
				case DISLoadProtocol.PROTOCOL_APP:
					this._boxmanager.openURL('http://localhost:' + this._managanaConfig.getConfig('webserverport') + '/cache/community/' + this._managana.currentCommunity + '.dis/' + String(evt.param.folder) + '/index.html');
					break;
				case DISLoadProtocol.PROTOCOL_FILE:
					this._boxmanager.openURL('http://localhost:' + this._managanaConfig.getConfig('webserverport') + '/community/' + (this._managana.currentCommunity) + ".dis/media/" + evt.param.from + "/html/" +  String(evt.param.folder) + "/index.html");
					break;
				case DISLoadProtocol.PROTOCOL_HTTP:
				case DISLoadProtocol.PROTOCOL_UNKNOWN:
					this._boxmanager.openURL(this._managanaConfig.getConfig('server') + "community/" + this._managana.currentCommunity + ".dis/media/" + evt.param.from + "/html/" +  String(evt.param.folder) + "/index.html");
					break;
			}
		}
		
		/**
		 * Process a generic message recceived from the player.
		 * @param	evt	the message information
		 */
		private function onGenericMessage(evt:Message):void {
			if (evt.param != null) {
				if (evt.param.ac != null) {
					switch (String(evt.param.ac)) {
						case "readQRCode":
							this.startQRCodeReading();
							break;
						case "showRemoteInfo":
							if (this._websocket.ready) {
								this._interface.showQRCode('http://' + TCPServer.ipv4 + ':' + this._managanaConfig.getConfig('webserverport') + '/cache/remote/index.html');
								this._interface.closeInterface();
							}
							break;
					}
				}
			}
		}
		
		/**
		 * Authenticate user.
		 */
		private function onAuthenticate(evt:Message):void {
			this.stage.frameRate = 10;
			this._playActivate = this._managana.playing;
			this._managana.pause();
			this._linkmanager.authenticate(evt.param.value);
		}
		
		/**
		 * Stage resize.
		 */
		private function onResize(evt:Event = null):void {
			if (this._bg != null) {
				this._bg.width = this.stage.stageWidth;
				this._bg.height = this.stage.stageHeight;
			}
			if (this._managana != null) {
				var wToUse:Number = this.stage.stageWidth;
				var hToUse:Number = this.stage.stageHeight;
				if (wToUse > hToUse) {
					this._managana.aspect = "landscape";
				} else {
					this._managana.aspect = "portrait";
				}
				this._managana.width = wToUse;
				this._managana.height = this._managana.width * this._managana.screenheight / this._managana.screenwidth;
				if (this._managana.height > hToUse) {
					this._managana.height = hToUse;
					this._managana.width = this._managana.height * this._managana.screenwidth / this._managana.screenheight;
				}
				this._managana.x = wToUse / 2;
				this._managana.y = hToUse / 2;
				if (this._interface != null) this._interface.redraw();
			}
			if (this._qrcode != null) {
				this._qrcode.resize(stage.stageWidth, stage.stageHeight);
			}
		}
		
		/**
		 * Zoom gesture.
		 */
		private function onZoom(evt:TransformGestureEvent):void {
			if (!this._linkmanager.visible && !this._boxmanager.visible) {
				this._managana.scaleX *= evt.scaleX;
				this._managana.scaleY = this._managana.scaleX;
			}
		}
		
		/**
		 * Swipe gesture.
		 */
		private function onSwipe(evt:TransformGestureEvent):void {
			if (!this._linkmanager.visible && !this._boxmanager.visible && this._managana.allowDrag) {
				if (!Main.dragging) {
					clearTimeout(Main.drinterval);
					if (evt.offsetX == 1) this._managana.navigateTo('xprev');
						else if (evt.offsetX == -1) this._managana.navigateTo('xnext');
						else if (evt.offsetY == 1) this._managana.navigateTo('ynext');
						else if (evt.offsetY == -1) this._managana.navigateTo('yprev');
				}
			}
		}
		
		/**
		 * Mouse down on stage.
		 */
		private function onStageMouseDown(evt:MouseEvent):void {
			if (!this._linkmanager.visible) {
				// wait to check if the user wants to drag managana
				Main.dragging = false;
				this._managana.mouseChildren = true;
				Main.drinterval = setTimeout(managanaDrag, 200);
			}
		}
		
		/**
		 * Mouse click on stage.
		 */
		private function onStageClick(evt:MouseEvent):void {
			// there is a recent click
			if (Main.recentclick) {
				Main.recentclick = false;
				this._managana.scaleX = 1;
				this._managana.scaleY = 1;
				this._managana.x = this.stage.stageWidth / 2;
				this._managana.y = this.stage.stageHeight / 2;
			} else {
				Main.recentclick = true;
				Main.clickinterval = setTimeout(managanaClick, 200);
			}
		}
		
		/**
		 * Release recent click flag.
		 */
		private function managanaClick():void {
			Main.recentclick = false;
		}
		
		/**
		 * Start managana drag.
		 */
		private function managanaDrag():void {
			if (this._managana.allowDrag) {
				Main.dragging = true;
				this._managana.mouseChildren = false;
				this._managana.startDrag();
			}
		}
		
		/**
		 * Mouse up on stage / stop managana drag.
		 */
		private function onStageMouseUp(evt:MouseEvent):void {
			if (!this._linkmanager.visible) {
				if (!Main.dragging) {
					clearTimeout(Main.drinterval);
				}
				Main.dragging = false;
				this._managana.stopDrag();
				this._managana.mouseChildren = true;
			}
		}
		
		/**
		 * Successfull authentication.
		 */
		private function onAuthOK(evt:Message):void {
			this.stage.frameRate = this._framerate;
			if (this._playActivate) this._managana.play();
			this._interface.doOpenLogin(evt.param.key);
		}
		
		/**
		 * Error on authentication.
		 */
		private function onAuthERROR(evt:Message):void {
			this.stage.frameRate = this._framerate;
			if (this._playActivate) this._managana.play();
		}
		
		/**
		 * Link manager window was closed.
		 */
		private function onLinkClose(evt:Event):void {
			this.stage.frameRate = this._framerate;
			if (this._playActivate) this._managana.play();
		}
		
		/**
		 * HTML box manager window was closed.
		 */
		private function onHTMLBoxClose(evt:Event):void {
			this.stage.frameRate = this._framerate;
			if (this._playActivate) this._managana.play();
			if (this._boxmanager.pcode != "") {
				this._managana.run(this._boxmanager.pcode);
			}
			this._boxmanager.pcode = "";
		}
		
		/**
		 * Activate application on user return.
		 */
		private function onActivate(evt:Event):void {
			if (this._managanaConfig.getConfig("desktop") != "true") if (this._managanaConfig.isConfig('sleep')) {
				if (this._managanaConfig.getConfig('sleep') == "false") {
					// do nothing: app must not be deactivated
				} else {
					if (this._managana != null) {
						this.stage.frameRate = this._framerate;
						if (this._playActivate) this._managana.play();
					}
				}
			}
			if (this._interface != null) this._interface.checkContent();
			//restore fullscreen after some time
			setTimeout(restoreFullScreen, 500);
		}
		
		/**
		 * Restore full screen after app re-activation.
		 */
		private function restoreFullScreen():void {
			if (this.stage != null) this.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
		}
		
		/**
		 * Deactivate application when the user leaves.
		 */
		private function onDeactivate(evt:Event):void {
			if (this._managanaConfig.getConfig("desktop") != "true") if (this._managanaConfig.isConfig('sleep')) {
				if (this._managanaConfig.getConfig('sleep') == "false") {
					// do nothing: app must not be deactivated
				} else {
					if (this._managana != null) {
						this._playActivate = this._managana.playing;
						this._managana.pause();
						this.stage.frameRate = 1;
					}
					this.saveOffline( { action: "stopdownload" } );
				}
			}
		}
		
		/**
		 * Geolocation data update.
		 */
		private function gpsUpdate():void {
			this._managana.setGeodata(this._gps.latitude, this._gps.longitude);
		}

		/**
		 * Leap event: leap motion device connected.
		 */
		private function onLeapConnect(evt:LeapDataEvent):void {
			// change target mode
			this._managana.targetMode = Target.INTERACTION_REMOTE;
			// check previous calibration data
			var deleteit:Boolean = false;
			var leapInfo:File = filePath("/data/leapinfo.xml");
			if (leapInfo.exists) {
				var leapstream:FileStream = new FileStream();
				leapstream.open(leapInfo, FileMode.READ);
				try {
					var leapcdata:XML = new XML(leapstream.readUTFBytes(leapstream.bytesAvailable));
					if (!isNaN(leapcdata.xmin) && !isNaN(leapcdata.xmax) && !isNaN(leapcdata.ymin) && !isNaN(leapcdata.ymax)) {
						this._leap.setCalibration(Number(leapcdata.xmin), Number(leapcdata.xmax), Number(leapcdata.ymin), Number(leapcdata.ymax));
					} else {
						// corrupted config: delete it
						deleteit = true;
					}
					System.disposeXML(leapcdata);
				} catch (e:Error) {
					// do nothing
				}
				leapstream.close();
				if (deleteit) leapInfo.deleteFile();
			}
		}
		
		/**
		 * Leap event: new frame data.
		 */
		private function onLeapFrame(evt:LeapDataEvent):void {
			// hand detected?
			if (this._leap.handsDetected) if (this._leap.numFingers0 > 0) {
				// place target according to the finger
				this._managana.setTarget(this._leap.fingers0[0].x, (100 - this._leap.fingers0[0].y));
			}
		}
			
		/**
		 * Leap event: next stream on X axis.
		 */
		private function onLeapNextX(evt:LeapDataEvent):void {
			this._managana.navigateTo('xnext');
		}
		
		/**
		 * Leap event: next stream on Y axis.
		 */
		private function onLeapNextY(evt:LeapDataEvent):void {
			this._managana.navigateTo('ynext');
		}
		
		/**
		 * Leap event: previous stream on X axis.
		 */
		private function onLeapPrevX(evt:LeapDataEvent):void {
			this._managana.navigateTo('xprev');
		}
		
		/**
		 * Leap event: previous stream on Y axis.
		 */
		private function onLeapPrevY(evt:LeapDataEvent):void {
			this._managana.navigateTo('yprev');
		}
		
		/**
		 * Leap event: next stream on Z axis = play/pause
		 */
		private function onLeapNextZ(evt:LeapDataEvent):void {
			if (this._managana.playing) this._managana.pause();
				else (this._managana.play());
		}
		
		/**
		 * Leap event: device calibrated.
		 */
		private function onLeapCalibrated(evt:LeapDataEvent):void {
			if (!isNaN(this._leap.calibration.xmin) && !isNaN(this._leap.calibration.xmax) && !isNaN(this._leap.calibration.ymin) && !isNaN(this._leap.calibration.ymax)) {
				var leapInfo:File = filePath("/data/leapinfo.xml");
				var leapstream:FileStream = new FileStream();
				leapstream.open(leapInfo, FileMode.WRITE);
				leapstream.writeUTFBytes('<?xml version="1.0" encoding="utf-8"?><data>');
				leapstream.writeUTFBytes('<xmin>' + this._leap.calibration.xmin + '</xmin>');
				leapstream.writeUTFBytes('<xmax>' + this._leap.calibration.xmax + '</xmax>');
				leapstream.writeUTFBytes('<ymin>' + this._leap.calibration.ymin + '</ymin>');
				leapstream.writeUTFBytes('<ymax>' + this._leap.calibration.ymax + '</ymax>');
				leapstream.writeUTFBytes('<zmin>' + this._leap.calibration.zmin + '</zmin>');
				leapstream.writeUTFBytes('<zmax>' + this._leap.calibration.zmax + '</zmax>');
				leapstream.writeUTFBytes('</data>');
				leapstream.close();
			}
		}
		
		/**
		 * Start the qrcode reading interface.
		 */
		private function startQRCodeReading():void {
			if (this._managanaConfig.getConfig("desktop") != "true") {
				this._managana.pause();
				this._qrcode.startReading();
				stage.addChild(this._qrcode);
			}
		}
		
		/**
		 * QRCode reading interface was closed.
		 */
		private function onQRCodeClose(evt:Event):void {
			stage.removeChild(this._qrcode);
			this._managana.play();
		}
		
		/**
		 * Prevent change from fullscreen on desktop application.
		 */
		private function displayStateChanged(evt:FullScreenEvent):void {
			evt.preventDefault();
		}
		
		/**
		 * Keyboard interaction.
		 */
		private function onKeyDown(evt:KeyboardEvent):void {
			switch (evt.keyCode) {
				case Keyboard.ESCAPE:
					// exit app on esc (not only go back to windowed mode)
					if (this._managanaConfig.getConfig('desktop') == "true") NativeApplication.nativeApplication.exit();
					break;
				case Keyboard.F3:
					// show leap motion calibration
					if (this._managanaConfig.getConfig('desktop') == "true") if (this._leap != null) if (this._leap.ready) this._leap.calibrate(this.stage, this._interface.getText('LEAPCALIBRATING'), this._interface.getText('LEAPERROR'), this._interface.getText('LEAPSUCCESS'), this._interface.getText('LEAPPOINTTL'), this._interface.getText('LEAPPOINTBR'));
					break;
			}
		}
		
		/**
		 * A new client just connected to the websocket interface.
		 */
		private function onWebsocketNew(evt:WebsocketEvent):void {
			this._interface.closeQRCode();
		}
		
		/**
		 * A websocket client closed connection.
		 */
		private function onWebsocketClose(evt:WebsocketEvent):void {
			trace ('websocket client close');
		}
		
		/**
		 * A message was received from the websocket interface.
		 */
		private function onWebsocketReceived(evt:WebsocketEvent):void {
			trace ('websocket message received: ' + evt.message);
		}
		
		/**
		 * The websocket interface is ready.
		 */
		private function onWebsocketReady(evt:Event):void {
			// create javascript websocket info file on webserver cache folder
			var infoFile:File = filePath("/websocket.js");
			var fileContent:String = "var webSocketAddress = '" + this._websocket.ipv4Address + "';\n";
			var fstream:FileStream = new FileStream();
			fstream.open(infoFile, FileMode.WRITE);
			fstream.writeUTFBytes(fileContent);
			fstream.close();
		}
		
		// STATIC METHODS
		
		/**
		 * Add a line to the debug display.
		 * @param	text	the string to add to debug
		 */
		public static function addDebug(text:String):void {
			if (Main.DEBUGGING) Main.debugWindow.out(text);
		}
		
	}
	
}