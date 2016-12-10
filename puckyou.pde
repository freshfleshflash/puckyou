// pins {mic, button1, button2, left, right}


int[] pins1 = {5, 2, 3, 4, 5};
int[] pins2 = {0, 8, 9, 10, 11};

import cc.arduino.*;
import processing.serial.*;
import muthesius.net.*;
import org.webbitserver.*;
import fisica.*;
import geomerative.*;

Arduino arduino;

WebSocketP5 socket1, socket2;

int prePressed1 = 0;
int prePressed2 = 0;

FWorld world;

ArrayList<String> wordsStorage = new ArrayList<String>();
ArrayList<Border> borders = new ArrayList<Border>();
ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();
//ArrayList<String> oWordsStorage = new ArrayList<String>();
String[] oWordsStorage = {"", "정말로", "이런", "아오"}; 
ArrayList<Ball> balls = new ArrayList<Ball>();

Player p1, p2;
PFont font;

void setup() {
  size(displayWidth, displayHeight);
  smooth();

  println(width, height);

  // arduino
  //setArduino();

  // socket
  socket1 = new WebSocketP5(this, 8080, "socket1");
  socket2 = new WebSocketP5(this, 9090, "socket2");

  // fisica
  Fisica.init(this);
  RG.init(this);
  RG.setPolygonizer(RG.ADAPTATIVE);

  world = new FWorld();
  world.setGravity(0, 0);
  world.setEdges(color(0, 0, 0, 0));
  world.setEdgesFriction(0);
  world.setEdgesRestitution(1);

  renderBorders();
  renderObstacles();

  // player
  p1 = new Player(pins1, -1);
  p2 = new Player(pins2, 1);

  // etc.
  font = createFont("Arial-Black-24.vlw", 24);
  textFont(font);
}

void draw() {
  background(255);

  //p1.method();
  p2.method();

  world.draw();
  world.step();

  manageBalls();
  //controlBallCreation();

  //drawCenterLine();
  //convertBooleanToInt();
}

void setArduino() {
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[2], 57600);

  //for (int i = 0; i < 3; i++) {
  //  arduino.pinMode(pins1[i], Arduino.INPUT); // player 1
  //  arduino.pinMode(pins2[i], Arduino.INPUT); // player 2
  //}

  for (int i = 3; i < 5; i++) {
    arduino.pinMode(pins1[i], Arduino.SERVO); // player 1
    arduino.pinMode(pins2[i], Arduino.SERVO); // player 2
  }
}

void stop() {
  socket1.stop();
  socket2.stop();
}

// player별로 따로 관리하고 싶으나 socket 연동하려니까 이거 어째..
void controlBallCreation() {
  if (((arduino.digitalRead(p1.pin_b1) - prePressed1) == 1)) {
    p1.portal = true;
    socket1.broadcast("start1");
    prePressed1 = 1;
  } else if ((arduino.digitalRead(p1.pin_b1) - prePressed1 == -1)) { 
    p1.portal = false;
    socket1.broadcast("stop1");    
    prePressed1 = 0;
  }

  if (((arduino.digitalRead(p2.pin_b1) - prePressed2) == 1)) {
    p2.portal = true;
    socket2.broadcast("start2");
    prePressed2 = 1;
  } else if ((arduino.digitalRead(p2.pin_b1) - prePressed2 == -1)) { 
    p2.portal = false;
    socket2.broadcast("stop2");
    prePressed2 = 0;
  }
}

// player별로 따로 관리하고 싶으나 socket 연동하려니까 이거 어째..
void controlBallCreationWithKey() {
  if (keyPressed && keyCode == LEFT) {
    p1.portal = true;
    socket1.broadcast("start1");
    prePressed1 = 1;
  } else { 
    p1.portal = false;
    socket1.broadcast("stop1");    
    prePressed1 = 0;
  }

  if (keyPressed && keyCode == RIGHT) {
    p2.portal = true;
    socket2.broadcast("start2");
    prePressed2 = 1;
  } else { 
    p2.portal = false;
    socket2.broadcast("stop2");
    prePressed2 = 0;
  }
}

int bId = 0;
void websocketOnMessage(WebSocketConnection con, String msg) {
  wordsStorage.add(msg);
  for (int i = 0; i < wordsStorage.size(); i++) {
    println(wordsStorage.get(i) + " ");
  }

  println(msg.substring(0, 3));

  Player p = (msg.substring(0, 3).equals("[a]")) ? p1 : p2;

  balls.add(new Ball(bId++, p.x, p.ballSlot, new PVector(p.player * -500, 0)));
  world.add((balls.get(balls.size() - 1)));
}

void websocketOnOpen(WebSocketConnection con) {
  println("A client joined ");
}

void websocketOnClosed(WebSocketConnection con) {
  println("A client left ");
}

void renderBorders() {
  //float borderW = 600;
  //float borderH = 20; 

  //borders.add(new Border(width/2, borderH, borderW, borderH, 0));
  //borders.add(new Border(width/2, height-borderH, borderW, borderH, 0));
  //borders.add(new Border(borderH, height/2, borderH, borderW, 0));
  //borders.add(new Border(width-borderH, height/2, borderH, borderW, 0));

  //borders.add(new Border((width-borderW)/4, (height-borderW)/4, borderH, borderW/2, 75));
  //borders.add(new Border(width - (width-borderW)/4, (height-borderW)/4, borderH, borderW/2, 105));
  //borders.add(new Border((width-borderW)/4, height - (height-borderW)/4, borderH, borderW/2, 105));
  //borders.add(new Border(width - (width-borderW)/4, height - (height-borderW)/4, borderH, borderW/2, 75));

  //for (int i = 0; i < borders.size(); i++) {
  //  world.add(borders.get(i));
  //}
}

void renderObstacles() {
  obstacles.add(new Obstacle());
  
  float borderW = 600;
  for (int i = 1; i <= 3; i++) {
    obstacles.add(new Obstacle(i, random((width-borderW)/4, width - (width-borderW)/4), random((height-borderW)/4, height - (height-borderW)/4)));
    world.add(obstacles.get(i));
  }
}

void manageBalls() {
  for (int i = 0; i < balls.size(); i++) {
    balls.get(i).moveText();
  }
}

void contactEnded(FContact c) {
  println(c.getBody1().getGroupIndex(), c.getBody2().getGroupIndex());

  if ((c.getBody1().getGroupIndex() < 0) || c.getBody2().getGroupIndex() < 0) {
    int bId = (c.getBody2().getGroupIndex() < 0) ? c.getBody1().getGroupIndex() : c.getBody2().getGroupIndex(); 
    int oId = (c.getBody2().getGroupIndex() < 0) ? c.getBody2().getGroupIndex() : c.getBody1().getGroupIndex(); 
    
    println(bId, wordsStorage.get(bId)); 
    String plus = oWordsStorage[-oId];
    wordsStorage.set(bId, wordsStorage.get(bId) + plus);
  }
}

void drawCenterLine() {
  stroke(100);
  line(0, height/2, 1280, height/2);
  line(width/2, 0, width/2, 800);
}

int pressed = 0;
void convertBooleanToInt() {
  if (keyPressed) pressed = 1;
  else pressed = 0;
}