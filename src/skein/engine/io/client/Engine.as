/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/27/14
 * Time: 2:04 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.client
{
import com.adobe.net.URI;

import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.utils.Timer;

import skein.emitter.Emitter;
import skein.engine.io.client.transport.Polling;
import skein.engine.io.client.transport.PollingXHR;
import skein.engine.io.client.transport.WebSocketTransport;
import skein.engine.io.parser.HandshakeData;
import skein.engine.io.parser.Packet;
import skein.engine.io.parser.Parser;
import skein.logger.Log;
import skein.utils.StringUtil;

public class Engine extends Emitter
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    public static const EVENT_OPEN:String  = "open";
    public static const EVENT_CLOSE:String = "close";
    public static const EVENT_MESSAGE:String  = "message";
    public static const EVENT_ERROR:String = "error";
    public static const EVENT_UPGRADE_ERROR:String = "upgradeError";
    public static const EVENT_FLUSH:String = "flush";
    public static const EVENT_DRAIN:String = "drain";


    public static const OPENING:String  = "opening";
    public static const OPEN:String     = "open";
    public static const CLOSING:String  = "closing";
    public static const CLOSED:String   = "closed";

    public static const EVENT_HANDSHAKE:String = "handshake";
    public static const EVENT_UPGRADING:String = "upgrading";
    public static const EVENT_UPGRADE:String = "upgrade";
    public static const EVENT_PACKET:String = "packet";
    public static const EVENT_PACKET_CREATE:String = "packetCreate";
    public static const EVENT_HEARTBEAT:String = "heartbeat";
    public static const EVENT_DATA:String = "data";

    public static const EVENT_TRANSPORT:String = "transport";

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    public function Engine(uri:Object, opts:SocketOptions = null)
    {
        super();

        if (uri is String)
            uri = new URI(uri as String);

        opts = SocketOptions.fromURI(URI(uri), opts);

        //

        if (opts.host != null)
        {
            var pieces:Array = opts.host.split(":");

            opts.hostname = pieces[0];

            if (pieces.length > 1)
            {
                opts.port = parseInt(pieces[pieces.length - 1]);
            }
        }

        this.secure = opts.secure;
        this.hostname = opts.hostname != null ? opts.hostname : "localhost";
        this.port = opts.port != 0 ? opts.port : (this.secure ? 443 : 80);
//        this.query = opts.query != null ? Util.qsParse(opts.query as String) : {};
        this.query = opts.query || {};
        this.upgrade = opts.upgrade;
        this.path = (opts.path != null ? opts.path : "/engine.io").replace("/$/g", "") + "/";
        this.timestampParam = opts.timestampParam != null ? opts.timestampParam : "t";
        this.timestampRequests = opts.timestampRequests;

        this.transports = Vector.<String>(opts.transports as Array || [WebSocketTransport.NAME]);

        this.policyPort = opts.policyPort != 0 ? opts.policyPort : 843;
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var secure:Boolean;
    private var upgrade:Boolean;
    private var timestampRequests:Boolean;
    private var upgrading:Boolean;

    private var port:int;
    private var policyPort:int;
    private var prevBufferLen:int;
    private var pingInterval:Number;
    private var pingTimeout:Number;

    private var id:String;
    private var hostname:String;
    private var path:String;
    private var timestampParam:String;

    private var transports:Vector.<String>;
    private var upgrades:Vector.<String>;

    private var query:Object;

    private var writeBuffer:Array = [];
    private var callbackBuffer:Array = [];

    private var transport:Transport;

    private var pingTimeoutTimer:Timer;
    private var pingIntervalTimer:Timer;

    private var readyState:String;

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------



    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    //--------------------------------------
    //  Methods: Public
    //--------------------------------------

    public function open():void
    {
        var transportName:String = this.transports[0];

        readyState = OPENING;

        var transport:Transport = createTransport(transportName);

        setTransport(transport);

        transport.open();
    }

    public function close():Engine
    {
        if (readyState == OPENING || readyState == OPEN)
        {
            onClose("forced close");
            Log.d("engine.io", "socket closing - telling transport to close");
            transport.close();
        }

        return this;
    }

    public function write(msg:String, callback:Function=null):void
    {
        this.send(msg, callback);
    }

    public function send(msg:String, callback:Function=null):void
    {
        sendPacket(Packet.MESSAGE, msg, callback);
    }

    //--------------------------------------
    //  Methods: transports
    //--------------------------------------

    private function createTransport(name:String):Transport
    {
        Log.d("engine.io", StringUtil.substitute("creating transport '{0}'", name));

        var query:Object = {};

        for (var p:String in this.query)
            query[p] = this.query[p];

        query["EIO"] = Parser.protocol;
        query["transport"] = name;

        if (id)
        {
            query["sid"] = id;
        }

        var opts:TransportOptions = new TransportOptions();
        opts.hostname = hostname;
        opts.port = port;
        opts.secure = secure;
        opts.path = path;
        opts.query = query;
        opts.timestampRequests = timestampRequests;
        opts.timestampParam = timestampParam;
        opts.policyPort = policyPort;

        if (name == WebSocketTransport.NAME)
            return new WebSocketTransport(opts);
        else if (name == Polling.NAME)
            return new PollingXHR(opts);

        throw new Error();
    }

    private function setTransport(transport:Transport):void
    {
        Log.d("engine.io", StringUtil.substitute("setting transport {0}", transport.name));

        if (this.transport)
        {
            Log.d("engine.io", StringUtil.substitute("clearing existing transport {0}", this.transport.name));

            this.transport.off();
        }

        this.transport = transport;

        emit(EVENT_TRANSPORT, transport);

        this.transport.on(Transport.EVENT_DRAIN,
            function (...rest):void
            {
                onDrain();
            });

        this.transport.on(Transport.EVENT_PACKET,
            function (packet:Packet):void
            {
                onPacket(packet);
            });

        this.transport.on(Transport.EVENT_ERROR,
            function (error:Error=null):void
            {
                onError(error);
            });

        this.transport.on(Transport.EVENT_CLOSE,
            function (...rest):void
            {
                onClose("transport close");
            });
    }

    //--------------------------------------
    //  Methods: probe
    //--------------------------------------

    private function probe(name:String):void
    {
        Log.d("engine.io", StringUtil.substitute("probing transport {0}", name));

        var transport:Transport = createTransport(name);
        var failed:Boolean = false;

        var self:Engine = this

        var onerror:Function = function (error:Error=null):void
        {
            if (failed) return;

            failed = true;

            transport.close();

            emit(EVENT_UPGRADE_ERROR, error);
        }

        transport.once(Transport.EVENT_OPEN,
            function (...rest):void
            {
                if (failed) return;

                Log.d("engine.io", StringUtil.substitute("probe transport '{0}' opened", name));

                var packet:Packet = new Packet(Packet.PING, "probe");

                transport.send([packet]);

                transport.once(Transport.EVENT_PACKET,
                    function (...rest):void
                    {
                        if (failed) return;

                        var msg:Packet = rest[0];

                        if (msg.type == Packet.PONG && msg.data == "probe")
                        {
                            Log.d("engine.io", StringUtil.substitute("probe transport '%s' pong", name));

                            upgrading = true;

                            emit(EVENT_UPGRADING, transport);

                            Log.d("engine.io", StringUtil.substitute("pausing current transport {0}", self.transport.name));

                            Polling(self.transport).pause(
                                function():void
                                {
                                    if (failed) return;

                                    if (readyState == CLOSED || readyState == CLOSING)
                                        return;

                                    Log.d("engine.io", "changing transport and sending upgrade packet");

                                    transport.off(Transport.EVENT_ERROR, onerror);
                                    emit(EVENT_UPGRADE, transport);
                                    setTransport(transport);
                                    var packet:Packet = new Packet(Packet.UPGRADE);
                                    transport.send([packet]);
                                    transport = null;
                                    upgrading = false;
                                    flush();
                                });
                        }
                        else
                        {
                            Log.d("engine.io", StringUtil.substitute("probe transport '{0}' failed", name));

                            emit(EVENT_UPGRADE_ERROR, new Error("probe error"));
                        }
                    })
            });

        transport.once(Transport.EVENT_ERROR, onerror);

        transport.once(Transport.EVENT_CLOSE,
            function (...rest):void
            {
                if (transport)
                {
                    Log.d("engine.io", "socket closed prematurely - aborting probe");
                    failed = true;
                    transport.close();
                    transport = null;
                }
            }
        );

        this.once(EVENT_UPGRADING,
            function (to:Transport=null):void
            {
                if (to != null && to.name != transport.name)
                {
                    Log.d("engine.io", StringUtil.substitute("'{0}' works - aborting '{1}'", to.name, transport[0].name));
                    transport.close();
                    transport = null;
                }


            });

        transport.open();
    }

    //------------------------------------
    //  Methods: Handlers
    //------------------------------------

    private function setPing():void
    {
        if (this.pingIntervalTimer)
        {
            this.pingIntervalTimer.stop();
            this.pingIntervalTimer.removeEventListener(TimerEvent.TIMER, pingIntervalTimer_timerHandler);
        }

        this.pingIntervalTimer = new Timer(pingInterval);
        this.pingIntervalTimer.addEventListener(TimerEvent.TIMER, pingIntervalTimer_timerHandler);
        this.pingIntervalTimer.start();
    }

    private function ping():void
    {
        sendPacket(Packet.PING);
    }

    private function flush():void
    {
        if (readyState != CLOSED && this.transport.writable && !this.upgrading && writeBuffer.length > 0)
        {
//            Log.d("engine.io", StringUtil.substitute("flushing {0} packets in socket", this.writeBuffer.length));

            prevBufferLen = writeBuffer.length;
            transport.send(writeBuffer);

            emit(EVENT_FLUSH);
        }
    }

    private function sendPacket(type:String, data:String=null, callback:Function=null)
    {
        var packet:Packet = new Packet(type, data);

        emit(EVENT_PACKET_CREATE, packet);

        writeBuffer.push(packet);
        callbackBuffer.push(callback);
        flush();
    }

//    //------------------------------------
//    //  Methods: Emitter
//    //------------------------------------
//
//    private var emitter:Emitter = new Emitter();
//
//    public function on(event:String, callback:Function):Engine
//    {
//        emitter.on(event, callback);
//
//        return this;
//    }
//
//    public function once(event:String, callback:Function):Engine
//    {
//        emitter.once(event, callback);
//
//        return this;
//    }
//
//    public function off(event:String=null, callback:Function=null):Engine
//    {
//        emitter.off(event, callback);
//
//        return this;
//    }
//
//    public function emit(event:String, ...rest):Engine
//    {
//        emitter.emit.apply(null, rest);
//
//        return this;
//    }

    //---------------------------------------
    //  Methods: Abstract
    //---------------------------------------

    /* abstract */ public function onopen():void{};

    /* abstract */ public function onmessage(data:String):void{};

    /* abstract */ public function onclose():void{};

    /* abstract */ public function onerror(error:Error):void{};

    //--------------------------------------------------------------------------
    //
    //  Handlers
    //
    //--------------------------------------------------------------------------

    private function onOpen():void
    {
        Log.d("engine.io", "socket open");

        this.readyState = OPEN;

        this.emit(EVENT_OPEN);
        this.onopen();
        this.flush();

        if (this.readyState == OPEN && this.upgrade && this.transport is Polling)
        {
            Log.d("engine.io", "starting upgrade probes");

            for (var i:int = 0, n:int = this.upgrades.length; i < n; i++)
            {
                this.probe(this.upgrades[i]);
            }

        }
    }

    private function onPacket(packet:Packet):void
    {
        if (this.readyState == OPENING || this.readyState == OPEN)
        {
//            Log.d("engine.io", StringUtil.substitute("socket received: type '{0}', data '{1}'", packet.type, packet.data));

            this.emit(EVENT_PACKET, packet);
            this.emit(EVENT_HEARTBEAT);

            switch (packet.type)
            {
                case Packet.OPEN :
                    onHandshake(HandshakeData.parse(packet.data));
                    break;

                case Packet.PONG :
                    setPing();
                    break;

                case Packet.ERROR :
                    emit(EVENT_ERROR, new Error("serve error"));
                    break;

                case Packet.MESSAGE :
                    emit(EVENT_DATA, packet.data);
                    emit(EVENT_MESSAGE, packet.data);
                    onmessage(packet.data);
                    break;
            }
        }
        else
        {
            Log.d("engine.io", StringUtil.substitute("packet received with socket readyState '{0}'", this.readyState));
        }
    }

    private function onHandshake(data:HandshakeData)
    {
        this.emit(EVENT_HANDSHAKE, data);
        this.id = data.sid;
        this.transport.query["sid"] = data.sid;
        this.upgrades = this.filterUpgrades(data.upgrades);
        this.pingInterval = data.pingInterval;
        this.pingTimeout = data.pingTimeout;
        this.onOpen();
        this.setPing();

        this.off(EVENT_HEARTBEAT, this.onHeartbeat);
        this.on(EVENT_HEARTBEAT, this.onHeartbeat);
    }

    private function onHeartbeat(timeout:Number=0):void
    {
        if (this.pingTimeoutTimer)
        {
            this.pingTimeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, pingTimeoutTimer_timerCompleteHandler);
            this.pingTimeoutTimer.stop();
        }

        if (timeout <= 0)
        {
            timeout = pingInterval + pingTimeout;
        }

        this.pingTimeoutTimer = new Timer(timeout, 1);
        this.pingTimeoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, pingTimeoutTimer_timerCompleteHandler);
        this.pingTimeoutTimer.start();
    }

    private function onDrain():void
    {
        for (var i:int = 0; i < prevBufferLen; i++)
        {
            var callback:Function = callbackBuffer[i];

            if (callback != null)
                callback.apply();
        }

        for (var i:int = 0; i < prevBufferLen; i++)
        {
            writeBuffer.shift();
            callbackBuffer.shift();
        }

        this.prevBufferLen = 0;
        if (writeBuffer.length == 0)
        {
            emit(EVENT_DRAIN);
        }
        else
        {
            flush();
        }
    }

    private function onError(error:Error):void
    {
        Log.d("engine.io", "socket error "+error);
        emit(EVENT_ERROR);
        onerror(error);
        onClose("transport error", error);
    }

    private function onClose(reason:String, error:Error=null):void
    {
        if (readyState == OPENING || readyState == OPEN)
        {
            if (pingIntervalTimer != null)
            {
                pingIntervalTimer.removeEventListener(TimerEvent.TIMER, pingIntervalTimer_timerHandler);
                pingIntervalTimer.stop();
            }

            if (pingTimeoutTimer != null)
            {
                pingTimeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, pingTimeoutTimer_timerCompleteHandler);
                pingTimeoutTimer.stop();
            }

            writeBuffer.length = 0;
            callbackBuffer.length = 0;
            prevBufferLen = 0;

            transport.off();

            var prevState:String = readyState;
            readyState = CLOSED;

            this.id = null;

            if (prevState == OPEN)
            {
                emit(EVENT_CLOSE, reason, error);
                onclose();
            }
        }
    }

    internal function filterUpgrades(upgrades:Array):Vector.<String>
    {
        var filteredUpgrades:Vector.<String> = new <String>[];

        for each (var upgrade:String in upgrades)
        {
            if (transports.indexOf(upgrade) != -1)
            {
                filteredUpgrades.push(upgrade);
            }
        }

        return filteredUpgrades;
    }

    //---------------------------------------
    //  Handlers: Timer
    //---------------------------------------

    private function pingIntervalTimer_timerHandler(event:TimerEvent):void
    {
//        Log.d("engine.io", StringUtil.substitute("writing ping packet - expecting pong within {0}", pingTimeout));

        ping();
        onHeartbeat(pingTimeout);
    }

    private function pingTimeoutTimer_timerCompleteHandler(event:TimerEvent):void
    {
        if (readyState != CLOSED)
        {
            onClose("ping timeout");
        }
    }
}
}
