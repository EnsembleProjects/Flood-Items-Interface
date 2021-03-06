import java.util.Map;
import processing.serial.*;

boolean showBackgroundImages = true;              // set false if you want a plain background rather than background images

int numItems = 23;                                             // number of items included in crate that can be scanned

int windowWidth;                                               // assigned in setup()
int windowHeight;
int xMid;                                                      // x co-ordinate of middle of window
int xQuarter;                                                  // 1/4 of window width
int yLine;                                                     // y co-ordinate for Line across screen below title
int xTitleLine;                                                // x co-ordinate of start of Title drawn above Line across screen (for list headers)
int yTitleLine;                                                // y co-ordinate of TitleLine
int fontSizeTitle;                                             // font size for TitleLine
int ySubTitleLine;                                             // y co-ordinate for start of subTitle below line drawn across screen
int fontSizeSubTitle;                                          // font size for SubTitleLine
int fontSizeText;                                              // font size for Text below titles
int ySmallItemGap;                                             // small vertical gap between spaced items
int yLargeItemGap;                                             // large vertical gap between spaced items
int yHeaderLine;                                               // y co-ordinate for screens with large centred headings
int fontSizeHeader;                                            // font size for centred headings
int xSandbags;                                                 // x co-ordinate for start of left-justified text on screen with sandbags image
int xThumbsUpWR;                                               // x co-ordinate for start of left-justified text on screen with thumbsupwithoutrescue image
int xCouchCat;                                                 // x co-ordinate for start of left-justified text on screen with couchcat image
int xUserItems;                                                // x co-ordinate for start of user input in UserItems
int xStepGap;                                                  // x gap between each step of scan instructions
int xStep1, xStep2, xStep3, xStep4, xStep5;                    // x co-ordinate for each step of the scan instructions
int yStepHeight;                                               // height of instructions; assigned in setup()
int lineWidthUserItems;                                        // width of user input line for UserItems
int fontSizeInputUserItems;                                    // font size for user input for UserItems
int xPromptUserItems;                                          // x co-ordinate for extra prompts for UserItems
int fontSizeScanBox;                                           // font size for Box/Discard(Bag) titles on scanning screen
int fontSizeItemName;                                          // font size for Name of enlarged scanned item
int fontSizeItemDesc;                                          // font size for Description of enlarged scanned item
int smallImageWidth;                                           // width of scanned item image 
int largeImageWidth;                                           // max width of enlarged scanned item image
int largeImageHeight;                                          // max height of enlarged scanned item image

int strokeWeight = 1;                                          // default stroke weight (used for lines)

int inputLineGap = 5;                                          // the distance (or buffer) between the flashing vertical line (cursor) and user input text
int descripEdge = 10;                                          // border between description text and edge of container-area

int infoWidth;                                                 // width of text in Box/Bag container area - assigned in setup()
int infoHeight;

int dbutWidth = 160;                                           // default button width (used for Next/Done/Restart, Back, and Dismiss buttons)
int dbutHeight = 80;                                           // default button height
int dButX;                                                     // button position, assigned in setup()
int dButY;

int keyLineGap;                                                // gap between each line (row) of the soft keyboard
int keyboardGap;                                               // gap at each side of the soft keyboard
int keyboardLine;                                              // start line for soft keyboard
int dKeyWidth = 120;                                           // default soft key width
int dKeyHeight = 75;                                           // default soft key height

color dBut = color(255,255,255,150);                           // white, semi-transparent
color eBut = color(255,255,255,10);                            // white, less transparent (used for Enter key on dark Welcome screen)
color backgroundColour = color(249, 246, 244);                 // 'pinkish' background colour
color backgroundTransparent = color(249, 246, 244, 100);       // semi-transparent background colour
color textColour = color(33, 33, 33);                          // graphite colour of text
color highlightColour = color(246, 79, 90);                    // cerise colour of highlighted text, or user input field
color descriptionColour = color(256, 250, 248);                 // 'pinkish' background colour

char softKey = ' ';                                            // used by softKey handler to tell others if Enter/Backspace pressed
boolean clickAct = false;                                      //ensures only 1 object reacts to a 'click'; true if a object has reacted to a click; resets on click release.
boolean backAct = false;                                       // true if BACKSPACE pressed but inStr is empty (used to backspace to previous input line)
int enlargedContainer = 0;                                     // remembers which container currently displays an enlarged item (0 if neither), to
                                                               //  ensure enlarge-clicks are ignored for the other container
int mPressX = 0;                                               // stores the mouse co-ordinates at the point it was last clicked
int mPressY = 0;

enum State {STARTSCREEN, NAMEENTRY, SCANINTRO, SCANITEMS, USERITEMS, REPORT, FINISHED};

State state = State.STARTSCREEN;                               // state machine powers up in STARTSCREEN state

PImage floodBox;                                               // image of flood box Grab Bag
PImage welcome;                                                // artist graphic for Welcome page background
PImage couchcat;                                               // artist graphic of woman with cat on couch
PImage boots;                                                  // artist graphic of muddy boots
PImage sandbags;                                               // artist graphic of sandbags
PImage thumbsupwithoutrescue;                                  // artist graphic of children with flood box for final Thanks page
//PImage emergBag;

PImage selectScanItem;                                         // instructions: Step 1 select item to scan
PImage readyToScan;                                            // instructions: Step 2 ready to scan
PImage scanItem;                                               // instructions: Step 3 scan item
PImage checkDescription;                                       // instructions: Step 4 check description
PImage itemIntoBag;                                            // instructions: Step 5 put scanned item into Bag

PImage LULogo;                                                 // Lancaster University logo for Welcome page
PImage EnsembleLogo;                                           // Ensemble logo for Welcome page
PImage EnvAgencyLogo;                                          // Environment Agency logo for Welcome page

PFont fontTitle, fontText;                                     // fonts for Titles, and the rest of the text
String PPname = "";                                            // name of the participant (PP), taken in nameEntry screen
int maxNameLength = 20;                                        // maximum length of participant's name
String[] a1Items = {};                                         // items the PP enters during activity 1
int a1Item = 0;                                                // item within a1Items[] that PP is currently addressing
String inStr = "";                                             // temp storage for input string (i.e. acts as input buffer)
int itemsPresent = 0;                                          // number of items scanned (and on screen) in total
int itemsInContainer[] = new int[2];                           // number of items in each container
                                                               // the first container is the Flood Box (now called the Grab Bag)
                                                               // the second container is the Emergency Bag (now used for Discard from the Grab Bag)

// used internally to ease generation of final report
String[] boxItems = {};                                        // items scanned into Box
String[] bagItems = {};                                        // items scanned into Bag
String[] report = {};                                          // text to be sent to printer

// class, with attributes and methods, for each scannable item
public class ItemTag
{
  public String id = "";
  public int container = 0;
  
  public void clear()                                          // used to clear record of last item scanned
  {
    id = "";
    container = 0;
  }
}

public class Item
{    
  public String id;
  public String name;
  public int x, y, container;
  //public int rLine = 0;
  public PImage smallImg;
  public PImage largeImg;
  public String[] descrip;
  
  public boolean present = false;
  //public boolean held = false;
  public boolean enlarged = false;
  
  public Item(String id, String name)
  {
    this.id = id;
    this.name = name;
    this.largeImg = loadImage("graphics/" + name + ".png");
    float laFactor = (float)largeImageWidth/largeImg.width;
    int laHeight = (int)(laFactor * largeImg.height);          // scale image to fit width
    if (laHeight <= largeImageHeight)                          //  and also to fit height
      this.largeImg.resize(largeImageWidth, laHeight);
    else
      this.largeImg.resize((int)((float)largeImageWidth*(largeImageHeight)/laHeight), largeImageHeight);
    
    this.smallImg = loadImage("graphics/" + name + ".png");
    int smFactor = smallImageWidth/smallImg.width; 
    this.smallImg.resize(smallImageWidth, smallImg.height*smFactor);
    
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
    double attempts = 0;                                       // count number of attempts to find non-colliding location
    do
    {
      attempts++;
      this.x = int(random(minX, maxX));
      this.y = int(random(yLine+fontSizeScanBox+2*ySmallItemGap, (windowHeight-smallImg.height-dbutHeight-2*ySmallItemGap)));  //accounts for dButs as well
                                                               // (don't let bottom of object go below top of buttons)
    } while (detectCollision() && attempts < 500);             // if we haven't found a non-collision in all these attempts, just use this location
    if (attempts == 500) println("placing collided object due to lack of space");
  }
  
  public void drawImg()
  {
    if (enlarged)
    {
      int imgX = 0;                                            // items in Box are drawn on the left hand side
      if (this.container == 2)
        imgX = xMid;                                           // items in Bag are drawn on the right hand side
      fill(backgroundTransparent);                             // draw rectangle same shade as background but slightly transparent
      noStroke();
      rect(imgX+strokeWeight, yLine+strokeWeight, xMid-2*strokeWeight, windowHeight-yLine-2*strokeWeight);  //  so we can still see other scanned items in this container, but they're fainter
      fill(backgroundColour);
      rect(xTitleLine, yLine, xMid-2*strokeWeight, fontSizeTitle); // hide instruction to press Next when done

      if (largeImg.width < xMid)
        imgX += (xMid - largeImg.width) / 2;                   // display enlarged item's image horizontally central
      image(largeImg, imgX, yLine+fontSizeScanBox);
      if (itemsInContainer[this.container-1] > 1)              // if there are >1 items in the enlarged container
      {                                                        //  enable scrolling through the enlarged items + descriptions
        //textFont(fontTitle);                                   // (should use fontTitle, but won't notice for ">")
        nextItemBut[this.container-1].drawSelf();              // display the next/prev-item buttons for this container (same side as Image)
        prevItemBut[this.container-1].drawSelf();
        //textFont(fontText);
      }
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
    int infoY = yLine+descripEdge+100;
    if (this.container == 1)
      infoX += xMid;

    fill(backgroundColour);                                    // draw rectangle same shade as background and obscuring items in this container
    //noStroke();                                                // rectangle has no lines around it
    stroke(highlightColour);
    strokeWeight(strokeWeight*10);
    rect(infoX+5*strokeWeight, yLine+5*strokeWeight, xMid-10*strokeWeight, windowHeight-yLine-10*strokeWeight);
                                                               // cover the content of the scanbox, but not its outline
    strokeWeight(strokeWeight);
    infoX += descripEdge + 30;
    fill(highlightColour);                                     // text colour to emphasise whether item in flood box (or not)
    addText((this.container == 1? "In":"Discarded from") + " the Grab Bag:", infoX+5, infoY+5, fontSizeItemName, LEFT, TOP);    // display whether item is in the Grab Bag
    fill(textColour);                                          // text colour for desciption text
    addText(this.name, infoX+5, infoY+5+fontSizeItemName, fontSizeItemName, LEFT, TOP);    // display name of enlarged item
    for (int i = 0; i < descrip.length; i++)                   // display description of enlarged item
      addText(descrip[i], infoX+5, infoY+2*fontSizeItemName+((i+1)*fontSizeItemDesc), fontSizeItemDesc, LEFT, TOP);
                                                               // display Dismiss button (to close Description)
    textFont(fontTitle);                                       // button text is in title font
    dismissBut[this.container-1].drawSelf();                     // display the dismiss-description button for this container
    textFont(fontText);                                        // put font back to normal
    noStroke();
  }
  
  public boolean clicked()
  {
    // if item is clicked while it is not enlarged and there are either no enlargements or enlargements are for the same container
    if (!enlarged && mousePressedOver() && mousePressed && !clickAct && (enlargedContainer == 0 || enlargedContainer == this.container))
    {  //ensures mutex
      clickAct = true;
      return true;
    }
    else
      return false;
  }
  
  //public void heldDrag()
  //{  //needed for ordering importance of items (was activity3; no longer used)
  //  if (clicked()) held = true;
  //  if (held == true)
  //  {
  //    if ((mouseX > 0 && mouseX < windowWidth && mouseY > yLine && mouseY < windowHeight)
  //    && ((this.container == 1 && mouseX < xMid) || (this.container == 2 && mouseX > xMid)))
  //    {
  //      x = mouseX-(smallImg.width/2);
  //      y = mouseY-(smallImg.height/2);
  //    }
  //    if (!clickAct) held = false;
  //  }
  //}
  
  public boolean detectCollision()                             // used to display scanned objects randomly on screen without overlapping
  {
    int myX = this.x + this.smallImg.width/8;                  // add small allowance: objects allowed to overlap by 1/8 at any edge
    int myY = this.y + this.smallImg.height/8;
    int myWid = this.smallImg.width - this.smallImg.width/8;
    int myHei = this.smallImg.height - this.smallImg.height/8;
    //println("New item at " + myX + "," + myY + " with width=" + myWid + " and height=" + myHei);
    for (int i = 0; i < crateItems.length; i++)                // check for collision with all other scanned createItems
    {
      if (crateItems[i].present && crateItems[i].id != this.id)
      {
        //print(" | " + i + " is present");
        int chalX = crateItems[i].x;                           // (don't add overlap allowance to these objects)
        int chalY = crateItems[i].y;
        int chalWid = crateItems[i].smallImg.width;
        int chalHei = crateItems[i].smallImg.height;
        //println("Existing item at " + chalX + "," + chalY + " with width=" + chalWid + " and height=" + chalHei);
        if ((chalX + chalWid) >= myX && chalX <= (myX+myWid) &&    //if challenger's right (edge) >= my left AND challenger's left <= my right              
            (chalY + chalHei) >= myY && chalY <= (myY+myHei))      //AND challenger's top >= my bottom AND challenger's bottom <= my top
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
    if (mPressX >= x && mPressX <= x+smallImg.width && mPressY >= y && mPressY <= y+smallImg.height)
      return true;
    else return false;
  }
}
  
public class Button
{
  public String txt;
  public int x, y, wid, hei;
  public int xtxt, ytxt, htxt;                                 // position and height of button text
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
    this.xtxt = x+(wid/2)-2;
    this.ytxt = y+(hei*3/8);
    this.htxt = hei/2;
  }
  
  public boolean clicked()
  {
    if (mousePressed && mousePressedOver() && !clickAct)
    {  //ensures mutex
      clickAct = true;
      return true;
    }
    return false;
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
    image(butImg, x, y);                                       // display button image
    
    if (mouseHoverOver()) fill(highlightColour);               // colour of text when mouse is hovering over
    else fill(textColour);                                     // colour of text when mouse is not hovering over
    addText(txt, xtxt, ytxt, htxt, CENTER, CENTER);            // display button text vertically centred
    
    fill(textColour);                                          // reset text colour back to normal
  }
  
  public void changeTxt(String t)                              // change text for this button
  {
    this.txt = t;
  }
}

Item[] crateItems = new Item[numItems];                        // all the items that the participant could scan
Button rBut;                                                   // right button, used for 'Done' or 'Next'
Button lBut;                                                   // left button, used for 'Back'
Button enterBut;                                               // Enter button on Welcome screen, used to get started
Button[] nextItemBut = new Button[2];                          // next item buttons, for Bag and Box; used on enlarged scanned item screen
Button[] prevItemBut = new Button[2];                          // previous item buttons, for Bag and Box; used on enlarged scanned item screen
Button[] dismissBut = new Button[2];                           // dismiss buttons, for Bag and Box; used to close item Description
Button keyBut[];                                               // soft keyboard buttons
String softKeyValue[][] = {{"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "+", "Bksp"}, 
                              {"a", "s", "d", "f", "g", "h", "j", "k", "l", "-"}, 
                                 {"z", "x", "c", "v", "b", "n", "m", "'", "Enter"}, 
                                    {" "}
                          };

Serial bagPort;                                                // input from Bag scanner
Serial boxPort;                                                // input from Box scanner
Serial printPort;                                              // output to printer
ItemTag latestScan = new ItemTag();                            // details of the last item scanned
String tagID = "";

void setup()
{
  //fullScreen();                                                // comment out to make the screen windowed
  //size(1300, 700);                                             // OR comment out to make full screen
  size(1280, 800);                                             // size of 10" touchscreen, but windowed
  windowWidth = width;
  windowHeight = height;

  // calculate all the screen start positions and fonts at start-up, to speed execution of main loop (draw) 
  xMid = windowWidth/2;                                        // x co-ordinate of middle of window
  xQuarter = xMid/2;                                           // 1/4 of window width
  yHeaderLine = windowHeight/8;                                // y co-ordinate for screens with a large header line
  fontSizeHeader = windowWidth/24;                             // font size for header lines
  yLine = windowHeight*8/100;                                  // y co-ordinate for Line across screen
  xTitleLine = 20;                                             // x co-ordinate of start of Title drawn above Line across screen (for list headers)
  yTitleLine = yLine*2/5;                                      // y co-ordinate of start of TitleLine
  fontSizeTitle = windowWidth/30;                              // font size for TitleLine
  ySmallItemGap = windowHeight/100;                            // small vertical gap between spaced items
  yLargeItemGap = windowHeight/15;                             // large vertical gap between spaced items
  ySubTitleLine = yLine + ySmallItemGap;                       // y co-ordinate for start of SubTitle below line drawn across screen
  fontSizeSubTitle = fontSizeTitle-10;                         // font size for SubTitleLine
  fontSizeText = fontSizeSubTitle;                             // font size for Text
  //println("fontSizeTitle=" + fontSizeTitle);
  //println("fontSizeSubTitle=" + fontSizeSubTitle);
  //println("fontSizeText=" + fontSizeText);
  xSandbags = windowWidth/4;                                   // x co-ordinate for start of left-justified text on screen with sandbags image
  xThumbsUpWR = windowWidth*2/5;                               // x co-ordinate for start of left-justified text on screen with thumbsupwithoutrescue image
  xCouchCat = windowWidth/4;                                   // x co-ordinate for start of left-justified text on screen with couchcat image
  xUserItems = xTitleLine+windowWidth/30;                      // x co-ordinate for start of user input in UserItems
  xStepGap = xTitleLine;                                       // gap between each step of scan instructions and at start and end of screen
  int stepWidth = (windowWidth - 6*xStepGap)/5;
  xStep1 = xStepGap;
  xStep2 = xStep1 + stepWidth + xStepGap;
  xStep3 = xStep2 + stepWidth + xStepGap;
  xStep4 = xStep3 + stepWidth + xStepGap;
  xStep5 = xStep4 + stepWidth + xStepGap;
  lineWidthUserItems = (windowWidth - 4*xUserItems)/3;         // each input line is a third of screen width ignoring gaps at edges and between columns
  fontSizeInputUserItems = lineWidthUserItems/12;              // use a font size that allows about 20 chars on each input line
  xPromptUserItems = xMid - lineWidthUserItems/2;              // x co-ordinate for extra prompts for UserItems
  fontSizeScanBox = fontSizeSubTitle;                          // font size for Box/Discard(Bag) titles on scanning screen 
  fontSizeItemName = fontSizeScanBox;                          // font size for Name of enlarged scanned item
  fontSizeItemDesc = fontSizeItemName-5;                       // font size for Description of enlarged scanned item
  infoWidth = (windowWidth/2) - (descripEdge*2);               // width of enlarged item description
  infoHeight = windowHeight - (descripEdge*2) - yLine - dbutHeight - 10;  // description fills other half of screen below Title line and above button

  smallImageWidth = 100;                                       // width of scanned item image 
  largeImageWidth = 500;                                       // max width of scanned item image when enlarged
  largeImageHeight = infoHeight - 20;                          // max height of scanned item image when enlarged

  keyLineGap = windowHeight/200;                               // gap between each line of the soft keyboard
  keyboardGap = windowWidth/14;                                // gap at each side of the soft keyboard
  keyboardLine = 9*windowHeight/14;                            // start line for soft keyboard

  
  //preload all the images, so they're ready for use when needed
  //floodBox = loadImage("graphics/floodBox.gif");
  //emergBag = loadImage("graphics/emergBag.png");
  floodBox = loadImage("graphics/emergBag.png");
  welcome = loadImage("background graphics/welcome.jpg");
  welcome.resize(windowWidth, windowHeight);
  couchcat = loadImage("background graphics/couchcatwithwoman.jpg");
  couchcat.resize(windowWidth, windowHeight);
  boots = loadImage("background graphics/boots.jpg");
  boots.resize(windowWidth, windowHeight);
  sandbags = loadImage("background graphics/sandbags.jpg");
  sandbags.resize(windowWidth, windowHeight);
  thumbsupwithoutrescue = loadImage("background graphics/thumbsupwithoutrescue.jpg");
  thumbsupwithoutrescue.resize(windowWidth, windowHeight);
  
  // load the images for the scan instructions
  selectScanItem = loadImage("graphics/instructions/select item to scan.png");  // instructions: Step 1 select item to scan
  selectScanItem.resize(stepWidth, stepWidth*selectScanItem.height/selectScanItem.width);
  readyToScan = loadImage("graphics/instructions/ready to scan.png");           // instructions: Step 2 ready to scan
  readyToScan.resize(stepWidth, stepWidth*readyToScan.height/readyToScan.width);
  scanItem = loadImage("graphics/instructions/scan item.png");                  // instructions: Step 3 scan item
  scanItem.resize(stepWidth, stepWidth*scanItem.height/scanItem.width);
  checkDescription = loadImage("graphics/instructions/check description.png");  // instructions: Step 4 check description
  checkDescription.resize(stepWidth, stepWidth*checkDescription.height/checkDescription.width);
  itemIntoBag = loadImage("graphics/instructions/scanned item into Bag.png");   // instructions: Step 5 put scanned item into Bag
  itemIntoBag.resize(stepWidth, stepWidth*itemIntoBag.height/itemIntoBag.width);
  yStepHeight = scanItem.height;
  
  // load the logos for the welcome page
  LULogo = loadImage("graphics/logos/LULogo.png");
  LULogo.resize(windowWidth/8, (int)(((float)LULogo.height/LULogo.width)*windowWidth/8));
  EnvAgencyLogo = loadImage("graphics/logos/EnvAgencyLogo.png");
  //EnvAgencyLogo.resize(windowWidth/8, (int)(((float)EnvAgencyLogo.height/EnvAgencyLogo.width)*windowWidth/8));
  EnvAgencyLogo.resize((int)((float)EnvAgencyLogo.width*LULogo.height/EnvAgencyLogo.height), LULogo.height);  // scale to same height as LU logo
  EnsembleLogo = loadImage("graphics/logos/EnsembleLogo.png");
  EnsembleLogo.resize(windowWidth/8, (int)(((float)EnsembleLogo.height/EnsembleLogo.width)*windowWidth/8));

  // preload the buttons
  dButX = windowWidth-dbutWidth-10;
  dButY = windowHeight-dbutHeight-10;
  rBut = new Button("Next", dButX, dButY, dbutWidth, dbutHeight, dBut);
  lBut = new Button("Back", 10, dButY, dbutWidth, dbutHeight, dBut);
  //enterBut = new Button("ENTER", xMid-(dbutWidth/2), yHeaderLine+3*fontSizeHeader, dbutWidth, dbutHeight, eBut);
  dismissBut[0] = new Button("Dismiss", windowWidth-dbutWidth-10, yLine+descripEdge+10, dbutWidth, dbutHeight, dBut);  // Dismiss button on same side as Descrip
  dismissBut[1] = new Button("Dismiss", xMid-dbutWidth-10, yLine+descripEdge+10, dbutWidth, dbutHeight, dBut);
  nextItemBut[0] = new Button(">", xMid-dbutWidth/2-10, dButY, dbutWidth/2, dbutHeight, dBut);           // next/prev buttons on same side as Image
  nextItemBut[1] = new Button(">", windowWidth-dbutWidth/2-10, dButY, dbutWidth/2, dbutHeight, dBut);
  prevItemBut[0] = new Button("<", 10, dButY, dbutWidth/2, dbutHeight, dBut);
  prevItemBut[1] = new Button("<", xMid+10, dButY, dbutWidth/2, dbutHeight, dBut);

  // preload the soft keyboard
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
  
  // preload the fonts we're going to use
  fontTitle = createFont("Roboto Slab", 30);
  fontText = createFont("Open Sans", 20);
  strokeWeight(strokeWeight);
  resetDefaults();
  
  // set up I/O ports by commenting out the lines you don't want
  boxPort = new Serial(this, "/dev/ttyACM0", 9600);                    // this line is for use on Pi
  //*/boxPort = new Serial(this, "COM5", 9600);                            // this line is for use on Windows //*/
  //boxPort = new Serial(this, "/dev/tty.usbmodem1A12421", 9600);        // these lines are for use on Mac
  //boxPort = new Serial(this, "/dev/tty.usbmodem14231", 9600);
  boxPort.buffer(10); //*/
  boxPort.clear(); //*/
  
  bagPort = new Serial(this, "/dev/ttyACM1", 9600);                    // Pi
  //*/bagPort = new Serial(this, "COM4", 9600);                            // Windows //*/
  //bagPort = new Serial(this, "/dev/tty.usbmodem1A1221", 9600);         // Mac
  //bagPort = new Serial(this, "/dev/tty.usbmodem14211", 9600);
  bagPort.buffer(10); //*/
  bagPort.clear(); //*/
  
  printPort = new Serial(this, "/dev/ttyUSB0", 19200);                 // Pi
  //*/printPort = new Serial(this, "COM6", 19200);                         // Windows //*/
  //printPort = new Serial(this, "/dev/tty.usbserial-A501DGRD", 19200);  // Mac

  initialiseData();
}

// clears all the user entered/selected data
// DO NOT call this from draw() unless you are sure it will be called only once for a given state - remember that draw() will run repeatedly
// you do not want to keep resetting all the data arrays
void initialiseData()
{
  PPname = "";                                                 // clear the participant's name
  boxPort.clear();                                         // reset the serial input ports //*/
  bagPort.clear(); //*/
  
  // clear the items entered by the participant
  a1Item = a1Items.length;
  while (a1Item > 0)
  {
    a1Item--;
    a1Items[a1Item] = "";
    a1Items = shorten(a1Items);
  }
  inStr = "";
  itemsPresent = 0;                                            // no items scanned yet
  itemsInContainer[0] = 0;                                     // no items in either container
  itemsInContainer[1] = 0;
  // clear the items from the Flood Box, the Flood Bag, and the Report (first two are used by the report)
  clearReport();
  // mark all items in Bag container at start
  for (int i = 0; i < crateItems.length; i++)
  {
    crateItems[i].present = true;                              // item scanned
    // for testing, put some items into Grab Bag
    //if (i <= 1 || i == 12 || i == 16)
    //{
    //  crateItems[i].container = 1;                               // item in Box container
    //  crateItems[i].scanned(1);                                  // place item randomly on screen
    //  itemsInContainer[0]++;                                     // count number of items in Box container
    //  itemsPresent++;                                            // count number of items present
    //}
    //else
    {
      crateItems[i].container = 2;                               // item in Bag container
      crateItems[i].scanned(2);                                  // place item randomly on screen
      itemsInContainer[1]++;                                     // count number of items in Bag container
      itemsPresent++;                                            // count number of items present
    }
  }
  enlargedContainer = 0;                                       // nothing is enlarged at the start
  println("total items present=" + itemsPresent + ", items in Box=" + itemsInContainer[0] + ", items in Discard=" + itemsInContainer[1]);

  enterBut = new Button("", 0, 0, windowWidth, windowHeight, eBut); // set up enter button for restart (will be nulled as soon as user starts)
}

void startScreen()
{
  //if (mousePressed) clickAct = true;                         // prevents buttons on next screen activating

  fill(textColour);                                            // colour for all display fonts
  if (showBackgroundImages)
    image(welcome, 0, 0);                                      // display the flood picture and welcome text
  else
    addText("Welcome", xMid, yLine, fontSizeHeader*2, CENTER, CENTER);    // display a plain background, with welcome text
  addText("Are you prepared for a flood?", xMid, yHeaderLine+fontSizeHeader+fontSizeSubTitle, fontSizeSubTitle, CENTER, CENTER);
  addText("Press anywhere on the screen to find out more", xMid, yHeaderLine+fontSizeHeader+2*fontSizeSubTitle+ySmallItemGap, fontSizeSubTitle, CENTER, CENTER);
  // display a slightly transparent white band along the bottom of the screen, and display the fonts on this
  // Note LU logo must have same amount of space above and below as used by "U"
  fill(255, 255, 255, 190);                                    // white, with some transparency
  rect(0, windowHeight-100, windowWidth, 100);
  fill(textColour);
  image(LULogo, windowWidth/5, windowHeight-75);
  image(EnsembleLogo, xMid-EnsembleLogo.width/2, windowHeight-90);
  image(EnvAgencyLogo, windowWidth*4/5-EnvAgencyLogo.width, windowHeight-75);
  //enterBut.drawSelf();                                         // display enter button (it's still active even when not displayed)
  if (enterBut.clicked() || keyCode == ENTER)                  // when Enter pressed
  {                                                            // go to next screen
    state = State.NAMEENTRY;
    keyCode = ' ';                                             // Enter has been dealt with, so clear it
    enterBut = null;
  }
}

void nameEntry()
{
  int lineY = yTitleLine;

  fill(textColour);                                            // colour for all display fonts
  if (showBackgroundImages)
    image(sandbags, 0, 0);

  addText("One in six UK homes are at risk", xSandbags, lineY, fontSizeTitle, LEFT, CENTER);
  lineY += fontSizeTitle;
  addText("of flooding", xSandbags, lineY, fontSizeTitle, LEFT, CENTER);
  lineY += fontSizeTitle;
  textFont(fontText);
  addText("Make a personal flood kit to be prepared", xSandbags, lineY, fontSizeSubTitle, LEFT, CENTER);
  lineY += fontSizeSubTitle;
  addText("before a flood happens", xSandbags, lineY, fontSizeSubTitle, LEFT, CENTER);
  lineY += 2*fontSizeTitle;
  addText("Let's get started ...", xSandbags, lineY, fontSizeText, LEFT, CENTER);
  lineY += fontSizeText+ySmallItemGap;
  textFont(fontTitle);
  addText("What name should we call you?", xSandbags, lineY, fontSizeTitle, LEFT, CENTER);
  showSoftKeyboard(false);                                     // show keyboard without Enter key
  lBut.changeTxt("Restart");
  rBut.drawSelf();
  lBut.drawSelf();
  fill(highlightColour);
  addText(PPname, xSandbags, lineY+fontSizeTitle+ySmallItemGap, fontSizeTitle, LEFT, CENTER);
  // flash a vertical line cursor where the input text is to go
  if (alternator(500))
    line(xSandbags+textWidth(PPname), lineY+ySmallItemGap+fontSizeTitle/2+ySmallItemGap, xSandbags+textWidth(PPname), lineY+fontSizeTitle+ySmallItemGap+3*fontSizeTitle/4);

  handleSoftKeyboard(false);                                   // handle input from soft keyboard

  if (inStr.length() > maxNameLength)                          // truncate name to maximum number of characters
    inStr = inStr.substring(0, maxNameLength);
  PPname = inStr;
  
  if (lBut.clicked())                                          // if Back clicked
  {
    initialiseData();                                          // clear data for restart for next user
    state = State.STARTSCREEN;                                 // go to previous screen
  }
  if (rBut.clicked() || keyCode == ENTER)                      // Enter can be used after typing name, rather than having to click Next
  {                                                            // if Enter pressed or Next clicked
    if (a1Items.length > 0) inStr = a1Items[a1Item];
    else inStr = "";
    softKey = ' ';
    keyCode = ' ';                                             // Enter has been dealt with, so clear it
    lBut.changeTxt("Back");
    state = State.SCANINTRO;                                   // go to next screen
  }
}

boolean tutorial = false;                                      // true if you want to display additional prompts re ENTER/BACKSPACE
void userItems()
{
  // displays 3 columns for user input; each column has 5 rows
  // first column displays all 5 items at the start
  // subsequent items are displayed only as needed (after previous item is entered)
  int lineX = xUserItems;                                      // x co-ordinate of first input line
  int lineY = ySubTitleLine + fontSizeTitle;                   // the title on this screen occupies 2 lines
  int startLineY;                                              // y co-ordinate of start of user input

  fill(textColour);
  if (showBackgroundImages)
    image(boots, 0, 0);

  addText("Is there anything else you'd like to add", xTitleLine, yTitleLine, fontSizeTitle, LEFT, CENTER);
  addText("to your personal Grab Bag?", xTitleLine, yTitleLine+fontSizeTitle, fontSizeTitle, LEFT, CENTER);
  showSoftKeyboard(true);                                      // show keyboard with Enter key
  rBut.drawSelf();                                             // display buttons
  lBut.drawSelf();
  textFont(fontText);                                          // activate the main font
  addText("You can add up to 15 items", xTitleLine, lineY, fontSizeSubTitle, LEFT, TOP);
  lineY += fontSizeSubTitle;
  addText("Press Enter to add another item.  Press Backspace to edit the previous item.", xTitleLine, lineY, fontSizeText, LEFT, TOP);
  lineY += 2*yLargeItemGap;
  startLineY = lineY;

  if (keyCode == ENTER || softKey == ENTER)                    // ensure no more than 15 items
  {
    if ((a1Items.length < 15) && (inStr.length() > 0))
    {
      //ensure can only move to next line once something has been entered on this line
      inStr = "";
      a1Item++;
    }
    softKey = ' ';                                             // Enter has been dealt with, so clear it
    keyCode = ' ';
  }
  
  //println("kC " + keyCode + " | item: " + a1Item + " | eB: " + backAct);
  //println("a1Item: " + a1Item + " | arrayLen: " + a1Items.length);
  if (keyCode == BACKSPACE || softKey == BACKSPACE)
  {
    if ((a1Item > 0) && backAct)                               // if backspace needs to go to previous item
    {
      //print("backAct");
      a1Item--;                                                // decrement number of items
      inStr = a1Items[a1Item];                                 // and go to end of what is now the last item
      backAct = false;                                         // dealt with
    }
    softKey = ' ';                                             // Backspace has been dealt with, so clear it
    keyCode = ' ';
  }

  if (a1Item >= a1Items.length) a1Items = append(a1Items, "");      //should never be greater than, only ever equal to
  else if (a1Item < a1Items.length-1) a1Items = shorten(a1Items);  //shortens if item is MORE than 1 below length (i.e. -2 or worse)
 
  if (tutorial)  // if tutorial required, display extra prompts on first 2 items on how to move on/back
  {
    if (a1Item == 0 && !a1Items[a1Item].equals(""))
      addText("Press Enter to add the next item", xPromptUserItems, lineY, fontSizeText, LEFT, BOTTOM);
    //if (a1Item == 1 && a1Items[1].equals(""))
    if (a1Item == 1)
      addText("Press Backspace to edit the previous item", xPromptUserItems, lineY+yLargeItemGap, fontSizeText, LEFT, BOTTOM);
  }
  if (a1Items.length >= 3) tutorial = false;                   // removes tutorial pointers once user has entered 3 items
  //else tutorial = true;                                      // restores tutorial if user reduces number of items
  if (a1Items.length == 5 && !a1Items[a1Item].equals(""))
  {
    // display prompt for more items, aligned with (and just above) last item entered
    addText("Can you think of any more?", xPromptUserItems, lineY+(4*yLargeItemGap)-fontSizeText-ySmallItemGap, fontSizeText, LEFT, BOTTOM);
    addText("Press Enter to continue adding", xPromptUserItems, lineY+(4*yLargeItemGap), fontSizeText, LEFT, BOTTOM);
  }

  fill(highlightColour);                                       // set colour for user input
  //line(lineX, lineY+(i*yLargeItemGap), lineX+lineWidthUserItems, lineY+(i*yLargeItemGap)); //display underline for first item
  addText(str(1) + ".", lineX-fontSizeInputUserItems-5, lineY, fontSizeInputUserItems, LEFT, BOTTOM);  // display index number for first item
  for (int i = 0; i < a1Items.length; i++)                     // display any additional items that have been entered
  {
      //print(i + ": ");
      if (i >= 10)
      {
        lineY = startLineY - (10*yLargeItemGap);
        lineX = windowWidth-lineWidthUserItems-xUserItems;
      }
      else if (i >= 5)
      {
        lineY = startLineY - (5*yLargeItemGap);
        lineX = xMid - lineWidthUserItems/2;
      }
      //line(lineX, lineY+(i*yLargeItemGap), lineX+lineWidthUserItems, lineY+(i*yLargeItemGap));  // display underline for next item
      int numWidth = ((i < 9)? fontSizeInputUserItems+5:5*fontSizeInputUserItems/3);      // adjust position so index number is displayed right-aligned to user input
      addText(str(i+1) + ".", lineX-numWidth, lineY+(i*yLargeItemGap), fontSizeInputUserItems, LEFT, BOTTOM);  // display index number for next item

    addText(a1Items[i], lineX, lineY+(i*yLargeItemGap), fontSizeInputUserItems, LEFT, BOTTOM);
  }
  // flash vertical line as cursor for next input area
  if (alternator(500))
    line(lineX+textWidth(a1Items[a1Item])+inputLineGap, lineY+(a1Item*yLargeItemGap)-fontSizeInputUserItems-ySmallItemGap, lineX+textWidth(a1Items[a1Item])+inputLineGap, lineY+(a1Item*yLargeItemGap));

  softKey = handleSoftKeyboard(true);                          // display keyboard with Enter key
  
  if (textWidth(inStr) <= lineWidthUserItems) 
    a1Items[a1Item] = inStr;
  else
  {
    inStr = a1Items[a1Item];
    //println("too long");
  }
  
  if (lBut.clicked())                                          // if Back clicked
  {                                                            // go back to previous screen, with its data
    inStr = PPname;
    state = State.SCANITEMS;
  }
  if (a1Items.length >= 0 && rBut.clicked())                   //compare to 5 if you want to force user to enter 5 items
  {                                                            // if Next clicked and enough items entered
    rBut.changeTxt("Done");
    state = State.REPORT;                                      // go on to next screen
  }
}

void scanIntro()
{
  fill(textColour);
  //if (showBackgroundImages)
  //  image(couchcat, 0, 0);

  int yPos = yTitleLine;

  textFont(fontTitle); //activate the main font
  addText("Next you'll create your personal Grab Bag for use", xTitleLine, yPos, fontSizeTitle, LEFT, CENTER);
  yPos += fontSizeTitle;
  addText("during flooding", xTitleLine, yPos, fontSizeTitle, LEFT, CENTER);
  yPos += fontSizeTitle + fontSizeText;

  textFont(fontText); //activate the main font
  addText("From the crate beside you select items you will find useful during a flood", xTitleLine, yPos, fontSizeText, LEFT, CENTER);
  yPos += fontSizeText;

  addText("Then scan these items into your Grab Bag", xTitleLine, yPos, fontSizeText, LEFT, CENTER);
  yPos += 2*fontSizeText;
  //image(floodBox, (xCouchCat-floodBox.width)/2, yPos);

  // show instructions across the screen
  //yPos = yStep1 - fontSizeText;
  addText("1. select item", xStep1, yPos, fontSizeText-10, LEFT, CENTER);
  addText("2. take to scanner", xStep2, yPos, fontSizeText-10, LEFT, CENTER);
  addText("3. scan item", xStep3, yPos, fontSizeText-10, LEFT, CENTER);
  addText("4. check description", xStep4, yPos, fontSizeText-10, LEFT, CENTER);
  addText("5. put into Grab Bag", xStep5, yPos, fontSizeText-10, LEFT, CENTER);
  yPos += fontSizeText;
  image(selectScanItem, xStep1, yPos);
  image(readyToScan, xStep2, yPos);
  image(scanItem, xStep3, yPos);
  image(checkDescription, xStep4, yPos);
  image(itemIntoBag, xStep5, yPos);
  yPos += yStepHeight + 3*fontSizeText;
  fill(highlightColour);                                       // highlight colour to emphasise they need to go to next screen before scanning
  addText("Press Next to get started", xTitleLine, yPos, fontSizeText, LEFT, CENTER);
  fill(textColour);

  textFont(fontTitle);
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
    state = State.NAMEENTRY;
    softKey = ' ';
  }
  if (rBut.clicked())
  {
    inStr = "";
    latestScan.clear();                                        // resets tagID before scanItems
    boxPort.clear(); //*/
    bagPort.clear(); //*/
    state = State.SCANITEMS;
  }
}
 
void scanItems()
{
  fill(textColour);
  addText("Scan the items you need from the crate to the Grab Bag", xTitleLine, yTitleLine, fontSizeTitle, LEFT, CENTER);
  if (enlargedContainer == 0)                                  // display Next/Back buttons only when no items are enlarged
  {
    if (itemsInContainer[0] > 0)                               // display Next button only when at least one item scanned into Flood Box
      rBut.drawSelf();
    lBut.drawSelf();
  }
  textFont(fontText);
  addText("Press Next when you've finished", xTitleLine, yLine+2*ySmallItemGap, fontSizeText, LEFT, CENTER);
  addText("In the Grab Bag", xQuarter, dButY, fontSizeScanBox, CENTER, TOP);
  addText("In the Crate", xMid+xQuarter, dButY, fontSizeScanBox, CENTER, TOP);
  line(xMid, yLine+fontSizeScanBox+ySmallItemGap, xMid, dButY);

  // handle latest scanned item (if any)
  if (!latestScan.id.equals(""))
  {
    for (int i = 0; i < crateItems.length; i++)
    {
      if (crateItems[i].id.equals(latestScan.id) && (!crateItems[i].present || crateItems[i].container != latestScan.container))
      {  //checks key against item IDs, then their presence OR scan into diff container
        //println("making present");
        if (crateItems[i].container > 0)                         // if item had previously been scanned
          itemsInContainer[crateItems[i].container-1]--;         //  reduce the count for where it used to be
        else                                                     // if item has not been scanned before
          itemsPresent++;                                        //  increment the count of total items scanned
        itemsInContainer[latestScan.container-1]++;              // increase the count for the new container
        crateItems[i].scanned(latestScan.container);             // scan item into container 1 or 2, in a random, non-overlapping screen position
        for (int j = 0; j < crateItems.length; j++)
        {
          if (j != i) crateItems[j].enlarged = false;            // reset the enlargement of all items but the scanned one
        }
        crateItems[i].enlarge();                                 // enlarge scanned item
        latestScan.clear();                                      // dealt with latest scan, so clear it
        //println("enlarge item " + i);
        println("total items present=" + itemsPresent + ", items in Box=" + itemsInContainer[0] + ", items in Discard=" + itemsInContainer[1]);
        break;
      }
    }
  }   
  
  // display all items, and handle clicks
  for (int i = 0; i < crateItems.length; i++)
  {
    if (crateItems[i].present == true)
    {
      if (!crateItems[i].enlarged && crateItems[i].clicked())  // clicked on an item that is not enlarged
      {
        for (int j = 0; j < crateItems.length; j++)
        {
          if (j != i) crateItems[j].enlarged = false;          // reset the enlargement of all but the clicked item
        }
        crateItems[i].enlarge();                               // enlarge clicked item
        //println("enlarge item " + i);
      }

      if (crateItems[i].enlarged && (enlargedContainer > 0) && dismissBut[enlargedContainer-1].clicked())        // clicked to Close the enlarged item
      {
        crateItems[i].unenlarge();                             // set nothing enlarged
        //println("unenlarge item " + i);
      }
      else if (crateItems[i].enlarged && (enlargedContainer > 0) && nextItemBut[enlargedContainer-1].clicked() && (itemsInContainer[crateItems[i].container-1]>1))
      {                                                        // clicked to enlarge next item in same container 
        //println("> clicked");
        for (int j = i+1; j != i; j++)
        {
          if (j >= crateItems.length) j = 0;
          if (crateItems[j].container == crateItems[i].container) // find next item in this container
          {
            crateItems[i].enlarged = false;                    // current item is no longer enlarged
            crateItems[j].enlarged = true;                     // next item is enlarged instead
            break;                                             // break out of inner for loop, as we've found the next item
          }
        }
      }
      else if (crateItems[i].enlarged && (enlargedContainer > 0) && prevItemBut[enlargedContainer-1].clicked() && (itemsInContainer[crateItems[i].container-1]>1))
      {                                                        // clicked to enlarge previous item in same container
        //println("< clicked");
        for (int j = i-1; j != i; j--)
        {
          if (j < 0) j = crateItems.length-1;
          if (crateItems[j].container == crateItems[i].container) // find previous item in this container
          {
            crateItems[i].enlarged = false;                    // current item is no longer enlarged
            crateItems[j].enlarged = true;                     // previous item is enlarged instead
            break;                                             // break out of inner for loop, as we've found the previous item
          }
        }
      }
      if (!crateItems[i].enlarged)                             // display unenlarged item
        crateItems[i].drawImg();
    }
  }

  // display any enlarged item on top of all the unenlarged items
  for (int i = 0; i < crateItems.length; i++)
    if (crateItems[i].enlarged)
    {
      crateItems[i].enlarge();                                 // display enlarged item on top of all the other items
      break;                                                   // there is at most one enlarged item
    }

  // can go to previous avtivity only when nothing is enlarged
  if (lBut.clicked() && (enlargedContainer == 0))
  {
    a1Item = a1Items.length - 1;
    if (a1Item >= 0)
      inStr = a1Items[a1Item];
    else
    {
      inStr = "";
      a1Item = 0;
    }
    state = State.SCANINTRO;
  }
  
  // can go to next activity only when nothing is enlarged and there is at least one item scanned into Flood Box
  if (rBut.clicked() && (enlargedContainer == 0) && (itemsInContainer[0] > 0)) //*/
  {
    inStr = "";
    state = State.USERITEMS;
  }
}

boolean once = false;                                          // for debug print
void report()
{
  int startL = ySubTitleLine;
  int itemNum;

  fill(textColour);
  addText(((!PPname.equals("")?(PPname + "'s"):"My") + " Flood Preparation Checklist"), xTitleLine, yTitleLine, fontSizeTitle, LEFT, CENTER);
  rBut.drawSelf();
  lBut.drawSelf();
  
  textFont(fontText);
  // generate the report to be printed
  if (report.length == 0)
  {
    if ((a1Item >= 0) && (a1Items.length != 0) && (a1Items[a1Item].equals("")))
    {                                                          // if last item of user input is empty
      a1Item--;
      a1Items = shorten(a1Items);                              // remove the empty field
    }
    makeReport();
    if (a1Item < 0) a1Item = 0;
  }

  if (boxItems.length > 0)
  {
    addText("My Grab Bag items:", xTitleLine, startL, fontSizeText, LEFT, TOP);
    startL += fontSizeText+ySmallItemGap;
    
    itemNum = 0;
    if (once) println("len: " + boxItems.length + " | len/3: " + float(boxItems.length)/3);
    for (int i = 0; i < ceil(float(boxItems.length)/3); i++)
    {
      for (int j = 0; j < 3; j++)
      {
        //println("i: " + i + "j: " + j + "num: " + itemNum + "len: " + a1Items.length);
        if (itemNum < boxItems.length)
        {        
          addText(str(itemNum+1) + ". " + boxItems[itemNum], xTitleLine+(j*(windowWidth/3)), startL+(i*(fontSizeInputUserItems+ySmallItemGap)), fontSizeInputUserItems, LEFT, TOP);  
          itemNum++;
        }
      }
    }
    startL += ((fontSizeInputUserItems+2*ySmallItemGap) * (ceil(float(boxItems.length)/3))) + 2*ySmallItemGap;
  }
  
  if (bagItems.length > 0)
  {
    addText("My emergency bag items:", xTitleLine, startL, fontSizeText, LEFT, TOP);  
    startL += fontSizeText+ySmallItemGap;
  
    itemNum = 0;
    if (once) println("len: " + bagItems.length + " | len/3: " + float(bagItems.length)/3);
    for (int i = 0; i < ceil(float(bagItems.length)/3); i++)
    {
      for (int j = 0; j < 3; j++)
      {
        //println("i: " + i + "j: " + j + "num: " + itemNum + "len: " + a1Items.length);
        if (itemNum < bagItems.length)
        {        
          addText(str(itemNum+1) + ". " + bagItems[itemNum], xTitleLine+(j*(windowWidth/3)), startL+(i*(fontSizeInputUserItems+ySmallItemGap)), fontSizeInputUserItems, LEFT, TOP);  
          itemNum++;
        }
      }
    }
    startL += ((fontSizeInputUserItems+2*ySmallItemGap) * (ceil(float(bagItems.length)/3))) + 2*ySmallItemGap;
  }
  once = false;
  
  if (a1Items.length > 0)
  {
    addText("Items I added to my Grab Bag:", xTitleLine, startL, fontSizeText, LEFT, TOP);
    startL += fontSizeText+ySmallItemGap;
    if (once) println(startL);
    
    itemNum = 0;
    if (once) println("len: " + a1Items.length + " | len/3: " + float(a1Items.length)/3);
    for (int i = 0; i < ceil(float(a1Items.length)/3); i++)
    {
      for (int j = 0; j < 3; j++)
      {
        //println("i: " + i + "j: " + j + "num: " + itemNum + "len: " + a1Items.length);
        if (itemNum < a1Items.length)
        {        
          addText(str(itemNum+1) + ". " + a1Items[itemNum], xTitleLine+(j*(windowWidth/3)), startL+(i*(fontSizeInputUserItems+ySmallItemGap)), fontSizeInputUserItems, LEFT, TOP);  
          itemNum++;
        }
      }
    }
    startL += ((fontSizeInputUserItems+ySmallItemGap) * (ceil(float(a1Items.length)/3))) + 2*ySmallItemGap; 
  }
  
  if (lBut.clicked())
  {
    clearReport();                                             // clear the report data in case the user changes the scanned items
    rBut.changeTxt("Next");
    state = State.USERITEMS;                                   // go to previous activity
  }
  
  if (rBut.clicked())
  {
    //println("SaveClick");
    // identify the filename for the report
    int fNum = 1;
    //println(sketchPath("reports/report" + str(fNum) + ".txt"));
    File f = new File(sketchPath("reports/report" + str(fNum) + ".txt"));
    //println(f.getName() + " : " + f.exists());
    while (f.exists())
    {
      //println(fNum + " exists");
      fNum++;
      f = new File(sketchPath("reports/report" + str(fNum) + ".txt"));
    }
    // save the report and print it
    //println("saving as report" + fNum + ".txt");
    saveStrings(sketchPath("reports/report" + str(fNum) + ".txt"), report);
    printTxt(report);
    rBut.changeTxt("Restart");
    state = State.FINISHED;                                    // go to Thanks screen
  }
}

void finished()
{
  fill(textColour);
  if (showBackgroundImages)
    image(thumbsupwithoutrescue, 0, 0);

  int yPos = yHeaderLine;
  int xPos = (showBackgroundImages ? xThumbsUpWR : xMid);

  // if background images are displayed the text is shown left justified to the right of the image
  addText("Thanks for taking part" + (!PPname.equals("")?(", " + PPname):"") + "!", xMid, yPos, fontSizeTitle, CENTER, CENTER);
  yPos += 3*fontSizeTitle;
  rBut.drawSelf();
  textFont(fontText);                                          // activate the main font
  addText("Please take your printout to use as", xPos, yPos, fontSizeText, (showBackgroundImages?LEFT:CENTER), CENTER);
  yPos += fontSizeText;
  addText("your Grab Bag checklist", xPos, yPos, fontSizeText, (showBackgroundImages?LEFT:CENTER), CENTER);
  yPos += 2*fontSizeText;
  addText("For more information visit", xPos, yPos, fontSizeText, (showBackgroundImages?LEFT:CENTER), CENTER);
  yPos += fontSizeText;
  fill(highlightColour);
  addText("nationalfloodforum.org.uk", xPos, yPos, fontSizeText, (showBackgroundImages?LEFT:CENTER), CENTER);
  fill(textColour);
  yPos += fontSizeText;
  addText("or call the Floodline on", xPos, yPos, fontSizeText, (showBackgroundImages?LEFT:CENTER), CENTER);
  yPos += fontSizeText;
  fill(highlightColour);
  addText("0345 988 1188", xPos, yPos, fontSizeText, (showBackgroundImages?LEFT:CENTER), CENTER);
  if (rBut.clicked())
  {
    rBut.changeTxt("Next");
    initialiseData();                                          // clear data for restart for next user
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
    case USERITEMS:
      userItems();
      break;
    case SCANINTRO:
      scanIntro();
      break;
    case SCANITEMS:
      scanItems();
      break;
   case REPORT:
      report();
      break;
    case FINISHED:
      finished();
      break;
  }
  mousePressed = false;        // this variable would otherwise be set for several loops, when we want it just once
  //delay(2);
}

// create the text for the printable reports
void makeReport()
{
  // Title the report, and include the participant's name
  if (PPname.equals(""))
    report = append(report, "\nMy Flood Preparation Checklist\n");
  else
  {
    report = append(report, "\n" + PPname + "'s" );    // need two lines for header, so that text does not break onto new line in a weird place 
    report = append(report, "\nFlood Preparation Checklist\n");
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
    // (Note: the Bag scanner is now used to Discard from the Box)
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
    report = append(report, "\n");                    // new line; need as separate append so that saving as .txt factors new line too
    report = append(report, "Grab Bag Items:\n");
    for (int i = 0; i < boxItems.length; i++)
      report = append(report, (i+1 + ". " + boxItems[i] + "\n"));
  }
  
  // list all the scanned emergency bag items in the report
  if (bagItems.length > 0)
  {
    //bagItems = sortItems(bagItems);
    report = append(report, "\n");  //new line
    report = append(report, "Emergency Bag Items:\n");
    for (int i = 0; i < bagItems.length; i++)
      report = append(report, (i+1 + ". " + bagItems[i] + "\n"));
  }

  // list all the participant's typed items in the report
  if (a1Items.length > 0)
  {
    report = append(report, "\n");                    // new line; need as separate append so that saving as .txt factors new line too
    report = append(report, "Items I added to my Grab Bag:\n");
    for (int i = 0; i < a1Items.length; i++)
    {
      if (!a1Items[i].equals(""))
        report = append(report, (str(i+1) + ". " + a1Items[i] + "\n"));
    }
  }
  
  // finish the report with a reference for more info
  report = append(report, "\n");
  report = append(report, "For more information visit\n");
  report = append(report, "nationalfloodforum.org.uk\n");
  report = append(report, "or call the Floodline on\n");
  report = append(report, "0345 988 1188\n");
  report = append(report, "________________________________\n");
  report = append(report, "\n\n\n\n\n\n\n________________________________\n"); //designed to cause the receipt to print longer, easier to cut
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
  background(backgroundColour);                                // colour of background
  stroke(textColour);                                          // colour of line and text
  textFont(fontTitle);                                         // activate the title font for the start of each screen
}

void serialEvent(Serial port)
{  //make class that extends port to include id
  latestScan.id = trim(port.readString());
  //println("tag: " + tagID + " | prvs: " + prvsTagID);
  if (port == boxPort) latestScan.container = 1;
  else latestScan.container = 2;
  port.clear();
  //println("Scanned into container " + latestScan.container);
}

void printTxt(String[] txt)
{
  for (int line = 0; line < txt.length; line++)
    printPort.write(txt[line]);  //*/
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
  backAct = false;                                             // assumes key is not a BACKSPACE with a blank inStr
  if (keyCode == BACKSPACE)
  {
    if (inStr.length() > 0) inStr = inStr.substring(0, inStr.length() - 1);
    else backAct = true;                                       // corrects if key IS BACKSPACE with a blank inStr
  }
  else if (key >= ' ' && key <= '~')
  {
    //should allow all numbers and letters, space, dash, comma, apostrophe
    if (key != ' ' || inStr.length() > 0)                      // ignore space at the start of the input line
      inStr = inStr + key;
  }
  //print(inStr);
}

// loads soft keyboard, ready for use
void loadSoftKeyboard()
{
  // set button size and position to scale with screen size
  int keyButWidth = (windowWidth - keyboardGap) / (softKeyValue[0].length);  // leave gap at each side of keyboard
  int keyButHeight = keyButWidth * dKeyHeight / dKeyWidth;
  int lineX = keyboardGap/2;                                     // get start x,y positions of keyboard;
  int lineY = keyboardLine;
  keyBut = new Button[softKeyValue.length * softKeyValue[0].length];
  
  for (int row = 0, i = 0; row < softKeyValue.length; row++, i++)
  {
    for (int col = 0; col < softKeyValue[row].length; col++, i++)
    {
      if (softKeyValue[row][col].equals(" "))                  // space bar is 6* wider than other keys
        keyBut[i] = new Button(softKeyValue[row][col], lineX+(keyButWidth*col), lineY, 6*keyButWidth, keyButHeight, dBut);
      else if (softKeyValue[row][col].equals("Enter"))         // Enter is 2* wider than other keys
        keyBut[i] = new Button(softKeyValue[row][col], lineX+(keyButWidth*col), lineY, 2*keyButWidth, keyButHeight, dBut);
      else if (row == softKeyValue.length-1)                   // in case there are any buttons on same row after space bar
        keyBut[i] = new Button(softKeyValue[row][col], lineX+(6*keyButWidth)+(keyButWidth*(col-1)), lineY, keyButWidth, keyButHeight, dBut);
      else
        keyBut[i] = new Button(softKeyValue[row][col], lineX+(keyButWidth*col), lineY, keyButWidth, keyButHeight, dBut);
    }
    lineX += keyButWidth/2;
    lineY += keyButHeight + keyLineGap;
  }
}

// displays soft keyboard
// param1 = true if Enter key is to be displayed
void showSoftKeyboard(boolean showEnter)
{
  for (int row = 0, i = 0; row < softKeyValue.length; row++, i++)
  {
    for (int col = 0; col < softKeyValue[row].length; col++, i++)
    {
      if (!softKeyValue[row][col].equals("Enter") || showEnter)  // display Enter key only if asked to do so
        keyBut[i].drawSelf();
    }
  }
}

// handles input from soft keyboard
// alpha keys are appended to inStr
// returns ENTER, BACKSPACE or ' '
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
          if (inStr.length() > 0)                              // ignore space at the start of the input line
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