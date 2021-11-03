import utils.KadabraUtils;
import openfl.display.Sprite;

class Gizmo extends Sprite
{
	public var vertical:Int;
	public var horizontal:Int;

	public var isRotate:Bool;

	public function new(horizontal:Int, vertical:Int)
	{
		super();

		this.vertical = vertical;
		this.horizontal = horizontal;

		isRotate = vertical == 0 && horizontal == 0;

		mouseChildren = false;
		buttonMode = true;

		graphics.beginFill(KadabraUtils.KADABRA_COLOR, 1);
		if (!isRotate)
			graphics.drawRect(-5, -5, 10, 10);
		else
			graphics.drawCircle(0, 0, 5);
		graphics.endFill();
	}
}
