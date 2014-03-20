/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 3/4/14
 * Time: 2:38 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.socket.io
{
import com.adobe.net.URI;

public class URL
{
    public static function extractId(uri:URI):String
    {
        return uri.scheme + "://" + uri.authority + (uri.port ? ":" + uri.port : "");
    }
}
}
