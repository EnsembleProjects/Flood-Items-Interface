import java.util.Map;
import processing.serial.*;

boolean showBackgroundImages = true;  // set false if you want a plain background rather than background images

int numItems = 23;        //change to show number of items included

int windWidth;            //assigned in setup()
int windHeight;
int strokeWeight = 3;     //default stroke weight

int inputLineBuff = 5;    //the distance (or buffer) between the flashing vertical line and any text that is input
int txtEdge = 20;         //the x-distance from the edge of the screen text (at the top) is displayed at
int txtLine;              //the y co-ordinate of the line below the text at the top of the screen - assigned in setup()
int descripEdge = 10;     //the x and y distance from description label to the edge of the container-area

int labTxtSz;             //size of container labels (e.g. 'BOX')
int nameTxtSz;            //size of item names (e.g. 'Button') when clicked on/scanned
int descripTxtSz;         //size of item descriptions when clicked on/scanned
int botTxtSz;             //size of text that appears at bottom of screen
int topTxtSz;             //size of text that appears at top of screen
int stgeTxtSz;            //size of text that shows stage (e.g. 'Stage 1/3')

int infoWidth;            //assigned in setup()
int infoHeight;

int dbutWidth = 100;      //the default button width, height, x, y, and colour
int dbutHeight = 30;
int dButX;                //assigned in setup()
int dButY;
color dBut = color(67, 49, 167); //this is temp - would prefer to use background image

boolean clickAct = false;  //ensures only 1 object reacts to a 'click'; true if a object has reacted to a click; resets on click release.
boolean backAct = false;   //true if BACKSPACE pressed but inStr is empty
int mPressX = 0;           //stores the mouse co-ordinates at the point it was last clicked
int mPressY = 0;

enum State {STARTSCREEN, NAMEENTRY, ACTIVITY1, TRANSIT1TO2, ACTIVITY2, REPORT, FINISHED};

State state = State.STARTSCREEN;  //used for switch statement

PImage gradient;
PImage floodBox;
PImage welcome;
PImage boots;
PImage sandbags;
PImage thumbsupwithoutrescue;
//PImage emergBag;

PFont font;
String PPname = "";        //name of the participant (PP), taken in nameEntry screen
String[] a1Items = {};     //items the PP comes up with during activity 1
int a1Item = 0;            //item within a1Items[] PP is currently addressing
String inStr = "";         //temp storage for input string (i.e. acts as input buffer)
int itemsPresent = 0;      //number of items scanned in and on screen
int slideNum = 1;          //slide number for transition periods between activities (reset at the beginning of each)

// used internally to ease generation of final report
String[] boxItems = {};    //items scanned into Box
String[] bagItems = {};    //items scanned into Bag
String[] report = {};      //text to be sent to printer

public class ItemTag
{
  public String id;
  public int container;
}

public class Item
{    
  public String id;
  public String name;
  public int x, y, container;
  public int rLine = 0;
  public PImage smallImg;
  public PImage largelImg;
  public String[] descrip;
  public Button close;
  
  public boolean present = false;
  public boolean held = false;
  public boolean enlarged = false;
  
  public int smWid = 100; 
  public int laWid = 500;
  
  public Item(String id, String name)
  {
    this.id = id;
    this.name = name;
    this.largelImg = loadImage("graphics/" + name + ".png");
    int laFactor = laWid/largelImg.width; 
    this.largelImg.resize(laWid, largelImg.height*laFactor);
    
    this.smallImg = loadImage("graphics/" + name + ".png");
    int smFactor = smWid/smallImg.width; 
    this.smallImg.resize(smWid, smallImg.height*smFactor);
    
    this.descrip = loadStrings("descrips/" + name + "Descrip.txt");
  }
  
  public void unenlarge()
  {
    enlarged = false;
    inStr = "";
  }
  
  public void scanned(int c)
  {
    present = true;
    this.container = c;
    int minX, maxX;
    if (this.container == 1)
    {
      minX = 0;
      maxX = windWidth/2 - smallImg.width;
    }
    else 
    {
      minX = windWidth/2;
      maxX = windWidth - smallImg.width;
    }
    double attempts = 0;      // count number of attempts to find non-colliding location
    do
    {
      attempts++;
      //println("trying to place, attempt " + attempts);
      this.x = int(random(minX, maxX));
      this.y = int(random(txtLine+labTxtSz, (windHeight-smallImg.height-dbutHeight-10)));  //accounts for dButs as well
                                                      // (don't let bottom of object go below top of buttons)
    } while (detectCollision() && attempts < 500);  // if we haven't found a non-collision in all these attempts, just use this location
    if (attempts == 500) println("placing collided object due to lack of space");
  }
  
  public void drawImg()
  {
    if (enlarged)
    {
      int imgX = 0;
      if (this.container == 2) imgX = windWidth/2; //if in the bag, will draw on the back side
      image(largelImg, imgX, txtLine+labTxtSz-10);//change vertical position but be aware that moving up too far could overlap text
    }      
    else 
      image(smallImg, x, y);
  }
  
  public void enlarge()
  {
    enlarged = true;
    drawImg();
    drawDescrip();
  }
  
  public void drawDescrip()
  {
    int infoX;
    int infoY = txtLine+descripEdge;
    if (this.container == 1) infoX = (windWidth/2)+descripEdge;
    else infoX = descripEdge;
     
     
    fill(67, 49, 167); //change this light blue
    //strokeWeight(2);
    rect(infoX, infoY, infoWidth, infoHeight);

    fill(224, 164, 14);  //yellow descipt txt
    addText(this.name, infoX+5, infoY+5, nameTxtSz, LEFT, TOP);
    for (int i = 0; i < descrip.length; i++)
    {
      addText(descrip[i], infoX+5, infoY+nameTxtSz+10+(i*descripTxtSz), descripTxtSz, LEFT, TOP);
    }
    close = new Button("X", infoX+infoWidth-60-5, infoY+5, 60, 60, color(255,200,200));
    close.drawSelf();
  }
  
  public boolean clicked()
  {
    if (!enlarged && mousePressedOver() && mousePressed && !clickAct)
    {  //ensures mutex
      clickAct = true;
      return true;
    }
    else
      return false;
  }
  
  public void heldDrag()
  {  //needed for ordering importance of items (was activity3; no longer used)
    if (clicked()) held = true;
    if (held == true)
    {
      if ((mouseX > 0 && mouseX < windWidth && mouseY > txtLine && mouseY < windHeight)
      && ((this.container == 1 && mouseX < windWidth/2) || (this.container == 2 && mouseX > windWidth/2)))
      {
        x = mouseX-(smallImg.width/2);
        y = mouseY-(smallImg.height/2);
      }
      if (!clickAct) held = false;
    }
  }
  
  public boolean detectCollision()      // used to display scanned objects randomly on screen without overlapping
  {
    int myX = this.x + this.smallImg.width/8;      // add small allowance: objects allowed to overlap by 1/8 at any edge
    int myY = this.y + this.smallImg.height/8;
    int myWid = this.smallImg.width - this.smallImg.width/8;
    int myHei = this.smallImg.height - this.smallImg.height/8;
    //println("New item at " + myX + "," + myY + " with width=" + myWid + " and height=" + myHei);
    for (int i = 0; i < crateItems.length; i++)    // check for collision with all other scanned createItems
    {
      if (crateItems[i].present && crateItems[i].id != this.id)
      {
        //print(" | " + i + " is present");
        int chalX = crateItems[i].x;    //(don't add overlap allowance to these objects)
        int chalY = crateItems[i].y;
        int chalWid = crateItems[i].smallImg.width;
        int chalHei = crateItems[i].smallImg.height;
        //println("Existing item at " + chalX + "," + chalY + " with width=" + chalWid + " and height=" + chalHei);
        if ((chalX + chalWid) >= myX && chalX <= (myX+myWid) &&         //if challenger's right (edge) >= my left AND challenger's left <= my right              
            (chalY + chalHei) >= myY && chalY <= (myY+myHei))           //AND challenger's top >= my bottom AND challenger's bottom <= my top
        {
          //println("This does collide");
          return true;
        }
        //else
          //println("This does NOT collide");
      }
    }
    return false;
  }
  
  public boolean mousePressedOver()
  {
    int tempX = this.x;
    int tempY = this.y;
    if (mPressX >= tempX && mPressX <= tempX+smallImg.width && mPressY >= tempY && mPressY <= tempY+smallImg.height)
      return true;
    else return false;
  }
}
  
public class Button
{
  public String txt;
  public int x, y, wid, hei;
  public color col;
  public PImage butImg;
  
  public Button(String t, int x, int y, int w, int h, color c)
  {
    this.txt = t;
    this.x = x;
    this.y = y;
    this.wid = w;
    this.hei = h;
    this.col = c;
    this.butImg = loadImage("graphics/but1.gif"); //Liz
    butImg.resize(w, h);
  }
  
  public boolean clicked()
  {
    if (mousePressedOver() && mousePressed && !clickAct)
    {  //ensures mutex
      //println("! click");
      clickAct = true;
      return true;
    }
    else return false;
  }
  
  public boolean mousePressedOver()
  {
    if (mPressX >= x && mPressX <= x+wid && mPressY >= y && mPressY <= y+hei)
      return true;
    else return false;
  }
  
  public boolean mouseHoverOver()
  {
    if (mouseX >= x && mouseX <= x+wid && mouseY >= y && mouseY <= y+hei)
      return true;
    else return false;
  }

  public void drawSelf()
  {
    noStroke();
    fill(col);
    //rect(x, y, wid, hei);
    image(butImg, x, y);                     //Liz
    
    if (mouseHoverOver()) fill(224, 164, 14);  //colour when mouse is hovering over
    else fill(255, 255, 255);                  //colour when mouse is not^
    addText(txt, x+(wid/2)-2, y+(hei/2)-2, hei/2, CENTER, CENTER); //text is half height of button
    
    fill(255, 255, 255);                 //reset colour back to white
    stroke(67, 49, 167);
  }
  
  public void changeTxt(String t)
  {
    this.txt = t;
  }
}

Item[] crateItems = new Item[numItems]; //all the items that the participant could scan
Button rBut;                            //right button, used for 'Done' or 'Next'
Button lBut;                            // left button, used for 'Back'

Serial bagPort;                         // input from Bag scanner
Serial boxPort;                         // input from Box scanner
Serial printPort;                       // output to printer
ItemTag latestScan = new ItemTag();
String tagID = "";

void setup()
{
  //fullScreen();           // comment out to make the screen windowed
  //size(1300, 700);        // OR comment out to make full screen
  size(1300, 480);        // for 10" touchscreen (on Pi)
  windWidth = width;
  windHeight = height;

  if (windHeight < 700)
  {
    txtLine = 50;         //the y co-ordinate of the line below the text at the top of the screen
    labTxtSz = 40;        //size of container labels (e.g. 'BOX')
    nameTxtSz = 30;       //size of item names (e.g. 'Button') when clicked on/scanned
    descripTxtSz = 20;    //size of item descriptions when clicked on/scanned
    botTxtSz = 15;        //size of text that appears at bottom of screen
    topTxtSz = 25;        //size of text that appears at top of screen
    stgeTxtSz = 15;       //size of text that shows stage (e.g. 'Stage 1/3')
  }
  else if (windHeight < 1000)
  {
    txtLine = 70;         //the y co-ordinate of the line below the text at the top of the screen
    labTxtSz = 60;        //size of container labels (e.g. 'BOX')
    nameTxtSz = 40;       //size of item names (e.g. 'Button') when clicked on/scanned
    descripTxtSz = 25;    //size of item descriptions when clicked on/scanned
    botTxtSz = 20;        //size of text that appears at bottom of screen
    topTxtSz = 30;        //size of text that appears at top of screen
    stgeTxtSz = 20;       //size of text that shows stage (e.g. 'Stage 1/3')
  }
  else
  {
    txtLine = 80;         //the y co-ordinate of the line below the text at the top of the screen
    labTxtSz = 80;        //size of container labels (e.g. 'BOX')
    nameTxtSz = 50;       //size of item names (e.g. 'Button') when clicked on/scanned
    descripTxtSz = 30;    //size of item descriptions when clicked on/scanned
    botTxtSz = 20;        //size of text that appears at bottom of screen
    topTxtSz = 30;        //size of text that appears at top of screen
    stgeTxtSz = 20;       //size of text that shows stage (e.g. 'Stage 1/3')
  }
  
  infoWidth = (windWidth/2) - (descripEdge*2);
  infoHeight = windHeight - (descripEdge*2) - txtLine;
  
  dButX = windWidth-dbutWidth-10;
  dButY = windHeight-dbutHeight-10;
  
  //preload all the images, so they're ready for use when needed
  gradient = loadImage("graphics/gradient.png");
  gradient.resize(windWidth-(strokeWeight*2), windHeight-txtLine-strokeWeight);
  floodBox = loadImage("graphics/floodBox.gif");
  //emergBag = loadImage("graphics/emergBag.png");
  welcome = loadImage("background graphics/welcome.jpg");
  welcome.resize(windWidth, windHeight);
  boots = loadImage("background graphics/boots.jpg");
  boots.resize(windWidth, windHeight);
  sandbags = loadImage("background graphics/sandbags.jpg");
  sandbags.resize(windWidth, windHeight);
  thumbsupwithoutrescue = loadImage("background graphics/thumbsupwithoutrescue.jpg");
  thumbsupwithoutrescue.resize(windWidth, windHeight);
  
  rBut = new Button("Done", dButX, dButY, dbutWidth, dbutHeight, dBut);
  lBut = new Button("Back", 10, dButY, dbutWidth, dbutHeight, dBut);
    
  //create NFC tags (in order of image size, so that colliding small items are shown on top) 
  crateItems[0] = new Item("18323229", "Insurance");
  crateItems[1] = new Item("18130013", "Emergency Information");
  crateItems[2] = new Item("17834525", "Baby Food");
  crateItems[3] = new Item("18286413", "Nappy Bags");
  crateItems[4] = new Item("18403213", "Waterproof & Clothes");
  crateItems[5] = new Item("17804269", "Batteries");
  crateItems[6] = new Item("18760461", "Nappies");
  crateItems[7] = new Item("18032317", "First Aid Kit");
  crateItems[8] = new Item("18597805", "Boots & Footwear");
  crateItems[9] = new Item("17995821", "Non-perishable Foods");
  crateItems[10] = new Item("18292445", "Radio");
  crateItems[11] = new Item("18478365", "Torch");
  crateItems[12] = new Item("17849405", "Toy or Comforter");
  crateItems[13] = new Item("17824605", "Gloves");
  crateItems[14] = new Item("18349901", "Money & bank cards");
  crateItems[15] = new Item("18585933", "Baby bottle or spoon");
  crateItems[16] = new Item("18421933", "Blanket or Duvet");
  crateItems[17] = new Item("17962525", "Water");
  crateItems[18] = new Item("18454525", "Wash Kit");
  crateItems[19] = new Item("18419453", "Playing Cards & Games");
  crateItems[20] = new Item("18724189", "Mobile & Charger");
  crateItems[21] = new Item("18482685", "Camera");
  crateItems[22] = new Item("18549581", "Medication");
  
  //surface.setSize(windWidth, windHeight);
  font = createFont("Roboto Slab", 20);
  textFont(font); //activates the font
  resetDefaults();
  
  // set up I/O ports by commenting out the lines you don't want
  //boxPort = new Serial(this, "/dev/ttyACM0", 9600);                    // this line is for use on Pi
  boxPort = new Serial(this, "COM5", 9600);                            // this line is for use on Windows
  //boxPort = new Serial(this, "/dev/tty.usbmodem1A12421", 9600);        // these lines are for use on Mac
  //boxPort = new Serial(this, "/dev/tty.usbmodem14231", 9600);
  boxPort.buffer(10);
  boxPort.clear();
  
  //bagPort = new Serial(this, "/dev/ttyACM1", 9600);                    // Pi
  bagPort = new Serial(this, "COM4", 9600);                            // Windows
  //bagPort = new Serial(this, "/dev/tty.usbmodem1A1221", 9600);         // Mac
  //bagPort = new Serial(this, "/dev/tty.usbmodem14211", 9600);
  bagPort.buffer(10);
  bagPort.clear();
  
  //printPort = new Serial(this, "/dev/ttyUSB0", 19200);                 // Pi
  printPort = new Serial(this, "COM6", 19200);                         // Windows
  //printPort = new Serial(this, "/dev/tty.usbserial-A501DGRD", 19200);  // Mac
  
}

void initialiseData()
{
  //println("initialiseData");
  PPname = "";                  // clear the participant's name
  boxPort.clear();              // reset the serial input ports
  bagPort.clear();
  // clear the items entered by the participant
  a1Item = a1Items.length;
  while (a1Item > 0)
  {
    a1Item--;
    a1Items[a1Item] = "";
    a1Items = shorten(a1Items);
  }
  inStr = "";
  itemsPresent = 0;              // no items scanned (for testing, set to crateItems.length)
  slideNum = 1;
  // clear the items from the Flood Box, the Flood Bag, and the Report (first two are used by the report)
  clearReport();
  // mark all crate items as not scanned and not in the Box/Bag
  for (int i = 0; i < crateItems.length; i++)
  {
    crateItems[i].present = false;    // item not scanned (for testing, set to true)
    crateItems[i].container = 0;      // item not in a container (for testing, set to 1)
  }
}

void startScreen()
{
  //if (mousePressed) clickAct = true;  //prevents buttons on next screen activating
  initialiseData();                     // clear data for restart for next user
  state = State.NAMEENTRY;
}

int count = 0;
void nameEntry()
{
  int lineX = 100;
  int lineY;
  int lineHeight, lineGap;
  if (windHeight < 700)
  {
    lineHeight = 35;
    lineGap = 25;
    lineY = 100;
  }
  else if (windHeight < 1000)
  {
    lineHeight = 40;
    lineGap = 35;
    lineY = 180;
  }
  else
  {
    lineHeight = 80;
    lineGap = 60;
    lineY = 270;
  }
  if (showBackgroundImages)
  {
    // display the flood picture and welcome text, with name prompt in black
    image(welcome, 0, 0);
    fill(0, 0, 0);
  }
  else
  {
    // display a plain background, with welcome text and name prompt in white
    fill(255, 255, 255);
    addText("Welcome", windWidth/2, 100, 90, CENTER, CENTER);
  }
  
  addText("What's your name?", lineX, lineY, lineHeight, LEFT, CENTER);
  lineY += (lineHeight + lineGap); 
  rBut.drawSelf();
  fill(255, 0, 0);  //fill(224, 164, 14);
  addText(PPname, lineX, lineY, lineHeight, LEFT, BOTTOM);
  line(lineX, lineY, windWidth-lineX, lineY);
  
  if (alternator(500)) line(lineX+textWidth(PPname)+inputLineBuff, lineY-lineHeight, lineX+textWidth(PPname)+inputLineBuff, lineY);

  if (textWidth(inStr) <= 700) PPname = inStr;
  else 
  {
    inStr = PPname;
    //println("too long");
  }
  
  //if (rBut.clicked() || keyCode == ENTER)  // this line can be used (instead of the one below) so that Enter 
                                             // can be used after typing name, rather than having to click Done.
                                             // However, sometimes it thinks that ENTER is pressed when it isn't
  if (rBut.clicked())
  {
    if (a1Items.length > 0) inStr = a1Items[a1Item];
    else inStr = "";
    state = State.ACTIVITY1;
  }
}

boolean tutorial = false;  // true if you want to display additional prompts re ENTER/BACKSPACE
void activity1()
{
  int lineX = 100;
  int ogLineX = lineX;  //because lineX is variable
  int lineY;
  int ogLineY;
  int lineWid = 350;
  int space;

  if (showBackgroundImages)
  {
    image(boots, 0, 0);
    fill(0, 0, 0);
  }
  if (windHeight < 700)
  {
    lineY = txtLine+75+botTxtSz+20;
    space = 40;
  }
  else if (windHeight < 1000)
  {
    lineY = 210;
    space = 60;
  }
  else
  {
    lineY = 250;
    space = 80;
  }
  ogLineY = lineY;
  addText("What items do YOU think would be useful to have in a flood" + (!PPname.equals("")? (", " + PPname):"") + "?", txtEdge, txtLine/2, topTxtSz, LEFT, CENTER);
  addText("Stage 1/3 ", windWidth-txtEdge, txtLine/2, stgeTxtSz, RIGHT, CENTER);
  line(0, txtLine, windWidth, txtLine);
  addText("List at least 5 below", windWidth/2, txtLine+20, topTxtSz, CENTER, TOP);
  addText("Press 'ENTER' to add the next item.  Press 'BACKSPACE' to edit the previous item.", windWidth/2, txtLine+25+topTxtSz, botTxtSz, CENTER, TOP);
  rBut.drawSelf();
  lBut.drawSelf();
  fill (255, 0, 0);

  if (keyCode == ENTER && a1Items.length < 15 && !inStr.equals(""))  // needs to be first to avoid Exception w/ input-line-draw | ensures less than 15 items
  {
    //ensure can only move on once something filled
    inStr = "";
    a1Item++;
  }
  
  //println("kC " + keyCode + " | item: " + a1Item + " | eB: " + backAct);
  //println("a1Item: " + a1Item + " | arrayLen: " + a1Items.length);
  if (keyCode == BACKSPACE && a1Item > 0 && backAct)  // needs to be first to avoid Exception w/ input-line-draw | ensures less than 15 items
  {
    //print("backAct");
    a1Item--;
    inStr = a1Items[a1Item];
    backAct = false; //dealt with
  }
  
  if (a1Item >= a1Items.length) a1Items = append(a1Items, "");      //should never be greater than, only ever equal to
  else if (a1Item < a1Items.length-1) a1Items = shorten(a1Items);  //shortens if item is MORE than 1 below length (i.e. -2 or worse)
  
  if (tutorial && a1Items.length == 1 && !a1Items[a1Item].equals(""))
    addText("Press 'ENTER' to add the next item", (windWidth/2 - lineWid/2), lineY, 30, LEFT, BOTTOM);
  if (tutorial && a1Items.length == 2)
    addText("Press 'BACKSPACE' to edit the previous item", (windWidth/2 - lineWid/2), lineY+space, 30, LEFT, BOTTOM);
  if (a1Items.length >= 3) tutorial = false;  //removes tutorial pointers once user has entered 3 items
  if (a1Items.length == 5 && !a1Items[a1Item].equals(""))
  {
    addText("Can you think of any more?", (windWidth/2 - lineWid/2), lineY+(4*space)-40, 30, LEFT, BOTTOM);
    addText("Press 'ENTER' to continue adding", (windWidth/2 - lineWid/2), (lineY+(4*space)), 30, LEFT, BOTTOM);
  }
  for (int i = 0; i < 5; i++) line(lineX, lineY+(i*space), lineX+lineWid, lineY+(i*space)); //sets up default 5 lines
  for (int i = 0; i < a1Items.length; i++)
  {
    if (i >= 5)
    {
      //print(i + ": ");
      if (i >= 10)
      {
        lineY = ogLineY - (10*space);
        lineX = windWidth-lineWid-ogLineX;
      }
      else
      {
        lineY = ogLineY - (5*space);
        lineX = windWidth/2 - lineWid/2;
      }
      line(lineX, lineY+(i*space), lineX+lineWid, lineY+(i*space));
    }
    addText(a1Items[i], lineX, lineY+(i*space), 35, LEFT, BOTTOM);  //change to BASELINE?
  }
  if (alternator(500))
    line(lineX+textWidth(a1Items[a1Item])+inputLineBuff, lineY-50+(a1Item*space), lineX+textWidth(a1Items[a1Item])+inputLineBuff, lineY+(a1Item*space));
  
  if (textWidth(inStr) <= lineWid) 
    a1Items[a1Item] = inStr;
  else
  {
    inStr = a1Items[a1Item];
    //println("too long");
  }
  
  if (lBut.clicked())
  {
    inStr = PPname;
    state = State.NAMEENTRY;
  }
  if (a1Items.length >= 0 && rBut.clicked()) //!!!SHOULD BE 5 (0 for debug)
  {
    rBut.changeTxt("Next");
    state = State.TRANSIT1TO2;
  }
}

void transit1to2()
{
  if (showBackgroundImages)
  {
    image(sandbags, 0, 0);
    fill(0, 0, 0);
  }
  int yPos, fontSize;
  if (windHeight < 700)
  {
    yPos = 20;
    fontSize = 40;
  }
  else if (windHeight < 1000)
  {
    yPos = 50;
    fontSize = 50;
  }
  else
  {
    yPos = 100;
    fontSize = 60;
  }
  addText("Great work" + (!PPname.equals("")? (" " + PPname):"") + "!", windWidth/2, yPos, fontSize, CENTER, CENTER);
  yPos += fontSize+10;
  fontSize -=10;
  addText("The crate beside you holds things we think", windWidth/2, yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("are useful when there's a flood", windWidth/2, yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("(you may have already thought of some of them)", windWidth/2, yPos, fontSize, CENTER, CENTER);
  yPos += fontSize+5;
  addText("To prepare for a flood, these items", windWidth/2, yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("can be stored in a Flood Box", windWidth/2, yPos, fontSize, CENTER, CENTER);
  yPos += fontSize+10;
  fontSize -=10;
  image(floodBox, windWidth-250, yPos);
  fill(255,0,0);  //fill(224, 164, 14);
  addText("A Flood Box is used to store things you may", windWidth/2, yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("need during a flood, either in your home", windWidth/2, yPos, fontSize, CENTER, CENTER); 
  yPos += fontSize;
  addText("(if there is a power cut, for example),", windWidth/2, yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("or if you have to move out to temporary", windWidth/2, yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("accommodation or an evacuation centre", windWidth/2, yPos, fontSize, CENTER, CENTER);
  rBut.drawSelf();
  lBut.drawSelf();
  if (lBut.clicked())
  {
    a1Item = a1Items.length - 1;
    if (a1Item >= 0)
      inStr = a1Items[a1Item];
    else
    {
      inStr = "";
      a1Item = 0;
    }
    state = State.ACTIVITY1;
  }
  if (rBut.clicked())
  {
    inStr = "";
    latestScan = new ItemTag();        //resets tagID before activity2
    boxPort.clear();
    bagPort.clear();
    rBut.changeTxt("DONE");
    state = State.ACTIVITY2;
  }
}
 
void activity2()
{
  addText("Scan the items you think you will need into the Flood Box", txtEdge, txtLine/2, topTxtSz, LEFT, CENTER);
  addText("Stage 2/3 ", windWidth-txtEdge, txtLine/2, stgeTxtSz, RIGHT, CENTER);
  line(0, txtLine, windWidth, txtLine);
  fill(80, 30, 120);  //fill (224, 164, 14); //yellow text
  addText("Box", 5, txtLine+5, labTxtSz, LEFT, TOP);
  line(windWidth/2, txtLine, windWidth/2, windHeight);
  //fill (224, 164, 14); //yellow text
  addText("Discard ", windWidth-5, txtLine+5, labTxtSz, RIGHT, TOP);
  rBut.drawSelf();
  lBut.drawSelf();

  for (int i = 0; i < crateItems.length; i++)
  {
    if (crateItems[i].id.equals(latestScan.id) && (!crateItems[i].present || crateItems[i].container != latestScan.container))
    {  //checks key against item IDs, then their presence OR scan into diff container
      //println("making present");
      crateItems[i].scanned(latestScan.container);                  //parameter = container, atm randomly 1 or 2 (box or bag)
      itemsPresent++;
      for (int j = 0; j < crateItems.length; j++)
      {
        if (j != i) crateItems[j].enlarged = false;                 //resets the enlargement of all but the clicked one
      }
      crateItems[i].enlarge();
      break;
    }
  }   
  
  for (int i = 0; i < crateItems.length; i++)
  {
    if (crateItems[i].present == true)
    {
      if (crateItems[i].clicked())
      {
        for (int j = 0; j < crateItems.length; j++)
        {
          if (j != i) crateItems[j].enlarged = false; //resets the enlargement of all but the clicked one
        }
        crateItems[i].enlarge();
      }
      else if (crateItems[i].enlarged && crateItems[i].close.clicked())
      {
        crateItems[i].unenlarge();
      }
      crateItems[i].drawImg();
    }
  }
  for (int i = 0; i < crateItems.length; i++)
    if (crateItems[i].enlarged) crateItems[i].enlarge();  //done after for drawing layer purposes
  
  if (lBut.clicked())
  {
    for (int i = 0; i < crateItems.length; i++) 
      crateItems[i].enlarged = false; //resets the enlargement of all
    a1Item = a1Items.length - 1;
    if (a1Item >= 0)
      inStr = a1Items[a1Item];
    else
    {
      inStr = "";
      a1Item = 0;
    }
    state = State.ACTIVITY1;
  }  
  if (rBut.clicked() && itemsPresent > 0)
  {
    for (int i = 0; i < crateItems.length; i++) 
      crateItems[i].enlarged = false; //resets the enlargement of all
    inStr = "";

    state = State.REPORT;
  }
}

boolean once = false;        // for debug print

//boolean repSaved = false;  // true once the report has been saved
void report()
{
  if (showBackgroundImages)
  {
    ;//*/image(thumbsup, 0, 0);
    //*/fill(0, 0, 0);
  }
  int startL, titleS, itemS, itemGap;
  if (windHeight < 700)
  {
    startL = txtLine + 5;
    titleS = 20;
    itemS = 15;
    itemGap = 5;
  }
  else if (windHeight < 1000)
  {
    startL = txtLine + 15;
    titleS = 40;
    itemS = 25;
    itemGap = 10;
  }
  else
  {
    startL = txtLine + 20;
    titleS = 50;
    itemS = 35;
    itemGap = 15;
  } 

  int rTxtLine = txtLine+5;
  addText(((!PPname.equals("")?(PPname + "'s"):"My") + " Flood Preparation Checklist"), txtEdge, rTxtLine/2, titleS+10, LEFT, CENTER);
  line(0, rTxtLine, windWidth, rTxtLine);
  rBut.drawSelf();
  lBut.drawSelf();
  fill(80, 30, 120);
  
  if (a1Item >= 0 && a1Items[a1Item].equals(""))
  {
    a1Item--;
    a1Items = shorten(a1Items);  //removes the empty field - this empty will return if user goes back
  }
  if (report.length == 0)
    makeReport();
  
  addText("Items that I felt were important", txtEdge, startL, titleS, LEFT, TOP);
  startL += titleS+5;
  if (once) println(startL);
  
  int itemNum = 0;
  if (once) println("len: " + a1Items.length + " | len/3: " + float(a1Items.length)/3);
  for (int i = 0; i < ceil(float(a1Items.length)/3); i++)
  {
    for (int j = 0; j < 3; j++)
    {
      //println("i: " + i + "j: " + j + "num: " + itemNum + "len: " + a1Items.length);
      if (itemNum < a1Items.length)
      {        
        addText(str(itemNum+1) + ": " + a1Items[itemNum], txtEdge+(j*(windWidth/3)), startL+(i*(itemS+itemGap)), itemS, LEFT, TOP);  
        itemNum++;
      }
    }
  }
  startL += ((itemS+itemGap) * (ceil(float(a1Items.length)/3))) + 5; 

  if (boxItems.length > 0)
  {
    addText("My flood box items", txtEdge, startL, titleS, LEFT, TOP);
    startL += titleS+5;
    
    itemNum = 0;
    if (once) println("len: " + boxItems.length + " | len/3: " + float(boxItems.length)/3);
    for (int i = 0; i < ceil(float(boxItems.length)/3); i++)
    {
      for (int j = 0; j < 3; j++)
      {
        //println("i: " + i + "j: " + j + "num: " + itemNum + "len: " + a1Items.length);
        if (itemNum < boxItems.length)
        {        
          addText(str(itemNum+1) + ": " + boxItems[itemNum], txtEdge+(j*(windWidth/3)), startL+(i*(itemS+itemGap)), itemS, LEFT, TOP);  
          itemNum++;
        }
      }
    }
    startL += ((itemS+itemGap) * (ceil(float(boxItems.length)/3))) + 5;
  }
  
  if (bagItems.length > 0)
  {
    addText("My emergency bag items", txtEdge, startL, titleS, LEFT, TOP);  
    startL += titleS+5;
    
    itemNum = 0;
    if (once) println("len: " + bagItems.length + " | len/3: " + float(bagItems.length)/3);
    for (int i = 0; i < ceil(float(bagItems.length)/3); i++)
    {
      for (int j = 0; j < 3; j++)
      {
        //println("i: " + i + "j: " + j + "num: " + itemNum + "len: " + a1Items.length);
        if (itemNum < bagItems.length)
        {        
          addText(str(itemNum+1) + ": " + bagItems[itemNum], txtEdge+(j*(windWidth/3)), startL+(i*(itemS+itemGap)), itemS, LEFT, TOP);  
          itemNum++;
        }
      }
    }
  }
  once = false;

  if (lBut.clicked())
  {
    clearReport();      // clear the report data in case the user changes the scanned items
    state = State.ACTIVITY2;
  }
  if (rBut.clicked())
  {
    //if (!repSaved)
    {
      //println("SaveClick");
      int fNum = 1;
      println(sketchPath("reports/report" + str(fNum) + ".txt"));
      File f = new File(sketchPath("reports/report" + str(fNum) + ".txt"));
      println(f.getName() + " : " + f.exists());
      while (f.exists())
      {
        //println(fNum + " exists");
        fNum++;
        f = new File(sketchPath("reports/report" + str(fNum) + ".txt"));
      }
      println("saving as " + fNum);
      saveStrings(sketchPath("reports/report" + str(fNum) + ".txt"), report);
      //repSaved = true;
      printTxt(report);
      //rBut.changeTxt("Restart");
    }
    //else
    {
      //println("RestartClick");
      //rBut.changeTxt("Done");
      state = State.FINISHED;
      //repSaved = false;
    }
  }
}

void finished()
{
  if (showBackgroundImages)
  {
    image(thumbsupwithoutrescue, 0, 0);
  }
  fill(80, 30, 120);
  int yPos, fontSize;
  if (windHeight < 700)
  {
    yPos = 50;
    fontSize = 50;
  }
  else if (windHeight < 1000)
  {
    yPos = 80;
    fontSize = 60;
  }
  else
  {
    yPos = 100;
    fontSize = 80;
  }
  // if background images are displayed the text needs to be further right so it's not hidden within image
  addText("Thank you for participating" + (!PPname.equals("")?(" " + PPname):"") + "!", (showBackgroundImages?windWidth/2+150:windWidth/2), yPos, fontSize, CENTER, CENTER);
  yPos += fontSize+10;
  fontSize -= 10;
  addText("We hope you gained some", (showBackgroundImages?windWidth/2+150:windWidth/2), yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("valuable insights as to the", (showBackgroundImages?windWidth/2+150:windWidth/2), yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("items you might need to", (showBackgroundImages?windWidth/2+150:windWidth/2), yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("prepare for a flood event", (showBackgroundImages?windWidth/2+150:windWidth/2), yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("We've printed a report", (showBackgroundImages?windWidth/2+150:windWidth/2), yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("for you to take home", (showBackgroundImages?windWidth/2+150:windWidth/2), yPos, fontSize, CENTER, CENTER);
  yPos += fontSize;
  addText("and use as a checklist", (showBackgroundImages?windWidth/2+150:windWidth/2), yPos, fontSize, CENTER, CENTER);
  rBut.drawSelf();
  rBut.changeTxt("Restart");
  if (rBut.clicked())
  {
    rBut.changeTxt("Done");
    state = State.STARTSCREEN;
  }
} 

void draw()
{
  resetDefaults();
  switch (state)
  {
    case STARTSCREEN:
      startScreen();
      break;      
    case NAMEENTRY:
      nameEntry();      
      break;
    case ACTIVITY1:
      activity1();
      break;
    case TRANSIT1TO2:
      transit1to2();
      break;
    case ACTIVITY2:
      activity2();
      break;
   case REPORT:
      report();
      break;
    case FINISHED:
      finished();
      break;
  }
}

// create the text for the printable reports
void makeReport()
{
  // Title the report, and include the participant's name
  report = append(report, "\n\n" + (PPname.equals("")?"My":(PPname+"'s")) + " Flood Preparation Checklist\n");
  report = append(report, "\n");  //new line; need as separate append so that saving as .txt factors new line too
  
  // list all the participant's typed items in the report
  report = append(report, "Items I thought were important\n");
  for (int i = 0; i < a1Items.length; i++)
  {
    if (!a1Items[i].equals(""))
      report = append(report, (str(i+1) + ": " + a1Items[i] + "\n"));
  }
  
  //sort the scanned items from the crate into box/bag arrays
  for (int i = 0; i < crateItems.length; i++)
  {
    if (crateItems[i].present && crateItems[i].container == 1)
    {
      //println("boxAdd: " + crateItems[i].name);
      boxItems = append(boxItems, crateItems[i].name);
    }
    // we are no longer using an Emergency Bag, so don't do this step
    // (Note: the Bag scanner is now used to discard from the Box)
    //if (crateItems[i].present && crateItems[i].container == 2)
    //{
    //  //println("bagAdd: " + crateItems[i].name);
    //  bagItems = append(bagItems, crateItems[i].name);
    //}
  }
  // now the scanned items are in the box/bag arrays, it is easier to generate the report
  
  // list all the scanned flood box items in the report
  if (boxItems.length > 0)
  {
    //boxItems = sortItems(boxItems);
    report = append(report, "\n");  //new line; need as separate append so that saving as .txt factors new line too
    report = append(report, "Flood Box Items\n");
    for (int i = 0; i < boxItems.length; i++)
      report = append(report, (i+1 + ": " + boxItems[i] + "\n"));
  }
  
  // list all the scanned emergency bag items in the report
  //if (bagItems.length > 0){
  //  bagItems = sortItems(bagItems);
  //  report = append(report, "\n");  //new line
  //  report = append(report, "Emergency Bag Items\n");
  //  for (int i = 0; i < bagItems.length; i++)
  //    report = append(report, (i+1 + ": " + bagItems[i] + "\n"));
  //}
  
  // finish the report with a reference for more info
  report = append(report, "\nFor more information visit https://nationalfloodforum.org.uk ");
  report = append(report, "\n________________________________");
  report = append(report, "\n\n\n\n\n\n\n\n________________________________\n"); //designed to cause the receipt to print longer, easier to cut
  //println(report.length);
}

// This method clears the prepared report data
// Used when restarting for a new user, and also when going Back to change scanned items
void clearReport()
{
  //if (report.length > 0)
  {
    // clear the items from the Flood Box
    int i = boxItems.length;
    while (i > 0)
    {
      i--;
      boxItems[i] = "";
      boxItems = shorten(boxItems);
    }
    // clear the items from the Bag (currently being used as Discard)
    i = bagItems.length;
    while (i > 0)
    {
      i--;
      bagItems[i] = "";
      bagItems = shorten(bagItems);
    }
    // clear the generated report
    i = report.length;
    while (i > 0)
    {
      i--;
      report[i] = "";
      report = shorten(report);
    }
  }
}

String[] sortItems(String[] items)
{
  StringList temp = new StringList();
  String[] sorted = {};
  FloatDict itemPriorities = new FloatDict();
  for (int i = 0; i < crateItems.length; i++)
  {
    if (crateItems[i].present)
      itemPriorities.set(crateItems[i].name, crateItems[i].y);
  }
  for (int i = 0; i < items.length; i++)
    temp.append(items[i]);
  while (temp.size() > 0)
  {
    //println(temp.size());
    int max = 0;
    for (int i = 0; i < temp.size(); i++)
    {
      if (itemPriorities.get(items[i]) < itemPriorities.get(items[max])) max = i;  //< because Y increases downwards
    }
    sorted = append(sorted, temp.get(max));
    temp.remove(max);
  }
  return sorted;
}

// xAlign can be LEFT, CENTER, RIGHT
// yAlign can be TOP, CENTER, BOTTOM, BASELINE
void addText(String txt, int x, int y, int size, int xAlign, int yAlign)
{
  textAlign(xAlign, yAlign);
  textSize(size);
  text(txt, x, y);
}  

void resetDefaults()
{
  stroke(0);

  background(169, 190, 217);  //34, 22, 122);
  fill(169, 190, 217);  //34, 22, 122);
  noStroke();
  rect(strokeWeight, strokeWeight, windWidth-(strokeWeight*2), windHeight-(strokeWeight*2));
  stroke(67, 49, 167);
  strokeWeight(strokeWeight);
  fill(255, 255, 255);
}

void serialEvent(Serial port)
{  //make class that extends port to include id
  latestScan.id = trim(port.readString());
  //println("tag: " + tagID + " | prvs: " + prvsTagID);
  if (port == boxPort) latestScan.container = 1;
  //if (port == bagPort) latestScan.container = 2;
  else latestScan.container = 2;
  port.clear();
  //println(latestScan.container);
}

void printTxt(String[] txt)
{
  for (int line = 0; line < txt.length; line++)
    printPort.write(txt[line]);
}
  
//following variables used exclusively in alternator() method, but need to be global
boolean alternator = true;
int startTime = 0;
int timer = 0;
boolean alternator(int time)
{  //timer, startTime, & alternator all global variables
  timer = millis() - startTime;
  if (timer > time)
  {
    alternator = !alternator;
    startTime = millis();
  }
  return alternator;
}

void keyPressed()
{
  //print(keyCode + " ");
  backAct = false;            //assumes key is not a BACKSPACE with a blank inStr
  if (keyCode == BACKSPACE)
  {
    if (inStr.length() > 0) inStr = inStr.substring(0, inStr.length() - 1);
    else backAct = true;      //corrects if key IS BACKSPACE with a blank inStr
  }
  else if ((keyCode >= ' ' && keyCode < 127) || keyCode == 222)
  {
    //should allow all numbers and letters, space, dash, comma, apostrophe
    inStr = inStr + key;
  }
  //print(inStr);
}

void mousePressed()
{
  mPressX = mouseX;
  mPressY = mouseY;
}

void mouseReleased()
{
  clickAct = false;  //resets
}