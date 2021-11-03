import openfl.geom.Rectangle;
import assets.KadabraImage;
import assets.KadabraAsset;
import openfl.geom.Point;
import openfl.events.MouseEvent;
import lime.ui.KeyCode;
import io.InputPoll;
import openfl.display.Sprite;

using utils.KadabraUtils;

// TODO add flag isDirty to only draw graphics when necessary
class TransformTool extends Sprite
{
	public static var onTransform:lime.app.Event<Void->Void> = new lime.app.Event<Void->Void>();

	public var isActive(default, null):Bool;

	// mode
	public var hasPivot:Bool;
	public var hasScale:Bool;

	public var asset(default, null):KadabraAsset;

	public var gizmosHeight:Float;
	public var gizmosWidth:Float;

	var upOrigin:Float;
	var downOrigin:Float;
	var leftOrigin:Float;
	var rightOrigin:Float;

	var currentGizmo:Gizmo;

	var defaultAngle:Float;

	var pivotEnabled = true;

	var ratio:Float;

	var gizmoOffsetX:Float;
	var gizmoOffsetY:Float;

	var defaultX:Float;
	var defaultY:Float;

	var radianRotation:Float;
	var cosinus:Float;
	var sinus:Float;

	public var scaling = false;

	// asset
	var gizmoUL:Gizmo;
	var gizmoU:Gizmo;
	var gizmoUR:Gizmo;
	var gizmoL:Gizmo;
	var gizmoR:Gizmo;
	var gizmoDL:Gizmo;
	var gizmoD:Gizmo;
	var gizmoDR:Gizmo;

	var rotationGizmo:Gizmo;

	public var pivot:Pivot;

	public function new()
	{
		super();

		gizmoDL = new Gizmo(-1, 1);
		gizmoD = new Gizmo(0, 1);
		gizmoDR = new Gizmo(1, 1);
		gizmoUL = new Gizmo(-1, -1);
		gizmoU = new Gizmo(0, -1);
		gizmoUR = new Gizmo(1, -1);
		gizmoL = new Gizmo(-1, 0);
		gizmoR = new Gizmo(1, 0);

		rotationGizmo = new Gizmo(0, 0);

		pivot = new Pivot();

		addChild(gizmoUL);
		addChild(gizmoU);
		addChild(gizmoUR);
		addChild(gizmoL);
		addChild(gizmoR);
		addChild(gizmoDL);
		addChild(gizmoD);
		addChild(gizmoDR);

		addChild(rotationGizmo);

		addChild(pivot);
	}

	function onKeyDown(key:KKey):Void
	{
		switch (key.charCode)
		{
			case(KeyCode.P):
				if (pivotEnabled)
				{
					removeChild(pivot);
					pivotEnabled = false;
				}
				else
				{
					addChild(pivot);
					pivotEnabled = true;
				}
		}
	}

	function onMouseDown(e:MouseEvent):Void
	{
		if (Std.is(e.target, Gizmo))
		{
			currentGizmo = cast(e.target, Gizmo);
			var xValue = currentGizmo.x;
			var yValue = currentGizmo.y;

			if (currentGizmo.isRotate)
			{ // gizmo offsets depend on pivot coordinates only during rotation
				xValue -= pivot.x;
				yValue -= pivot.y;
			}

			gizmoOffsetX = e.stageX / scaleX - ((xValue) * cosinus - (yValue) * sinus);
			gizmoOffsetY = e.stageY / scaleY - ((xValue) * sinus + (yValue) * cosinus);

			defaultAngle = Math.atan((currentGizmo.x - pivot.x) / (currentGizmo.y - pivot.y));
			defaultX = asset.x + (pivot.x * cosinus - pivot.y * sinus);
			defaultY = asset.y + (pivot.x * sinus + pivot.y * cosinus);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMoveGizmo);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		else if (Std.is(e.target, Pivot))
		{
			// gizmoOffsets are here used for the pivot
			gizmoOffsetX = e.stageX / scaleX - (pivot.x * cosinus - pivot.y * sinus);
			gizmoOffsetY = e.stageY / scaleY - (pivot.x * sinus + pivot.y * cosinus);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMovePivot);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
	}

	function onMouseUp(e:MouseEvent):Void
	{
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMoveGizmo);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMovePivot);
		stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
	}

	function upSide(x:Float, y:Float, a:Point, b:Point)
	{
		return ((b.y - a.y) * (x - a.x) - (b.x - a.x) * (y - a.y)) >= 0;
	}

	function onMoveGizmo(e:MouseEvent):Void
	{
		trace(currentGizmo.horizontal, currentGizmo.vertical);
		if (currentGizmo.isRotate)
		{
			rotate(e);
		} else
		{
			scale(e);

			var oldGizmosHeight = gizmosHeight;
			var oldGizmosWidth = gizmosWidth;
			gizmosHeight = downOrigin - upOrigin;
			gizmosWidth = rightOrigin - leftOrigin;

			// TODO multi select + other asset type
			// image dimensions are adjusted and asset coordinates are changed to always keep upOrigin = LeftOrigin = 0
			var kimage:KadabraImage = cast asset;
			kimage.image.scaleX = (gizmosWidth / kimage.defaultWidth).roundDecimal(2);
			kimage.image.scaleY = (gizmosHeight / kimage.defaultHeight).roundDecimal(2);
			// rotate
			asset.x += leftOrigin * cosinus - upOrigin * sinus;
			asset.y += upOrigin * cosinus + leftOrigin * sinus;

			updateGizmos(kimage.image.getBounds(asset), pivot.x, pivot.y);
		}

		x = leftOrigin;
		y = upOrigin;

		onTransform.dispatch();
		e.updateAfterEvent();
	}

	function scale(e:MouseEvent):Void
	{
		if (!scaling)
		{
			scaling = true;
		}

		var coef = currentGizmo.vertical * currentGizmo.horizontal;
		if (coef != 0)
		{ // if coef != 0, currentGizmo is a corner
			if (!e.altKey)
			{ // preserving proportions
				var aPoint = new Point(0, 0);
				var bPoint = new Point(0, 0);

				if (coef < 0)
				{
					aPoint = new Point(gizmosHeight * sinus, gizmosHeight * cosinus);
					bPoint = new Point(gizmosWidth * cosinus, gizmosWidth * sinus);
				}
				else if (coef > 0)
				{
					aPoint = new Point(x, y);
					bPoint = new Point(gizmosWidth * cosinus - gizmosHeight * sinus,
						gizmosHeight * cosinus + gizmosWidth * sinus);
				}

				if (currentGizmo.vertical < 0)
				{ // is an Up gizmo
					if (!upSide(e.stageX / scaleX - gizmoOffsetX, e.stageY / scaleY - gizmoOffsetY, aPoint, bPoint))
					{
						var oldUpOrigin = upOrigin;
						upOrigin = (e.stageY / scaleY
							- gizmoOffsetY) * cosinus
							- (e.stageX / scaleX - gizmoOffsetX) * sinus;
						gizmoOffsetY += upOrigin;

						/*if (upOrigin >= downOrigin)
							{ // minimum scale
								gizmoOffsetY -= upOrigin - (downOrigin - 0.1);
								upOrigin = downOrigin - 0.1;
						}*/

						if (currentGizmo.horizontal < 0)
						{ // is a Left gizmo
							leftOrigin += (upOrigin - oldUpOrigin) / ratio;
							gizmoOffsetX += leftOrigin;
						}
						else if (currentGizmo.horizontal > 0)
						{ // is a Right gizmo
							rightOrigin -= (upOrigin - oldUpOrigin) / ratio;
						}
					}
					else
					{
						if (currentGizmo.horizontal < 0)
						{ // is a Left gizmo
							var oldLeftOrigin = leftOrigin;
							leftOrigin = (e.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (e.stageY / scaleY - gizmoOffsetY) * sinus;
							gizmoOffsetX += leftOrigin;

							/*if (leftOrigin >= rightOrigin)
								{ // minimum scale
									gizmoOffsetX -= leftOrigin - (rightOrigin - 0.1);
									leftOrigin = rightOrigin - 0.1;
							}*/

							upOrigin += (leftOrigin - oldLeftOrigin) * ratio;
							gizmoOffsetY += upOrigin;
						}
						else if (currentGizmo.horizontal > 0)
						{ // is a Right gizmo
							var oldRightOrigin = rightOrigin;
							rightOrigin = (e.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (e.stageY / scaleY - gizmoOffsetY) * sinus;

							/*if (rightOrigin <= leftOrigin)
								{ // minimum scale
									rightOrigin = leftOrigin + 0.1;
							}*/

							upOrigin += (oldRightOrigin - rightOrigin) * ratio;
							gizmoOffsetY += upOrigin;
						}
					}
				}
				else if (currentGizmo.vertical > 0)
				{ // is a Down gizmo
					if (upSide(e.stageX / scaleX - gizmoOffsetX, e.stageY / scaleY - gizmoOffsetY, aPoint, bPoint))
					{
						var oldDownOrigin = downOrigin;
						downOrigin = (e.stageY / scaleY
							- gizmoOffsetY) * cosinus
							- (e.stageX / scaleX - gizmoOffsetX) * sinus;

						/*if (downOrigin <= upOrigin)
							{ // minimum scale
								downOrigin = upOrigin + 0.1;
						}*/

						if (currentGizmo.horizontal < 0)
						{ // is a Left gizmo
							leftOrigin += (oldDownOrigin - downOrigin) / ratio;
							gizmoOffsetX += leftOrigin;
						}
						else if (currentGizmo.horizontal > 0)
						{ // is a Right gizmo
							rightOrigin -= (oldDownOrigin - downOrigin) / ratio;
						}
					}
					else
					{
						if (currentGizmo.horizontal < 0)
						{ // is a Left gizmo
							var oldLeftOrigin = leftOrigin;
							leftOrigin = (e.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (e.stageY / scaleY - gizmoOffsetY) * sinus;
							gizmoOffsetX += leftOrigin;

							/*if (leftOrigin >= rightOrigin)
								{ // minimum scale
									gizmoOffsetX -= leftOrigin - (rightOrigin - 0.1);
									leftOrigin = rightOrigin - 0.1;
							}*/

							downOrigin -= (leftOrigin - oldLeftOrigin) * ratio;
						}
						else if (currentGizmo.horizontal > 0)
						{ // is a Right gizmo
							var oldRightOrigin = rightOrigin;
							rightOrigin = (e.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (e.stageY / scaleY - gizmoOffsetY) * sinus;

							/*if (rightOrigin <= leftOrigin)
								{ // minimum scale
									rightOrigin = leftOrigin + 0.1;
							}*/

							downOrigin -= (oldRightOrigin - rightOrigin) * ratio;
						}
					}
				}
			}
			else
			{ // not preserving proportions
				if (currentGizmo.vertical < 0)
				{ // is an Up gizmo
					upOrigin = (e.stageY / scaleY
						- gizmoOffsetY) * cosinus
						- (e.stageX / scaleX - gizmoOffsetX) * sinus;
					gizmoOffsetY += upOrigin;

					/*if (upOrigin >= downOrigin)
						{
							gizmoOffsetY -= upOrigin - (downOrigin - 0.1);
							upOrigin = downOrigin - 0.1;
					}*/
				}
				else if (currentGizmo.vertical > 0)
				{ // is a Down gizmo
					downOrigin = (e.stageY / scaleY
						- gizmoOffsetY) * cosinus
						- (e.stageX / scaleX - gizmoOffsetX) * sinus;

					/*if (downOrigin <= upOrigin)
						{
							downOrigin = upOrigin + 0.1;
					}*/
				}

				if (currentGizmo.horizontal < 0)
				{ // is a Left gizmo
					leftOrigin = (e.stageX / scaleX
						- gizmoOffsetX) * cosinus
						+ (e.stageY / scaleY - gizmoOffsetY) * sinus;
					gizmoOffsetX += leftOrigin;

					/*if (leftOrigin >= rightOrigin)
						{
							gizmoOffsetX -= leftOrigin - (rightOrigin - 0.1);
							leftOrigin = rightOrigin - 0.1;
					}*/
				}
				else if (currentGizmo.horizontal > 0)
				{ // is a Right gizmo
					rightOrigin = (e.stageX / scaleX
						- gizmoOffsetX) * cosinus
						+ (e.stageY / scaleY - gizmoOffsetY) * sinus;

					/*if (rightOrigin <= leftOrigin)
						{
							rightOrigin = leftOrigin + 0.1;
					}*/
				}
			}
		}
		else
		{ // gizmo has only one direction
			if (currentGizmo.vertical < 0)
			{ // is an Up gizmo
				upOrigin = (e.stageY / scaleY - gizmoOffsetY) * cosinus - (e.stageX / scaleX - gizmoOffsetX) * sinus;
				gizmoOffsetY += upOrigin;

				/*if (upOrigin >= downOrigin)
					{
						gizmoOffsetY -= upOrigin - (downOrigin - 0.1);
						upOrigin = downOrigin - 0.1;
				}*/
			}
			else if (currentGizmo.vertical > 0)
			{ // is a Down gizmo

				downOrigin = (e.stageY / scaleY - gizmoOffsetY) * cosinus - (e.stageX / scaleX - gizmoOffsetX) * sinus;
				/*if (downOrigin <= upOrigin)
					{
						downOrigin = upOrigin + 0.1;
				}*/
			}
			else if (currentGizmo.horizontal < 0)
			{ // is a Left gizmo
				leftOrigin = (e.stageX / scaleX - gizmoOffsetX) * cosinus + (e.stageY / scaleY - gizmoOffsetY) * sinus;
				gizmoOffsetX += leftOrigin;

				/*if (leftOrigin >= rightOrigin)
					{
						gizmoOffsetX -= leftOrigin - (rightOrigin - 0.1);
						leftOrigin = rightOrigin - 0.1;
				}*/
			}
			else if (currentGizmo.horizontal > 0)
			{ // is a Right gizmo
				rightOrigin = (e.stageX / scaleX - gizmoOffsetX) * cosinus + (e.stageY / scaleY - gizmoOffsetY) * sinus;

				/*if (rightOrigin <= leftOrigin)
					{
						rightOrigin = leftOrigin + 0.1;
				}*/
			}
		}
	}

	function rotate(e:MouseEvent):Void
	{
		var newAngle = Math.atan((e.stageX / scaleX - gizmoOffsetX) / (e.stageY / scaleY - gizmoOffsetY));
		newAngle -= defaultAngle;
		newAngle = Math.round(newAngle.toDegree());

		if (e.stageY / scaleY - gizmoOffsetY >= 0)
		{
			// adjusts the angle if the mouse is under the pivot
			newAngle += 180;
		}

		asset.rotation = -newAngle;

		radianRotation = asset.rotation.toRadians();
		cosinus = Math.cos(radianRotation);
		sinus = Math.sin(radianRotation);

		if (hasPivot)
		{
			var kImage:KadabraImage = cast asset;
			asset.x = (defaultX
				- (pivot.X * kImage.image.width * kImage.image.scaleX.sign()) * cosinus
				+ (pivot.Y * kImage.image.height * kImage.image.scaleY.sign()) * sinus).roundDecimal(2);
			asset.y = (defaultY
				- (pivot.X * kImage.image.width * kImage.image.scaleX.sign()) * sinus
				- (pivot.Y * kImage.image.height * kImage.image.scaleY.sign()) * cosinus).roundDecimal(2);
		}
	}

	function onMovePivot(e:MouseEvent):Void
	{
		var kImage:KadabraImage = cast asset;
		trace(asset.mouseX, kImage.image.mouseX);

		var pivotX = kImage.image.mouseX * cosinus + kImage.image.mouseY * sinus;
		var pivotY = kImage.image.mouseY * cosinus - kImage.image.mouseX * sinus;

		// minimum & maximum positions
		pivotX = pivotX.bound(0, gizmosWidth);
		pivotY = pivotY.bound(0, gizmosHeight);

		// TODO group
		kImage.pivotX = (pivotX / gizmosWidth).roundDecimal(2);
		kImage.pivotY = (pivotY / gizmosHeight).roundDecimal(2);

		var signX = kImage.image.scaleX.sign();
		var signY = kImage.image.scaleY.sign();

		pivot.setPivot(kImage.pivotX, kImage.pivotY);
		pivot.updatePos(gizmosWidth * signX, gizmosHeight * signY);

		onTransform.dispatch();
		e.updateAfterEvent();
	}

	public function updateGizmos(bounds:Rectangle, pivotX:Float, pivotY:Float)
	{
		this.upOrigin = bounds.top;
		this.downOrigin = bounds.bottom;
		this.leftOrigin = bounds.left;
		this.rightOrigin = bounds.right;

		this.gizmosHeight = downOrigin - upOrigin;
		this.gizmosWidth = rightOrigin - leftOrigin;

		trace(leftOrigin, rightOrigin, upOrigin, downOrigin, pivotX, pivotY);

		var ratio = this.gizmosHeight / this.gizmosWidth;

		this.pivot.setPivot(pivotX, pivotY);

		gizmoU.x = gizmosWidth / 2;

		gizmoUR.x = gizmosWidth;

		gizmoL.y = gizmosHeight / 2;

		gizmoR.x = gizmosWidth;
		gizmoR.y = gizmosHeight / 2;

		gizmoDL.y = gizmosHeight;

		gizmoD.x = gizmosWidth / 2;
		gizmoD.y = gizmosHeight;

		gizmoDR.x = gizmosWidth;
		gizmoDR.y = gizmosHeight;

		rotationGizmo.x = gizmosWidth / 2;
		rotationGizmo.y = -50;

		var kImage:KadabraImage = cast asset;
		var signX = kImage.image.scaleX.sign();
		var signY = kImage.image.scaleY.sign();

		pivot.updatePos(gizmosWidth * signX, gizmosHeight * signY);

		graphics.clear();
		graphics.lineStyle(1, hasScale ? 0 : KadabraUtils.KADABRA_COLOR, 1);
		graphics.moveTo(0, 0);
		graphics.lineTo(gizmosWidth, 0);
		graphics.lineTo(gizmosWidth, gizmosHeight);
		graphics.lineTo(0, gizmosHeight);
		graphics.lineTo(0, 0);
		graphics.moveTo(gizmosWidth / 2, 0);
		graphics.lineTo(gizmosWidth / 2, -50);

		this.x = leftOrigin;
		this.y = upOrigin;
	}

	public function active(parent:Sprite, asset:KadabraAsset):Void
	{
		if (parent != null)
		{
			unactive();
			isActive = true;
			parent.addChild(this);
			this.asset = asset;
			radianRotation = asset.rotation.toRadians();
			cosinus = Math.cos(radianRotation);
			sinus = Math.sin(radianRotation);
			InputPoll.onKeyDown.add(onKeyDown);
			this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, true);

			switch (asset.type)
			{
				case POINT:
					hasPivot = false;
					hasScale = false;
				default:
					hasPivot = true;
					hasScale = true;
			}

			pivot.visible = hasPivot;
			gizmoUL.visible = hasScale;
			gizmoU.visible = hasScale;
			gizmoUR.visible = hasScale;
			gizmoL.visible = hasScale;
			gizmoR.visible = hasScale;
			gizmoDL.visible = hasScale;
			gizmoD.visible = hasScale;
			gizmoDR.visible = hasScale;
		}
	}

	public function unactive():Void
	{
		if (parent != null)
			parent.removeChild(this);

		isActive = false;

		InputPoll.onKeyDown.remove(onKeyDown);
		this.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, true);
	}
}
