/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/27/14
 * Time: 11:15 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.client.transport
{
import flash.events.Event;

import skein.engine.io.client.Transport;
import skein.engine.io.client.TransportOptions;
import skein.engine.io.client.Util;
import skein.engine.io.parser.Packet;
import skein.engine.io.parser.Parser;
import skein.utils.StringUtil;

public class Polling extends Transport
{
    public static const NAME:String = "polling";

    public static const EVENT_POLL:String = "poll";
    public static const EVENT_POLL_COMPLETE:String = "pollComplete";

    public function Polling(opts:TransportOptions)
    {
        super(opts);

        this.name = NAME;
    }

    private var polling:Boolean;

    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------

    override protected function doOpen():void
    {
        this.poll();
    }

    override protected function doClose():void
    {
        var close:Function = function (...rest):void
        {
            write([new Packet(Packet.CLOSE)]);
        }

        if (_readyState == OPEN)
        {
            trace("transport open - closing");

            close();
        }
        else
        {
            // in case we're trying to close while
            // handshaking is in progress (engine.io-client GH-164)
            trace("transport not open - deferring close");
            once(EVENT_OPEN, close);
        }
    }

    override protected function onData(data:String):void
    {
        trace(StringUtil.substitute("polling got data {0}", data));

        Parser.decodePayload(data,
            function(packet:Packet, index:int, total:int):Boolean
            {
                if (_readyState == OPENING)
                {
                    onOpen();
                }

                if (packet.type == Packet.CLOSE)
                {
                    onClose();
                    return false;
                }

                onPacket(packet);
                return true;
            });

        if (_readyState != CLOSED)
        {
            this.polling = false;
            emit(EVENT_POLL);

            if (_readyState == OPEN)
            {
                this.poll();
            }
            else
            {
                trace(StringUtil.substitute("ignoring poll - transport state {0}", this.readyState));
            }
        }
    }

    override protected function write(packets:Array):void
    {
        this.writable = false;

        doWrite(Parser.encodePayload(packets),
            function():void
            {
                writable = true;
                emit(EVENT_DRAIN);
            });
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    public function pause(callback:Function):void
    {
        _readyState = PAUSED;

        function onPaused():void
        {
            _readyState = PAUSED;

            callback();
        }

        if (this.polling || !this.writable)
        {
            var total:int = 0;

            if (this.polling)
            {
                trace("we are currently polling - waiting to pause");

                total++;

                this.once(EVENT_POLL_COMPLETE,
                    function (...args):void
                    {
                        trace("pre-pause polling complete");

                        if (--total == 0)
                        {
                            onPaused();
                        }
                    });
            }

            if (!this.writable)
            {
                trace("we are currently writing - waiting to pause");

                total++;

                this.once(EVENT_DRAIN,
                    function (...args):void
                    {
                        trace("pre-pause writing complete");

                        if (--total == 0)
                        {
                            onPaused();
                        }
                    });
            }
        }
        else
        {
            onPaused();
        }
    }

    private function poll():void
    {
        trace("polling");

        this.polling = true;
        this.doPoll();

        emit(EVENT_POLL);
    }

    protected function uri():String
    {
        var query:Object = this.query || {};

        var schema:String = this.secure ? "https" : "http";

        var port:String = "";

        if (timestampRequests)
            query[timestampParam] = new Date().getTime();

        var q:String = Util.qs(query);

        if (this.port > 0 && (schema == "https" && this.port != 443) || (schema == "http" && this.port != 80))
        {
            port = ":" + this.port;
        }

        if (q.length > 0)
            q = "?" + q;

        return schema + "://" + hostname + port + path + q;
    }

    //--------------------------------------------------------------------------
    //
    //  Methods Abstract
    //
    //--------------------------------------------------------------------------

    /* abstract */ protected function doWrite(data:String, fn:Function):void{};

    /* abstract */ protected function doPoll():void{};
}
}
