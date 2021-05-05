import openfl.ui.Mouse;
import hl.UI.Window;
import openfl.ui.MouseCursor;
import lime.ui.MouseCursor;
import feathers.controls.ScrollContainer;
import openfl.geom.Point;
import feathers.skins.RectangleSkin;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.system.Capabilities;
import openfl.Assets;
import openfl.Lib;

class KadabraCanvas extends Sprite {

    public var background:RectangleSkin;
	var imageContainer:Sprite;

	public var offsets:Array<Float>;
	var gizmoOffsetX:Float;
	var gizmoOffsetY:Float;

	public var selectedImages:List<KadabraImage>;

	public var dragging = false;

	var upOrigin:Float;
	var downOrigin:Float;
	var leftOrigin:Float;
	var rightOrigin:Float;
	var gizmosHeight:Float;
	var gizmosWidth:Float;

	var gizmoUL:Gizmo;
	var gizmoU:Gizmo;
	var gizmoUR:Gizmo;
	var gizmoL:Gizmo;
	var gizmoR:Gizmo;
	var gizmoDL:Gizmo;
	var gizmoD:Gizmo;
	var gizmoDR:Gizmo;

	var currentGizmo:Gizmo;

	var scaleDone = false;
	var forceCalcul = false;

	var ratio:Float;

	public var scrollX:Float;
	public var scrollY:Float;
	public var scrollSpeedX = 0.;
	public var scrollSpeedY = 0.;

    public function new () {
		
		super ();
		
		initialize ();
		construct ();
		
	}

    private function construct ():Void {

		//graphics.beginFill(0xCCCCCC, 1);
		//graphics.drawRect(-200,-200,600,600);
		//graphics.endFill();
		background = new RectangleSkin();
		background.width = 3000;
		background.height = 2000;
		background.fill = SolidColor(0xCCCCCC);
		background.mouseEnabled = false;

		addChild (background);

		addChild (imageContainer);

		addEventListener(Event.ADDED_TO_STAGE, onAddedtoStage);
		
	}

    private function initialize ():Void {

		imageContainer = new Sprite();
		
		offsets = [];
		selectedImages = new List<KadabraImage>();

		gizmoDL = new Gizmo(1, -1);
		gizmoD = new Gizmo(1, 0);
		gizmoDR = new Gizmo(1, 1);
		gizmoUL = new Gizmo(-1, -1);
		gizmoU = new Gizmo(-1, 0);
		gizmoUR = new Gizmo(-1, 1);
		gizmoL = new Gizmo(0, -1);
		gizmoR = new Gizmo(0, 1);

		//opaqueBackground = 0x7F0000;
	}

	private function onAddedtoStage(event:Event){

		stage.window.onDropFile.add(dragNDrop);
		stage.addEventListener (MouseEvent.MOUSE_DOWN, startDragging, true);
		stage.addEventListener (MouseEvent.MOUSE_UP, stopDragging);
		stage.addEventListener (MouseEvent.CLICK, selectImage, true);

		stage.addEventListener (MouseEvent.RELEASE_OUTSIDE, onMouseUp);
	}

    private function dragNDrop(path:String){

		//Add an image object when an image file is dropped in the window
		BitmapData.loadFromFile(path).onComplete(function (bitmapdata){
			var image = new KadabraImage (bitmapdata);
			imageContainer.addChild(image);
			var splitPath = path.split("\\");
			image.name = splitPath[splitPath.length - 1];

			for (image in selectedImages) {
				image.unselect();
			} 
			selectedImages.clear();
			selectedImages.add(image);
			selectedImages.last().select();

			var imagePoint = new Point(stage.mouseX, stage.mouseY);
			imagePoint = globalToLocal(imagePoint);

			image.x = imagePoint.x;
			image.y = imagePoint.y;

			offsets = [];
			offsets.push(x + parent.parent.x + image.width / 2 - scrollX);
			offsets.push(y + parent.parent.parent.y + image.height / 2 - scrollY);

			stage.addEventListener (MouseEvent.MOUSE_MOVE, dragImage);
		});
	}
	
	private function startDragging (event:MouseEvent):Void{
		
		if (Std.is (event.target, KadabraImage)) {
			if (selectedImages.isEmpty()){
				selectedImages.add(cast (event.target, KadabraImage));
				selectedImages.last().select();
			}

			if (!event.shiftKey){		//if Shift is pressed while clicking an image, it is added to the selection
				if((selectedImages.filter(function(image) { return (image == cast (event.target, KadabraImage));})).isEmpty()){
					for (image in selectedImages) {
						image.unselect();
					} 
					selectedImages.clear();
					selectedImages.add(cast (event.target, KadabraImage));
					selectedImages.last().select();
				}
			}

			for (image in selectedImages){
				offsets.push(event.stageX - image.x);
				offsets.push(event.stageY - image.y);
			}

			stage.addEventListener (MouseEvent.MOUSE_MOVE, dragImage);
			
		}
		else if (Std.is (event.target, Gizmo)) {
			currentGizmo = cast (event.target, Gizmo);
			gizmoOffsetX = event.stageX - currentGizmo.x;
			gizmoOffsetY = event.stageY - currentGizmo.y;

			stage.addEventListener(MouseEvent.MOUSE_MOVE, scale);
		}
	}

	private function stopDragging (event:MouseEvent):Void{
		stage.removeEventListener (MouseEvent.MOUSE_MOVE, dragImage);
		stage.removeEventListener (MouseEvent.MOUSE_MOVE, scale);
		offsets = [];

		for (image in selectedImages){
			image.defaultHeight = image.height;
			image.defaultWidth = image.width;
			image.defaultX = image.x;
			image.defaultY = image.y;
		}
		
		updateGizmos();
	}

	private function dragImage (event:MouseEvent):Void{
		if (!dragging) {
			dragging = true;

			removeChild(gizmoUL);
			removeChild(gizmoU);
			removeChild(gizmoUR);
			removeChild(gizmoL);
			removeChild(gizmoR);
			removeChild(gizmoDL);
			removeChild(gizmoD);
			removeChild(gizmoDR);
		}

		var containerPoint = new Point(scrollX, scrollY);
		containerPoint = parent.localToGlobal(containerPoint);

		if (event.stageX < containerPoint.x) {
			//stage.window.warpMouse(Std.int(containerPoint.x), Std.int(event.stageY));
			scrollSpeedX = (event.stageX - containerPoint.x) / 50;
		}
		else if (event.stageX > containerPoint.x + parent.parent.width){
			//stage.window.warpMouse(Std.int(containerPoint.x + parent.parent.width), Std.int(event.stageY));
			scrollSpeedX = (event.stageX - (containerPoint.x + parent.parent.width)) / 50;
		}
		else {
			scrollSpeedX = 0;
		}

		if (event.stageY < containerPoint.y) {
			//stage.window.warpMouse(Std.int(event.stageX), Std.int(containerPoint.y));
			scrollSpeedY = (event.stageY - containerPoint.y) / 20;
		}
		else if (event.stageY > containerPoint.y + parent.parent.height){
			//stage.window.warpMouse(Std.int(event.stageX), Std.int(containerPoint.y + parent.parent.height));
			scrollSpeedY = (event.stageY - (containerPoint.y + parent.parent.height)) / 20;
		}
		else {
			scrollSpeedY = 0;
		}

		var i = 0;
		for (image in selectedImages){
			image.x = event.stageX - offsets[i*2];
			image.y = event.stageY - offsets[i*2+1];

			if (image.x < -x) {
				image.x = -x;
			}
			else if (image.x + image.width > background.width + x) {
				image.x = background.width + x - image.width;
			}

			if (image.y < -y) {
				image.y = -y;
			}
			else if (image.y + image.height > background.height + y) {
				image.y = background.height + y - image.height;
			}

			++i;
		}

		event.updateAfterEvent();
	}

	private function scale (event:MouseEvent):Void{
		if (currentGizmo.up) {
			scaleUp(event);
			var scaleUpDone = scaleDone;
			if (currentGizmo.left) {
				scaleLeft(event);
			}
			else if (currentGizmo.right) {
				scaleRight(event);
			}
			if (!scaleUpDone && !scaleDone) {	//force scaleUp if cursor is in the image
				forceCalcul = true;
				scaleUp(event);
				scaleDone = false;
			}
		}

		else if (currentGizmo.down) {
			scaleDown(event);
			var scaleDownDone = scaleDone;
			if (currentGizmo.left) {
				scaleLeft(event);
			}
			else if (currentGizmo.right) {
				scaleRight(event);
			}
			if (!scaleDownDone && !scaleDone) {	//force scaleDown if cursor is in the image
				forceCalcul = true;
				scaleDown(event);
				scaleDone = false;
			}
		}

		else if (currentGizmo.left) {
			scaleLeft(event);
		}

		else if (currentGizmo.right) {
			scaleRight(event);
		}

		event.updateAfterEvent();
	}

	private function scaleUp (event:MouseEvent):Void{
		if (!event.altKey){
			if (currentGizmo.left || currentGizmo.right){
				if (!scaleDone) {
					//if the cursor is at the left or right of the currentGizmo (depending on its left and right booleans), the Gizmo's position is determined by the cursor's Y coord
					if (Math.abs(event.stageX - gizmoOffsetX - gizmoL.x - gizmosWidth / 2) > Math.abs(currentGizmo.x - gizmoL.x - gizmosWidth / 2) || forceCalcul) {
						gizmosHeight = downOrigin - (event.stageY - gizmoOffsetY);

						if (gizmosHeight <= 0) {	//minimum Height
							gizmosHeight = 0.01;
						}

						gizmoUL.y = gizmoU.y = gizmoUR.y = event.stageY - gizmoOffsetY;
						gizmoL.y = gizmoR.y = (event.stageY - gizmoOffsetY) + gizmosHeight / 2;

						gizmosWidth = gizmosHeight / ratio;
						if (currentGizmo.left) {
							gizmoUL.x = gizmoL.x = gizmoDL.x = rightOrigin - gizmosWidth;
							gizmoU.x = gizmoD.x = rightOrigin - gizmosWidth / 2;
						}
						else if (currentGizmo.right) {
							gizmoUR.x = gizmoR.x = gizmoDR.x = leftOrigin + gizmosWidth;
							gizmoU.x = gizmoD.x = leftOrigin + gizmosWidth / 2;
						}

						scaleDone = true;
						forceCalcul = false;
					}
				}
				else {
					scaleDone = false;
				}
			}
			else {
				gizmosHeight = downOrigin - (event.stageY - gizmoOffsetY);
				gizmoUL.y = gizmoU.y = gizmoUR.y = event.stageY - gizmoOffsetY;
				gizmoL.y = gizmoR.y = (event.stageY - gizmoOffsetY) + gizmosHeight / 2;
			}
		}
		else {
		gizmosHeight = downOrigin - (event.stageY - gizmoOffsetY);
		gizmoUL.y = gizmoU.y = gizmoUR.y = event.stageY - gizmoOffsetY;
		gizmoL.y = gizmoR.y = (event.stageY - gizmoOffsetY) + gizmosHeight / 2;
		}

		if (gizmoU.y >= downOrigin){	//minimum scale
			gizmosHeight = 0.01;
			gizmoUL.y = gizmoU.y = gizmoUR.y = downOrigin - gizmosHeight;
			gizmoL.y = gizmoR.y = downOrigin - gizmosHeight;
		}

		for (image in selectedImages){
			image.height = image.defaultHeight * ((downOrigin - gizmoU.y) / (downOrigin - upOrigin));
			image.y = gizmoU.y + (image.defaultY - upOrigin) * ((downOrigin - gizmoU.y) / (downOrigin - upOrigin));
		}
	}

	private function scaleDown (event:MouseEvent):Void{
		if (!event.altKey){
			if (currentGizmo.left || currentGizmo.right){
				if (!scaleDone) {
					//if the cursor is at the left or right of the currentGizmo (depending on its left and right booleans), the Gizmo's position is determined by the cursor's Y coord
					if (Math.abs(event.stageX - gizmoOffsetX - gizmoL.x - gizmosWidth / 2) > Math.abs(currentGizmo.x - gizmoL.x - gizmosWidth / 2) || forceCalcul) {
						gizmosHeight = (event.stageY - gizmoOffsetY) - upOrigin;

						if (gizmosHeight <= 0) {	//minimum Height
							gizmosHeight = 0.01;
						}

						gizmoDL.y = gizmoD.y = gizmoDR.y = event.stageY - gizmoOffsetY;
						gizmoL.y = gizmoR.y = upOrigin + gizmosHeight / 2;

						gizmosWidth = gizmosHeight / ratio;
						if (currentGizmo.left) {
							gizmoUL.x = gizmoL.x = gizmoDL.x = rightOrigin - gizmosWidth;
							gizmoU.x = gizmoD.x = rightOrigin - gizmosWidth / 2;
						}
						else if (currentGizmo.right) {
							gizmoUR.x = gizmoR.x = gizmoDR.x = leftOrigin + gizmosWidth;
							gizmoU.x = gizmoD.x = leftOrigin + gizmosWidth / 2;
						}

						scaleDone = true;
						forceCalcul = false;
					}
				}
				else {
					scaleDone = false;
				}
			}
			else {
				gizmosHeight = (event.stageY - gizmoOffsetY) - upOrigin;
				gizmoDL.y = gizmoD.y = gizmoDR.y = event.stageY - gizmoOffsetY;
				gizmoL.y = gizmoR.y = upOrigin + gizmosHeight / 2;
			}
		}
		else {
			gizmosHeight = (event.stageY - gizmoOffsetY) - upOrigin;
			gizmoDL.y = gizmoD.y = gizmoDR.y = event.stageY - gizmoOffsetY;
			gizmoL.y = gizmoR.y = upOrigin + gizmosHeight / 2;
		}
		
		if (gizmoD.y <= upOrigin){	//minimum scale
			gizmosHeight = 0.01;
			gizmoDL.y = gizmoD.y = gizmoDR.y = upOrigin + gizmosHeight;
			gizmoL.y = gizmoR.y = upOrigin + gizmosHeight;
		}

		for (image in selectedImages){
			image.height = image.defaultHeight * ((gizmoD.y - upOrigin) / (downOrigin - upOrigin));
			image.y = upOrigin + (image.defaultY - upOrigin) * ((gizmoD.y - upOrigin) / (downOrigin - upOrigin));
		}
	}

	private function scaleLeft (event:MouseEvent):Void{
		if (!event.altKey) {
			if (currentGizmo.up || currentGizmo.down) {
				if (!scaleDone) {
					//if the cursor is abose or below the currentGizmo (depending on its up and down booleans), the Gizmo's position is determined by the cursor's X coord
					if (Math.abs(event.stageY - gizmoOffsetY - gizmoU.y - gizmosHeight / 2) >= Math.abs(currentGizmo.y - gizmoU.y - gizmosHeight / 2)) {
						gizmosWidth = rightOrigin - (event.stageX - gizmoOffsetX);

						if (gizmosWidth <= 0) {	//minimum Width
							gizmosWidth = 0.01;
						}

						gizmoUL.x = gizmoL.x = gizmoDL.x = event.stageX - gizmoOffsetX;
						gizmoU.x = gizmoD.x = (event.stageX - gizmoOffsetX) + gizmosWidth / 2;

						gizmosHeight = gizmosWidth * ratio;
						if (currentGizmo.up) {
							gizmoUL.y = gizmoU.y = gizmoUR.y = downOrigin - gizmosHeight;
							gizmoL.y = gizmoR.y = downOrigin - gizmosHeight / 2;
						}
						else if (currentGizmo.down) {
							gizmoDL.y = gizmoD.y = gizmoDR.y = upOrigin + gizmosHeight;
							gizmoL.y = gizmoR.y = upOrigin + gizmosHeight / 2;
						}

						scaleDone = true;
					}
				}
				else {
					scaleDone = false;
				}
			}
			else {
				gizmosWidth = rightOrigin - (event.stageX - gizmoOffsetX);
				gizmoUL.x = gizmoL.x = gizmoDL.x = event.stageX - gizmoOffsetX;
				gizmoU.x = gizmoD.x = (event.stageX - gizmoOffsetX) + gizmosWidth / 2;
			}
		}
		else {
			gizmosWidth = rightOrigin - (event.stageX - gizmoOffsetX);
			gizmoUL.x = gizmoL.x = gizmoDL.x = event.stageX - gizmoOffsetX;
			gizmoU.x = gizmoD.x = (event.stageX - gizmoOffsetX) + gizmosWidth / 2;
		}

		if (gizmoL.x >= rightOrigin){	//minimum scale
			gizmosWidth = 0.01;
			gizmoUL.x = gizmoL.x = gizmoDL.x = rightOrigin - gizmosWidth;
			gizmoU.x = gizmoD.x = rightOrigin - gizmosWidth;
		}

		for (image in selectedImages){
			image.width = image.defaultWidth * ((rightOrigin - gizmoL.x) / (rightOrigin - leftOrigin));
			image.x = gizmoL.x + (image.defaultX - leftOrigin) * ((rightOrigin - gizmoL.x) / (rightOrigin - leftOrigin));
		}
	}

	private function scaleRight (event:MouseEvent):Void{
		if (!event.altKey){
			if (currentGizmo.up || currentGizmo.down) {
				if (!scaleDone){
					//if the cursor is abose or below the currentGizmo (depending on its up and down booleans), the Gizmo's position is determined by the cursor's X coord
					if (Math.abs(event.stageY - gizmoOffsetY - gizmoU.y - gizmosHeight / 2) >= Math.abs(currentGizmo.y - gizmoU.y - gizmosHeight / 2)) {
						gizmosWidth = (event.stageX - gizmoOffsetX) - leftOrigin;

						if (gizmosWidth <= 0) {	//minimum Width
							gizmosWidth = 0.01;
						}

						gizmoUR.x = gizmoR.x = gizmoDR.x = event.stageX - gizmoOffsetX;
						gizmoU.x = gizmoD.x = leftOrigin + gizmosWidth / 2;

						gizmosHeight = gizmosWidth * ratio;
						if (currentGizmo.up) {
							gizmoUL.y = gizmoU.y = gizmoUR.y = downOrigin - gizmosHeight;
							gizmoL.y = gizmoR.y = downOrigin - gizmosHeight / 2;
						}
						else if (currentGizmo.down) {
							gizmoDL.y = gizmoD.y = gizmoDR.y = upOrigin + gizmosHeight;
							gizmoL.y = gizmoR.y = upOrigin + gizmosHeight / 2;
						}

						scaleDone = true;
					}
				}
				else {
					scaleDone = false;
				}
			}
			else {
				gizmosWidth = (event.stageX - gizmoOffsetX) - leftOrigin;
				gizmoUR.x = gizmoR.x = gizmoDR.x = event.stageX - gizmoOffsetX;
				gizmoU.x = gizmoD.x = leftOrigin + gizmosWidth / 2;
			}
		}
		else {
			gizmosWidth = (event.stageX - gizmoOffsetX) - leftOrigin;
			gizmoUR.x = gizmoR.x = gizmoDR.x = event.stageX - gizmoOffsetX;
			gizmoU.x = gizmoD.x = leftOrigin + gizmosWidth / 2;
		}

		if (gizmoR.x <= leftOrigin){	//minimum scale
			gizmosWidth = 0.01;
			gizmoUR.x = gizmoR.x = gizmoDR.x = leftOrigin + gizmosWidth;
			gizmoU.x = gizmoD.x = leftOrigin + gizmosWidth;
		}

		for (image in selectedImages){
			image.width = image.defaultWidth * ((gizmoR.x - leftOrigin) / (rightOrigin - leftOrigin));
			image.x = leftOrigin + (image.defaultX - leftOrigin) * ((gizmoR.x - leftOrigin) / (rightOrigin - leftOrigin));
		}
	}

	private function selectImage (event:MouseEvent):Void{
		if (!dragging) {
			if (Std.is (event.target, KadabraImage)) {
				if (event.shiftKey){
					if (!(cast (event.target, KadabraImage)).isSelected){
						selectedImages.add(cast (event.target, KadabraImage));
						selectedImages.last().select();
					}
				}
				else {
					for (image in selectedImages) {
						image.unselect();
					} 
					selectedImages.clear();
					selectedImages.add(cast (event.target, KadabraImage));
					selectedImages.last().select();
				}
			}
			else if (!Std.is (event.target, Gizmo)){
				for (image in selectedImages) {
					image.unselect();
				} 
				selectedImages.clear();
			}
			updateGizmos();
		}
		else{
			dragging = false;
		}
	}

	private function updateGizmos (){	//puts gizmos on the corners and in the middle of the sides of the selection
		if (selectedImages.isEmpty()){
			removeChild(gizmoUL);
			removeChild(gizmoU);
			removeChild(gizmoUR);
			removeChild(gizmoL);
			removeChild(gizmoR);
			removeChild(gizmoDL);
			removeChild(gizmoD);
			removeChild(gizmoDR);
		}
		else {
			addChild(gizmoUL);
			addChild(gizmoU);
			addChild(gizmoUR);
			addChild(gizmoL);
			addChild(gizmoR);
			addChild(gizmoDL);
			addChild(gizmoD);
			addChild(gizmoDR);

			upOrigin = stage.height;
			downOrigin = -800;
			leftOrigin = stage.width;
			rightOrigin = -800;

			for (image in selectedImages){	//determines bounds of the selection
				if (image.y < upOrigin){
					upOrigin = image.y;
				}
				if (image.y + image.height > downOrigin){
					downOrigin = image.y + image.height;
				}
				if (image.x < leftOrigin){
					leftOrigin = image.x;
				}
				if (image.x + image.width > rightOrigin){
					rightOrigin = image.x + image.width;
				}
			}

			gizmosHeight = downOrigin - upOrigin;
			gizmosWidth = rightOrigin - leftOrigin;

			ratio = gizmosHeight / gizmosWidth;

			gizmoUL.x = leftOrigin;
			gizmoUL.y = upOrigin;

			gizmoU.x = leftOrigin + gizmosWidth / 2;
			gizmoU.y = upOrigin;
			
			gizmoUR.x = rightOrigin;
			gizmoUR.y = upOrigin;
			
			gizmoL.x = leftOrigin;
			gizmoL.y = upOrigin + gizmosHeight / 2;
			
			gizmoR.x = rightOrigin;
			gizmoR.y = upOrigin + gizmosHeight / 2;
			
			gizmoDL.x = leftOrigin;
			gizmoDL.y = downOrigin;
			
			gizmoD.x = leftOrigin + gizmosWidth / 2;
			gizmoD.y = downOrigin;
			
			gizmoDR.x = rightOrigin;
			gizmoDR.y = downOrigin;
		}
	}

	function onMouseUp(e:MouseEvent) {
        dragging = false;
    }
}