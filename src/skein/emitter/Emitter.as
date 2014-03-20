/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/15/14
 * Time: 8:54 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.emitter
{
public class Emitter
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    public function Emitter()
    {
        super();
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------

    private var callbacksMap:Object;
    private var onceCallbacks:Vector.<Function>;

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    public function on(event:String, callback:Function):Emitter
    {
        if (callbacksMap == null)
            callbacksMap = new Object();

        var callbacks:Vector.<Function> = callbacksMap[event] as Vector.<Function>;
        if (callbacks == null)
            callbacksMap[event] = new <Function>[callback];
        else if (callbacks.indexOf(callback) == -1) // check for duplicates
            callbacks.push(callback);

        return this;
    }

    public function once(event:String, callback:Function):Emitter
    {
        if (onceCallbacks)
            onceCallbacks = new Vector.<Function>();

        on(event, callback);

        return this;
    }

    public function off(event:String=null, callback:Function=null):Emitter
    {
        if (event == null && callback == null) // all
        {
            if (callbacksMap)
            {
                callbacksMap = null;
            }
        }
        else if (event != null && callback == null) // event
        {
            if (callbacksMap)
            {
                if (callbacksMap.hasOwnProperty(event))
                {
                    callbacksMap[event] = null;
                    delete callbacksMap[event];
                }
            }
        }
        else if (event != null && callback != null) // callback
        {
            if (callbacksMap)
            {
                var callbacks:Vector.<Function> = callbacksMap[event] as Vector.<Function>;
                if (callbacks)
                {
                    var remainingCallbacks:Vector.<Function> = new <Function>[];

                    for (var i:int= 0, n:int = callbacks.length; i<n; ++i)
                    {
                        var otherCallback:Function = callbacks[i];
                        if (otherCallback != callback) remainingCallbacks.push(otherCallback);
                    }

                    callbacksMap[event] = remainingCallbacks;
                }
            }
        }

        return this;
    }

    public function emit(event:String, ...rest):Emitter
    {
        if (callbacksMap)
        {
            var callbacks:Vector.<Function> = callbacksMap[event] as Vector.<Function>;

            if (callbacks)
            {
                for (var i:int = 0, n:int = callbacks.length; i < n; i++)
                {
                    var callback:Function = callbacks[i];

                    callback.apply(null, rest);

                    var found:int = onceCallbacks ? onceCallbacks.indexOf(callback) : -1;

                    if (found != -1)
                    {
                        onceCallbacks.splice(found, 1);

                        off(event, callback);
                    }
                }
            }
        }

        return this;
    }
}
}
