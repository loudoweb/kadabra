import openfl.display.Sprite;

class Pivot extends Sprite
{
	public var X:Float;
	public var Y:Float;

	public function new()
	{
		super();

		X = 0.;
		Y = 0.;

		mouseChildren = false;
		buttonMode = true;

		graphics.beginFill(0x000000, 1);
		graphics.drawCircle(0, 0, 4);
		graphics.endFill();

		graphics.beginFill(0xFFFFFF, 1);
		graphics.drawCircle(0, 0, 3);
		graphics.endFill();
	}

	inline public function setPivot(X:Float, Y:Float):Void
	{
		this.X = X;
		this.Y = Y;
	}

	inline public function updatePos(width:Float, height:Float):Void
	{
		x = width * X;
		y = height * Y;
	}
}
