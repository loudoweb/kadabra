import utils.KadabraUtils;
import openfl.display.Sprite;

class Gizmo extends Sprite
{
	public var vertical:Int;
	public var horizontal:Int;

	public var isRotate:Bool;

	public function new(vertical:Int, horizontal:Int)
	{
		super();

		this.vertical = vertical;
		this.horizontal = horizontal;

		isRotate = vertical == 0 && horizontal == 0;

		mouseChildren = false;
		buttonMode = true;

		graphics.beginFill(KadabraUtils.KADABRA_COLOR, 1);
		graphics.drawRect(-4, -4, 8, 8);
		graphics.endFill();
	}
}
