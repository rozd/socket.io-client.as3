/**
 * Created by max.rozdobudko@gmail.com on 11/12/17.
 */
package skein.engine.io.client.transport.websocket {
import flash.system.Security;

import net.gimite.websocket.IWebSocketLogger;
import net.gimite.websocket.WebSocket;
import net.gimite.websocket.WebSocketEvent;

import skein.core.WeakReference;
import skein.logger.Log;
import skein.utils.delay.callLater;

public class WebSocketClient implements IWebSocketLogger {

    // Constructor

    public function WebSocketClient(uri: String, protocols:Array, proxyHost:String = null, proxyPort:int = 0, headers:String = null) {
        super();

        callLater(function (): void {
            create(uri, protocols, proxyHost, proxyPort, headers);
        });
    }

    // Delegate

    private var _delegate: WeakReference;
    public function get delegate(): WebSocketClientDelegate {
        return _delegate ? _delegate.value : null;
    }
    public function set delegate(value: WebSocketClientDelegate): void {
        _delegate = new WeakReference(value);
    }

    // Variables

    private var webSocket: WebSocket;

    private var debug:Boolean = false;
    private var manualPolicyFileLoaded:Boolean = false;

    protected function create(url:String, protocols:Array, proxyHost:String = null, proxyPort:int = 0, headers:String = null):void {
        if (!manualPolicyFileLoaded) {
            loadDefaultPolicyFile(url);
        }

        var newSocket:WebSocket = new WebSocket(getId(), url, protocols, getOrigin(), proxyHost, proxyPort, getCookie(url), headers, this);
        newSocket.addEventListener(WebSocketEvent.OPEN, socketOpenHandler);
        newSocket.addEventListener(WebSocketEvent.CLOSE, socketCloseHandler);
        newSocket.addEventListener(WebSocketEvent.ERROR, socketErrorHandler);
        newSocket.addEventListener(WebSocketEvent.MESSAGE, socketMessageHandler);
        webSocket = newSocket;
    }

    public function send(encData:String):int {
        return webSocket.send(encData);
    }

    public function close():void {
        webSocket.close();
    }

    // Load Policy

    private function loadDefaultPolicyFile(wsUrl:String):void {
        var policyUrl:String = "xmlsocket://" + getHostname() + ":843";
        log("policy file: " + policyUrl);
        Security.loadPolicyFile(policyUrl);
    }

    public function loadManualPolicyFile(policyUrl:String):void {
        log("policy file: " + policyUrl);
        Security.loadPolicyFile(policyUrl);
        manualPolicyFileLoaded = true;
    }

    // Connection Options

    protected function getId(): int {
        return delegate.webSocketClientID();
    }
    protected function getHostname(): String {
        return delegate.webSocketClientHostname();
    }

    protected function getOrigin(): String {
        return delegate.webSocketClientOrigin();
    }

    protected function getCookie(url: String): String {
        return delegate.webSocketClientCookie();
    }

    // Parse Data

    private function parseEvent(event:WebSocketEvent):Object {
        var webSocket:WebSocket = event.target as WebSocket;
        var eventObj:Object = {};
        eventObj.type = event.type;
        eventObj.webSocketId = webSocket.getId();
        eventObj.readyState = webSocket.getReadyState();
        eventObj.protocol = webSocket.getAcceptedProtocol();
        if (event.message !== null) {
            eventObj.message = event.message;
        }
        if (event.wasClean) {
            eventObj.wasClean = event.wasClean;
        }
        if (event.code) {
            eventObj.code = event.code;
        }
        if (event.reason !== null) {
            eventObj.reason = event.reason;
        }
        return eventObj;
    }

    // Handlers

    private function socketOpenHandler(event: WebSocketEvent): void {
        if (delegate) {
            delegate.webSocketClientDidOpen();
        }
    }

    private function socketCloseHandler(event: WebSocketEvent): void {
        if (delegate) {
            delegate.webSocketClientDidClose();
        }
    }

    private function socketErrorHandler(event: WebSocketEvent): void {
        if (delegate) {
            delegate.webSocketClientDidError();
        }
    }

    private function socketMessageHandler(event: WebSocketEvent): void {
        if (delegate) {
            delegate.webSocketClientDidMessage(event.message);
        }
    }

    // <IWebSocketLogger>

    public function log(message: String): void {
        if (debug) {
            Log.d("engine.io", message);
        }
    }

    public function error(message: String): void {
        Log.d("engine.io", message);
    }
}
}
