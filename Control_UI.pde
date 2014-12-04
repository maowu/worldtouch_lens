ControlP5 cp5;

Range range1, range2;

void ControlUI_init() {
  cp5 = new ControlP5(this);
  range1 = cp5.addRange("DepthrangeController")
             // disable broadcasting since setRange and setRangeValues will trigger an event
             .setBroadcast(false) 
             .setPosition(50,sh/2+100)
             .setSize(400,40)
             .setHandleSize(20)
             .setRange(50,3000)
             .setRangeValues(50,100)
             .setLowValue(minDepth)
             .setHighValue(maxDepth)
             // after the initialization we turn broadcast back on again
             .setBroadcast(true)
             .setColorForeground(color(255,40))
             .setColorBackground(color(255,40))  
             ;
 range2 = cp5.addRange("touchDepthrangeController")
             // disable broadcasting since setRange and setRangeValues will trigger an event
             .setBroadcast(false) 
             .setPosition(50,sh/2+150)
             .setSize(400,40)
             .setHandleSize(20)
             .setRange(50,3000)
             .setRangeValues(50,100)
             .setLowValue(mintouchDepth)
             .setHighValue(maxtouchDepth)
             // after the initialization we turn broadcast back on again
             .setBroadcast(true)
             .setColorForeground(color(255,40))
             .setColorBackground(color(255,40))  
             ;
 cp5.addToggle("_SENSOR_MOD")
     .setPosition(50,sh/2+50)
     .setSize(100,30)
     .setValue(_SENSOR_MOD)
     .setMode(ControlP5.SWITCH)
     ;
 cp5.addToggle("_SHOW_SET")
     .setPosition(50,sh/2+220)
     .setSize(50,20)
     .setValue(_SHOW_SET)
     .setMode(ControlP5.SWITCH)
     ;
 cp5.addToggle("_DRAW_DEMO")
     .setPosition(150,sh/2+220)
     .setSize(50,20)
     .setValue(_DRAW_DEMO)
     .setMode(ControlP5.SWITCH)
     ;
}

void controlEvent(ControlEvent theControlEvent) {
  if(theControlEvent.isFrom("DepthrangeController")) {
    minDepth = int(theControlEvent.getController().getArrayValue(0));
    maxDepth = int(theControlEvent.getController().getArrayValue(1));
    println("depth range update, done.");
  }
  if(theControlEvent.isFrom("touchDepthrangeController")) {
    mintouchDepth = int(theControlEvent.getController().getArrayValue(0));
    maxtouchDepth = int(theControlEvent.getController().getArrayValue(1));
    println("touch depth range update, done.");
  }
  
}

// keyboard control
void keyPressed() {

  if (key == 'b') {
    _NOWBG_SAVE = true;
    nowbgsavecount = 0;
  }
  if (key == 'p') {
    _SHOW_SET = !_SHOW_SET;
  }

  if (key>='0' && key<='3') {
    area[key-'0'].set(mouseX, mouseY);
    println(area[key-'0']);
  }

  if (key=='s') {
    settings.save();
    println("saving settings.txt");
  }

  if (key=='w') {
    _DRAW_DEMO = !_DRAW_DEMO;
  }
  
  if (key==' ') {
    _SHOWUI = !_SHOWUI;
    if(_SHOWUI)  cp5.show();
    else cp5.hide();
  }
}
