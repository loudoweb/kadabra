import utils.KadabraUtils;
import openfl.display.Sprite;

class KadabraPoint extends Sprite
{
	public var X:Float;
	public var Y:Float;

	public var isSelected:Bool;

	public function new()
	{
		super();

		isSelected = false;
		mouseChildren = false;
		buttonMode = true;

		select();
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
		}
	}

	public function unselect():Void
	{
		if (isSelected)
		{
			isSelected = false;

			graphics.clear();
			graphics.lineStyle(0x000000, 2);
			graphics.beginFill(0xFFFFFF);
			graphics.drawCircle(0, 0, 4);
			graphics.endFill();
		}
	}
}
