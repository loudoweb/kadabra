package panels;

import feathers.skins.RectangleSkin;
import utils.KadabraUtils;
import feathers.layout.HorizontalLayout;
import feathers.layout.HorizontalLayoutData;
import feathers.controls.LayoutGroup;

class Footer extends LayoutGroup
{
	public function new()
	{
		super();

		layoutData = new HorizontalLayoutData(100.0);
		layout = new HorizontalLayout();
		// autoSizeMode = STAGE;
		height = KadabraUtils.HEADER_THICKNESS;

		backgroundSkin = new RectangleSkin(KadabraUtils.HEADER_FILL);
	}
}
