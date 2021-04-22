import openfl.display.Sprite;

class Gizmo extends Sprite {
    public var up = false;
    public var down = false;
    public var left = false;
    public var right = false;

    public function new(vertical:Int, horizontal:Int){
        
        super();

        //the different gizmos have different colors to identify them during debug
        var rectColor = 0x7F007F;

        if (horizontal > 0) {
            right = true;
            rectColor += 0x7F0000;
        }
        else if (horizontal < 0) {
            left = true;
            rectColor -= 0x7F0000;
        }
        if (vertical > 0) {
            down = true;
            rectColor += 0x00007F;
        }
        else if (vertical < 0) {
            up = true;
            rectColor -= 0x00007F;
        }

        mouseChildren = false;
        buttonMode = true;

        graphics.beginFill(rectColor, 1);
        graphics.drawRect(-4,-4,8,8);
        graphics.endFill();
    }
}