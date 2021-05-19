import openfl.display.Sprite;

class Gizmo extends Sprite
{
	public var vertical:Int;
	public var horizontal:Int;

	public function new(ver:Int, hor:Int)
	{
		super();

		vertical = ver;
		horizontal = hor;

		// the different gizmos have different colors to identify them during debug
		var rectColor = 0x7F007F;

		rectColor += vertical * 0x00007F + horizontal * 0x7F0000;

		mouseChildren = false;
		buttonMode = true;

		graphics.beginFill(rectColor, 1);
		graphics.drawRect(-4, -4, 8, 8);
		graphics.endFill();
	}
}
