package panels;

import lime.app.Event;
import feathers.events.TriggerEvent;
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

	public static var selectedButton = "icon-cursor";

	public static var onButtonChange:Event<String->Void>;

	public function new()
	{
		super();

		onButtonChange = new Event<String->Void>();

		var _layout = new VerticalLayout();
		_layout.horizontalAlign = CENTER;
		_layout.gap = 18;
		layout = _layout;
		width = 50;
		minWidth = 50;
		maxWidth = 50;

		addChild(UIFactory.createHeader("Tools"));

		for (buttonName in buttonsName)
		{
			var button = new Button();
			button.name = buttonName;
			button.icon = KadabraUtils.getIcon(buttonName);
			button.width = 26;
			button.height = 26;
			button.buttonMode = true;
			if (button.name == selectedButton)
			{
				button.backgroundSkin = new RectangleSkin(KadabraUtils.SELECTED_FILL, KadabraUtils.ICON_BORDER);
			}
			else
			{
				button.backgroundSkin = new RectangleSkin(KadabraUtils.ICON_FILL, KadabraUtils.ICON_BORDER);
			}
			addChild(button);
			button.addEventListener(TriggerEvent.TRIGGER, selectButton);
		}
	}

	function selectButton(event:TriggerEvent):Void
	{
		var currentButton = cast(event.target, Button);
		if (selectedButton != currentButton.name)
		{
			var oldButton = cast(getChildByName(selectedButton), Button);
			oldButton.backgroundSkin = new RectangleSkin(KadabraUtils.ICON_FILL, KadabraUtils.ICON_BORDER);
			onButtonChange.dispatch(currentButton.name);
			selectedButton = currentButton.name;
			currentButton.backgroundSkin = new RectangleSkin(KadabraUtils.SELECTED_FILL, KadabraUtils.ICON_BORDER);
			trace(selectedButton);
		}
	}
}
