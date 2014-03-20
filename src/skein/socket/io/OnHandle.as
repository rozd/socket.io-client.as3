/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 3/4/14
 * Time: 12:45 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.socket.io
{
public class OnHandle
{
    function OnHandle(destroyFunction:Function)
    {
        super();

        this.destroyFunction = destroyFunction;
    }

    private var destroyFunction:Function;

    public function destroy():void
    {
        destroyFunction.apply();
    }
}
}
