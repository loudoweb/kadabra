package panels;

import openfl.display.Sprite;
import utils.UIFactory;
import feathers.data.ArrayHierarchicalCollection;
import feathers.controls.TreeView;
import openfl.events.Event;

class HierarchyPanel extends TreeView
{
	public function new():Void
	{
		super();
		var hierarchyData = new ArrayHierarchicalCollection();
		dataProvider = hierarchyData;
		width = 180;
		minWidth = 180;
		maxWidth = 800;

		addChild(UIFactory.createHeader("Hierarchy"));

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	function onAddedToStage(event:Event)
	{
		KadabraScene.addedChild.add(addAsset);
		KadabraScene.removedChild.add(removeAsset);
	}

	public function addAsset(asset:Sprite):Void
	{
		dataProvider.addAt(asset.name, [0]);
	}

	public function removeAsset(asset:Sprite):Void
	{
		dataProvider.remove(asset.name);
	}
}
