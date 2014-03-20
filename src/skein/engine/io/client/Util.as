/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/27/14
 * Time: 9:38 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.client
{
public class Util
{
    public static function qs(obj:Object):String
    {
        var str:String = "";

        for (var p:String in obj)
        {
            if (str.length > 0)
                str += "&";

            str += encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]);
        }

        return str.toString();
    }

    public static function qsParse(qs:String):Object
    {
        var result:Object = new Object();

        var pairs:Array = qs.split("&");

        for each (var str:String in pairs)
        {
            var pair:Array = str.split("=");

            result[pair[0]] = pair[1];
        }

        return result;
    }


    public static function encodeURIComponent(str:String):String
    {
        return escape(str)
            .replace("+", "%20")
            .replace("%21", "!")
            .replace("%27", "'")
            .replace("%28", "(")
            .replace("%29", ")")
            .replace("%7E", "~");
    }

    public static function decodeURIComponent(str:String):String
    {
        return unescape(str);
    }
}
}
