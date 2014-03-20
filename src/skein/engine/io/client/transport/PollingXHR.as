/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/28/14
 * Time: 10:06 AM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.client.transport
{
import flash.net.URLRequest;

import skein.engine.io.client.TransportOptions;
import skein.engine.io.client.transport.xhr.Request;
import skein.engine.io.client.transport.xhr.RequestOptions;

public class PollingXHR extends Polling
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    public function PollingXHR(opts:TransportOptions)
    {
        super(opts)
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var sendXhr:Request;
    private var pollXhr:Request;

    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------

    override protected function doWrite(data:String, fn:Function):void
    {
        var opts:RequestOptions = new RequestOptions();
        opts.method = "POST";
        opts.data = data;

        sendXhr = request(opts);

        sendXhr.on(Request.EVENT_SUCCESS,
            function():void
            {
                fn.apply();
            });

        sendXhr.on(Request.EVENT_ERROR,
            function(error:Error):void
            {
                onError("xhr post error", error);
            })

        sendXhr.create();
    }

    override protected function doPoll():void
    {
        trace("xhr poll");

        pollXhr = request();

        pollXhr.on(Request.EVENT_DATA,
            function(data:String):void
            {
                onData(data);
            });

        pollXhr.on(Request.EVENT_ERROR,
            function(error:Error):void
            {
                onError("xhr poll error", error);
            })

        pollXhr.create();
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    protected function request(opts:RequestOptions=null):Request
    {
        if (opts == null)
            opts = new RequestOptions();

        opts.uri = this.uri();

        var request:Request = new Request(opts);

        request
        .on(Request.EVENT_REQUEST_HEADERS,
            function(headers:Array):void
            {
                emit(EVENT_REQUEST_HEADERS, headers);
            })
        .on(Request.EVENT_RESPONSE_HEADERS,
            function(headers:Array):void
            {
                emit(EVENT_RESPONSE_HEADERS, headers);
            });

        return request;
    }

    //--------------------------------------------------------------------------
    //
    //  Handlers
    //
    //--------------------------------------------------------------------------


}
}
