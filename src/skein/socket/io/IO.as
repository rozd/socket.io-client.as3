/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 3/4/14
 * Time: 2:33 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.socket.io
{
import com.adobe.net.URI;

import skein.socket.io.parser.Parser;

public class IO
{
    public static const protocol:int = Parser.protocol;

    private static var managers:Object = {};

    public static function socket(uri:String, opts:Options=null):Socket
    {
        if (opts == null)
            opts = new Options();

        var href:URI = new URI(uri);

        var io:Manager;

        if (opts.forceNew || !opts.multiplex)
        {
            io = new Manager(href, opts);
        }
        else
        {
            var id:String = URL.extractId(href);

            if (!managers.hasOwnProperty(id))
            {
                io = managers[id] = new Manager(href, opts);
            }
            else
            {
                io = managers[id];
            }
        }

        var path:String = href.path || "/";

        return io.socket(path);
    }

}
}
