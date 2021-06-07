package panels;

import feathers.layout.VerticalLayoutData;
import feathers.layout.HorizontalLayoutData;
import feathers.layout.VerticalLayout;
import feathers.controls.LayoutGroup;
import openfl.display.Sprite;
import utils.UIFactory;
import feathers.data.ArrayHierarchicalCollection;
import feathers.controls.TreeView;
import openfl.events.Event;

class HierarchyPanel extends LayoutGroup
{
	var tree:TreeView;

	public function new():Void
	{
		super();

		width = 180;
		minWidth = 180;
		maxWidth = 800;

		var _layout = new VerticalLayout();
		_layout.horizontalAlign = LEFT;
		_layout.gap = 18;
		layout = _layout;
		layoutData = new VerticalLayoutData(100.0, 100.0);

		tree = new TreeView(new ArrayHierarchicalCollection());
		tree.layoutData = new VerticalLayoutData(100.0, 100.0);

		addChild(UIFactory.createHeader("Hierarchy"));
		addChild(tree);

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	function onAddedToStage(e:Event)
	{
		KadabraScene.addedChild.add(addAsset);
		KadabraScene.removedChild.add(removeAsset);
	}

	public function addAsset(asset:Sprite):Void
	{
		tree.dataProvider.addAt(asset.name, [0]);
	}

	public function removeAsset(asset:Sprite):Void
	{
		tree.dataProvider.remove(asset.name);
	}
}
