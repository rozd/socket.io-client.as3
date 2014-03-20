/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 3/3/14
 * Time: 12:36 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.socket.io
{
import com.adobe.net.URI;

import flash.events.Event;

import flash.events.TimerEvent;

import flash.utils.Timer;

import skein.emitter.Emitter;
import skein.engine.io.client.Engine;
import skein.socket.io.parser.Packet;
import skein.socket.io.parser.Parser;
import skein.utils.StringUtil;

public class Manager extends Emitter
{
    public static const CLOSED:String   = "closed";
    public static const OPENING:String  = "opening";
    public static const OPEN:String     = "open";


    public static const EVENT_OPEN:String = "open";
    public static const EVENT_CLOSE:String = "close";
    public static const EVENT_PACKET:String = "packet";
    public static const EVENT_ERROR:String = "error";

    public static const EVENT_CONNECT_ERROR:String = "connectError";
    public static const EVENT_CONNECT_TIMEOUT:String = "connectTimeout";

    public static const EVENT_RECONNECT:String = "reconnect";
    public static const EVENT_RECONNECT_ERROR:String = "reconnectError";
    public static const EVENT_RECONNECT_FAILED:String = "reconnectFailed";

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    public function Manager(uri:URI, opts:Options)
    {
        super();

        opts = initOptions(opts);

        this.engine = new Engine(uri, opts);
    }

    private function initOptions(opts:Options):Options
    {
        if (opts == null)
            opts = new Options();

        if (opts.path == null)
            opts.path = "/socket.io";

        this.reconnection(opts.reconnection);
        this.reconnectionAttempts(opts.reconnectionAttempts || int.MAX_VALUE);
        this.reconnectionDelay(opts.reconnectionDelay || 1000);
        this.reconnectionDelayMax(opts.reconnectionDelayMax || 5000);
        this.timeout(opts.timeout < 0 ? 10000 : opts.timeout);
        return opts;
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    internal var readyState:String;

    private var _reconnection:Boolean;
    private var skipReconnect:Boolean;
    private var reconnecting:Boolean;
    private var _reconnectionAttempts:int;
    private var _reconnectionDelay:Number;
    private var _reconnectionDelayMax:Number;
    private var _timeout:Number;
    private var connected:int;
    private var attempts:int;
    private var subs:Array = [];
    private var engine:Engine;
    private var nsps:Object = {};

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //------------------------------------
    //  reconnection
    //------------------------------------

    public function reconnection(value:Boolean):Manager
    {
        _reconnection = value;

        return this;
    }

    //------------------------------------
    //  reconnectionAttempts
    //------------------------------------

    public function reconnectionAttempts(value:int):Manager
    {
        _reconnectionAttempts = value;

        return this;

    }

    //------------------------------------
    //  reconnectionDelay
    //------------------------------------

    public function reconnectionDelay(value:Number):Manager
    {
        _reconnectionDelay = value;

        return this;
    }

    //------------------------------------
    //  reconnectionDelayMax
    //------------------------------------

    public function reconnectionDelayMax(value:Number):Manager
    {
        _reconnectionDelayMax = value;

        return this;
    }

    //------------------------------------
    //  timeout
    //------------------------------------

    public function timeout(value:Number):Manager
    {
        _timeout = value;

        return this;
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    public function open(callback:Function=null):Manager
    {
        if (readyState == OPEN) return this;

        readyState = OPENING;

        var openSub:OnHandle = On.on(engine, Engine.EVENT_OPEN,
            function (...args):void
            {
                onopen();

                if (callback != null)
                    callback();
            });

        var errorSub:OnHandle = On.on(engine, Engine.EVENT_ERROR,
            function (data:Object=null):void
            {
                cleanup();
                emit(EVENT_CONNECT_ERROR, data);

                if (callback != null)
                    callback(data as Error);
            }
        );

        if (_timeout >= 0)
        {
            trace(StringUtil.substitute("connection attempt will timeout after {0}", _timeout));

            var timeoutHandler:Function = function(event:Event):void
            {
                timer.removeEventListener(TimerEvent.TIMER_COMPLETE, timeoutHandler);

                trace(StringUtil.substitute("connect attempt timed out after {0}", _timeout));

                openSub.destroy();
                engine.close();
                engine.emit(Engine.EVENT_ERROR, new Error("timeout"));
                emit(EVENT_CONNECT_TIMEOUT, _timeout);
            };

            var timer:Timer = new Timer(_timeout, 1);
            timer.addEventListener(TimerEvent.TIMER_COMPLETE, timeoutHandler);
            timer.start();

            var timeSub:OnHandle = new OnHandle(
                function():void
                {
                    timer.removeEventListener(TimerEvent.TIMER_COMPLETE, timeoutHandler);
                    timer.stop();
                });

            subs.push(timeSub);
        }

        subs.push(openSub);
        subs.push(errorSub);

        engine.open();

        return this;
    }

    public function socket(nsp:String):Socket
    {
        var socket:Socket = nsps[nsp];

        if (socket == null)
        {
            socket = nsps[nsp] = new Socket(this, nsp);

            socket.on(Socket.EVENT_CONNECT,
                function():void
                {
                    connected++;
                });
        }

        return socket;
    }

    internal function destroy(socket:Socket):void
    {
        socket.off(Socket.EVENT_CONNECT);

        connected--;

        if (connected == 0)
        {
            close();
        }
    }

    internal function packet(packet:Packet):void
    {
        trace(StringUtil.substitute("writing packet {0}", packet));

        this.engine.write(Parser.encode(packet));
    }

    private function cleanup():void
    {
        var sub:OnHandle;

        while (sub = this.subs.shift())
        {
            sub.destroy();
        }
    }

    private function close():void
    {
        skipReconnect = true;
        cleanup();
        readyState = CLOSED;
        engine.close();
    }

    private function reconnect():void
    {
        attempts++;

        if (attempts > _reconnectionAttempts)
        {
            emit(EVENT_RECONNECT_FAILED);
            reconnecting = false;
        }
        else
        {
            var delay:Number = attempts * _reconnectionDelay;
            delay = Math.min(delay, _reconnectionDelayMax);

            trace(StringUtil.substitute("will wait {0} before reconnect attempt", delay));

            reconnecting = true;

            var delayHandler:Function = function(event:TimerEvent):void
            {
                timer.removeEventListener(TimerEvent.TIMER_COMPLETE, delayHandler);

                open(function(error:Error=null):void
                     {
                         if (error != null)
                         {
                             trace("reconnect attempt error");
                             reconnect();
                             emit(EVENT_RECONNECT_ERROR, error);
                         }
                         else
                         {
                             trace("reconnect success");
                             onreconnect();
                         }
                     });
            }

            var timer:Timer = new Timer(delay, 1);
            timer.addEventListener(TimerEvent.TIMER, delayHandler);
            timer.start();

            subs.push(new OnHandle(function():void
                {
                    timer.removeEventListener(TimerEvent.TIMER, delayHandler);
                    timer.stop();
                })
            );
        }
    }

//    //------------------------------------
//    //  Methods: Emitter
//    //------------------------------------
//
//    private var emitter:Emitter = new Emitter();
//
//    public function on(event:String, callback:Function):Manager
//    {
//        emitter.on(event, callback);
//
//        return this;
//    }
//
//    public function once(event:String, callback:Function):Manager
//    {
//        emitter.once(event, callback);
//
//        return this;
//    }
//
//    public function off(event:String=null, callback:Function=null):Manager
//    {
//        emitter.off(event, callback);
//
//        return this;
//    }
//
//    public function emit(event:String, ...rest):Manager
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
        cleanup();

        readyState = OPEN;
        emit(EVENT_OPEN);

        this.subs.push(On.on(engine, Engine.EVENT_DATA,
            function(data:String):void
            {
                ondata(data);
            }));

        this.subs.push(On.on(engine, Engine.EVENT_ERROR,
            function(data:Error):void
            {
                onerror(data);
            }));

        this.subs.push(On.on(engine, Engine.EVENT_CLOSE,
            function (...args):void
            {
                onclose();
            }));
    }

    private function ondata(data:String):void
    {
        emit(EVENT_PACKET, Parser.decode(data));
    }

    private function onerror (error:Error):void
    {
        emit(EVENT_ERROR, error);
    }

    private function onclose():void
    {
        cleanup();
        readyState = CLOSED;

        if (_reconnection && !skipReconnect)
            reconnect();
    }

    private function onreconnect():void
    {
        var attempts:int = this.attempts;
        this.attempts = 0;
        this.reconnecting = false;
        emit(EVENT_RECONNECT, attempts);
    }
}
}
