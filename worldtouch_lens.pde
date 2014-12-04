// import processing library, you can add those from [Processing > Sketch> Import Library...]
import SimpleOpenNI.*;
import gab.opencv.*;
import hypermedia.net.*;
import de.looksgood.ani.*;
import controlP5.*;

// import some extra java library
import java.awt.Rectangle;
import java.awt.Polygon;

import org.opencv.imgproc.Imgproc;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Size;
import org.opencv.core.Mat;
import org.opencv.core.CvType;


// setting for this application
int screen_x = 0;    //  screen location x
int screen_y = 0;    //  screen location y
int sw = 1280;       //  screen width
int sh = 960;        //  screen height
int kw = 640;        //  kinect capture width
int kh = 480;        //  kinect capture height

// Kinector for OpenNI and Something for OpenCV
SimpleOpenNI  kinect;
OpenCV opencv;

int[] bgDepth;
int[] nowbgDepth;
int[] depthMap; 
PGraphics sensor_canvas, warp_canvas;

PImage depthImg, maskImg, rgbImg, touchImg, subbgImg;

int minDepth =  500;      // the min depth distance for kinect sensing (mm)
int maxDepth = 1500;      // the man depth distance for kinect sensing (mm)
int mintouchDepth =  5;  // the min depth distance bewteen surface
int maxtouchDepth = 200;  // the max depth distance bewteen surface
int threshold = 200;      // opencv threshold value

float wScale = 0;         // calurate the scale from kw->sw
float hScale = 0;         // calurate the scale from kh->sh

int SENSOR_COLOR = 0xFFFFFFFF;
int BG_COLOR = 0xFF000000;
int BLOBBG_COLOR = 0xFFFF0000;
int NOTRANGE_COLOR = color(55, 107, 109);
int OBJ_COLOR = 0xFFFF5555;
int BGSUB_COLOR = 0xFF5555FF;
int NO_COLOR = 0x00000000;
int BORDER_COLOR = color(134, 193, 102);

long check_timer = 0;
int BG_AvgNums = 10;
int bgsavecount = 0;
int nowbgsavecount = 0;
int _SENSOR_MOD = 0;    // 0: nomal kinect mod, 1: flexible surface sensor mod, 
boolean _DEBUG = false;
boolean _BG_SAVE = false;
boolean _NOWBG_SAVE = false;
boolean _DRAW_DEMO = true;
boolean _SHOW_SET = true;
boolean _SHOWUI = true;

ArrayList<Contour> contours = new ArrayList<Contour>();
ArrayList<InteractiveContour> blobs = new ArrayList<InteractiveContour>();

ArrayList<PVector> client_center = new ArrayList<PVector>();
ArrayList<PVector> local_center = new ArrayList<PVector>();

// sensor area
PVector[] area = new PVector[4];

// for Network
UDP udp;  // define the UDP object
String HOST_IP = "localhost";
int send_port = 12345;
int recieve_port = 54321;
String UDP_Str = "";
int[] tdata;

// for setting
Settings settings = null;
String TIP_MSG = "";


// for Grid Len
int Grid_size = 100;
int Grid_row = sw/Grid_size;
int Grid_col = sh/Grid_size;
int Grid_NUMS = Grid_row*Grid_col;

int local_col = color(73, 201, 250);
int remote_col = color(228, 54, 161);
int static_col = color(206, 214, 34);

Len [] Len_Arr = new Len[Grid_NUMS];
int [] LenVal_Arr = new int[Grid_NUMS];
int [] RemoteLenVal_Arr = new int[Grid_NUMS];
int len_basicval = 0;
int len_maxval = 100;

PImage lpg, rpg;
PGraphics canvas;
long interactive_timer = 0;

String local_tiltle = "TAIPEI";
String remote_title = "TOKYO";

void setup() {
  // loading pre setting
  loadInitialSettings(); 

  size(sw, sh, P2D);

  Ani.init(this);

  // init kinect setting
  kinect = new SimpleOpenNI(this);
  if (kinect.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }
  // setting mirror
  kinect.setMirror(false);
  //  enable depthMap generation
  kinect.enableDepth();
  //  enable rgb image get
  kinect.enableRGB();
  kinect.alternativeViewPointDepthToImage();

  TIP_MSG = "kinect start ......";

  // setting some PImage init
  depthImg = new PImage(kw, kh);
  touchImg = new PImage(kw, kh);
  maskImg = new PImage(kw, kh);
  rgbImg = new PImage(kw, kh);
  subbgImg = new PImage(kw, kh);

  // setting depth info init
  bgDepth = new int[kw*kh];
  nowbgDepth = new int[kw*kh];
  for (int i=0; i< kw*kh; i++) {
    bgDepth[i] = 0;
    nowbgDepth[i] = 0;
  }

  opencv = new OpenCV(this, kw, kh);

  wScale = (float)sw/(float)kw;
  hScale = (float)sh/(float)kh;

  // for debug show
  sensor_canvas = createGraphics(kw, kh);
  warp_canvas = createGraphics(kw, kh);
  TIP_MSG = "";

  // Network
  udp = new UDP( this, recieve_port );
  udp.listen( true );
  
  // Control UI
  ControlUI_init();

  // for Demo 
  for (int i=0; i<Grid_row; i++) {
    for (int j=0; j<Grid_col; j++) {
      Len_Arr[i+j*Grid_row] = new Len(Grid_size/2+Grid_size*i, Grid_size/2+Grid_size*j, Grid_size, local_col, remote_col, static_col);
      RemoteLenVal_Arr[i+j*Grid_row] = len_basicval;
    }
  }

  lpg = loadImage("taipei.jpg");
  lpg.resize(sw, sh);
  rpg = loadImage("tokyo.jpg");
  rpg.resize(sw, sh);
  canvas = createGraphics(sw, sh);
}


void draw() {
  // update the cam
  kinect.update();

  if (millis() - check_timer > 5) {
    // ----- begin the kinect sensing and processing ------- //
    background(0);
    
    sensor_canvas.clear();
    warp_canvas.clear();

    depthMap = kinect.depthMap();
    depthImg = kinect.depthImage();
    rgbImg = kinect.rgbImage();

    // save new depth info for background
    if (_BG_SAVE) {
      bgsavecount++;
      depthBGSave(bgDepth);
      TIP_MSG = "Don't Move, Background scaning ......" + (BG_AvgNums-bgsavecount);
    }
    if (_NOWBG_SAVE) {
      nowbgsavecount++;
      depthBGSave(nowbgDepth);
      TIP_MSG = "Don't Move, Background scaning ......" + (BG_AvgNums-nowbgsavecount);
    }

    // turn depthMap data into gray image (with limited distance between max and min depth )
    touchImg.loadPixels();
    depthImg.loadPixels();
    int tmp_index = 0;
    PVector tmp_pt = new PVector(0, 0);
    for (int x = 0; x < kw; x++) {
      for (int y=0; y < kh; y++) {
        tmp_index = x+y*kw;
        tmp_pt.set(x, y);

        if (depthMap[tmp_index] >= minDepth && depthMap[tmp_index] <= maxDepth) {
          if (_SENSOR_MOD==1) {
            if ( abs(nowbgDepth[tmp_index]- depthMap[tmp_index]) > mintouchDepth &&  abs(nowbgDepth[tmp_index] - depthMap[tmp_index]) < maxtouchDepth) {
              if (!isInsidePolygon(tmp_pt, area)) {
                touchImg.pixels[tmp_index] = BG_COLOR;
              } else {
                touchImg.pixels[tmp_index] = SENSOR_COLOR;
              }
            } else {
              touchImg.pixels[tmp_index] = BG_COLOR;
            }
          } else {
            if (!isInsidePolygon(tmp_pt, area)) {
              touchImg.pixels[tmp_index] = BG_COLOR;
            } else {
              touchImg.pixels[tmp_index] = SENSOR_COLOR;
            }
          }
        } else {
          touchImg.pixels[tmp_index] = BG_COLOR;
          depthImg.pixels[tmp_index] = NOTRANGE_COLOR;
          subbgImg.pixels[tmp_index] = BG_COLOR;
        }
      }  // -- end for(y) -- //
    } // -- end for(x) -- //
    touchImg.updatePixels();
    depthImg.updatePixels();

    if (_NOWBG_SAVE && nowbgsavecount>BG_AvgNums) {
      println("nowbg_saved");
      updateBGSub();
      TIP_MSG = "";
      _NOWBG_SAVE = false;
    }

    // load the image from gray image
    opencv.loadImage(touchImg);

    // simple smooth image 
    opencv.blur(8);
    // make it as binary image with threshold
    opencv.threshold(threshold); 
    // use image then dilate and erode it to close holes
    opencv.dilate();
    opencv.erode();

    // find contours
    contours.clear();
    contours = opencv.findContours(false, true);
    filterContours(contours, kw*kh/128.0);
    if (_SHOW_SET) {
      image(depthImg, 0, 0, kw, kh);
    }

    // draw interactive area
    if (_SHOW_SET) {
      for (int i=0; i<area.length; i++) {
        pushStyle();
        fill(190, 194, 63);
        stroke(190, 194, 63);
        ellipse(area[i].x, area[i].y, 20, 20);
        line(area[i].x, area[i].y, area[(i+1)%area.length].x, area[(i+1)%area.length].y);
        fill(196, 98, 67);
        textAlign(CENTER);
        text(i, area[i].x, area[i].y+3);
        popStyle();
      }
    }

    drawContours(sensor_canvas, blobs, 0, 0, 1.0, 1.0, color(255, 255, 0), 3, true, BLOBBG_COLOR, false);
    if (_SHOW_SET) {
      image(sensor_canvas, 0, 0, kw, kh);
    }

    // now starting warp sensor image to project view image
    opencv.loadImage(sensor_canvas);
    opencv.gray();
    opencv.threshold(threshold); 
    opencv.toPImage(warpPerspective(area, kw, kh), warp_canvas);
    opencv.loadImage(warp_canvas);
    contours.clear();
    contours = opencv.findContours(false, true);
    filterContours(contours, kw*kh/128.0);
    PGraphics pg = createGraphics(kw, kh);

    drawContours(pg, blobs, 0, 0, 1.0, 1.0, color(200, 200, 0), 3, true, BLOBBG_COLOR, true);
    
    if (_SHOW_SET) {
      showThumbImg(pg.get(), kw, 0, kw, kh, true, BORDER_COLOR, "warp contours");
    }

    // draw centerpoint from client;
    CenterPointCollect(blobs);
    sendInteraction(local_center);
    drawClientInteractive(client_center);


    // begin use kinect content to do something
    // you can put your application below ~~~~
    if (_DRAW_DEMO) {
      canvas.clear();
      for (int i=0; i<Grid_NUMS; i++) {
        Len_Arr[i].update();
        Len_Arr[i].draw(canvas);
      }
      rpg.mask(canvas);
      image(rpg, 0, 0, sw, sh);

      drawClientInteractive(client_center);

      if (millis() - interactive_timer > 300) {
        for (InteractiveContour b : blobs) {
          for (int i=0; i<Grid_NUMS; i++) {
            if (b.isInside( FixKinectPointSet( Len_Arr[i].getPt() ) )) {  
              int tmp_val = len_maxval;
              LenVal_Arr[i] = constrain(tmp_val, -len_maxval, len_maxval);  // more close -100 = see more local image;

              sendInteractionLen(i, tmp_val);
              //sendInteractionCursor(tmp_p.x, tmp_p.y);
              Len_Arr[i].setVal(tmp_val);
            }
          }
        }

        interactive_timer = millis();
      }
    }
    
    // end the application with kinect content


    // ----- end the kinect sensing and processing ------- //
    check_timer = millis();
  }
  showTIPMSG();
}


void drawContours(PGraphics p, ArrayList<InteractiveContour> tblob, int xRef, int yRef, float wcaleIn, float hscaleIn, int colorStrokeIn, int strokeWeightIn, boolean fillIn, int colorFillIn, boolean Mode) {
  p.beginDraw();
  for (InteractiveContour b : tblob) {
    if (fillIn)  
      p.fill(colorFillIn); 
    else 
      p.noFill();
    p.stroke(colorStrokeIn);
    p.strokeWeight(strokeWeightIn);

    //contour.setPolygonApproximationFactor(max( (float)contour.getPolygonApproximationFactor()*0.1 , 0.1));

    p.beginShape();
    for (PVector point : b.getPoints ()) {
      p.vertex(point.x, point.y);
    }
    p.endShape();

    if (Mode) {
      p.stroke(200, 0, 0);
      p.noFill();
      p.stroke(150, 210, 40);
      p.rect(b.getBoundingBox().x, b.getBoundingBox().y, b.getBoundingBox().width, b.getBoundingBox().height);

      PVector tmp_center = b.getCenterPoint();
      p.fill(40, 250, 210);
      float tmp_r = sqrt(b.area())/2;
      p.ellipse(tmp_center.x, tmp_center.y, tmp_r, tmp_r);
    }
  }
  p.endDraw();
}

void CenterPointCollect(ArrayList<InteractiveContour> tblob) {
  local_center.clear();
  for (InteractiveContour b : tblob) {
    local_center.add( FixScreenPointSet(b.getCenterPoint()) );
  }
}

// Convert kw,kh scale point into sw,sh scale
PVector FixScreenPointSet(PVector pt) {
  return new PVector(pt.x*wScale, pt.y*hScale);
}
// Convert sw,sh scale point into kw,kh scale
PVector FixKinectPointSet(PVector pt) {
  return new PVector(pt.x/wScale, pt.y/hScale);
}


void filterContours(ArrayList<Contour> cts, float sizeRef) {
  blobs.clear();  
  int count = 0;
  for (int i=cts.size ()-1; i>=0; i--) {
    Contour contour = cts.get(i);
    if (contour.area()<sizeRef) {
      cts.remove(i);
    } else {
      count++;
      InteractiveContour itc = new InteractiveContour(contour);
      blobs.add(itc);
    }
  }
}



boolean isInsidePolygon(PVector pos, PVector[] vertices) {
  int i, j=vertices.length-1;
  int sides = vertices.length;
  boolean oddNodes = false;
  for (i=0; i<sides; i++) {
    float tmpi_y = vertices[i].y;
    float tmpi_x = vertices[i].x;
    float tmpj_y = vertices[j].y;
    float tmpj_x = vertices[j].x;
    if ((tmpi_y < pos.y && tmpj_y >= pos.y || tmpj_y < pos.y && tmpi_y >= pos.y) && (tmpi_x <= pos.x || tmpj_x <= pos.x)) {
      oddNodes^=(tmpi_x + (pos.y-tmpi_y)/(tmpj_y - tmpi_y)*(tmpj_x-tmpi_x)<pos.x);
    }
    j=i;
  }
  return oddNodes;
}

void showTIPMSG() {
  int str_l = TIP_MSG.length();
  if (str_l>0) {
    pushStyle();
    fill(255, 177, 27);
    noStroke();
    textSize(20);
    rect(0, 20, str_l*10+20, 40);
    fill(255, 255, 255);
    text(TIP_MSG, 10, 45);
    popStyle();
  }
}

void showThumbImg(PImage pg, int Xref, int Yref, int Wref, int Href, boolean border, int bordercolor, String title) {
  pushMatrix();
  translate(Xref, Yref);
  image(pg, 0, 0, Wref, Href);
  noFill();
  if (border) {  
    stroke(bordercolor);
    rect(0, 0, Wref-1, Href-1);
  }

  fill(255);
  text(title, 5, 10);
  popMatrix();
}

void depthBGSave(int[] tmpDepth) {
  int tmp_index = 0;
  int [] tDepth = tmpDepth;
  for (int x = 0; x < kw; x++) {
    for (int y=0; y < kh; y++) {
      tmp_index = x+y*kw;
      int tmpdepth = depthMap[tmp_index];
      tDepth[tmp_index] = (tDepth[tmp_index]+tmpdepth)/2;
    }
  }
}

void updateBGSub() {
  subbgImg.loadPixels();
  int tmp_index = 0;
  for (int x = 0; x < kw; x++) {
    for (int y=0; y < kh; y++) {
      tmp_index = x+y*kw;
      int tmpdepth = depthMap[tmp_index];
      if (abs(nowbgDepth[tmp_index]-bgDepth[tmp_index])>10) {
        subbgImg.pixels[tmp_index] = BGSUB_COLOR;
      } else {
        subbgImg.pixels[tmp_index] = BG_COLOR;
      }
    }
  }
  subbgImg.updatePixels();
}


Mat getPerspectiveTransformation(PVector[] inputPoints, int w, int h) {
  Point[] canonicalPoints = new Point[4];
  canonicalPoints[0] = new Point(0, 0);
  canonicalPoints[1] = new Point(w, 0);
  canonicalPoints[2] = new Point(w, h);
  canonicalPoints[3] = new Point(0, h);

  MatOfPoint2f canonicalMarker = new MatOfPoint2f();
  canonicalMarker.fromArray(canonicalPoints);

  Point[] points = new Point[4];
  for (int i = 0; i < 4; i++) {
    points[i] = new Point(inputPoints[i].x, inputPoints[i].y);
  }
  MatOfPoint2f marker = new MatOfPoint2f(points);
  return Imgproc.getPerspectiveTransform(marker, canonicalMarker);
}

Mat warpPerspective(PVector[] inputPoints, int w, int h) {
  Mat transform = getPerspectiveTransformation(inputPoints, w, h);
  Mat unWarpedMarker = new Mat(w, h, CvType.CV_8UC1);    
  Imgproc.warpPerspective(opencv.getColor(), unWarpedMarker, transform, new Size(w, h));
  return unWarpedMarker;
}

