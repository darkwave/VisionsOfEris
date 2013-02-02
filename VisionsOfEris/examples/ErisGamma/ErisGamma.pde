/*

	Visions of Eris
	a Free Software Augmented Reality Dectective Story made with Processing
	
	Code by Massimo Avvisati <http://mondonerd.com> is under GPL v3
	3D Assets under Creative Commons (BY-NC-SA)
	<http://mightydargor.deviantart.com/art/Visions-Of-Eris-Assets-Showcase-351390914>



	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

import jp.nyatla.nyar4psg.*;

import codeanticode.gsvideo.*;
GSCapture cam;


MultiMarker nya;

int numberOfMarkers = 0;

PShape[] scene;
PShape[] visions;

int errors = 0;

// CONFIGURAZIONE 1
String[] sceneModels = { 
  "stanzaletto_ingame.obj", 
  "stanzamorto_ingame.obj", 
  "ospedale_ingame.obj", 
  "corridoio_ingame.obj",
};
String[] visionModels = { 
  "stanzaletto_ingame.obj", 
  "stanzamorto_ingame.obj", 
  "ospedale_ingame.obj", 
  "corridoio_ingame.obj",
};


int sequenceCounter;
boolean showingAnimation;
PImage[] animation;

HashMap<String, PImage> clues = new HashMap<String, PImage>();
HashMap<String, PImage> horror = new HashMap<String, PImage>();

PImage message = null;
int messageTimer;

int numberOfModels;

float angle = 0;

boolean dragging = false;
float lastMouseX;

PGraphics offscreen;
PImage splashScreen;
boolean justStarted = true;

int messageCounter = 0;
float messageDeCenter = 100;
PGraphics canvas;

HashMap<String, PImage> solution = new HashMap<String, PImage>();
PImage victory, dead;

//Shaders

PShader fisheye;
PImage icon;
void setup() {
  size(displayWidth, displayHeight, P3D);
  orientation(LANDSCAPE); //for android display

  //Shaders
  fisheye = loadShader("FishEye.glsl");
  fisheye.set("aperture", 140.0); 

  icon = loadImage("icon.png");

  noStroke();
  imageMode(CENTER);


  numberOfModels = sceneModels.length;
  //load models into scene array
  scene = new PShape[numberOfModels];
  visions = new PShape[numberOfModels];
  int angle = 0;
  for (int i = 0; i < numberOfModels; i++) {
    scene[i] = loadShape(sceneModels[i]);

    scene[i].rotateX(radians(90));
    scene[i].rotateY(radians(angle));
    scene[i].scale(20, 20, 20);
    scene[i].translate(1, 0, 0);
    visions[i] = loadShape(visionModels[i]);

    visions[i].rotateX(radians(90));
    visions[i].rotateY(radians(angle));
    visions[i].scale(20, 20, 20);
    visions[i].translate(1, 0, 0);
    angle += 90;
  }

  cam = new GSCapture(this, 640, 480);

  offscreen = createGraphics(cam.width, cam.height);
  offscreen.beginDraw();
  offscreen.background(0);
  offscreen.endDraw();

  //init AR
  nya=new MultiMarker(this, offscreen.width, offscreen.height, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
  //add markers

  nya.addARMarker("patt.hiro", 80);
  splashScreen = loadImage("splash.jpg");
  victory = loadImage("victory.png");

  dead = loadImage("dead.png");
  refreshInput(splashScreen);
  //TODO aggiungere immagini sequenza
  String[] visionsFilenames = {
    "vision.png"
  };
  String[] visionsKeywords = {
    "Verde"
  };
  animation = new PImage[visionsFilenames.length];
  for (int i = 0; i < visionsFilenames.length; i++) {
    PImage vision = loadImage(visionsFilenames[i]);
    clues.put(visionsKeywords[i], vision);
    animation[i] = vision;
  }

  String[] horrorsFilenames = {
    "horror.png"
  };
  String[] horrorsKeywords = {
    "Rosso"
  };

  for (int i = 0; i < horrorsFilenames.length; i++) {
    horror.put(horrorsKeywords[i], loadImage(horrorsFilenames[i]));
  }
}


void refreshInput(PImage inputImg) {
  offscreen.beginDraw();
  offscreen.pushMatrix();
  offscreen.scale(-1, 1);
  offscreen.image(inputImg, -offscreen.width, 0, offscreen.width, offscreen.height); 
  offscreen.popMatrix();
  offscreen.endDraw();
  try {
    nya.detect(offscreen);
  } 
  catch (Exception e) {
    println("AAAhhhh");
  }
}

void lights() {
  directionalLight(255, 255, 255, 0, 0, -0.5);
}

void showSequence() {


  if (message == null && sequenceCounter < solution.size()) {
    message = animation[sequenceCounter];
    messageTimer = millis();
    sequenceCounter++;
  } 
  else if (message == null && sequenceCounter >= solution.size()) {
    sequenceCounter = 0;
    showingAnimation = false;
  }
}

boolean showMessage() {
  if (canvas == null) {
    canvas = createGraphics(width, height, P2D);
    canvas.noStroke();
    canvas.imageMode(CENTER);
  }
  if (message != null && millis() - messageTimer < 4000) {
    messageCounter += 1;
    float imageCenterX = sin(radians(messageCounter)) * messageDeCenter;
    float imageCenterY = cos(radians(messageCounter)) * messageDeCenter;

    background(0);
    //
    canvas.beginDraw();
    canvas.background(0);
    canvas.image(message, imageCenterX + width / 2, imageCenterY + height / 2);
    canvas.endDraw();
    shader(fisheye);
    pushMatrix();
    translate(width / 2, height / 2);
    scale(1.3);
    image(canvas, 0, 0);
    popMatrix();

    return true;
  } 
  else {
    return false;
  }
}

void draw() {
  if (showingAnimation) {
    showSequence();
  }

  if (solution.size() >= 2) {
    message = victory;
    messageTimer = millis() + 5000;
  } 
  else if (errors >= 2) {
    message = dead;
    messageTimer = millis() + 5000;
  }
  if (!justStarted) {

    if (showMessage())
      return; //don't do nothing when showing messages


    resetShader();
    
    if (cam.available()) {
      onCameraPreviewEvent();
    }
    
    display(g, false);
    image(icon, icon.width / 2, height - icon.height);
  } 
  else {
    background(0);
    image(splashScreen, width / 2, height / 2);
    return;
  }
}

void display(PGraphics pg, boolean off) {
  imageMode(CORNER);
  pg.perspective();
  pg.hint(DISABLE_DEPTH_TEST);
  if (!off) {
    lights();
    pg.image(offscreen, 0, 0, width, height);
  }
  else {
    pg.background(0);
  }

  pg.textSize(20);
  pg.text("Eris - Global Game Jam 2013\nCode by Mondonerd.com under GPL v3", 20, 25);
  pg.hint(ENABLE_DEPTH_TEST);
  pg.pushMatrix();
  PMatrix3D m=nya.getProjectionMatrix().get();

  pg.setMatrix(m);
  for (int i = 0; i < 1; i++) {
    if (nya.isExistMarker(i)) {
      pg.pushMatrix();
      pg.setMatrix(nya.getMarkerMatrix(i)); //load Marker matrix
      for (int j = 0; j < scene.length; j++) {
        if (!off) {
          pg.shape(scene[j], 0, 0);
        }
        else {
          pg.shape(visions[j], 0, 0);
        }
      }
      pg.popMatrix();
    }
  }
  pg.popMatrix();
  imageMode(CENTER);
}

String getObjectID(int mouseX, int mouseY) {
  /*
  colorBuffer.beginDraw();
  display(colorBuffer, true);
  colorBuffer.endDraw();
*/
  float pickedColor = random(100);//colorBuffer.get(mouseX, mouseY);
  if (pickedColor < 50) {
    
    if (pickedColor < 20) {
      return "Rosso";
    } 
    else if (pickedColor < 40) {

      return "Verde";
    } 
    else {
      return "Non importante";
    }
  } 
  else { //clicked on background
    return null;
  }
}

void mousePressed() {
  if (justStarted) {
    cam.start();
    justStarted = false;
    messageTimer = millis();
    message = null;
  }
  else {

    if (dist(mouseX, mouseY, 0, height) < 50 && solution.size() > 0) {
      showingAnimation = true;
      message = animation[0];
      messageTimer = millis();
    }

    String clueTry = getObjectID(mouseX, mouseY);
    if (clueTry != null)
      if (clues.containsKey(clueTry)) {
        PImage clueImage = clues.get(clueTry);
        message = clueImage;
        if (!solution.containsKey(clueTry)) {
          solution.put(clueTry, clueImage);
        }


        messageTimer = millis();
      } 
      else if (horror.containsKey(clueTry)) {
        PImage horrorImage = horror.get(clueTry);
        message = horrorImage;
        errors++;
        messageTimer = millis();
      }
  }
}

void onCameraPreviewEvent()
{
  cam.read();
  refreshInput(cam);
}
