//Add option to delete a scanned item when enlarged? (although may disconnect from physical?)
//Store people's rationales behind items

import java.util.Map;
import processing.serial.*;

int numItems = 24;        //change to show number of items included

int windWid;              //assigned in setup()
int windHei;
int sWei = 3;             //default stroke weight

int inputLineBuff = 5;    //the distance (or buffer) between the flashing verticle line and any text that is input
int txtEdge = 20;         //the x-distance from the edge of the screen text (at the top) is displayed at
int txtLine = 80;         //the y co-ordinate of the line below the text at the top of the screen
int descripEdge = 10;     //the x and y distance from description label to the edge of the container-area

int labTxtSz = 80;        //size of container labels (e.g. 'BOX')
int nameTxtSz = 50;       //size of item names (e.g. 'Button') when clicked on/scanned
int descripTxtSz = 30;    //size of item descriptions when clicked on/scanned
int botTxtSz = 20;        //size of text that appears at bottom of screen
int topTxtSz = 30;        //size of text that appears at top of screen
int stgeTxtSz = 20;       //size of text that shows stage (e.g. 'Stage 1/3')

int infoWid;              //assigned in setup()
int infoHei;


int dButWid = 100;          //the default button width, height, x, y, and colour
int dButHei = 30;
//int dButWid = 200;        //previous the default button width, height, x, y, and colour
//int dButHei = 100;
int dButX;                //assigned in setup()
int dButY;
//color dBut = color(200, 200, 255);
color dBut = color(67, 49, 167); //this is temp - would prefer to use background image
PImage but1;               //Liz

boolean clickAct = false;  //ensures only 1 object reacts to a 'click'; true if a object has reacted to a click; resets on click release.
boolean backAct = false;   //true if BACKSPACE pressed but inStr is empty
int mPressX = 0;           //stores the mouse co-ordinates at the point it was last clicked
int mPressY = 0;

String state = "startScreen";  //used for switch statement

PImage gradient;
PImage floodBox;
PImage emergBag;
PFont font;
String PPname = "";     //name of the participant (PP), taken in nameEntry screen
String[] a1Items = {};  //items the PP comes up with during activity 1
int a1Item = 0;         //item within a1Items[] PP is currently addressing
String inStr = "";      //temp storage for input string (i.e. acts as input buffer)
int itemsPresent = 0;   //number of items scanned in and on screen
int slideNum = 1;       //slide number for transition periods between activities (reset at the beginning of each)

String[] boxItems = {};
String[] bagItems = {};

String[] report = {};

public class ItemTag{
  public String id;
  public int container;
}

//Should make inheritance heirarchy eventually?
public class Item{    
  public String id;
  public String name;
  public int x, y, container;
  public int rLine = 0;
  public PImage smImg;
  public PImage laImg;
  public String[] descrip;
  public String[] rationale = {};
  public Button close;
  
  public boolean present = false;
  public boolean held = false;
  public boolean enlarged = false;
  
 // public int smWid = 150;                          //change this val to change size of scanned objects 
  public int smWid = 100; 
  public int laWid = 500;
  
  public Item(String id, String name){
    this.id = id;
    this.name = name;
    PImage img = loadImage("graphics/" + name + ".png");
    int factor = laWid/img.width; //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    img.resize(smWid, img.height*factor);
    this.descrip = loadStrings("descrips/" + name + "Descrip.txt");
  }
  
  public void unenlarge(){
    enlarged = false;
    inStr = "";
  }
  
  public void scanned(int c){
    present = true;
    this.container = c;
    int minX, maxX;
    if (this.container == 1){
      minX = 0;
      maxX = windWid/2 - img.width;
    }
    else {
      minX = windWid/2;
      maxX = windWid - img.width;
    }
    int attempts = 0;  //debug only
    do {
      //println("re-trying to place");
      attempts++;
      this.x = int(random(minX, maxX));
      this.y = int(random(txtLine+labTxtSz, (windHei-img.height-(dButHei-10))));  //accounts for dButs aswell
    } while (detectCollision());
    //println(attempts);
  }
  
  public void drawImg(){
    if (enlarged){
      int imgX = 0;
      if (this.container == 2) imgX = windWid/2; //if in the bag, will draw on the back side
      float factor = float(laWid/img.width);
      img.resize(laWid, int(img.height*factor));
      //blurry image here
      image(img, imgX, txtLine+labTxtSz-10);//change vertical position but be aware that moving up too far could overlap text
    }      
    else {
      float factor = float(smWid/img.width);
      img.resize(smWid, int(img.height*factor));
      image(img, x, y);
    }
  }
  
  public void enlarge(){
    if (!enlarged && rationale.length > 0) inStr = rationale[rLine];
    enlarged = true;
    drawImg();
    drawDescrip();
  
  }
  
  public void drawDescrip(){
    int infoX;
    int infoY = txtLine+descripEdge;
    if (this.container == 1) infoX = (windWid/2)+descripEdge;
    else infoX = descripEdge;
     
     
 fill(200, 200, 255);
    //strokeWeight(2);
    rect(infoX, infoY, infoWid, infoHei);
    
    fill(255, 255, 255); //text colour
    addText(this.name, infoX+5, infoY+5, nameTxtSz, "L", "T");
    for (int i = 0; i < descrip.length; i++){
      addText(descrip[i], infoX+5, infoY+nameTxtSz+10+(i*descripTxtSz), descripTxtSz, "L", "T");
    }

    //rationale part below
    /*
    int rY = infoY+int(infoHei-200);
    addText("Rationale", infoX+5, rY-(descripTxtSz+5), descripTxtSz+10, "L", "T");
    //println("rLength: " + this.rationale.length + " | rLine: " + rLine);    
    //println(rY+(descripTxtSz*(rLine+1)) + " vs " + (infoY+infoHei));
    if (this.rationale.length > rLine+1) this.rationale = shorten(this.rationale);
    else if (this.rationale.length == rLine) this.rationale = append(this.rationale, ""); //if the line we're on doesn't exist, append a new line
    
    textSize(descripTxtSz);
    boolean exceedX = (textWidth(inStr) > infoWid-5);  //am I currently exceeding the info space  
    boolean exceedY = ((rY+(descripTxtSz*(rLine+1)) > (infoY+infoHei))); //would the next line exceed the info space   

    if ((!exceedX && !exceedY) && alternator(500)) line(infoX+textWidth(this.rationale[rLine])+inputLineBuff, rY+((rLine+1)*descripTxtSz), infoX+textWidth(this.rationale[rLine])+inputLineBuff, rY+((rLine)*descripTxtSz));    
    print(rLine);
    
    if (exceedX){
      char lastChar = inStr.charAt(inStr.length()-1);
      println(lastChar);
      inStr = str(lastChar);
      //rLine++;
        if (!exceedY) rLine++;
    }   
    else if (!exceedY) this.rationale[rLine] = inStr;
    else inStr = "";
    
    if (keyCode == ENTER && !inStr.equals("")){  // needs to be first to avoid Exception w/ input-line-draw | ensures less than 15 items
      inStr = "";
      rLine++;
    }
    
    if (inStr.equals("") && keyCode == BACKSPACE && rLine > 0){
      rLine--;
      inStr = this.rationale[rLine];
    }   

    for (int i = 0; i < this.rationale.length; i++){
      addText(this.rationale[i], infoX+5, rY+(descripTxtSz*i), descripTxtSz, "L", "T");
      line(infoX+5, rY+(descripTxtSz*(i+1)), infoX+infoWid-10, rY+(descripTxtSz*(i+1)));
    }
    */
    
    close = new Button("X", infoX+infoWid-60-5, infoY+5, 60, 60, color(255,200,200));
    close.drawSelf();
  }
  
  public boolean clicked(){
    if (!enlarged && mousePressedOver() && mousePressed && !clickAct){  //ensures mutex
      clickAct = true;
      return true;
    }
    else return false;
  }
  
  public void heldDrag(){  //needed for activity3
    if (clicked()){
      held = true;
    }
    if (held == true){
      if ((mouseX > 0 && mouseX < windWid && mouseY > txtLine && mouseY < windHei)
      && ((this.container == 1 && mouseX < windWid/2) || (this.container == 2 && mouseX > windWid/2))){
          x = mouseX-(img.width/2);
          y = mouseY-(img.height/2);
      }
      if (!clickAct) held = false;
    }
  }
  
  public boolean detectCollision(){
    int allowance = smWid/2 - 5;  //smWid/2 -> no collision, more subtracted, less allowance
    for (int i = 0; i < crateItems.length; i++){
      if (crateItems[i].id != this.id && crateItems[i].present){
        //print(" | " + i + " is present");
        int myX = this.x +allowance;
        int myY = this.y +allowance;
        int myWid = this.img.width -allowance;
        int myHei = this.img.height -allowance;
        int chalX = crateItems[i].x +allowance;
        int chalY = crateItems[i].y +allowance;
        int chalWid = crateItems[i].img.width -allowance;
        int chalHei = crateItems[i].img.height -allowance;
        if ((chalX + chalWid) >= myX && chalX <= (myX+myWid) &&         //if challenger's right (edge) >= my left AND challenger's left <= my right              
            (chalY + chalHei) >= myY && chalY <= (myY+myHei)){          //AND challenger's top >= my bottom AND challenger's bottom <= my top
              //print(" | it does collide");
              return true;
        }
      }
    }
    return false;
  }
  
  public boolean mousePressedOver(){
    int tempX = this.x;
    int tempY = this.y;
    if (mPressX >= tempX && mPressX <= tempX+img.width && mPressY >= tempY && mPressY <= tempY+img.height){
      return true;
    }
    else return false;
  }
}
  
public class Button{
  public String txt;
  public int x, y, wid, hei;
  public color col;
  
  public Button(String t, int x, int y, int w, int h, color c){
    this.txt = t;
    this.x = x;
    this.y = y;
    this.wid = w;
    this.hei = h;
    this.col = c;
    //this.drawSelf();
  }
  
  public boolean clicked(){
    if (mousePressedOver() && mousePressed && !clickAct){  //ensures mutex
      //println("! click");
      clickAct = true;
      return true;
    }
    else return false;
  }
  
  public boolean mousePressedOver(){
    if (mPressX >= x && mPressX <= x+wid && mPressY >= y && mPressY <= y+hei)
      return true;
    else return false;
  }
  
  public boolean mouseHoverOver(){
    if (mouseX >= x && mouseX <= x+wid && mouseY >= y && mouseY <= y+hei)
      return true;
    else return false;
  }

  public void drawSelf(){
    noStroke();
    fill(col);
    //rect(x, y, wid, hei);
    image(but1, x, y);                     //Liz
    
    if (mouseHoverOver()) fill(0, 0, 0);  //colour when mouse is hovering over
    else fill(255, 255, 255);             //colour when mouse is not^
    addText(txt, x+(wid/2)-2, y+(hei/2)-2, hei/2, "C", "C"); //text is half height of button
    
    fill(255, 255, 255);                 //reset colour back to black
    stroke(67, 49, 167);
  }
  
  public void changeTxt(String t){
    this.txt = t;
  }
}

Item[] crateItems = new Item[numItems]; //length of #crateItems
Button rBut;
Button lBut;

Serial bagPort;
Serial boxPort;
Serial printPort;
ItemTag latestScan = new ItemTag();
String tagID = "";

void setup(){
  //fullScreen();                  //uncomment this and comment the below to make fullscreen
  size(1300, 700);             //do the opposite to ^ to make windowed
  windWid = width;
  windHei = height;
  
  infoWid = (windWid/2) - (descripEdge*2);
  infoHei = windHei - (descripEdge*2) - txtLine;
  
  dButX = windWid-dButWid-10;
  dButY = windHei-dButHei-10;
  
  gradient = loadImage("graphics/gradient.png");
  gradient.resize(windWid-(sWei*2), windHei-txtLine-sWei);
  floodBox = loadImage("graphics/floodBox.gif");
  emergBag = loadImage("graphics/emergBag.png");
  but1 = loadImage("graphics/but1.gif");                   //Liz
  but1.resize(dButWid, dButHei);                           //Liz
  
  rBut = new Button("Done", dButX, dButY, dButWid, dButHei, dBut);
  lBut = new Button("Back", 10, dButY, dButWid, dButHei, dBut);
    
  //ADD NFC TAG IDS ALONGSIDE THEIR ITEM NAMES HERE | ITEM NAMES SHOULD MATCH GRAPHICS & DESCRIP NAMES  
  
  //old tags
  /*
  crateItems[0] = new Item("17846141", "Torch");
  crateItems[1] = new Item("18291181", "Boots");
  crateItems[2] = new Item("18366317", "Bottle");
  crateItems[3] = new Item("18742141", "Bear");
  */ 
  
  //new tags
  crateItems[0] = new Item("18323229", "Insurance");
  crateItems[1] = new Item("18724189", "Mobile");
  crateItems[2] = new Item("18324685", "Cash");
  crateItems[3] = new Item("18645805", "Medication");
  crateItems[4] = new Item("17834525", "Babyfood");
  crateItems[5] = new Item("18585933", "Babybottle");
  crateItems[6] = new Item("18760461", "Nappies");
  crateItems[7] = new Item("18286413", "Nappybags");
  crateItems[8] = new Item("18804301", "Babyclothes");
  crateItems[9] = new Item("17849405", "Toy");
  crateItems[10] = new Item("18482685", "Camera");
  crateItems[11] = new Item("18130013", "Info");
  crateItems[12] = new Item("18478365", "Torch");
  crateItems[13] = new Item("17804269", "Batteries");
  crateItems[14] = new Item("18292445", "Radio");
  crateItems[15] = new Item("17995821", "Food");
  crateItems[16] = new Item("17962525", "Water");
  crateItems[17] = new Item("18454525", "Washkit");
  crateItems[18] = new Item("18419453", "Cards");
  crateItems[19] = new Item("18421933", "Blanket");
  crateItems[20] = new Item("18597805", "Boots");
  crateItems[21] = new Item("18403213", "Waterproof");
  crateItems[22] = new Item("17824605", "Gloves");
  crateItems[23] = new Item("18032317", "Firstaid");
 
  
  
  //extras
  //crateItems[24] = new Item("18331069", "Firstaid");
  //crateItems[25] = new Item("18032317", "Firstaid");
  //crateItems[26] = new Item("18349901", "Firstaid");
 // crateItems[27] = new Item("18549581", "Firstaid");
  //crateItems[28] = new Item("18132429", "Firstaid");
 // crateItems[29] = new Item("18274109", "Firstaid");
  //crateItems[30] = new Item("18645805", "Firstaid");  //tag assigned
 // crateItems[31] = new Item("18324685", "Firstaid");  //tag assigned
 // crateItems[32] = new Item("18724189", "Firstaid");  //tag assigned
 // crateItems[33] = new Item("18323229", "Firstaid");  //tag assigned
 //crateItems[23] = new Item("17885661", "Firstaid");
 // crateItems[0] = new Item("17885661", "Firstaid");
  
  
  //surface.setSize(windWid, windHei);
 // font = createFont("Candara", 30);
 font = createFont("Roboto Slab", 20);
  textFont(font); //actives the font, apperently
  resetDefaults();
  
  /* !!! Below commented out for Edward's PC to run without Arduinos connected
  
  //boxPort = new Serial(this, "COM4", 9600);
  boxPort = new Serial(this, "/dev/tty.usbmodem1A12421", 9600);
  boxPort.buffer(10);
  boxPort.clear();
  
 // bagPort = new Serial(this, "COM5", 9600);
  bagPort = new Serial(this, "/dev/tty.usbmodem1A1221", 9600);
  bagPort.buffer(10);
  bagPort.clear();
  
  //printPort = new Serial(this, "COM3", 19200);
 // printPort = new Serial(this, "/dev/tty.usbserial-A501DGRD", 19200);
 
 */
  
}

void startScreen(){
  //println("0");  //debug
  addText("Welcome!", windWid/2, windHei/2-100, 90, "C", "C");
  addText("CLICK to begin", windWid/2, windHei/2+100, 50, "C", "C");
  if (mousePressed){
    clickAct = true;  //prevents buttons on next screen activating
    inStr = "";  //avoids carrying over key press from prvs state
    state = "nameEntry";
  }
}

int count = 0;
void nameEntry(){
  int lineY = 350;
  int lineX = 100;
  //println("1");  //debug
  addText("What's your name?", 50, 100, 60, "L", "C");
  //addText("We will not store this, it is for your eyes only!", windWid/2, windHei-50, botTxtSz, "C", "C");
  rBut.drawSelf();
  
  //print(PPname + "\n");
  addText(PPname, lineX, lineY, 80, "L", "Bo");
  line(lineX, lineY, windWid-lineX, lineY);
  
  if (alternator(500)) line(lineX+textWidth(PPname)+inputLineBuff, lineY-80, lineX+textWidth(PPname)+inputLineBuff, lineY);

  if (textWidth(inStr) <= 700) PPname = inStr;
  else {
    inStr = PPname;
    println("too long");
  }
  
  if (rBut.clicked()){
    if (a1Items.length > 0) inStr = a1Items[a1Item];
    else inStr = "";
    state = "activity1";
  }
}

boolean tutorial = true;
void activity1(){
  int lineX = 100;
  int ogLineX = lineX;  //because lineX is variable, 
  int lineY = 250;
  int ogLineY = lineY;
  int lineWid = 350;
  int space = 80;


  if (!PPname.equals(""))
    addText("What items do YOU think would be useful to have in a flood, " + PPname + "?", txtEdge, txtLine/2, topTxtSz, "L", "C");
  else addText("What items do YOU think would be useful to have in a flood?", txtEdge, txtLine/2, topTxtSz, "L", "C");
  addText("Stage 1/3", windWid-txtEdge, txtLine/2, stgeTxtSz, "R", "C");
  addText("Press 'ENTER' to add the next item", windWid/2, windHei-(botTxtSz*2)-10, botTxtSz, "C", "Bo");
  addText("Press 'BACKSPACE' to edit the previous item", windWid/2, windHei-botTxtSz, botTxtSz, "C", "Bo");
  line(0, txtLine, windWid, txtLine);
  addText("List at least 5 below", windWid/2, txtLine+20, 50, "C", "T");
  rBut.drawSelf();
  lBut.drawSelf();

  if (keyCode == ENTER && a1Items.length < 15 && !inStr.equals("")){  // needs to be first to avoid Exception w/ input-line-draw | ensures less than 15 items
  //ensure can only move on once something filled
    inStr = "";
    a1Item++;
  }
  
  //println("kC " + keyCode + " | item: " + a1Item + " | eB: " + backAct);
  //println("a1Item: " + a1Item + " | arrayLen: " + a1Items.length);
  if (keyCode == BACKSPACE && a1Item > 0 && backAct){  // needs to be first to avoid Exception w/ input-line-draw | ensures less than 15 items
    //print("backAct");
    a1Item--;
    inStr = a1Items[a1Item];
    backAct = false; //dealt with
  }
  
  if (a1Item >= a1Items.length) a1Items = append(a1Items, "");      //should never be greater than, only ever equal to
  else if (a1Item < a1Items.length-1) a1Items = shorten(a1Items);  //shortens if item is MORE than 1 below length (i.e. -2 or worse)
  
  if (tutorial && a1Items.length == 1 && !a1Items[a1Item].equals("")){
    addText("Press 'ENTER' to add the next item", (windWid/2 - lineWid/2), lineY, 30, "L", "Bo");
  }
  if (tutorial && a1Items.length == 2){
    addText("Press 'BACKSPACE' to edit the previous item", (windWid/2 - lineWid/2), lineY+space, 30, "L", "Bo");
  }
  if (a1Items.length >= 3) tutorial = false;  //removes tutorial pointers once user has entered 3 items
  if (a1Items.length == 5 && !a1Items[a1Item].equals("")){
    addText("Can you think of anymore?", (windWid/2 - lineWid/2), lineY+(4*space)-40, 30, "L", "Bo");
    addText("Press 'ENTER' to continue adding", (windWid/2 - lineWid/2), (lineY+(4*space)), 30, "L", "Bo");
  }
  //textSize(50);
  //strokeWeight(sWei);
  for (int i = 0; i < 5; i++) line(lineX, lineY+(i*space), lineX+lineWid, lineY+(i*space)); //sets up default 5 lines
  for (int i = 0; i < a1Items.length; i++){
    if (i >= 5){
      print(i + ": ");
      if (i >= 10){
        println(3);
        lineY = ogLineY - (10*space);
        lineX = windWid-lineWid-ogLineX;
      }
      else {
        println(2);
        lineY = ogLineY - (5*space);
        lineX = windWid/2 - lineWid/2;
      }
      line(lineX, lineY+(i*space), lineX+lineWid, lineY+(i*space));
    }
    addText(a1Items[i], lineX, lineY+(i*space), 35, "L", "Bo");  //change to Ba?
  }
  if (alternator(500)) line(lineX+textWidth(a1Items[a1Item])+inputLineBuff, lineY-50+(a1Item*space), lineX+textWidth(a1Items[a1Item])+inputLineBuff, lineY+(a1Item*space)); 
  
  if (textWidth(inStr) <= lineWid) a1Items[a1Item] = inStr;
  else {
    inStr = a1Items[a1Item];
    println("too long");
  }
  
  if (lBut.clicked()){
    inStr = PPname;
    state = "nameEntry";
  }
  if (a1Items.length >= 0 && rBut.clicked()){ //!!!SHOULD BE 5 (0 for debug)
    slideNum = 1;
    rBut.changeTxt("Next");
    state = "transit1to2";
  }
}

void transit1to2(){
  addText("Please read the information above before scanning!", windWid/2, windHei-20, topTxtSz, "C", "Bo");
  rBut.drawSelf();
  lBut.drawSelf();
  switch(slideNum){
    case 1:
      if (!PPname.equals("")) addText("Great work, " + PPname + "!", windWid/2, 200, 90, "C", "C");
      else addText("Great work!", windWid/2, 200, 90, "C", "C");
      addText("Now, have a look in the crate above.", windWid/2, 350, 50, "C", "C");
      addText("You'll find items we believe to be important.", windWid/2, 450, 50, "C", "C");
      break;
    case 2:
      addText("To prepare for a flood, these items can either", windWid/2, 250, 50, "C", "C");
      addText("be stored in a Flood Box or Emergency Bag", windWid/2, 350, 50, "C", "C");
      break;
    case 3:
      addText("A Flood Box is...<add descr>", windWid/2, 250, 50, "C", "C");
      image(floodBox, 10, 10);
      break;
    case 4:
      addText("An Emergency Bag is...<add descr>", windWid/2, 250, 50, "C", "C");
      image(emergBag, windWid-floodBox.width, 10);
      break;
    case 5:
      addText("Please put the items in front of you", windWid/2, 250, 50, "C", "C");
      addText("into either the Flood Box or Emergency Bag", windWid/2, 350, 50, "C", "C");
      addText("and remember to scan as you put them in!", windWid/2, 450, 30, "C", "C");
      break;
  }
  if (lBut.clicked()){
    if (slideNum-1 > 0) slideNum--;
    else {
      if (a1Items.length > 0) inStr = a1Items[a1Item];
      else inStr = "";
      state = "activity1";
    }
  }
  if (rBut.clicked()){
    if (slideNum < 5) slideNum++;
    else {
      inStr = "";
      latestScan = new ItemTag();        //resets tagID before activity2
      /* !!! Below commented out for Edward's PC to run without Arduinos connected
      boxPort.clear();
      bagPort.clear();
      */
      rBut.changeTxt("DONE");
      state = "activity2";
    }
  }
}
    
void activity2(){
  addText("Sort items into either the Flood Box or Emergency Bag. Remember to scan them!", txtEdge, txtLine/2, topTxtSz, "L", "C");
  addText("Stage 2/3", windWid-txtEdge, txtLine/2, stgeTxtSz, "R", "C");
  line(0, txtLine, windWid, txtLine);
  addText("BOX", 5, txtLine+5, labTxtSz, "L", "T");
  line(windWid/2, txtLine, windWid/2, windHei);
  addText("BAG", windWid-5, txtLine+5, labTxtSz, "R", "T");
  rBut.drawSelf();
  lBut.drawSelf();

  for (int i = 0; i < crateItems.length; i++){
    if (crateItems[i].id.equals(latestScan.id) && (!crateItems[i].present || crateItems[i].container != latestScan.container)){  //checks key against item IDs, then their presence OR scan into diff container
      println("making present");
      //int container = (int)random(1,3);
      crateItems[i].scanned(latestScan.container);                         //parameter = container, atm randomly 1 or 2 (box or bag)
      itemsPresent++;
      for (int j = 0; j < crateItems.length; j++){
        if (j != i) crateItems[j].enlarged = false;                 //resets the enlargement of all but the clicked one
      }
      crateItems[i].enlarge();
      break;
    }
  }   
  
  for (int i = 0; i < crateItems.length; i++){
    if (crateItems[i].present == true){
      if (crateItems[i].clicked()){
        for (int j = 0; j < crateItems.length; j++){
          if (j != i) crateItems[j].enlarged = false; //resets the enlargement of all but the clicked one
        }
        //print("large");
        crateItems[i].enlarge(); //do I need this here given for-loop at bottom?
      }
      else if (crateItems[i].enlarged && crateItems[i].close.clicked()){
        //for (int j = 0; j < crateItems.length; j++){
          crateItems[i].unenlarge();
        //}
      }
      crateItems[i].drawImg();
      //if (crateItems[i].enlarged) crateItems[i].drawDescrip();
      //crateItems[i].heldDrag();
      //println("item held: " + crateItems[i].held + " | mouseover: " + crateItems[i].mousePressedOver() + " | act: " + clickAct);
    }
  }
  for (int i = 0; i < crateItems.length; i++){
    if (crateItems[i].enlarged) crateItems[i].enlarge();  //done after for drawing layer purposes
  }
  
  if (lBut.clicked()){
    for (int i = 0; i < crateItems.length; i++) crateItems[i].enlarged = false; //resets the enlargement of all
    if (a1Items.length > 0) inStr = a1Items[a1Item];
    else inStr = "";
    state = "activity1";
  }  
  if (rBut.clicked() && itemsPresent > 0){
    for (int i = 0; i < crateItems.length; i++) crateItems[i].enlarged = false; //resets the enlargement of all
    inStr = "";
    state = "transit2to3";
    rBut.changeTxt("Next");
    slideNum = 1;
  }
}

void transit2to3(){
  rBut.drawSelf();
  lBut.drawSelf();
  
  switch(slideNum){
    case 1:
      if (!PPname.equals("")) addText("Brilliant " + PPname + "!", windWid/2, 200, 90, "C", "C");
      else addText("Brilliant!", windWid/2, 200, 100, "C", "C");
      addText("Lastly, please move the items you have chosen up or down", windWid/2, 350, 50, "C", "C"); //change 3rd value for text scale 
      addText("based on how important you believe they are.", windWid/2, 450, 50, "C", "C");
      break;
    case 2:
      addText("You do not need to move the items in the real world,", windWid/2, 250, 50, "C", "C");
      addText("only the ones seen on screen!", windWid/2, 350, 50, "C", "C");
      break;
  }
  if (lBut.clicked()){
    inStr = "";
    latestScan = new ItemTag();
    bagPort.clear();
    state = "activity2";
  }  
  if (rBut.clicked()){
    if (slideNum < 2) slideNum++;
    else state = "activity3";
  }
}

void activity3(){
  image(gradient, sWei, txtLine);
  addText("Move items you feel are most important higher, and less important lower", txtEdge, txtLine/2, topTxtSz, "L", "C");
  addText("Stage 3/3", windWid-txtEdge, txtLine/2, stgeTxtSz, "R", "C");
  line(0, txtLine, windWid, txtLine);
  addText("BOX", 5, txtLine+5, labTxtSz, "L", "T");
  line(windWid/2, txtLine, windWid/2, windHei);
  addText("BAG", windWid-5, txtLine+5, labTxtSz, "R", "T");
  rBut.drawSelf();
  lBut.drawSelf();

  for (int i = 0; i < crateItems.length; i++){
    if (crateItems[i].present){
      crateItems[i].heldDrag();
      crateItems[i].drawImg();
    }
  }
  
  if (lBut.clicked()){
    inStr = "";
    state = "activity2";
  }  
  
  if (rBut.clicked()){
    state = "preReport";   
    slideNum = 1;
  }
}

void preReport(){
  rBut.drawSelf();
  lBut.drawSelf();
  switch (slideNum){
    case 1:
      if (!PPname.equals("")) addText("Thank you for participating " + PPname + "!", windWid/2, 200, 50, "C", "C");
      else addText("Thank you for participating!", windWid/2, 200, 50, "C", "C");
      addText("We hope you gained some valuable insights as to what items", windWid/2, 350, 50, "C", "C");
      addText("you might need to prepare for a flood event.", windWid/2, 450, 50, "C", "C");
      break;
    case 2:
      addText("Now you'll be able to see and print your report", windWid/2, 250, 50, "C", "C");
      addText("for you to take home and use as a checklist!", windWid/2, 350, 50, "C", "C");
      break;
  }
  if (lBut.clicked()){
    state = "activity3";
  }
  if (rBut.clicked()){
    slideNum++;
    if (slideNum > 2){
      if (a1Items[a1Item].equals("")){
        a1Item--;
        a1Items = shorten(a1Items);  //removes the empty field - this empty will return if user goes back
      }
      makeReport();
      rBut.changeTxt("Save");
      state = "report";
    }
  }
} 

boolean once = true;  //!debug only

boolean repSaved = false;
void report(){
  int rTxtLine = txtLine+5;
  if (!PPname.equals("")) addText((PPname + "'s Flood Preparation Checklist"), txtEdge, txtLine/2, 60, "L", "C");
  else addText(("My Flood Preparation Checklist"), txtEdge, rTxtLine/2, 60, "L", "C");
  line(0, rTxtLine, windWid, rTxtLine);
  rBut.drawSelf();
  
  int startL = txtLine+40; //ease of Xcord ref'ing
  int itemS = 30;
  int titleS = 50;
  
  addText("Items that I felt were important", txtEdge, startL, titleS, "L", "T");
  startL = startL + titleS;
  if (once) println(startL);
  
  int itemNum = 0;
  if (once) println("len: " + a1Items.length + " | len/3: " + float(a1Items.length)/3);
  for (int i = 0; i < ceil(float(a1Items.length)/3); i++){
    for (int j = 0; j < 3; j++){
      //println("i: " + i + "j: " + j + "num: " + itemNum + "len: " + a1Items.length);
      if (itemNum < a1Items.length){        
        addText(str(itemNum+1) + ": " + a1Items[itemNum], txtEdge+(j*(windWid/3)), startL+(i*(itemS+10)), itemS, "L", "T");  
        itemNum++;
      }
    }
  }
  startL = startL + ((itemS+10) * (1+ceil(float(a1Items.length)/3))); 
  
  if (boxItems.length > 0){
    addText("My flood box items", txtEdge, startL, titleS, "L", "T");
    startL = startL + titleS;
    
    itemNum = 0;
    if (once) println("len: " + boxItems.length + " | len/3: " + float(boxItems.length)/3);
    for (int i = 0; i < ceil(float(boxItems.length)/3); i++){
      for (int j = 0; j < 3; j++){
        //println("i: " + i + "j: " + j + "num: " + itemNum + "len: " + a1Items.length);
        if (itemNum < boxItems.length){        
          addText(str(itemNum+1) + ": " + boxItems[itemNum], txtEdge+(j*(windWid/3)), startL+(i*(itemS+10)), itemS, "L", "T");  
          itemNum++;
        }
      }
    }
    startL = startL + ((itemS+10) * (1+ceil(float(boxItems.length)/3)));
  }
  
  if (bagItems.length > 0){
    addText("My emergency bag items", txtEdge, startL, titleS, "L", "T");  
    startL = startL + titleS;
    
    itemNum = 0;
    if (once) println("len: " + bagItems.length + " | len/3: " + float(bagItems.length)/3);
    for (int i = 0; i < ceil(float(bagItems.length)/3); i++){
      for (int j = 0; j < 3; j++){
        //println("i: " + i + "j: " + j + "num: " + itemNum + "len: " + a1Items.length);
        if (itemNum < bagItems.length){        
          addText(str(itemNum+1) + ": " + bagItems[itemNum], txtEdge+(j*(windWid/3)), startL+(i*(itemS+10)), itemS, "L", "T");  
          itemNum++;
        }
      }
    }
  }

  //state = "startState";
  if (rBut.clicked() && !repSaved){
    println("SaveClick");
    int fNum = 1;
    println(sketchPath("reports/report" + str(fNum) + ".txt"));
    File f = new File(sketchPath("reports/report" + str(fNum) + ".txt"));
    println(f.getName() + " : " + f.exists());
    while (f.exists()){
      println(fNum + " exists");
      fNum++;
      f = new File(sketchPath("reports/report" + str(fNum) + ".txt"));
    }
    println("saving as " + fNum);
    saveStrings(sketchPath("reports/report" + str(fNum) + ".txt"), report);
    repSaved = true;
    printTxt(report);
  }
  
  once = false;
}

void draw(){
  resetDefaults();
  switch (state)  {
  case "startScreen":
    startScreen();
    break;      
  case "nameEntry":
    nameEntry();      
    break;
  case "activity1":
    activity1();
    break;
  case "transit1to2":
    transit1to2();
    break;
  case "activity2":
    activity2();
    break;
  case "transit2to3":
    transit2to3();
    break;
  case "activity3":
    activity3();
    break;
  case "preReport":
    preReport();
    break;
  case "report":
    report();
    break;
  //case "endScreen":
    //endScreen();
    //break;
  }
}

void makeReport(){
  //print(report.length);
  if (!PPname.equals("")) report = append(report, "\n\n" + PPname + "'s \nFlood Preparation Checklist\n");
  else report = append(report, "\n\nMy Flood Preparation Checklist\n");
  
  report = append(report, "\n");
  report = append(report, "Items I thought were important\n");
  for (int i = 0; i < a1Items.length; i++){
    if (!a1Items[i].equals("")){
      report = append(report, (str(i+1) + ": " + a1Items[i] + "\n"));
    }
  }
  
  //sorts the items from the crate into either box or bag arrays
  for (int i = 0; i < crateItems.length; i++){
    if (crateItems[i].present && crateItems[i].container == 1){
      println("boxAdd: " + crateItems[i].name);
      boxItems = append(boxItems, crateItems[i].name);
    }
    if (crateItems[i].present && crateItems[i].container == 2){
      println("bagAdd: " + crateItems[i].name);
      bagItems = append(bagItems, crateItems[i].name);
    }
  }
  
  if (boxItems.length > 0){
    boxItems = sortItems(boxItems);
    report = append(report, "\n");  //new line; need as seperate append so that saving as .txt factors new line too
    report = append(report, "Flood Box Items\n");
    for (int i = 0; i < boxItems.length; i++){
      report = append(report, (i+1 + ": " + boxItems[i] + "\n"));
    }
  }
  
  if (bagItems.length > 0){
    bagItems = sortItems(bagItems);
    report = append(report, "\n");  //new line
    report = append(report, "Emergency Bag Items\n");
    for (int i = 0; i < bagItems.length; i++){
      report = append(report, (i+1 + ": " + bagItems[i] + "\n"));
    }
  }
  report = append(report, "\n________________________________");
  report = append(report, "\n\n\n\n\n\n________________________________"); //designed to cause the receipt to print longer, easier to cut
  //println(report.length);
}

String[] sortItems(String[] items){
  StringList temp = new StringList();
  String[] sorted = {};
  FloatDict itemPriorities = new FloatDict();
  for (int i = 0; i < crateItems.length; i++){
    if (crateItems[i].present == true){
      itemPriorities.set(crateItems[i].name, crateItems[i].y);
    }
  }
  for (int i = 0; i < items.length; i++){
    temp.append(items[i]);
  }
  while (temp.size() > 0){
    println(temp.size());
    int max = 0;
    for (int i = 0; i < temp.size(); i++){
      if (itemPriorities.get(items[i]) < itemPriorities.get(items[max])) max = i;  //< because Y increases downwards
    }
    sorted = append(sorted, temp.get(max));
    temp.remove(max);
  }
  return sorted;
}

void addText(String txt, int x, int y, int size, String aliX, String aliY){
  if (aliX.equals("L")){
    if (aliY.equals("T")) textAlign(LEFT, TOP);
    else if (aliY.equals("C")) textAlign(LEFT, CENTER);
    else if (aliY.equals("Bo")) textAlign(LEFT, BOTTOM);
    else if (aliY.equals("Ba")) textAlign(LEFT, BASELINE);
  }
  else if (aliX.equals("C")){
    if (aliY.equals("T")) textAlign(CENTER, TOP);
    else if (aliY.equals("C")) textAlign(CENTER, CENTER);
    else if (aliY.equals("Bo")) textAlign(CENTER, BOTTOM);
    else if (aliY.equals("Ba")) textAlign(CENTER, BASELINE);
  }
  else if (aliX.equals("R")){
    if (aliY.equals("T")) textAlign(RIGHT, TOP);
    else if (aliY.equals("C")) textAlign(RIGHT, CENTER);
    else if (aliY.equals("Bo")) textAlign(RIGHT, BOTTOM);
    else if (aliY.equals("Ba")) textAlign(RIGHT, BASELINE);
  }
  textSize(size);
  text(txt, x, y);
}  

void resetDefaults(){
  stroke(0);

  //background(0, 0, 0);
  background(34, 22, 122);
  fill(34, 22, 122);
  noStroke();
  rect(sWei, sWei, windWid-(sWei*2), windHei-(sWei*2));
  stroke(67, 49, 167);
  strokeWeight(sWei);
  fill(255, 255, 255);
}

void serialEvent(Serial port){  //make class that extends port to include id
  latestScan.id = trim(port.readString());
  //println("tag: " + tagID + " | prvs: " + prvsTagID);
  if (port == boxPort) latestScan.container = 1;
  if (port == bagPort) latestScan.container = 2;
  port.clear();
  println(latestScan.container);
}

void printTxt(String[] txt){
  for (int line = 0; line < txt.length; line++){
    printPort.write(txt[line]);
  }
}
  
//following variables used exclusively in alternator() method, but need to be global
boolean alternator = true;
int startTime = 0;
int timer = 0;
boolean alternator(int time){  //timer, startTime, & alternator all global variables
  timer = millis() - startTime;
  if (timer > time){
    alternator = !alternator;
    startTime = millis();
  }
  return alternator;
}

void keyPressed(){
  //print(keyCode + " ");
  backAct = false;            //assumes key is not a BACKSPACE with a blank inStr
  if (keyCode == BACKSPACE){
    if (inStr.length() > 0) inStr = inStr.substring(0, inStr.length() - 1);
    else backAct = true;      //corrects if key IS BACKSPACE with a blank inStr
  }
  else if ((keyCode > 46 && keyCode < 91) || keyCode == 32 || keyCode == 45 || keyCode == 44 || keyCode == 222){ //space | dash | comma | apostophe
    //should allow all numbers and letters
  
    inStr = inStr + key;
  }
  //print(inStr);
}

void mousePressed(){
  mPressX = mouseX;
  mPressY = mouseY;
}

void mouseReleased(){
  clickAct = false;  //resets
}