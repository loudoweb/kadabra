package panels;

import feathers.skins.RectangleSkin;
import utils.KadabraUtils;
import openfl.utils.Assets;
import openfl.display.Bitmap;
import openfl.display.PixelSnapping;
import feathers.controls.AssetLoader;
import feathers.controls.Button;
import utils.UIFactory;
import feathers.layout.VerticalLayout;
import feathers.controls.LayoutGroup;

class ToolPanel extends LayoutGroup
{
	static var buttonsName = [
		"icon-cursor",
		"icon-graphic-circle",
		"icon-graphic-square",
		"icon-square",
		"icon-circle",
		"icon-point",
		"icon-polygon",
		"icon-text",
		"icon-fx"
	];

	public function new()
	{
		super();

		var _layout = new VerticalLayout();
		_layout.horizontalAlign = CENTER;
		_layout.gap = 18;
		layout = _layout;
		width = 45;
		minWidth = 45;
		maxWidth = 60;

		addChild(UIFactory.createHeader("Tools"));

		for (buttonName in buttonsName)
		{
			var button = new Button();
			button.name = buttonName;
			button.icon = KadabraUtils.getIcon(buttonName);
			button.width = 26;
			button.height = 26;
			button.buttonMode = true;
			button.backgroundSkin = new RectangleSkin(KadabraUtils.ICON_FILL, KadabraUtils.ICON_BORDER);
			addChild(button);
		}
	}
}
