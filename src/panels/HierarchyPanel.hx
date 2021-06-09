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
	public static var onAssetSelected:lime.app.Event<String->Void> = new lime.app.Event<String->Void>();

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

		tree.addEventListener(Event.CHANGE, treeView_changeHandler);
	}

	function onAddedToStage(e:Event)
	{
		KadabraScene.onChildAdded.add(addAsset);
		KadabraScene.onChildRemoved.add(removeAsset);
		KadabraScene.onAssetSelected.add(selectAsset);
	}

	public function addAsset(asset:Sprite):Void
	{
		tree.dataProvider.addAt(asset.name, [0]);
	}

	public function removeAsset(asset:Sprite):Void
	{
		tree.dataProvider.remove(asset.name);
	}

	public function selectAsset(asset:Sprite):Void
	{
		tree.selectedItem = asset.name;
	}

	function treeView_changeHandler(event:Event):Void
	{
		if (tree.selectedItem != null)
		{
			trace(tree.selectedItem);
			onAssetSelected.dispatch(tree.selectedItem);
		}
	}
}
