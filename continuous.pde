import java.util.*;
import processing.video.*;
import processing.sound.*;
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput in;

Capture cam;
Boolean enter=false;
int points;
int skips=5;
int sw = 2;
PImage img;
PImage logo;
Boolean t = false;
Boolean v = false;
color colour = color(255);
int bgcolor;
int n;
Boolean nn = false;
ddf.minim.analysis.FFT fft;
float hertz;
float midi;

int sampleRate = 44100;
float [] max= new float [sampleRate/2];//array that contains the half of the sampleRate size, because FFT only reads the half of the sampleRate frequency. This array will be filled with amplitude values.
float maximum;//the maximum amplitude of the max array
float frequency;//the frequency in hertz

ArrayList<PVector> vectList;

void setup() {
  size(1280, 720);
  frameRate(10);
  imageMode(CENTER);
  textAlign(CENTER);
  logo = loadImage("continuous.png");
  bgcolor = logo.get(20, 20);
  println(logo.get(20, 20));

  minim = new Minim(this);
  minim.debugOn();
  in = minim.getLineIn(Minim.MONO, 4096, sampleRate);
  in.enableMonitoring();
  fft = new ddf.minim.analysis.FFT(in.left.size(), sampleRate);


  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }

    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[0]);
    cam.start();
  }
}

public class Comp implements Comparator<PVector> {
  public int compare(PVector a, PVector b) {
    return (a.z == b.z) ? 0 : ((a.z < b.z) ? 1 : -1);
  }
}

void draw() {
  float m = in.left.level();
  background(bgcolor);
  if (enter==false) {
    image(logo, width/2, height/2, 700, 500);
  } else {
    if (nn)
      findNote();
    points = min((int)(m*10000), 8000);
    //points = 2000;
    println(t);
    if (cam.available() == true) {
      cam.read();
    }
    pushMatrix();
    scale(-1, 1);
    translate(-cam.width, 0);
    if (v)
      image(cam, width/2, height/2, 1280, 720);
    popMatrix();
    img = cam;
    int t = millis();

    PImage flipped = createImage(img.width, img.height, RGB);//create a new image with the same dimensions
    for (int i = 0; i < flipped.pixels.length; i++) {       //loop through each pixel
      int srcX = i % flipped.width;                        //calculate source(original) x position
      int dstX = flipped.width-srcX-1;                     //calculate destination(flipped) x position = (maximum-x-1)
      int y    = i / flipped.width;                        //calculate y coordinate
      flipped.pixels[y*flipped.width+dstX] = img.pixels[i];//write the destination(x flipped) pixel based on the current pixel
    }
    vectList = new ArrayList<PVector>();
    flipped.loadPixels();
    for (int i=0; i<flipped.pixels.length-1; i+=skips) {
      float pixel1 = alpha(flipped.pixels[i])+red(flipped.pixels[i])+green(flipped.pixels[i])+blue(flipped.pixels[i]);
      float pixel2 = alpha(flipped.pixels[i+1])+red(flipped.pixels[i+1])+green(flipped.pixels[i+1])+blue(flipped.pixels[i+1]);
      int diff = (int)(pixel1-pixel2);
      vectList.add(new PVector(i % flipped.width, i / flipped.width, diff));
    }
    Collections.sort(vectList, new Comp());
    continuous(flipped);
    println(skips);
  }
}

void continuous(PImage img) {
  float closest;
  ArrayList<PVector> vectors = new ArrayList<PVector>();

  int max = min(points, vectList.size());

  for (int i = 0; i < max; i++) {
    vectors.add(vectList.get(i));
  }

  int a = 0;
  int b = 0;
  float dist=img.width;

  while (vectors.size()>34) {
    closest = img.width;
    float px = vectors.get(a).x;
    float py = vectors.get(a).y;
    vectors.remove(a);
    for (int p = 0; p < vectors.size(); p++) {
      dist=dist(px, py, vectors.get(p).x, vectors.get(p).y);
      if (dist<closest) {
        closest = dist;
        b=p;
      }
    }
    strokeWeight(sw);
    stroke(255);
    line(px, py, vectors.get(b).x, vectors.get(b).y);
    a=b;
  }
}


void keyPressed() {
  if (key==ENTER) {
    enter=true;
  }
  if (key=='m') {
    if (v==false)
      v=true;
    else v=false;
  }
  if (key=='n') {
    bgcolor = logo.get(20, 20);
    colour = color(255);
    if (nn==false)
      nn=true;
    else nn=false;
  }
  if (key=='c') {
    bgcolor = color(random(0, 255), random(0, 255), random(0, 255));
    colour = color(random(0, 255), random(0, 255), random(0, 255));
  }
  if (key==CODED) {
    if (keyCode==UP) {
      skips++;
    }
    if (keyCode==DOWN) {
      if (skips>1)
        skips--;
    }
    if (keyCode==LEFT) {
      if (sw>1)
        sw--;
    }
    if (keyCode==RIGHT) {
      sw++;
    }
  }
}

void findNote() {

  fft.forward(in.left);
  for (int f=0; f<sampleRate/2; f++) { //analyses the amplitude of each frequency analysed, between 0 and 22050 hertz
    max[f]=fft.getFreq(float(f)); //each index is correspondent to a frequency and contains the amplitude value
  }
  maximum=max(max);//get the maximum value of the max array in order to find the peak of volume

  for (int i=0; i<max.length; i++) {// read each frequency in order to compare with the peak of volume
    if (max[i] == maximum) {//if the value is equal to the amplitude of the peak, get the index of the array, which corresponds to the frequency
      frequency= i;
    }
  }


  midi= 69+12*(log((frequency-6)/440));// formula that transform frequency to midi numbers
  n= int (midi);//cast to int


  //the octave have 12 tones and semitones. So, if we get a modulo of 12, we get the note names independently of the frequency  
  if (n%12==9)
  {
    bgcolor = #447c69;
  }

  if (n%12==10)
  {
    bgcolor =  #74c493;
  }

  if (n%12==11)
  {
    bgcolor = #e4bf80;
  }

  if (n%12==0)
  {
    bgcolor = #E9D78E;
  }

  if (n%12==1)
  {
    bgcolor = #f19670;
  }

  if (n%12==2)
  {
    bgcolor = #E16552;
  }

  if (n%12==3)
  {
    bgcolor =  #a34974;
  }

  if (n%12==4)
  {
    bgcolor = #9163b6;
  }

  if (n%12==5)
  {
    bgcolor = #E279A3;
  }

  if (n%12==6)
  {
    bgcolor = #E0598B;
  }

  if (n%12==7)
  {
    bgcolor =  #7c9fb0;
  }

  if (n%12==8)
  {
    bgcolor = #5698c4;
  }
}

void stop() {
  // always close Minim audio classes when you are done with them
  in.close();
  minim.stop();
  super.stop();
}