/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 3/3/14
 * Time: 12:35 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.socket.io
{
import skein.emitter.Emitter;
import skein.socket.io.parser.Packet;
import skein.socket.io.parser.Parser;
import skein.utils.StringUtil;

public class Socket extends Emitter
{
    public static const EVENT_CONNECT:String = "connect";

    public static const EVENT_DISCONNECT:String = "disconnect";

    public static const EVENT_ERROR:String = "error";

    public static const EVENT_MESSAGE:String = "message";

    private static const events:Array =
    [
        EVENT_CONNECT, EVENT_DISCONNECT, EVENT_ERROR,
    ]

    //--------------------------------------------------------------------------
    //
    //  Class methods
    //
    //--------------------------------------------------------------------------

    private static function toJsonArray(list:Array):String
    {
        return JSON.stringify(list);
    }

    private static function fromJsonArray(array:String):Array
    {
        return JSON.parse(array) as Array;
    }

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    public function Socket(io:Manager, nsp:String)
    {
        super();

        this.io = io;
        this.nsp = nsp;
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var connected:Boolean;
    private var disconnected:Boolean = true;
    private var ids:int;
    private var nsp:String;
    private var io:Manager;
    private var acks:Object = {};
    private var subs:Array = [];

    private var buffer:Array = [];

    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------

    override public function emit(event:String, ...args):Emitter
    {
        if (events.indexOf(event) != -1)
        {
            args.unshift(event);

            super.emit.apply(this, args);
        }
        else
        {
            var packet:Packet;

            if (args[args.length-1] is Function)
            {
                var ack:Function = args.pop() as Function;

                args.unshift(event);

                trace(StringUtil.substitute("emitting packet with ack id {0}", ids));

                packet = new Packet(Parser.EVENT, args);
                acks[ids] = ack;
                packet.id = ids++;
                this.packet(packet);
            }
            else
            {
                args.unshift(event);

                packet = new Packet(Parser.EVENT, toJsonArray(args));
                this.packet(packet);
            }
        }

        return this;
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    public function connect():void
    {
        this.open();
    }

    public function open():void
    {
        subs.push(On.on(io, Manager.EVENT_OPEN,
            function():void
            {
                onopen();
            }));

        subs.push(On.on(io, Manager.EVENT_ERROR,
            function(error:Error=null):void
            {
                onerror(error);
            }));

        subs.push(On.on(io, Manager.EVENT_PACKET,
            function (packet:Packet):void
            {
                onpacket(packet);
            }));

        subs.push(On.on(io, Manager.EVENT_CLOSE,
            function (reason:String=null):void
            {
                onclose(reason);
            }));

        if (io.readyState == Manager.OPEN)
            onopen();

        io.open();
    }

    public function close():void
    {
        if (connected) return;

        trace(StringUtil.substitute("performing disconnect ({0})", this.nsp));

        packet(new Packet(Parser.DISCONNECT));

        destroy();

        onclose("io client disconnect");
    }

    public function disconnect():void
    {
        close();
    }

    public function send(...args):Socket
    {
        args.unshift(EVENT_MESSAGE);

        this.emit.apply(this, args);

        return this;
    }

    private function packet(packet:Packet):void
    {
        packet.nsp = this.nsp;

        io.packet(packet);
    }

//    private function toJsonArray(list:Object):void
//    {
//
//    }

//    //------------------------------------
//    //  Methods: Emitter
//    //------------------------------------
//
//    private var emitter:Emitter = new Emitter();
//
//    public function on(event:String, callback:Function):Socket
//    {
//        emitter.on(event, callback);
//
//        return this;
//    }
//
//    public function once(event:String, callback:Function):Socket
//    {
//        emitter.once(event, callback);
//
//        return this;
//    }
//
//    public function off(event:String=null, callback:Function=null):Socket
//    {
//        emitter.off(event, callback);
//
//        return this;
//    }
//
//    public function emit(event:String, ...rest):Socket
//    {
//        emitter.emit.apply(null, rest);
//
//        return this;
//    }

    //--------------------------------------------------------------------------
    //
    //  Handlers
    //
    //--------------------------------------------------------------------------

    private function onopen():void
    {
        trace("transport is open - connecting");

        if (this.nsp != "/")
        {
            this.packet(new Packet(Parser.CONNECT));
        }
    }

    private function onclose(reason:String):void
    {
        connected = false;
        disconnected = true;

        emit(EVENT_DISCONNECT, reason);
    }

    private function onerror(error:Error):void
    {
        emit(EVENT_ERROR, error);
    }

    private function onpacket(packet:Packet):void
    {
        if (this.nsp != packet.nsp) return;

        switch (packet.type)
        {
            case Parser.CONNECT:
                this.onconnect();
                break;

            case Parser.EVENT:
                this.onevent(packet);
                break;

            case Parser.ACK:
                this.onack(packet);
                break;

            case Parser.DISCONNECT:
                this.ondisconnect();
                break;

            case Parser.ERROR:
                this.emit(EVENT_ERROR, packet.data);
                break;
        }
    }

    private function onevent(packet:Packet):void
    {
        var args:Array = packet.data as Array;

        trace(StringUtil.substitute("emitting event {0}", args));

        if (packet.id >= 0)
        {
            trace("attaching ack callback to event");

            args.push(this.ack(packet.id));
        }

        if (connected)
        {
//            var event:String = args.shift();
//
//            super.emit(event, args);

            super.emit.apply(this, args);
        }
        else
        {
            buffer.push(args);
        }
    }

    private function ack(id:int):Ack
    {
        var self:Socket = this;
        var sent:Boolean = false;

        return new Ack(
            function (...args):void
            {
                if (sent) return;

                sent = true;

                trace(StringUtil.substitute("sending ack {0}", args));

                var packet:Packet = new Packet(Parser.ACK, args);
                packet.id = id;

                self.packet(packet);
            });
//
//        var ack:Function = function (...args):void
//        {
//            if (sent) return;
//
//            sent = true;
//
//            trace(StringUtil.substitute("sending ack {0}", args));
//
//            var packet:Packet = new Packet(Parser.ACK, args);
//            packet.id = id;
//
//            self.packet(packet);
//        }
//
//        return ack;
    }

    private function onack(packet:Packet):void
    {
        trace(StringUtil.substitute("calling ack {0} with {1}", packet.id, packet.data));

        var fn:Function = acks[packet.id];

        acks[packet.id] = null;
        delete acks[packet.id];

        fn.apply(null, packet.data);
    }

    private function onconnect():void
    {
        connected = true;
        disconnected = false;
        emit(EVENT_CONNECT);

        emitBuffered();
    }

    private function emitBuffered():void
    {
        var data:Object;

        while (data = buffer.shift() != null)
        {
            var event:String = data.shift();
            emit(event, data);
        }
    }

    private function ondisconnect():void
    {
        trace(StringUtil.substitute("server disconnect ({0})", this.nsp));
        destroy();
        onclose("io server disconnect");
    }

    private function destroy():void
    {
        trace(StringUtil.substitute("destroying socket ({0})", this.nsp));

        for each (var handle:OnHandle in subs)
        {
            handle.destroy();
        }

        io.destroy(this);
    }
}
}
