/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 3/3/14
 * Time: 1:03 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.socket.io.parser
{
import skein.logger.Log;
import skein.utils.StringUtil;

public class Parser
{
    public static const CONNECT:int = 0;

    public static const DISCONNECT:int = 1;

    public static const EVENT:int = 2;

    public static const ACK:int = 3;

    public static const ERROR:int = 4;

    public static const protocol:int = 1;

    public static const types:Array =
    [
        "CONNECT", "DISCONNECT", "EVENT", "ACK", "ERROR"
    ];

    public function Parser()
    {
    }

    public static function encode(obj:Packet):String
    {
        var str = '';
        var nsp = false;

        // first is type
        str += obj.type;

        // if we have a namespace other than `/`
        // we append it followed by a comma `,`
        if (obj.nsp && '/' != obj.nsp) {
            nsp = true;
            str += obj.nsp;
        }

        // immediately followed by the id
        if (obj.id != -1) {
            if (nsp) {
                str += ',';
                nsp = false;
            }
            str += obj.id;
        }

        // json data
        if (null != obj.data) {
            if (nsp) str += ',';
            str += JSON.stringify(obj.data);
        }

        Log.d("socket.io", ['encoded %j as %s', obj, str]);
        return str;
    }

    public static function decode(str:String):Packet
    {
        var p = new Packet();
        var i = 0;

        // look up type
        p.type = Number(str.charAt(0));
        if (null == types[p.type]) return error();

        // look up namespace (if any)
        if ('/' == str.charAt(i + 1)) {
            p.nsp = '';
            while (++i) {
                var c = str.charAt(i);
                if (',' == c) break;
                p.nsp += c;
                if (i + 1 == str.length) break;
            }
        } else {
            p.nsp = '/';
        }

        // look up id
        var next = str.charAt(i + 1);
        if ('' != next && Number(next) == next)
        {
            var id:String = "";
            while (++i) {
                var c = str.charAt(i);
                if (null == c || Number(c) != c) {
                    --i;
                    break;
                }
                id += str.charAt(i);
                if (i + 1 == str.length) break;
            }
            p.id = Number(id);
        }

        // look up json data
        if (str.charAt(++i)) {
            try
            {
                p.data = JSON.parse(str.substr(i));
            }
            catch(e)
            {
                return error();
            }
        }

        Log.d("socket.io", StringUtil.substitute('decoded {0} as {1}', str, p));

        return p;
    }

    private static function error():Packet
    {
        return new Packet(2);
    }
}
}
