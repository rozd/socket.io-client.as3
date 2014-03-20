/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/27/14
 * Time: 10:22 AM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.parser
{
public class Packet
{
    public static const OPEN:String = "open";
    public static const CLOSE:String = "close";
    public static const PING:String = "ping";
    public static const PONG:String = "pong";
    public static const UPGRADE:String = "upgrade";
    public static const MESSAGE:String = "message";
    public static const NOOP:String = "noop";
    public static const ERROR:String = "error";

    public function Packet(type:String, data:String = null)
    {
        super();

        this.type = type;
        this.data = data;
    }

    public var type:String;

    public var data:String;
}
}
