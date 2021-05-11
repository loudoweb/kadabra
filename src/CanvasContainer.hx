import openfl.geom.Point;
import utils.KadabraUtils;
import openfl.ui.Keyboard;
import io.InputPoll;
import openfl.events.MouseEvent;
import openfl.ui.Mouse;
import openfl.events.Event;
import feathers.events.ScrollEvent;
import feathers.skins.RectangleSkin;
import feathers.controls.ScrollContainer;

class CanvasContainer extends ScrollContainer
{
	var canvas:RectangleSkin;

	public var scene:KadabraScene;

	var zoomValue = 1.;

	var movePoint:Point;

	inline static var minZoomValue = 4.;
	inline static var moveSpeedDivisor = 50.;

	public function new()
	{
		super();

		scene = new KadabraScene();

		canvas = new RectangleSkin();
		canvas.fill = KadabraUtils.CANVAS_FILL;

		if (scene.background.width < 800)
		{
			canvas.width = scene.background.width * 3;
			scene.x = scene.background.width;
		}
		else
		{
			canvas.width = scene.background.width + 1600;
			scene.x = 800;
		}

		if (scene.background.height < 800)
		{
			canvas.height = scene.background.height * 3;
			scene.y = scene.background.height;
		}
		else
		{
			canvas.height = scene.background.height + 1600;
			scene.y = 800;
		}
		canvas.mouseEnabled = false;

		addChild(canvas);
		addChild(scene);
		scrollX = scene.x;
		scrollY = scene.y;

		scene.scrollX = scrollX;
		scene.scrollY = scrollY;

		addEventListener(ScrollEvent.SCROLL_COMPLETE, scrollUpdate);
		addEventListener(Event.ENTER_FRAME, scrollAuto);

		InputPoll.onMouseWheel.add(zoom);

		InputPoll.onMiddleMouseDown.add(setMovePoint);
	}

	function scrollUpdate(e:ScrollEvent):Void
	{
		scene.scrollX = scrollX;
		scene.scrollY = scrollY;
	}

	function scrollAuto(e:Event):Void
	{
		if (scene.dragging)
		{
			scrollX += scene.scrollSpeedX;
			scrollY += scene.scrollSpeedY;

			if (scrollX < 0)
			{
				scrollX = 0;
			}
			else if (scrollX > maxScrollX)
			{
				scrollX = maxScrollX;
			}
			else
			{
				var i = 0;
				for (image in scene.selectedImages)
				{
					image.x += scene.scrollSpeedX;
					scene.offsets[i * 2] -= scene.scrollSpeedX;
					++i;
				}
			}

			if (scrollY <= 0)
			{
				scrollY = 0;
			}
			else if (scrollY >= maxScrollY)
			{
				scrollY = maxScrollY;
			}
			else
			{
				var i = 0;
				for (image in scene.selectedImages)
				{
					image.y += scene.scrollSpeedY;
					scene.offsets[i * 2 + 1] -= scene.scrollSpeedY;
					++i;
				}
			}

			scene.scrollX = scrollX;
			scene.scrollY = scrollY;
		}
		if (InputPoll.isMouseMiddleDown)
		{
			var mousePoint = new Point(mouseX, mouseY);
			mousePoint = localToGlobal(mousePoint);

			// scroller.restrictedScrollX += (mousePoint.x - movePoint.x) / moveSpeedDivisor;
			// scroller.restrictedScrollY += (mousePoint.y - movePoint.y) / moveSpeedDivisor;
		}
	}

	function zoom(e:MouseEvent)
	{
		if (InputPoll.isKeyDown(Keyboard.CONTROL))
		{
			e.stopImmediatePropagation();

			var canvasMousePoint = new Point(e.stageX, e.stageY);
			canvasMousePoint = canvas.globalToLocal(canvasMousePoint);

			var containerMousePoint = new Point(e.stageX, e.stageY);
			containerMousePoint = globalToLocal(containerMousePoint);

			if (canvas.width >= width - scrollBarY.width && canvas.width >= height - scrollBarX.height)
			{
				var newZoomValue = zoomValue + (e.delta / 100);
				if (newZoomValue <= minZoomValue)
				{
					scene.x *= (newZoomValue / zoomValue);
					scene.y *= (newZoomValue / zoomValue);
					zoomValue = newZoomValue;
					canvas.scaleX = canvas.scaleY = scene.scaleX = scene.scaleY = zoomValue;
				}
			}

			var visibleWidth = width;
			if (maxScrollY > 0)
			{
				visibleWidth -= scrollBarY.width;
			}
			if (canvas.width < visibleWidth)
			{
				var newZoomValue = visibleWidth * zoomValue / canvas.width;
				scene.x *= (newZoomValue / zoomValue);
				scene.y *= (newZoomValue / zoomValue);
				zoomValue = newZoomValue;
				canvas.scaleX = canvas.scaleY = scene.scaleX = scene.scaleY = zoomValue;
			}

			var visibleHeight = height;
			if (maxScrollX > 0)
			{
				visibleHeight -= scrollBarX.height;
			}
			if (canvas.height < visibleHeight)
			{
				var newZoomValue = visibleHeight * zoomValue / canvas.height;
				scene.x *= (newZoomValue / zoomValue);
				scene.y *= (newZoomValue / zoomValue);
				zoomValue = newZoomValue;
				canvas.scaleX = canvas.scaleY = scene.scaleX = scene.scaleY = zoomValue;
			}

			restrictedScrollX = canvasMousePoint.x * zoomValue - containerMousePoint.x;
			restrictedScrollY = canvasMousePoint.y * zoomValue - containerMousePoint.y;
		}
	}

	function resetZoom()
	{
		scene.x /= zoomValue;
		scene.y /= zoomValue;
		zoomValue = 1.;
		canvas.scaleX = canvas.scaleY = scene.scaleX = scene.scaleY = zoomValue;
	}

	function fitCanvas()
	{
		if (canvas.width < canvas.height)
		{
			var newZoomValue = (width - scrollBarY.width) * zoomValue / canvas.width;
			scene.x *= (newZoomValue / zoomValue);
			scene.y *= (newZoomValue / zoomValue);
			zoomValue = newZoomValue;
			canvas.scaleX = canvas.scaleY = scene.scaleX = scene.scaleY = zoomValue;
		}
		else
		{
			var newZoomValue = (height - scrollBarX.height) * zoomValue / canvas.height;
			scene.x *= (newZoomValue / zoomValue);
			scene.y *= (newZoomValue / zoomValue);
			zoomValue = newZoomValue;
			canvas.scaleX = canvas.scaleY = scene.scaleX = scene.scaleY = zoomValue;
		}
	}

	function fitScene()
	{
		if (scene.width < scene.height)
		{
			var newZoomValue = (width - scrollBarY.width) * zoomValue / scene.width;
			scene.x *= (newZoomValue / zoomValue);
			scene.y *= (newZoomValue / zoomValue);
			zoomValue = newZoomValue;
			canvas.scaleX = canvas.scaleY = scene.scaleX = scene.scaleY = zoomValue;

			scrollX = maxScrollX / 2;
			scrollY = scene.y;
		}
		else
		{
			var newZoomValue = (height - scrollBarX.height) * zoomValue / scene.height;
			scene.x *= (newZoomValue / zoomValue);
			scene.y *= (newZoomValue / zoomValue);
			zoomValue = newZoomValue;
			canvas.scaleX = canvas.scaleY = scene.scaleX = scene.scaleY = zoomValue;

			scrollX = scene.x;
			scrollY = maxScrollY / 2;
		}
	}

	function setMovePoint(e:MouseEvent)
	{
		movePoint = new Point(e.stageX, e.stageY);
	}
}
