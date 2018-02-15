/**
 * Created by max.rozdobudko@gmail.com on 11/12/17.
 */
package skein.engine.io.client.transport {
import flash.events.Event;
import flash.system.Security;

import skein.engine.io.client.Transport;
import skein.engine.io.client.TransportOptions;
import skein.engine.io.client.transport.websocket.WebSocketClient;
import skein.engine.io.client.transport.websocket.WebSocketClientDelegate;
import skein.engine.io.parser.Packet;
import skein.engine.io.parser.Parser;

public class WebSocketTransport extends Transport implements WebSocketClientDelegate {

    public static const NAME:String = "websocket";

    // Constructor

    public function WebSocketTransport(opts:TransportOptions) {
        super(opts);
        this.name = NAME;
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var socket:WebSocketClient;

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    protected function get uri():String
    {
        var query:Object = this.query || new Object();

        var schema:String = this.secure ? "wss" : "ws";

        var port:String = "";

        if (this.port > 0 && (schema == "wss" && this.port != 443) || (schema == "ws" && this.port != 80))
        {
            port = ":" + this.port;
        }

        if (this.timestampRequests)
        {
            query[this.timestampParam] = new Date().getTime();
        }

        var params:Array = [];

        for (var p:String in query)
        {
            params.push(p + "=" + query[p]);
        }

        var q:String = "";

        if (params.length > 0)
        {
            q = "?" + params.join("&");
        }

        return schema + "://" + this.hostname + port + this.path + q;
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    override protected function doOpen():void
    {
        if (!this.check())
            return;

        socket = new WebSocketClient(uri, []);
        socket.delegate = this;
    }

    override protected function write(packets:Array):void
    {
        for each (var packet:Packet in packets)
        {
            socket.send(Parser.encodePacket(packet));
        }

        writable = true;
        emit(EVENT_DRAIN);
    }

    override protected function onClose():void
    {
        super.onClose();
    }

    override protected function doClose():void
    {
        if (socket != null)
        {
            socket.close();
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    private function check():Boolean
    {
        return true;
    }

    // <WebSocketClientDelegate>

    public function webSocketClientID(): int {
        return 0;
    }

    public function webSocketClientHostname(): String {
        return hostname;
    }

    public function webSocketClientOrigin(): String {
        return (secure ? "https" : "http") + "://" + hostname;
    }

    public function webSocketClientCookie(): String {
        return "";
    }

    public function webSocketClientDidOpen(): void {
        var headers:Array = [];
        emit(EVENT_RESPONSE_HEADERS, headers);
        onOpen();
    }

    public function webSocketClientDidClose(): void {
        onClose();
    }

    public function webSocketClientDidError(): void {
        onError("websocket error", new Error());
    }

    public function webSocketClientDidMessage(message: String): void {
        onData(message);
    }
}
}