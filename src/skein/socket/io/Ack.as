/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 3/3/14
 * Time: 1:51 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.socket.io
{
public class Ack
{
    public function Ack(acknowledge:Function)
    {
        super();

        this.acknowledgeFunction = acknowledge;
    }

    private var acknowledgeFunction:Function;

    public function call(...args):void
    {
        acknowledgeFunction.apply(null, args);
    }
}
}
