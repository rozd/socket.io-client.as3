/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 3/3/14
 * Time: 5:38 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.socket.io
{
import skein.engine.io.client.SocketOptions;

public class Options extends SocketOptions
{
    public function Options()
    {
        super();
    }

    public var forceNew:Boolean;

    public var multiplex:Boolean = true;

    public var reconnection:Boolean = true;
    public var reconnectionAttempts:int;
    public var reconnectionDelay:Number;
    public var reconnectionDelayMax:Number;
    public var timeout:Number = -1;
}
}
