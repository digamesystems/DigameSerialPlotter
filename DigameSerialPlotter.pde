/*
DigameSerialPlotter 

A modification and slight re-factoring of the BasicRealTimePlotter example from
Sebastian Nilsson's spiffy serial plotting utility for Processing:

  https://github.com/sebnil/RealtimePlotter

Like his code, this code relies on the excellent library of UI controls developed by
Andreas Schlegel:

  https://sojamo.de/libraries/controlP5

Modifications: 
  * For my work, I didn't need the bar chart included in Sebastian's example so I removed it. 
  * Added a 'terminator' variable so we can accomodate different message terminations. 
  * Did some playing with fonts to make it a bit more readable for my old eyes. ;)
  * Added an 'offset' UI element in addition to Sebastian's 'multiplier' so we can shift 
    traces relative to each other on the fly.
  * Some re-factoring of the UI setup code to improve readability.
  * Added data logging option.

Code available on: 

*/

// import libraries
import java.awt.Frame;
import java.awt.BorderLayout;
import java.io.*;
import controlP5.*; // Nifty UI library for Processing 
                    //   See: http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

/* GLOBALS */

// Serial port to connect to
String  serialPortName="COM24";  // For Linux / Pi something like: "/dev/tty.usbmodem1411";
byte    terminator     = '\n';   // The last character in a data frame -- usually <cr> or <lf> 
boolean mockupSerial   = false;  // If you want to debug the plotter without using 
                                 //   a real serial port set this to true

processing.serial.Serial serialPort; // Serial port object

ControlP5 cp5; 

JSONObject plotterConfigJSON;    // Settings for the plotter are saved in this object

// Plot
Graph LineGraph = new Graph(450, 70, 900, 600, color (20, 20, 200));
float[][] lineGraphValues      = new float[6][200];
float[] lineGraphSampleNumbers = new float[200];
color[] graphColors            = new color[6];

String topSketchPath = "";  // Path to config file



long numPointsLogged = 0;
Textlabel lblPointsLogged;
Toggle    tglLogData;
Textfield txtLogFileName;



//***********************************************************************************
Textfield addTextField(String name, int x, int y, PFont font)
//***********************************************************************************
{
  Textfield tf;
  
  tf = cp5.addTextfield(name)
    .setPosition(x,y)
    .setSize(65, 35)
    .setColorBackground(color(255,255,255))
    .setColorForeground(color(0,0,0))
    .setColorValue(color(0,0,0))
    .setColorActive(color(0,255,0))
    .setFont(font)
    .setText(getPlotterConfigString(name))
    .setAutoClear(false);
  return tf;
}

//***********************************************************************************
Textfield addTextField(String name, int x, int y, PFont font, int fieldWidth)
//***********************************************************************************
{
  
  Textfield tf;
  
  tf = cp5.addTextfield(name)
    .setPosition(x,y)
    .setSize(fieldWidth, 35)
    .setColorBackground(color(255,255,255))
    .setColorForeground(color(0,0,0))
    .setColorValue(color(0,0,0))
    .setColorActive(color(0,255,0))
    .setFont(font)
    .setText(getPlotterConfigString(name))
    .setAutoClear(false);
  return tf;
}




//***********************************************************************************
void addToggle(String name, int x, int y, color aColor)
//***********************************************************************************
{ 
  cp5.addToggle(name)
    .setPosition(x, y)
    .setSize(60,30)
    .setValue(int(getPlotterConfigString(name)))
    .setMode(ControlP5.SWITCH)
    .setColorActive(aColor);   
  return;
}


//***********************************************************************************
void initSerial() {
//***********************************************************************************
  if (args != null) {
    println(args.length);
    println(args[0]);
    delay(1000);
    serialPortName = args[0];
  } else {
    println("No com port specified. Using default value. (COM24)");
    delay(1000);
    serialPortName = "COM24";  // Change to match your setup if you don't run from the command line. 
  }
  
  //  serial communication
  if (!mockupSerial) {
    //String serialPortName = Serial.list()[3];
    serialPort = new processing.serial.Serial(this, serialPortName, 115200);
  }
  else
    serialPort = null;
}


//***********************************************************************************
void setup() {
//***********************************************************************************
  
  initSerial(); 
    
  surface.setTitle("Digame Serial Plotter");
  size(1500, 800);

  // set line graph colors
  graphColors[0] = color(131, 255, 20);
  graphColors[1] = color(232, 158, 12);
  graphColors[2] = color(255, 0, 0);
  graphColors[3] = color(62, 12, 232);
  graphColors[4] = color(13, 255, 243);
  graphColors[5] = color(200, 46, 232);

  // Load the previous graph settings
  topSketchPath     = sketchPath();
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  // initialize GUI library
  cp5 = new ControlP5(this);
  
  // initialize chart
  setChartSettings();
  
  // build x axis values for the line graph
  for (int i=0; i<lineGraphValues.length; i++) {
    for (int k=0; k<lineGraphValues[0].length; k++) {
      lineGraphValues[i][k] = 0;
      if (i==0)
        lineGraphSampleNumbers[k] = k;
    }
  }
  
  // build the gui
  int initX    = 380;
  int x        = initX;
  int initY    = 60;
  int y        = initY;  
  int ySpacing = 50; 
 
  PFont   font;   // Selected font used for text 
  font = createFont("arial",20,true);

  addTextField("lgMaxY", x,y, font);
  addTextField("lgMinY", x,y+578, font);

  cp5.addTextlabel("label").setFont(font).setText("ON-OFF").setPosition(x=35, y).setColor(0);
  cp5.addTextlabel("multipliers").setFont(font).setText("Multiplier").setPosition(x=125, y).setColor(0);
  cp5.addTextlabel("offsets").setFont(font).setText("Offset").setPosition(x=225, y).setColor(0);
  
  addTextField("lgMultiplier1", x=130, y=y+ySpacing, font);
  addTextField("lgMultiplier2", x,     y=y+ySpacing, font);
  addTextField("lgMultiplier3", x,     y=y+ySpacing, font);
  addTextField("lgMultiplier4", x,     y=y+ySpacing, font);
  addTextField("lgMultiplier5", x,     y=y+ySpacing, font);
  addTextField("lgMultiplier6", x,     y=y+ySpacing, font);
  
  y = initY + ySpacing;
  addTextField("lgOffset1", x=230, y, font);
  addTextField("lgOffset2", x, y=y+ySpacing, font);
  addTextField("lgOffset3", x, y=y+ySpacing, font);
  addTextField("lgOffset4", x, y=y+ySpacing, font);
  addTextField("lgOffset5", x, y=y+ySpacing, font);
  addTextField("lgOffset6", x, y=y+ySpacing, font);
  
  y = initY + ySpacing;
  addToggle("lgVisible1", x=45, y,            graphColors[0]);
  addToggle("lgVisible2", x,    y=y+ySpacing, graphColors[1]);
  addToggle("lgVisible3", x,    y=y+ySpacing, graphColors[2]);
  addToggle("lgVisible4", x,    y=y+ySpacing, graphColors[3]);
  addToggle("lgVisible5", x,    y=y+ySpacing, graphColors[4]);
  addToggle("lgVisible6", x,    y=y+ySpacing, graphColors[5]);
  
  
  cp5.addTextlabel("lblLogFile").setFont(font).setText("Log File: ").setPosition(x=33, y=y+ySpacing*2).setColor(0);
  txtLogFileName = addTextField("txtLogFileName", x=125, y-5, font, 150);
  
  cp5.addTextlabel("lblLoggingActive").setFont(font).setText("Logging Active: ").setPosition(x=33, y=y+ySpacing).setColor(0);
  tglLogData = cp5.addToggle("toggleValue")
   .setPosition(190,y)
   .setSize(35,35)
   .setColorBackground(color(128,128,128));
   
  lblPointsLogged = cp5.addTextlabel("lblNumPointsLogged")
    .setFont(font)
    .setText("Points Logged: 0")
    .setPosition(x=33, y=y+ySpacing)
    .setColor(0);
  
}


//***********************************************************************************
public static void appendStrToFile(String fileName, String str)
//***********************************************************************************
{
    //println(fileName);
    // Try block to check for exceptions
    try {
 
        // Open given file in append mode by creating an
        // object of BufferedWriter class
        BufferedWriter out = new BufferedWriter(
            new FileWriter(fileName, true));
 
        // Writing on output stream
        out.write(str);
        // Closing the connection
        out.close();
    }
 
    // Catch block to handle the exceptions
    catch (IOException e) {
        // Display message when exception occurs
        System.out.println("exception occurred" + e);
    }
        
}


//***********************************************************************************
void appendLog(String s) {
//***********************************************************************************
  appendStrToFile(topSketchPath+"/data/"+txtLogFileName.getText(),s); 
}


//***********************************************************************************
void draw() {
//***********************************************************************************
  byte[] inBuffer = new byte[1024]; // holds serial message
  int i = 0; // loop variable
  
  /* Read serial and update values */
  if (mockupSerial || serialPort.available() > 0) {
    String myString = "";
    if (!mockupSerial) {
      try {
        serialPort.readBytesUntil(terminator, inBuffer);
      }
      catch (Exception e) {
      }
      myString = new String(inBuffer);
      myString = trim(myString) +"\n";
      if (tglLogData.getValue()==1){
        numPointsLogged++;
        lblPointsLogged.setText("Points Logged: " + numPointsLogged);
        appendLog(myString);
      }
    }
    else {
      myString = mockupSerialFunction();
    }

    //println(myString);

    // split the string at delimiter (space)
    String[] nums = split(myString, ' ');
    
    // build the arrays for line graph
    for (i=0; i<nums.length; i++) {
      
      // update line graph
      try {
        if (i<lineGraphValues.length) {
          for (int k=0; k<lineGraphValues[i].length-1; k++) {
            lineGraphValues[i][k] = lineGraphValues[i][k+1];
          }

          lineGraphValues[i][lineGraphValues[i].length-1] = \
            float(nums[i]) * float(getPlotterConfigString("lgMultiplier"+(i+1))) + \
            float(getPlotterConfigString("lgOffset"+(i+1)))
            ;
        }
      }
        catch (Exception e) {
      }
      
    }
  }

  background(255); 

  // Draw the line graph
  LineGraph.DrawAxis();
  for (i=0;i<lineGraphValues.length; i++) {
    LineGraph.GraphColor = graphColors[i];
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
      LineGraph.LineGraph(lineGraphSampleNumbers, lineGraphValues[i]);
  }
  
}


//***********************************************************************************
void setChartSettings() { // Called each time the chart settings are changed  
//***********************************************************************************
  LineGraph.xLabel=" Samples ";
  LineGraph.yLabel="Value";
  LineGraph.Title="Serial Plotter v. 1.0";  
  LineGraph.xDiv=10;  
  LineGraph.xMax=0; 
  LineGraph.xMin=-200;  
  LineGraph.yMax=int(getPlotterConfigString("lgMaxY")); 
  LineGraph.yMin=int(getPlotterConfigString("lgMinY"));
}


//***********************************************************************************
void controlEvent(ControlEvent theEvent) {  // Handle gui actions
//***********************************************************************************  
  if (theEvent.isAssignableFrom(Textfield.class) || 
      theEvent.isAssignableFrom(Toggle.class) ||  
      theEvent.isAssignableFrom(Button.class)) 
  {
    String parameter = theEvent.getName();
    String value = "";
    
    if (theEvent.isAssignableFrom(Textfield.class))
      value = theEvent.getStringValue();
    else if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class))
      value = theEvent.getValue()+"";

    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
  }
  setChartSettings();
}


//***********************************************************************************
// Get GUI settings from plotter configuration JSON object
String getPlotterConfigString(String id) {
//***********************************************************************************
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}
