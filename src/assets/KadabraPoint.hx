package assets;

import utils.KadabraUtils;
import openfl.display.Sprite;

class KadabraPoint extends KadabraAsset
{
	public var X:Float;
	public var Y:Float;

	public function new()
	{
		super();

		mouseChildren = false;
		buttonMode = true;

		type = POINT;
	}

	override public function select():Void
	{
		super.select();

		if (isSelected)
		{
			graphics.clear();
			graphics.beginFill(KadabraUtils.KADABRA_COLOR, 1);
			graphics.drawCircle(0, 0, 4);
			graphics.endFill();
		}
	}

	override public function unselect():Void
	{
		super.unselect();
		if (!isSelected)
		{
			graphics.clear();
			graphics.lineStyle(0x000000, 2);
			graphics.beginFill(0xFFFFFF);
			graphics.drawCircle(0, 0, 4);
			graphics.endFill();
		}
	}
}
