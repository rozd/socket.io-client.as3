/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/27/14
 * Time: 10:25 AM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.parser
{
public class HandshakeData
{
    public static function parse(json:String):HandshakeData
    {
        var o:Object = JSON.parse(json);

        var hd:HandshakeData = new HandshakeData();
        hd.sid = o.sid;
        hd.upgrades = o.upgrades;
        hd.pingInterval = o.pingInterval;
        hd.pingTimeout = o.pingTimeout;

        return hd;
    }

    public function HandshakeData()
    {
        super();
    }

    public var sid:String;
    public var upgrades:Array;
    public var pingInterval:Number;
    public var pingTimeout:Number;
}
}
