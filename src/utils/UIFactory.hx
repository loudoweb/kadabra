package utils;

import feathers.layout.ILayoutData;
import feathers.layout.HorizontalLayoutData;
import feathers.controls.TextInput;
import feathers.layout.VerticalLayoutData;
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
		header.layoutData = new VerticalLayoutData(100.0);
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

	static public function createItemLabel(label:String, name:String, gap:Int = 10, ?glayout:ILayoutData,
			?iLayout:ILayoutData, useOnlyNumbers:Bool = false):
			{
				group:LayoutGroup,
				input:TextInput
			}
	{
		var item = new LayoutGroup();
		var _layout = new HorizontalLayout();
		_layout.gap = gap;
		item.layout = _layout;
		if (glayout != null)
			item.layoutData = glayout;

		var txt = new Label(label);
		txt.textFormat = KadabraUtils.FONT_NORMAL;

		var input = new TextInput();
		input.name = name;
		if (iLayout != null)
			input.layoutData = iLayout;
		if (useOnlyNumbers)
			input.restrict = "0-9\\.";

		item.addChild(txt);
		item.addChild(input);

		return {group: item, input: input};
	}
}
