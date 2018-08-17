import java.util.Map;
import processing.serial.*;

boolean showBackgroundImages = true;  // set false if you want a plain background rather than background images

int numItems = 23;         // number of items included in crate that can be scanned

int windowWidth;           // assigned in setup()
int windowHeight;
int xMid;                  // x co-ordinate of middle of window
int yLine;                 // y co-ordinate for Line across screen
int xTitleLine;            // x co-ordinate of start of Title drawn above Line across screen (for list headers)
int yTitleLine;            // y co-ordinate of start of TitleLine
int fontTitleLine;         // font size for TitleLine
int ySubTitleLine;         // y co-ordinate for start of subTitle below line drawn across screen
int fontSubTitleLine;      // font size for SubTitleLine
int ySmallItemGap;         // small vertical gap between spaced items
int yLargeItemGap;         // large vertical gap between spaced items
int yHeaderLine;           // y co-ordinate for screens with large centred headings
int fontHeaderLine;        // font size for centred headings
int xSandbags;             // x co-ordinate for start of left-justified text on screen with sandbags image
int xThumbsUpWR;           // x co-ordinate for start of left-justified text on screen with thumbsupwithoutrescue image
int xActivity1;            // x co-ordinate for start of user input in Activity1
int lineWidthActivity1;    // width of user input line for Activity1
int fontLineActivity1;     // font size for user input for Activity1
int xPromptActivity1;      // x co-ordinate for extra prompts for Activity1
int fontScanBox;           // font size for Box/Discard(Bag) titles on scanning screen
int fontItemName;          // font size for Name of enlarged scanned item
int fontItemDesc;          // font size for Description of enlarged scanned item

int strokeWeight = 3;      //default stroke weight

int inputLineGap = 5;      //the distance (or buffer) between the flashing vertical line (cursor) and any text that is input
int descripEdge = 10;      //the x and y distance from description label to the edge of the container-area

int infoWidth;             //assigned in setup()
int infoHeight;

int dbutWidth = 120;       //the default button width, height, x, y, and colour    was 120
int dbutHeight = 65;       // was 50
int dButX;                 //assigned in setup()
int dButY;

int keyLineGap;            // gap between each line of the soft keyboard
int keyboardGap;           // gap at each side of the soft keyboard
int keyboardLine;          // start line for soft keyboard

color dBut = color(67, 49, 167); //this is temp - would prefer to use background image

char softKey = ' ';        // used by softKey handler to tell others if Enter/Backspace pressed
boolean clickAct = false;  //ensures only 1 object reacts to a 'click'; true if a object has reacted to a click; resets on click release.
boolean backAct = false;   //true if BACKSPACE pressed but inStr is empty
int enlargedContainer = 0; // remembers which container currently displays an enlarged item (0 if neither), to
                           //  ensure enlarge-clicks are ignored for the other container
int mPressX = 0;           //stores the mouse co-ordinates at the point it was last clicked
int mPressY = 0;

enum State {STARTSCREEN, NAMEENTRY, ACTIVITY1, TRANSIT1TO2, ACTIVITY2, REPORT, FINISHED};

State state = State.STARTSCREEN;  //used for switch statement

PImage floodBox;
PImage welcome;
PImage boots;
PImage sandbags;
PImage thumbsupwithoutrescue;
//PImage emergBag;

PFont font;
String PPname = "";        //name of the participant (PP), taken in nameEntry screen
int maxNameLength = 20;    //maximum length of participant's name
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
  public PImage largeImg;
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
    this.largeImg = loadImage("graphics/" + name + ".png");
    int laFactor = laWid/largeImg.width;
    int laHeight = largeImg.height*laFactor;        // scale image to fit width
    this.largeImg.resize(laWid, laHeight);        // then draw it
    
    this.smallImg = loadImage("graphics/" + name + ".png");
    int smFactor = smWid/smallImg.width; 
    this.smallImg.resize(smWid, smallImg.height*smFactor);
    
    this.descrip = loadStrings("descrips/" + name + "Descrip.txt");
  }
  
  public void unenlarge()
  {
    enlarged = false;
    enlargedContainer = 0;
    inStr = "";
  }
  
  public void scanned(int c)
  {
    present = true;
    this.container = c;
    enlargedContainer = c;                          // remember which container has an enlarged item
    int minX, maxX;
    if (this.container == 1)
    {
      minX = 0;
      maxX = xMid - smallImg.width;
    }
    else 
    {
      minX = xMid;
      maxX = windowWidth - smallImg.width;
    }
    double attempts = 0;      // count number of attempts to find non-colliding location
    do
    {
      attempts++;
      this.x = int(random(minX, maxX));
      this.y = int(random(yLine+fontScanBox+10, (windowHeight-smallImg.height-dbutHeight-10)));  //accounts for dButs as well
                                                    // (don't let bottom of object go below top of buttons)
    } while (detectCollision() && attempts < 500);  // if we haven't found a non-collision in all these attempts, just use this location
    if (attempts == 500) println("placing collided object due to lack of space");
  }
  
  public void drawImg()
  {
    if (enlarged)
    {
      int imgX = 0;                                 // items in Box are drawn on the left hand side
      if (this.container == 2)
        imgX = xMid;                                // items in Bag are drawn on the right hand side
      fill(169, 190, 217, 150);                     // draw rectangle same shade as background but slightly transparent
      rect(imgX, yLine, xMid, windowHeight-yLine);  //  so we can still see other scanned items in this container, but they're fainter
      image(largeImg, imgX, yLine+fontScanBox); //-10);//change vertical position but be aware that moving up too far could overlap text
    }      
    else 
      image(smallImg, x, y);
  }
  
  public void enlarge()
  {
    enlarged = true;
    enlargedContainer = this.container;
    drawImg();
    drawDescrip();
  }
  
  public void drawDescrip()
  {
    int infoX = 0;
    int infoY = yLine+descripEdge;
    if (this.container == 1)
      infoX += xMid;

    fill(169, 190, 217);                            // draw rectangle same shade as background and obscuring items in this container
    rect(infoX, yLine, xMid, windowHeight-yLine);

    fill(80, 30, 120);                              // desciption txt
    infoX += descripEdge;
    addText(this.name, infoX+5, infoY+5, fontItemName, LEFT, TOP);    // display name of enlarged item
    for (int i = 0; i < descrip.length; i++)        // display description of enlarged item
    {
      addText(descrip[i], infoX+5, infoY+fontItemName+10+(i*fontItemDesc), fontItemDesc, LEFT, TOP);
    }
                                                    // display Close button (to unenlarge item)
    close = new Button("Close", infoX+infoWidth-dbutWidth-10, infoY+10, dbutWidth, dbutHeight, dBut);
    close.drawSelf();
  }
  
  public boolean clicked()
  {
    if (!enlarged && mousePressedOver() && mousePressed && !clickAct && (enlargedContainer == 0 || enlargedContainer == this.container))
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
      if ((mouseX > 0 && mouseX < windowWidth && mouseY > yLine && mouseY < windowHeight)
      && ((this.container == 1 && mouseX < xMid) || (this.container == 2 && mouseX > xMid)))
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
    this.butImg = loadImage("graphics/button.png");
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
    image(butImg, x, y);
    
    if (mouseHoverOver()) fill(224, 164, 14);           // colour when mouse is hovering over
    else fill(255, 255, 255);                           // colour when mouse is not^
    //addText(txt, x+(wid/2)-2, y+(hei/2)-2, hei/2, CENTER, CENTER); // text is half height of button
    addText(txt, x+(wid/2)-2, y+(hei*3/7), hei*3/7, CENTER, CENTER);   // text is 3/7 height of button
    
    fill(255, 255, 255);                                // reset colour back to white
    stroke(67, 49, 167);
  }
  
  public void changeTxt(String t)
  {
    this.txt = t;
  }
}

Item[] crateItems = new Item[numItems];                 // all the items that the participant could scan
Button rBut;                                            // right button, used for 'Done' or 'Next'
Button lBut;                                            // left button, used for 'Back'
Button spaceBut[];                                      // soft keyboard space bar
Button keyBut[];                                        // soft keyboard buttons
String softKeyValue[][] = {{"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "+", "Bksp"}, 
                              {"a", "s", "d", "f", "g", "h", "j", "k", "l", "-"}, 
                                 {"z", "x", "c", "v", "b", "n", "m", "'", "Enter"}, 
                                    {" "}
                          };

Serial bagPort;                                         // input from Bag scanner
Serial boxPort;                                         // input from Box scanner
Serial printPort;                                       // output to printer
ItemTag latestScan = new ItemTag();
String tagID = "";

void setup()
{
  //fullScreen();                   // comment out to make the screen windowed
  //size(1300, 700);                // OR comment out to make full screen
  size(1280, 800);                // for 10" touchscreen (on Pi), was (1280,470)
  windowWidth = width;
  windowHeight = height;

  // calculate all the screen start positions and fonts at start-up, to speed execution of main loop (draw) 
  xMid =  windowWidth/2;                                // x co-ordinate of middle of window
  yHeaderLine = windowHeight/8;                         // y co-ordinate for screens with a large header line
  fontHeaderLine = windowWidth/24;                      // font size for header lines
  yLine = windowHeight*9/100;                           // y co-ordinate for Line across screen
  xTitleLine = 20;                                      // x co-ordinate of start of Title drawn above Line across screen (for list headers)
  yTitleLine = yLine/2;                                 // y co-ordinate of start of TitleLine
  fontTitleLine = windowWidth/40;                       // font size for TitleLine
  ySmallItemGap = windowHeight/100;                     // small vertical gap between spaced items
  yLargeItemGap = windowHeight/15;                      // large vertical gap between spaced items
  ySubTitleLine = yLine + ySmallItemGap;                // y co-ordinate for start of SubTitle below line drawn across screen
  fontSubTitleLine = fontTitleLine - 5;                 // font size for SubTitleLine
  xSandbags = windowWidth/4;                            // x co-ordinate for start of left-justified text on screen with sandbags image
  xThumbsUpWR = 2*windowWidth/5;                        // x co-ordinate for start of left-justified text on screen with thumbsupwithoutrescue image
  xActivity1 = xTitleLine+windowWidth/30;               // x co-ordinate for start of user input in Activity1
  lineWidthActivity1 = (windowWidth - 4*xActivity1)/3;  // each input line is a third of screen width ignoring gaps at edges and between columns
  fontLineActivity1 = lineWidthActivity1 / 12;          // use a font size that allows about 20 chars on each input line
  xPromptActivity1 = xMid - lineWidthActivity1/2;       // x co-ordinate for extra prompts for Activity1
  fontScanBox = windowHeight/20;                        // font size for Box/Discard(Bag) titles on scanning screen 
  fontItemName = fontTitleLine;                         // font size for Name of enlarged scanned item
  fontItemDesc = fontItemName - 10;                     // font size for Description of enlarged scanned item
  infoWidth = (windowWidth/2) - (descripEdge*2);        // width of enlarged item description
  infoHeight = windowHeight - (descripEdge*2) - yLine - dbutHeight - 10;  // description fills other half of screen below Title line and above button

  keyLineGap = windowHeight/200;                       // gap between each line of the soft keyboard
  keyboardGap = windowWidth/14;                        // gap at each side of the soft keyboard
  keyboardLine = 9*windowHeight/14;                    // start line for soft keyboard

  
  //preload all the images, so they're ready for use when needed
  floodBox = loadImage("graphics/floodBox.gif");
  //emergBag = loadImage("graphics/emergBag.png");
  welcome = loadImage("background graphics/welcome.jpg");
  welcome.resize(windowWidth, windowHeight);
  boots = loadImage("background graphics/boots.jpg");
  boots.resize(windowWidth, windowHeight);
  sandbags = loadImage("background graphics/sandbags.jpg");
  sandbags.resize(windowWidth, windowHeight);
  thumbsupwithoutrescue = loadImage("background graphics/thumbsupwithoutrescue.jpg");
  thumbsupwithoutrescue.resize(windowWidth, windowHeight);

  dButX = windowWidth-dbutWidth-10;
  dButY = windowHeight-dbutHeight-10;
  rBut = new Button("Next", dButX, dButY, dbutWidth, dbutHeight, dBut);
  lBut = new Button("Back", 10, dButY, dbutWidth, dbutHeight, dBut);
  loadSoftKeyboard();
    
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
  
  //surface.setSize(windowWidth, windowHeight);
  font = createFont("Roboto Slab", 20);
  textFont(font); //activates the font
  resetDefaults();
  
  // set up I/O ports by commenting out the lines you don't want
  //boxPort = new Serial(this, "/dev/ttyACM0", 9600);                    // this line is for use on Pi
  //*/boxPort = new Serial(this, "COM5", 9600);                            // this line is for use on Windows //*/
  //boxPort = new Serial(this, "/dev/tty.usbmodem1A12421", 9600);        // these lines are for use on Mac
  //boxPort = new Serial(this, "/dev/tty.usbmodem14231", 9600);
  //*/boxPort.buffer(10); //*/
  //*/boxPort.clear(); //*/
  
  //bagPort = new Serial(this, "/dev/ttyACM1", 9600);                    // Pi
  //*/bagPort = new Serial(this, "COM4", 9600);                            // Windows //*/
  //bagPort = new Serial(this, "/dev/tty.usbmodem1A1221", 9600);         // Mac
  //bagPort = new Serial(this, "/dev/tty.usbmodem14211", 9600);
  //*/bagPort.buffer(10); //*/
  //*/bagPort.clear(); //*/
  
  //printPort = new Serial(this, "/dev/ttyUSB0", 19200);                 // Pi
  //*/printPort = new Serial(this, "COM6", 19200);                         // Windows //*/
  //printPort = new Serial(this, "/dev/tty.usbserial-A501DGRD", 19200);  // Mac
}

void initialiseData()
{
  PPname = "";                          // clear the participant's name
  //*/boxPort.clear();                  // reset the serial input ports //*/
  //*/bagPort.clear(); //*/
  // clear the items entered by the participant
  a1Item = a1Items.length;
  while (a1Item > 0)
  {
    a1Item--;
    a1Items[a1Item] = "";
    a1Items = shorten(a1Items);
  }
  inStr = "";
  itemsPresent = 0;                     // no items scanned yet
  slideNum = 1;
  // clear the items from the Flood Box, the Flood Bag, and the Report (first two are used by the report)
  clearReport();
  // mark all crate items as not scanned and not in the Box/Bag
  for (int i = 0; i < crateItems.length; i++)
  {
    //crateItems[i].present = false;    // item not scanned (for testing, set to true)
    //crateItems[i].container = 0;      // item not in a container (for testing, set to 1)
    // for test purposes, pretend item has been scanned into Box
    crateItems[i].present = true;       // item scanned
    if (i < 11 || i > 13)                        // torch
    {
      crateItems[i].container = 1;        // item in Box container
      crateItems[i].scanned(1);           // place item randomly on screen
    }
    else
    {
      crateItems[i].container = 2;        // item in Bag container
      crateItems[i].scanned(2);           // place item randomly on screen
    }
    itemsPresent++;                     // count number of items present
  }
  enlargedContainer = 0;
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
  int lineY = yHeaderLine+3*fontTitleLine;

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
    addText("Welcome", xMid, yHeaderLine, fontHeaderLine*2, CENTER, CENTER);
  }
  
  addText("What's your name?", xMid-fontTitleLine, lineY, fontTitleLine, RIGHT, CENTER);
  showSoftKeyboard(false); 
  rBut.drawSelf();
  fill(255, 0, 0);  //fill(224, 164, 14);
  addText(PPname, xMid, lineY, fontTitleLine, LEFT, CENTER);
  //line(xMid, lineY+3*fontTitleLine/4, xMid+10+fontTitleLine*9, lineY+3*fontTitleLine/4);  // draw a line where the user will enter their name
  // draw a vertical line cursor where the input text is to go
  if (alternator(500)) line(xMid+textWidth(PPname)+inputLineGap, lineY-fontTitleLine/4, xMid+textWidth(PPname)+inputLineGap, lineY+3*fontTitleLine/4);

  handleSoftKeyboard(false);                  // show keyboard without Enter key

  if (inStr.length() > maxNameLength)         // truncate name to maximum number of characters
    inStr = inStr.substring(0, maxNameLength);
  PPname = inStr;
  
  if (rBut.clicked() || keyCode == ENTER)     // this line can be used (instead of the one below) so that Enter 
                                              // can be used after typing name, rather than having to click Done.
  //if (rBut.clicked())
  {
    if (a1Items.length > 0) inStr = a1Items[a1Item];
    else inStr = "";
    state = State.ACTIVITY1;
    softKey = ' ';
    keyCode = ' ';                            // Enter has been dealt with, so clear it
  }
}

boolean tutorial = false;  // true if you want to display additional prompts re ENTER/BACKSPACE
void activity1()
{
  // displays 3 columns for user input; each column has 5 rows
  // first column displays all 5 items at the start
  // subsequent items are displayed only as needed (after previous item is entered)
  int lineX = xActivity1;                     // x co-ordinate of first input line
  int lineY = ySubTitleLine;
  int startLineY;                             // y co-ordinate of start of user input

  if (showBackgroundImages)
  {
    image(boots, 0, 0);
    fill(0, 0, 0);
  }

  //addText("What items do YOU think you should have ready in case of a flood" + (!PPname.equals("")? (", " + PPname):"") + "?", xTitleLine, yTitleLine, fontTitleLine, LEFT, CENTER);
  addText("What items do YOU think you should have ready in case of a flood?", xTitleLine, yTitleLine, fontTitleLine, LEFT, CENTER);
  line(0, yLine, windowWidth, yLine);    // draw line across width of screen
  addText("List at least 5 below", xTitleLine, lineY, fontSubTitleLine, LEFT, TOP);
  lineY += fontSubTitleLine + ySmallItemGap;
  addText("Press Enter to add the next item.  Press Backspace to edit the previous item.", xTitleLine, lineY, fontSubTitleLine-5, LEFT, TOP);
  lineY += 2*yLargeItemGap;
  startLineY = lineY;
  
  showSoftKeyboard(true);    // show keyboard with Enter key

  rBut.drawSelf();
  lBut.drawSelf();
  fill(0, 0, 0);            // set colour for prompts

  if (keyCode == ENTER || softKey == ENTER)  // ensures less than 15 items
  {
    //if (keyCode == ENTER) println("Keyboard Enter");
    //if (softKey == ENTER) println("softKey Enter");
    if ((a1Items.length < 15) && (inStr.length() > 0))
    {
      //ensure can only move to next line once something has been entered on this line
      inStr = "";
      a1Item++;
    }
    softKey = ' ';          // Enter has been dealt with, so clear it
    keyCode = ' ';
  }
  
  //println("kC " + keyCode + " | item: " + a1Item + " | eB: " + backAct);
  //println("a1Item: " + a1Item + " | arrayLen: " + a1Items.length);
  if (keyCode == BACKSPACE || softKey == BACKSPACE)
  {
    //if (keyCode == BACKSPACE) println("Keyboard Backspace");
    //if (softKey == BACKSPACE) println("softKey Backspace");
    if ((a1Item > 0) && backAct)
    {
      //print("backAct");
      a1Item--;
      inStr = a1Items[a1Item];
      backAct = false;      //dealt with
    }
    softKey = ' ';          // Backspace has been dealt with, so clear it
    keyCode = ' ';
  }

  if (a1Item >= a1Items.length) a1Items = append(a1Items, "");      //should never be greater than, only ever equal to
  else if (a1Item < a1Items.length-1) a1Items = shorten(a1Items);  //shortens if item is MORE than 1 below length (i.e. -2 or worse)
 
  if (tutorial)
  {
    if (a1Item == 0 && !a1Items[a1Item].equals(""))
      addText("Press Enter to add the next item", xPromptActivity1, lineY, fontSubTitleLine-5, LEFT, BOTTOM);
    //if (a1Item == 1 && a1Items[1].equals(""))
    if (a1Item == 1)
      addText("Press Backspace to edit the previous item", xPromptActivity1, lineY+yLargeItemGap, fontSubTitleLine-5, LEFT, BOTTOM);
  }
  if (a1Items.length >= 3) tutorial = false;  //removes tutorial pointers once user has entered 3 items
  //else tutorial = true;                       //restores tutorial if user reduces number of items
  if (a1Items.length == 5 && !a1Items[a1Item].equals(""))
  {
    // display prompt for more, aligned with (and just above) last item entered
    addText("Can you think of any more?", xPromptActivity1, lineY+(4*yLargeItemGap)-fontSubTitleLine-ySmallItemGap, fontSubTitleLine-5, LEFT, BOTTOM);
    addText("Press Enter to continue adding", xPromptActivity1, lineY+(4*yLargeItemGap), fontSubTitleLine-5, LEFT, BOTTOM);
  }

  fill(255, 0, 0);            // set colour for user input
  for (int i = 0; i < 5; i++)
  {
    //line(lineX, lineY+(i*yLargeItemGap), lineX+lineWidthActivity1, lineY+(i*yLargeItemGap)); //display underline for first 5 items
    addText(str(i+1) + ".", lineX-fontLineActivity1-5, lineY+(i*yLargeItemGap), fontLineActivity1, LEFT, BOTTOM);  // display index number for first 5 items
  }
  for (int i = 0; i < a1Items.length; i++)
  {
    if (i >= 5)
    {
      //print(i + ": ");
      if (i >= 10)
      {
        lineY = startLineY - (10*yLargeItemGap);
        lineX = windowWidth-lineWidthActivity1-xActivity1;
      }
      else
      {
        lineY = startLineY - (5*yLargeItemGap);
        lineX = xMid - lineWidthActivity1/2;
      }
      //line(lineX, lineY+(i*yLargeItemGap), lineX+lineWidthActivity1, lineY+(i*yLargeItemGap));  // display underline for next item
      int numWidth = ((i < 9)? fontLineActivity1+5:5*fontLineActivity1/3);      // adjust position so index number is displayed right-aligned to user input
      addText(str(i+1) + ".", lineX-numWidth, lineY+(i*yLargeItemGap), fontLineActivity1, LEFT, BOTTOM);  // display index number for next item
    }
    addText(a1Items[i], lineX, lineY+(i*yLargeItemGap), fontLineActivity1, LEFT, BOTTOM);
  }
  // display vertical line as cursor for next input area
  if (alternator(500))
    line(lineX+textWidth(a1Items[a1Item])+inputLineGap, lineY+(a1Item*yLargeItemGap)-fontLineActivity1-ySmallItemGap, lineX+textWidth(a1Items[a1Item])+inputLineGap, lineY+(a1Item*yLargeItemGap));

  softKey = handleSoftKeyboard(true);    // display keyboard with Enter key
  
  if (textWidth(inStr) <= lineWidthActivity1) 
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
  if (a1Items.length >= 0 && rBut.clicked()) //compare to 5 if you want to force user to enter 5 items
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

  int yPos = yHeaderLine;
  int fontSize = fontHeaderLine;
  int xPos = xSandbags;

  addText("Great work" + (!PPname.equals("")? (", " + PPname):"") + "!", xPos, yPos, fontSize, LEFT, CENTER);
  fontSize -=20;
  yPos += 2*fontSize;
  image(floodBox, windowWidth-250, yPos);
  addText("The crate beside you holds items that", xPos, yPos, fontSize, LEFT, CENTER);
  yPos += fontSize;
  addText("you might find useful during a flood", xPos, yPos, fontSize, LEFT, CENTER);
  yPos += 2*fontSize;
  fill(80, 30, 120);     //fill(224, 164, 14);
  addText("On the next screen, we'll ask you", xPos, yPos, fontSize, LEFT, CENTER);
  yPos += fontSize;
  addText("to select from these items to", xPos, yPos, fontSize, LEFT, CENTER);
  yPos += fontSize;
  addText("create your personal Flood Box,", xPos, yPos, fontSize, LEFT, CENTER);
  yPos += fontSize;
  addText("containing things you'll need", xPos, yPos, fontSize, LEFT, CENTER);
  yPos += fontSize;
  addText("to survive during a flood", xPos, yPos, fontSize, LEFT, CENTER);
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
    softKey = ' ';
  }
  if (rBut.clicked())
  {
    inStr = "";
    latestScan = new ItemTag();        //resets tagID before activity2
    //*/boxPort.clear(); //*/
    //*/bagPort.clear(); //*/
    state = State.ACTIVITY2;
  }
}
 
void activity2()
{
  if (showBackgroundImages)
  {
    fill(0, 0, 0);
  }
  addText("Scan the items you think you will need, and put them into the Flood Box", xTitleLine, yTitleLine, fontTitleLine, LEFT, CENTER);
  line(0, yLine, windowWidth, yLine);
  fill(80, 30, 120);  //fill (224, 164, 14); //yellow text
  addText("Box", 10, yLine+5, fontScanBox, LEFT, TOP);
  line(xMid, yLine, xMid, windowHeight);
  //fill (224, 164, 14); //yellow text
  addText("Discard ", windowWidth-5, yLine+5, fontScanBox, RIGHT, TOP);
  rBut.changeTxt("Done");
  rBut.drawSelf();
  lBut.drawSelf();

  for (int i = 0; i < crateItems.length; i++)
  {
    if (crateItems[i].id.equals(latestScan.id) && (!crateItems[i].present || crateItems[i].container != latestScan.container))
    {  //checks key against item IDs, then their presence OR scan into diff container
      //println("making present");
      crateItems[i].scanned(latestScan.container);                  //parameter = container
      itemsPresent++;
      for (int j = 0; j < crateItems.length; j++)
      {
        if (j != i) crateItems[j].enlarged = false;                 //resets the enlargement of all but the clicked one
      }
      crateItems[i].enlarge();
      //println("enlarge item " + i);
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
        //println("enlarge item " + i);
      }
      else if (crateItems[i].enlarged && crateItems[i].close.clicked())
      {
        crateItems[i].unenlarge();
        //println("unenlarge item " + i);
      }
      crateItems[i].drawImg();
    }
  }
  for (int i = 0; i < crateItems.length; i++)
    if (crateItems[i].enlarged) 
      crateItems[i].enlarge();  //done after for drawing layer purposes
  
  if (lBut.clicked() && (enlargedContainer == 0))
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
    rBut.changeTxt("Next");
    state = State.ACTIVITY1;
  }  
  if (rBut.clicked() && (enlargedContainer == 0) && itemsPresent > 0) //*/
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
    //image(thumbsup, 0, 0);
    fill(0, 0, 0);
  }
  int titleS = fontTitleLine - 5;
  int itemS = titleS - 5;
  int startL = ySubTitleLine;

  addText(((!PPname.equals("")?(PPname + "'s"):"My") + " Flood Preparation Checklist"), xTitleLine, yTitleLine, fontTitleLine, LEFT, CENTER);
  line(0, yLine, windowWidth, yLine);
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
  
  addText("Items that I felt were important", xTitleLine, startL, titleS, LEFT, TOP);
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
        addText(str(itemNum+1) + ": " + a1Items[itemNum], xTitleLine+(j*(windowWidth/3)), startL+(i*(itemS+ySmallItemGap)), itemS, LEFT, TOP);  
        itemNum++;
      }
    }
  }
  startL += ((itemS+ySmallItemGap) * (ceil(float(a1Items.length)/3))) + 5; 

  if (boxItems.length > 0)
  {
    addText("My flood box items", xTitleLine, startL, titleS, LEFT, TOP);
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
          addText(str(itemNum+1) + ": " + boxItems[itemNum], xTitleLine+(j*(windowWidth/3)), startL+(i*(itemS+ySmallItemGap)), itemS, LEFT, TOP);  
          itemNum++;
        }
      }
    }
    startL += ((itemS+ySmallItemGap) * (ceil(float(boxItems.length)/3))) + 5;
  }
  
  if (bagItems.length > 0)
  {
    addText("My emergency bag items", xTitleLine, startL, titleS, LEFT, TOP);  
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
          addText(str(itemNum+1) + ": " + bagItems[itemNum], xTitleLine+(j*(windowWidth/3)), startL+(i*(itemS+ySmallItemGap)), itemS, LEFT, TOP);  
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
    printTxt(report);
    state = State.FINISHED;
  }
}

void finished()
{
  if (showBackgroundImages)
  {
    image(thumbsupwithoutrescue, 0, 0);
  }
  fill(80, 30, 120);

  int yPos = yHeaderLine;
  int fontSize = fontHeaderLine;
  int xPos = (showBackgroundImages ? xThumbsUpWR : xMid);

  // if background images are displayed the text is shown left justified to the right of the image
  addText("Thanks for taking part" + (!PPname.equals("")?(" " + PPname):"") + "!", xMid, yPos, fontSize, CENTER, CENTER);
  fontSize -= 10;
  yPos += 3*fontSize;
  addText("Please take your printout to use", xPos, yPos, fontSize, (showBackgroundImages?LEFT:CENTER), CENTER);
  yPos += fontSize;
  addText("as your Flood Box checklist", xPos, yPos, fontSize, (showBackgroundImages?LEFT:CENTER), CENTER);
  rBut.drawSelf();
  rBut.changeTxt("Restart");
  if (rBut.clicked())
  {
    rBut.changeTxt("Next");
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
  //delay(30);
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
  rect(strokeWeight, strokeWeight, windowWidth-(strokeWeight*2), windowHeight-(strokeWeight*2));
  stroke(67, 49, 167);
  strokeWeight(strokeWeight);
  fill(255, 255, 255);
}

void serialEvent(Serial port)
{  //make class that extends port to include id
  latestScan.id = trim(port.readString());
  //println("tag: " + tagID + " | prvs: " + prvsTagID);
  if (port == boxPort) latestScan.container = 1;
  else latestScan.container = 2;
  port.clear();
  //println(latestScan.container);
}

void printTxt(String[] txt)
{
  for (int line = 0; line < txt.length; line++)
    ;//*/printPort.write(txt[line]);  //*/
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

void loadSoftKeyboard()
{
  // set button size and position to scale with screen size
  int keyButWidth = (windowWidth - 2*keyboardGap) / (softKeyValue[0].length);  // leave gap at each side of keyboard
  int keyButHeight = keyButWidth * dbutHeight / dbutWidth;
  int lineX = keyboardGap;                                     // calculate start xPosition of keyboard;
  int lineY = keyboardLine;
  keyBut = new Button[softKeyValue.length * softKeyValue[0].length];
  
  for (int row = 0, i = 0; row < softKeyValue.length; row++, i++)
  {
    for (int col = 0; col < softKeyValue[row].length; col++, i++)
    {
      if (softKeyValue[row][col].equals(" "))
        keyBut[i] = new Button(softKeyValue[row][col], lineX+(keyButWidth*col), lineY, 6*keyButWidth, keyButHeight, dBut);
      else if (softKeyValue[row][col].equals("Enter"))
        keyBut[i] = new Button(softKeyValue[row][col], lineX+(keyButWidth*col), lineY, 2*keyButWidth, keyButHeight, dBut);
      else if (row == softKeyValue.length-1)
        keyBut[i] = new Button(softKeyValue[row][col], lineX+(6*keyButWidth)+(keyButWidth*(col-1)), lineY, keyButWidth, keyButHeight, dBut);
      else
        keyBut[i] = new Button(softKeyValue[row][col], lineX+(keyButWidth*col), lineY, keyButWidth, keyButHeight, dBut);
    }
    lineX += keyButWidth/2;
    lineY += keyButHeight + keyLineGap;
  }
}

void showSoftKeyboard(boolean showEnter)
{
  for (int row = 0, i = 0; row < softKeyValue.length; row++, i++)
  {
    for (int col = 0; col < softKeyValue[row].length; col++, i++)
    {
      if (!softKeyValue[row][col].equals("Enter") || showEnter)
        keyBut[i].drawSelf();
    }
  }
}

char handleSoftKeyboard(boolean showEnter)
{
  char charPressed = ' ';
  for (int row = 0, i = 0; row < softKeyValue.length; row++, i++)
  {
    for (int col = 0; col < softKeyValue[row].length; col++, i++)
    {
      if (keyBut[i].clicked())
      {
        if (softKeyValue[row][col].equals("Enter"))
        {
          if (showEnter)
          {
            charPressed = ENTER;
            //println("Enter clicked");
          }
        }
        else if (softKeyValue[row][col].equals("Bksp"))
        {
          charPressed = BACKSPACE;
          //println("Backspace clicked");
          if (inStr.length() > 0)
          {
            backAct = false;
            inStr = inStr.substring(0, inStr.length() - 1);
          }
          else
            backAct = true;
        }
        else if (softKeyValue[row][col].equals(" "))
        {
          if (inStr.length() > 0)                      // ignore space at the start of the input line
            inStr += softKeyValue[row][col];
        }
        else
        {
          // if at start of line or there's a space before this key entry, then capitalise key entry
          if ((inStr.length() == 0) || inStr.substring(inStr.length()-1).equals(" ") || inStr.substring(inStr.length()-1).equals("'"))
            inStr = inStr + softKeyValue[row][col].toUpperCase();
          else
            inStr = inStr + softKeyValue[row][col];
        }
      }
    }
  }
  return charPressed;
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