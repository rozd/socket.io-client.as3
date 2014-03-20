/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/27/14
 * Time: 9:35 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.client
{
import com.adobe.net.URI;

public class SocketOptions extends TransportOptions
{
    internal static function fromURI(uri:URI, opts:SocketOptions=null):SocketOptions
    {
        if (opts == null)
            opts = new SocketOptions();

        opts.hostname = uri.authority;

        opts.secure = uri.scheme == "https" || uri.scheme == "wss";

        if (uri.port)
            opts.port = Number(uri.port);

        if (uri.queryRaw)
            opts.query = uri.queryRaw;

        return opts;
    }

    public var transports:Array;

    public var upgrade:Boolean;

    public var host:String;
}
}
