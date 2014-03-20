/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/17/14
 * Time: 6:17 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.client
{
import flash.errors.IllegalOperationError;
import flash.events.DataEvent;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;

import skein.emitter.Emitter;

import skein.engine.io.parser.Packet;
import skein.engine.io.parser.Parser;

public class Transport extends Emitter
{
    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------

    public static const EVENT_OPEN:String = "open";
    public static const EVENT_CLOSE:String = "close";
    public static const EVENT_PACKET:String = "packet";
    public static const EVENT_DRAIN:String = "drain";
    public static const EVENT_ERROR:String = "error";
    public static const EVENT_REQUEST_HEADERS:String = "requestHeaders";
    public static const EVENT_RESPONSE_HEADERS:String = "responseHeaders";

    public static const OPENING:String = "opening";
    public static const OPEN:String = "open";
    public static const CLOSED:String = "closed";
    public static const PAUSED:String = "paused";

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    public function Transport(opts:TransportOptions):void
    {
        if (opts)
        {
            this.path = opts.path;
            this.hostname = opts.hostname;
            this.port = opts.port;
            this.secure = opts.secure;
            this.query = opts.query;
            this.timestampParam = opts.timestampParam;
            this.timestampRequests = opts.timestampRequests;
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    public var name:String;

    public var writable:Boolean;
    public var query:Object;

    protected var secure:Boolean;
    protected var timestampRequests:Boolean;
    protected var port:int;
    protected var path:String;
    protected var hostname:String;
    protected var timestampParam:String;

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    protected var _readyState:String;

    public function get readyState():String
    {
        return _readyState;
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    protected function onError(msg:String, error:Error):Transport
    {
        // TODO: handle error
        emit(EVENT_ERROR, error);

        return this;
    }

    public function open():Transport
    {
        if (_readyState == CLOSED || _readyState == null)
        {
            _readyState = OPENING;
            doOpen();
        }

        return this;
    }

    public function close():Transport
    {
        if (_readyState == OPENING || _readyState == OPEN)
        {
            doClose();
            onClose();
        }

        return this;
    }

    public function send(packets:Array):void
    {
        if (_readyState == OPEN)
            write(packets)
        else
            throw new IllegalOperationError("Transport not open");
    }


    protected function onOpen():void
    {
        this._readyState = OPEN;
        this.writable = true;

        emit(EVENT_OPEN);
    }

    protected function onData(data:String):void
    {
        trace(data);

        this.onPacket(Parser.decodePacket(decodeURIComponent(data)));
    }

    protected function onPacket(packet:Packet):void
    {
        emit(EVENT_PACKET, packet);
    }

    protected function onClose():void
    {
        _readyState = CLOSED;

        emit(EVENT_CLOSE);
    }

//    //------------------------------------
//    //  Methods: Emitter
//    //------------------------------------
//
//    private var emitter:Emitter = new Emitter();
//
//    public function on(event:String, callback:Function):Transport
//    {
//        emitter.on(event, callback);
//
//        return this;
//    }
//
//    public function once(event:String, callback:Function):Transport
//    {
//        emitter.once(event, callback);
//
//        return this;
//    }
//
//    public function off(event:String=null, callback:Function=null):Transport
//    {
//        emitter.off(event, callback);
//
//        return this;
//    }
//
//    public function emit(event:String, ...rest):Transport
//    {
//        dispatchEvent(new Event(event));
//
//        rest.push(event);
//
//        emitter.emit.apply(null, rest);
//
//        return this;
//    }

    //--------------------------------------------------------------------------
    //
    //  Abstract methods
    //
    //--------------------------------------------------------------------------

    /* abstract */ protected function write(packets:Array):void{};

    /* abstract */ protected function doOpen():void{};

    /* abstract */ protected function doClose():void{};

}
}
