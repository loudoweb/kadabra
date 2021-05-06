package panels;

import feathers.layout.HorizontalLayoutData;
import utils.UIFactory;
import feathers.controls.LayoutGroup;

class PropertiesPanel extends LayoutGroup
{
	public function new():Void
	{
		super();

		width = 300;
		minWidth = 300;
		maxWidth = 600;
		layoutData = new HorizontalLayoutData(100.0);

		addChild(UIFactory.createHeader("Properties"));
	}
}
