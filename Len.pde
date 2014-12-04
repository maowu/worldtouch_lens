public class Len {
  float x,y;
  int basic_val = 0;
  int shift_val = 2;
  int sensor_max = 100;
  float maxlensize = 50;
  float minlensize = 5;
  int now_val, target_val;
  int local_color;
  int remote_color;
  int static_color;
  float lensize;
  long check_timer = 0;
  long set_timer = 0;
  float total_cleap = 24;
  PVector tmp_pt1 = new PVector();
  PVector tmp_pt2 = new PVector();
  
  Ani lenAni;
  float duration = 0.9;
  PImage pg;
 
  public Len(float x, float y, int maxlensize, int local_color, int remote_color, int static_color) {
    this.x = x;
    this.y = y;
    this.maxlensize = maxlensize*1.5;
    this.now_val = basic_val;
    this.target_val = basic_val;
    this.local_color = local_color;
    this.remote_color = remote_color;
    this.static_color = static_color;
    this.lensize = minlensize;
    this.lenAni = new Ani(this, duration, "lensize", maxlensize, Ani.EXPO_IN_OUT, "onStart:AniStarted, onEnd:AniEnd");
    pg = createImage(maxlensize, maxlensize, ARGB);
  }
  
  public void draw(PGraphics pg) {
    
    if(now_val==basic_val) {
      pushStyle();
      noFill();
      stroke(static_color);
      ellipse(x, y, lensize, lensize);
      popStyle();
    }
    
    if(now_val>basic_val) {  // remote
      //stroke(remote_color);
      pg.beginDraw();
      pg.fill(255);
      pg.stroke(255);
      pg.ellipse(x, y, lensize, lensize);
      pg.endDraw();
    }
  }
  
  public void update() {
    if(abs(now_val-basic_val)>0 && millis()-set_timer>1000) {
      Ani.to(this, 1.5, "now_val", basic_val, Ani.CUBIC_OUT);
      check_timer = millis();
    }
    lensize = map(abs(now_val-basic_val), basic_val, sensor_max, minlensize, maxlensize);
  }
  
  public void setVal(float val) {
    if(millis()-set_timer>1000) {
      Ani.to(this, duration, "now_val", val, Ani.ELASTIC_OUT);
    }
    set_timer = millis();
  }
  
  public int getVal() {
    return now_val;
  }
  
  public boolean isInLen(float mx, float my) {
    if( (mx>x-maxlensize/2 && mx<x+maxlensize/2) && (my>y-maxlensize/2 && my<y+maxlensize/2) )
      return true;
    return false;
  }
  
  public PVector getPt() {
    return new PVector(x,y);
  }
  
  // called onStart of diameterAni animation
  public void AniStarted() {
    //println("diameterAni started");
  }
  
  // called onEnd of diameterAni animation
  public void AniEnd(Ani theAni) {
    //float end = theAni.getEnd();
    //float newEnd = 5;
    //theAni.setEnd(newEnd);
    //println("diameterAni finished. current end: "+end+" -> "+"new end: "+newEnd);
    //println("diameterAni finished. current end: ");
    //Ani.to(this, duration, "now_val", 5, Ani.ELASTIC_OUT);
  }

  
  
}
