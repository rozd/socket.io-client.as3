/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/27/14
 * Time: 10:27 AM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.parser
{
public class Parser
{
    public static const protocol:int = 2;

    private static const packets:Object = {};
    {
        packets[Packet.OPEN] = 0;
        packets[Packet.CLOSE] = 1;
        packets[Packet.PING] = 2;
        packets[Packet.PONG] = 3;
        packets[Packet.MESSAGE] = 4;
        packets[Packet.UPGRADE] = 5;
        packets[Packet.NOOP] = 6;
    }

    private static const bipackets:Object = {};
    {
        bipackets[0] = Packet.OPEN;
        bipackets[1] = Packet.CLOSE;
        bipackets[2] = Packet.PING;
        bipackets[3] = Packet.PONG;
        bipackets[4] = Packet.MESSAGE;
        bipackets[5] = Packet.UPGRADE;
        bipackets[6] = Packet.NOOP;
    }

    private static const err:Packet = new Packet(Packet.ERROR, "parser error");

    public function Parser()
    {
        super();
    }

    public static function encodePacket(packet:Packet):String
    {
        var encoded:String = String(packets[packet.type]);

        if (packet.data != null)
        {
            encoded += packet.data;
        }

        return encodeURIComponent(encoded);
    }

    public static function decodePacket(data:String):Packet
    {
        var type:int = -1;

        try
        {
            type = parseInt(data.charAt(0));
        }
        catch (error:Error) {}

        if (type < 0 || type >= packets.length)
        {
            return err;
        }

        return new Packet(bipackets[type], data.length > 1 ? data.substring(1) : null);
    }

    public static function encodePayload(packets:Array):String
    {
        if (packets.length == 0)
            return "0:";

        var encoded:String = "";

        for each (var packet:Packet in packets)
        {
            var message:String = encodePacket(packet);

            encoded += message.length + ":" + message;
        }

        return encoded;
    }

    public static function decodePayload(data:String, callback:Function):void
    {
        if (!data)
        {
            callback(err, 0, 1);
            return;
        }

        var length:String = "";

        for (var i:int = 0, l = data.length; i < l; i++)
        {
            var char:String = data.charAt(i);

            if (':' != char)
            {
                length += char;
            }
            else
            {
                var n:int;

                try
                {
                    n = parseInt(length);
                }
                catch (e:Error)
                {
                    callback.call(err, 0, 1);
                    return;
                }

                var msg:String;

                try
                {
                    msg = data.substring(i + 1, i + 1 + n);
                }
                catch (e:Error)
                {
                    callback.call(err, 0, 1);
                    return;
                }

                if (msg.length != 0)
                {
                    var packet:Packet = decodePacket(msg);

                    if (packet.type == err.type && packet.data == err.data)
                    {
                        callback.call(err, 0, 1);
                        return;
                    }

                    var ret:Boolean = callback(packet, i + n, l);

                    if (!ret) return;
                }

                i += n;
                length = "";
            }
        }

        if (length.length > 0)
            callback.call(err, 0, 1);
    }
}
}
