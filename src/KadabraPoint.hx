import utils.KadabraUtils;
import openfl.display.Sprite;

class KadabraPoint extends Sprite
{
	public var X:Float;
	public var Y:Float;

	public var isSelected = true;

	public function new()
	{
		super();

		mouseChildren = false;
		buttonMode = true;

		graphics.beginFill(KadabraUtils.KADABRA_COLOR, 1);
		graphics.drawCircle(0, 0, 4);
		graphics.endFill();

		graphics.beginFill(0x000000, 1);
		graphics.drawCircle(0, 0, 3);
		graphics.endFill();
	}

	public function select():Void
	{
		if (!isSelected)
		{
			isSelected = true;

			graphics.clear();
			graphics.beginFill(KadabraUtils.KADABRA_COLOR, 1);
			graphics.drawCircle(0, 0, 4);
			graphics.endFill();

			graphics.beginFill(0x000000, 1);
			graphics.drawCircle(0, 0, 3);
			graphics.endFill();
		}
	}

	public function unselect():Void
	{
		if (isSelected)
		{
			isSelected = false;

			graphics.clear();
			graphics.beginFill(0x000000, 1);
			graphics.drawCircle(0, 0, 4);
			graphics.endFill();

			graphics.beginFill(KadabraUtils.KADABRA_COLOR, 1);
			graphics.drawCircle(0, 0, 3);
			graphics.endFill();
		}
	}
}
