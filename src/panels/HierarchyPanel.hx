package panels;

import utils.UIFactory;
import feathers.data.ArrayHierarchicalCollection;
import feathers.controls.TreeView;

class HierarchyPanel extends TreeView
{
	public function new():Void
	{
		super();
		var hierarchyData = new ArrayHierarchicalCollection();
		dataProvider = hierarchyData;
		width = 60;
		minWidth = 180;
		maxWidth = 800;

		addChild(UIFactory.createHeader("Hierarchy"));
	}
}
