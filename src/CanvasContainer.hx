import openfl.events.MouseEvent;
import openfl.ui.Mouse;
import openfl.events.Event;
import feathers.events.ScrollEvent;
import feathers.skins.RectangleSkin;
import feathers.controls.ScrollContainer;

class CanvasContainer extends ScrollContainer {

    public var canvas:KadabraCanvas;

    public function new() {
        super();

        canvas = new KadabraCanvas();

        var rect = new RectangleSkin();
		rect.fill = SolidColor(0x505050);

        if (canvas.background.width < 800) {
            rect.width = canvas.background.width * 3;
            canvas.x = canvas.background.width;
        }
        else {
            rect.width = canvas.background.width + 1600;
            canvas.x = 800;
        }

        if (canvas.background.height < 800) {
            rect.height = canvas.background.height * 3;
            canvas.y = canvas.background.height;
        }
        else {
            rect.height = canvas.background.height + 1600;
            canvas.y = 800;
        }
		rect.mouseEnabled = false;

        addChild(rect);
        addChild(canvas);
        scrollX = canvas.x;
        scrollY = canvas.y;

        canvas.scrollX = scrollX;
        canvas.scrollY = scrollY;

        addEventListener(ScrollEvent.SCROLL_COMPLETE, scrollUpdate);
        addEventListener(Event.ENTER_FRAME, scrollAuto);
    }



    function scrollUpdate(e:ScrollEvent):Void
    {
        canvas.scrollX = scrollX;
        canvas.scrollY = scrollY;
    }

    function scrollAuto(e:Event):Void
    {
        if (canvas.dragging) {
            scrollX += canvas.scrollSpeedX;
            scrollY += canvas.scrollSpeedY;

            if (scrollX < 0) {
                scrollX = 0;
            }
            else if (scrollX > maxScrollX){
                scrollX = maxScrollX;
            }
            else {
                var i = 0;
                for (image in canvas.selectedImages){
                    image.x += canvas.scrollSpeedX;
                    canvas.offsets[i*2] -= canvas.scrollSpeedX;
                    ++i;
                }
            }

            if (scrollY <= 0) {
                scrollY = 0;
            }
            else if (scrollY >= maxScrollY){
                scrollY = maxScrollY;
            }
            else {
                var i = 0;
                for (image in canvas.selectedImages){
                    image.y += canvas.scrollSpeedY;
                    canvas.offsets[i*2+1] -= canvas.scrollSpeedY;
                    ++i;
                }
            }

            canvas.scrollX = scrollX;
            canvas.scrollY = scrollY;
        }
    }

    function onMouseUp(e:MouseEvent) {
        canvas.dragging = false;
    }
}