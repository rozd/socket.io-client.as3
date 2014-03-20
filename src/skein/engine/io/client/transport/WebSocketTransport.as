/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/27/14
 * Time: 11:06 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.client.transport
{
import flash.events.Event;
import flash.system.Security;

import skein.engine.io.client.Transport;
import skein.engine.io.client.TransportOptions;
import skein.engine.io.parser.Packet;
import skein.engine.io.parser.Parser;

public class WebSocketTransport extends Transport
{
    public static const NAME:String = "websocket";

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    public function WebSocketTransport(opts:TransportOptions)
    {
        super(opts);
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var socket:WebSocket;

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

        var origin:String = (secure ? "https" : "http") + "://" + hostname;

        loadDefaultPolicyFile();
        socket = new WebSocket(new WebSocketWrapper(origin), uri, null);
        socket.addEventListener("event", socketHandler);
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

    protected function loadDefaultPolicyFile():void
    {
        var policyUrl:String = "xmlsocket://" + this.hostname + ":843";

        Security.loadPolicyFile(policyUrl);
    }

    private function check():Boolean
    {
        return true;
    }

    //--------------------------------------------------------------------------
    //
    //  Handlers
    //
    //--------------------------------------------------------------------------

    private function socketHandler(e:Event):void
    {
        var events:Array = socket.receiveEvents();

        var event:Object = events[0];

        switch (event.type)
        {
            case "open" :

                var headers:Array = [];

                emit(EVENT_RESPONSE_HEADERS, headers);

                onOpen();

                break;

            case "close" :

                socket.removeEventListener("event", socketHandler);

                onClose();

                break;

            case "message" :

                onData(event.data);

                break;

            case "error" :

                onError("websocket error", new Error());

                break;
        }
    }
}
}

class WebSocketWrapper implements IWebSocketWrapper
{
    public function WebSocketWrapper(origin:String, debug:Boolean=true)
    {
        super();

        this.origin = origin;
        this.debug = debug;
    }

    private var origin:String;
    private var debug:Boolean;

    public function getOrigin():String
    {
        return origin;
    }

    public function getCallerHost():String
    {
        return null;
    }

    public function log(message:String):void
    {
        if (debug)
            trace("WebSocket LOG:", message);
    }

    public function fatal(message:String):void
    {
        trace("WebSocket FATAL:", message);
    }

    public function error(message:String):void
    {
        trace("WebSocket ERROR", message);
    }
}
