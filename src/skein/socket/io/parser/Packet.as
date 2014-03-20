/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 3/3/14
 * Time: 1:02 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.socket.io.parser
{
public class Packet
{
    public function Packet(type:int=-1, data:Object=null)
    {
        super();

        this.type = type;
        this.data = data;
    }

    public var type:int = -1;
    public var id:int = -1;
    public var nsp:String;
    public var data:Object;
}
}
