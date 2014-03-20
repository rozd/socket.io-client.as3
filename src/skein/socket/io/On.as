/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 3/3/14
 * Time: 12:43 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.socket.io
{
public class On
{
    public static function on(emitter:Object, event:String, listener:Function):OnHandle
    {
        emitter.on(event, listener);

        var destroy:Function = function():void
        {
            emitter.off(event, listener);
        }

        return new OnHandle(destroy);
    }
}
}

