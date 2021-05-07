package utils;

import feathers.skins.UnderlineSkin;
import feathers.skins.RectangleSkin;
import feathers.controls.Label;
import feathers.controls.LayoutGroup;
import feathers.layout.HorizontalLayout;

class UIFactory
{
	static public function createHeader(title:String, ?icon:String, ?iconSize:Int):LayoutGroup
	{
		var skin = new UnderlineSkin(KadabraUtils.HEADER_FILL, KadabraUtils.HEADER_BORDER);
		var layout = new HorizontalLayout();
		layout.horizontalAlign = JUSTIFY;
		var header = new LayoutGroup();
		header.variant = LayoutGroup.VARIANT_TOOL_BAR;
		header.height = KadabraUtils.HEADER_THICKNESS;
		header.backgroundSkin = skin;
		header.layout = layout;
		if (icon != null)
		{
			var _icon = KadabraUtils.getIcon(icon);
			if (iconSize != null)
				_icon.width = _icon.height = iconSize;
			header.addChild(_icon);
		}
		// new HorizontalLayoutData(100, 50);
		// header.autoSizeMode = STAGE;
		var label = new Label();
		label.text = title;
		label.textFormat = KadabraUtils.HEADER_FORMAT;
		header.addChild(label);
		return header;
	}
}
