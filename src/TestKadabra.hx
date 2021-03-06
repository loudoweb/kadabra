import openfl.text.TextField;
import openfl.display.Bitmap;
import sys.KadabraClipboard;
import crashdumper.CrashDumper;
import crashdumper.SessionData;
import haxe.extension.EClipboard;
import feathers.layout.AnchorLayoutData;
import feathers.controls.TextInput;
import feathers.layout.AnchorLayout;
import openfl.display.Sprite;
import feathers.controls.HDividedBox;
import openfl.events.MouseEvent;
import feathers.controls.Button;
import openfl.events.Event;
import feathers.layout.VerticalLayout;
import feathers.layout.HorizontalLayoutData;
import feathers.controls.Panel;
import openfl.text.TextFormat;
import feathers.skins.RectangleSkin;
import feathers.controls.LayoutGroup;
import feathers.layout.HorizontalLayout;
import feathers.controls.Application;
import feathers.controls.Label;
import openfl.Assets;
import openfl.text.TextFieldAutoSize;
import format.SVG;

class MainKadabra extends Application
{
	var panel:LayoutGroup;

	public function new()
	{
		super();

		// crash logs system

		var unique_id:String = SessionData.generateID("kadabra_");
		var crashDumper = new CrashDumper(unique_id);

		// test clipboard
		trace("count");
		// trace(KadabraClipboard.count());
		trace('has');
		// trace(KadabraClipboard.has(EClipboard.TYPE_HTML));
		trace("image");
		var bd = KadabraClipboard.getImage();
		if (bd != null)
		{
			addChild(new Bitmap(bd));
		}
		trace('html');
		var html = KadabraClipboard.getString(TYPE_HTML);
		if (html != "")
		{
			trace(html);
			var tf = new TextField();
			tf.htmlText = html;
			tf.multiline = true;
			tf.wordWrap = true;
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.x = 200;
			tf.y = 200;
			tf.width = 500;
			addChild(tf);
		}
		trace('svg');
		var svgstr = KadabraClipboard.getString(TYPE_SVG);
		trace(svgstr);
		if (svgstr != "")
		{
			var svg = new SVG(svgstr);
			var spr = new Sprite();
			spr.x = 200;
			spr.y = 400;
			svg.render(spr.graphics);
			addChild(spr);
		}

		// application

		var darkSKin = new RectangleSkin();
		darkSKin.fill = SolidColor(0x262626); // 0x262626 333333 404040

		var semiDarkSkin = new RectangleSkin();
		semiDarkSkin.fill = SolidColor(0x333333);

		var greySkin = new RectangleSkin();
		semiDarkSkin.fill = SolidColor(0x404040);

		var vLayout = new VerticalLayout();
		vLayout.horizontalAlign = JUSTIFY;
		vLayout.verticalAlign = JUSTIFY;

		panel = new LayoutGroup();
		panel.layout = vLayout;
		panel.width = stage.stageWidth;
		panel.height = stage.stageHeight;

		panel.addChild(createHeader(darkSKin));
		panel.addChild(createMainBoxes(semiDarkSkin));

		addChild(panel);

		stage.addEventListener(Event.RESIZE, onResize);

		stage.addEventListener(Event.ENTER_FRAME, onUpdate);
	}

	function createHeader(skin:RectangleSkin):LayoutGroup
	{
		var layout = new HorizontalLayout();
		layout.horizontalAlign = JUSTIFY;

		var header = new LayoutGroup();
		header.variant = LayoutGroup.VARIANT_TOOL_BAR;
		header.height = 30;
		header.backgroundSkin = skin;
		header.layout = layout;
		// new HorizontalLayoutData(100, 50);
		// header.autoSizeMode = STAGE;
		var label = new Label();
		label.text = "Kadabra";
		label.textFormat = new TextFormat(Assets.getFont("assets/fonts/Roboto-Regular.ttf").fontName, 20, 0xFFFFFF);
		header.addChild(label);

		return header;
	}

	function createMainBoxes(skin:RectangleSkin):HDividedBox
	{
		var box = new HDividedBox();

		var tool = new LayoutGroup();
		tool.layout = new VerticalLayout();
		tool.width = 60;

		var canvas = new Sprite();

		var properties = new LayoutGroup();
		properties.width = 300;
		properties.minWidth = 300;

		box.addChild(tool);
		box.addChild(canvas);
		box.addChild(properties);

		return box;
	}

	function onResize(e:Event):Void
	{
		panel.width = stage.stageWidth;
		panel.height = stage.stageHeight;
	}

	function onUpdate(e:Event):Void
	{
		// stage.window.x, stage.window.y; //pour bouger window avec borderless false
	}
}
