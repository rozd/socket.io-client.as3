/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/28/14
 * Time: 10:15 AM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.client.transport.xhr
{
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;

import skein.emitter.Emitter;

import skein.utils.StringUtil;

public class Request extends Emitter
{
    public static const EVENT_SUCCESS:String = "success";
    public static const EVENT_DATA:String = "data";
    public static const EVENT_ERROR:String = "error";
    public static const EVENT_REQUEST_HEADERS:String = "requestHeaders";
    public static const EVENT_RESPONSE_HEADERS:String = "responseHeaders";
        
    public function Request(opts:RequestOptions)
    {
        super();
    }

    var method:String;
    var uri:String;
    var data:String;
    var xhr:URLLoader;

    public function create():void
    {
        trace(StringUtil.substitute("xhr open {0}: {1}", this.method, this.uri));

        xhr = new URLLoader();

        var request:URLRequest = new URLRequest(this.uri);
        request.method = this.method;

        var headers:Array = [];

        if (this.method == "POST")
        {
            headers.push(new URLRequestHeader("Content-Type", "text/plain;charset=UTF-8"));
        }

        onRequestHeaders(headers);

        request.requestHeaders = headers;

        var resultHandler:Function = function(event:Event):void
        {
            xhr.removeEventListener(Event.COMPLETE, resultHandler);
            xhr.removeEventListener("httpResponseStatus", responseStatusHandler);
            xhr.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            xhr.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);

            onData(xhr.data);
        };

        var responseStatusHandler:Function = function(event:HTTPStatusEvent):void
        {
            onResponseHeaders(event.responseHeaders);
        };

        var errorHandler:Function = function(event:ErrorEvent):void
        {
            xhr.removeEventListener(Event.COMPLETE, resultHandler);
            xhr.removeEventListener("httpResponseStatus", responseStatusHandler);
            xhr.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            xhr.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);

            onError(new Error(event.text, event.errorID));
        };

        xhr.addEventListener(Event.COMPLETE, resultHandler);
        xhr.addEventListener("httpResponseStatus", responseStatusHandler);
        xhr.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        xhr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);

        xhr.load(request);
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    private function onSuccess():void
    {
        this.emit(EVENT_SUCCESS);
        this.cleanup();
    }

    private function onData(data:String):void
    {
        this.emit(EVENT_DATA, data);
        this.onSuccess();
    }

    private function onError(error:Error):void
    {
        this.emit(EVENT_ERROR, error);
        this.cleanup();
    }

    private function onRequestHeaders(headers:Array)
    {
        this.emit(EVENT_REQUEST_HEADERS, headers);
    }

    private function onResponseHeaders(headers:Array)
    {
        this.emit(EVENT_RESPONSE_HEADERS, headers);
    }

    private function cleanup()
    {
        if (xhr != null)
        {
            xhr.close();
            xhr = null;
        }
    }

    public function abort():void
    {
        this.cleanup();
    }

//    //------------------------------------
//    //  Methods: Emitter
//    //------------------------------------
//
//    private var emitter:Emitter = new Emitter();
//
//    public function on(event:String, callback:Function):Request
//    {
//        emitter.on(event, callback);
//
//        return this;
//    }
//
//    public function once(event:String, callback:Function):Request
//    {
//        emitter.once(event, callback);
//
//        return this;
//    }
//
//    public function off(event:String=null, callback:Function=null):Request
//    {
//        emitter.off(event, callback);
//
//        return this;
//    }
//
//    public function emit(event:String, ...rest):Request
//    {
//        emitter.emit.apply(null, rest);
//
//        return this;
//    }

}
}
