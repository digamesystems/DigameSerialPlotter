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

Code available on: 

*/

// import libraries
import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

/* SETTINGS BEGIN */
  // Serial port to connect to
  String  serialPortName;// For Linux / Pi something like: "/dev/tty.usbmodem1411";
  byte    terminator     = '\n';   // The last character in a data frame -- usually <cr> or <lf> 
  boolean mockupSerial   = false;  // If you want to debug the plotter without using 
                                   // a real serial port set this to true
/* SETTINGS END */

Serial serialPort; // Serial port object

ControlP5 cp5; // Nifty UI library for Processing
               //   See: https://sojamo.de/libraries/controlP5/
                         
// Settings for the plotter are saved in this file
JSONObject plotterConfigJSON;

// Plots
Graph LineGraph = new Graph(450, 70, 900, 500, color (20, 20, 200));
float[][] lineGraphValues = new float[6][200];
float[] lineGraphSampleNumbers = new float[200];
color[] graphColors = new color[6];

// helper for saving the executing path
String topSketchPath = "";


void addTextField(String name, int x, int y, PFont font)
{
  
  cp5.addTextfield(name)
  .setPosition(x,y)
  .setSize(65, 30)
  .setFont(font)
  .setText(getPlotterConfigString(name))
  .setAutoClear(false);
  return;
}

void addToggle(String name, int x, int y, color aColor)
{ 
  cp5.addToggle(name)
    .setPosition(x, y)
    .setValue(int(getPlotterConfigString(name)))
    .setMode(ControlP5.SWITCH)
    .setColorActive(aColor);   
  return;
}

void setup() {
   if (args != null) {
    println(args.length);
    println(args[0]);
    serialPortName = args[0];
  } else {
    println("No com port specified. Using default value. (COM24).");
    serialPortName = "COM24";  // Change to match your setup if you don't run from the command line. 
  }
  
  
  surface.setTitle("Tweaked Real-Time plotter");
  size(1500, 700);

  // set line graph colors
  graphColors[0] = color(131, 255, 20);
  graphColors[1] = color(232, 158, 12);
  graphColors[2] = color(255, 0, 0);
  graphColors[3] = color(62, 12, 232);
  graphColors[4] = color(13, 255, 243);
  graphColors[5] = color(200, 46, 232);

  // Load the previous graph settings
  topSketchPath = sketchPath();
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
  
  // start serial communication
  if (!mockupSerial) {
    //String serialPortName = Serial.list()[3];
    serialPort = new Serial(this, serialPortName, 115200);
  }
  else
    serialPort = null;


  // build the gui
  int initX = 380;
  int x = initX;
  int initY = 55;
  int y = initY;  
  int ySpacing = 50; 
  
  PFont   font;                   // Selected font used for text 
  font = createFont("arial",20);
  
  addTextField("lgMaxY", x,y, font);
  addTextField("lgMinY", x,y+488, font);

  cp5.addTextlabel("label").setFont(font).setText("ON/OFF").setPosition(x=13, y).setColor(0);
  cp5.addTextlabel("multipliers").setFont(font).setText("Multiplier").setPosition(x=100, y).setColor(0);
  cp5.addTextlabel("offsets").setFont(font).setText("Offset").setPosition(x=200, y).setColor(0);
  
  addTextField("lgMultiplier1", x=110, y=y+ySpacing, font);
  addTextField("lgMultiplier2", x,     y=y+ySpacing, font);
  addTextField("lgMultiplier3", x,     y=y+ySpacing, font);
  addTextField("lgMultiplier4", x,     y=y+ySpacing, font);
  addTextField("lgMultiplier5", x,     y=y+ySpacing, font);
  addTextField("lgMultiplier6", x,     y=y+ySpacing, font);
  
  y = initY + ySpacing;
  addTextField("lgOffset1", x=210, y, font);
  addTextField("lgOffset2", x, y=y+ySpacing, font);
  addTextField("lgOffset3", x, y=y+ySpacing, font);
  addTextField("lgOffset4", x, y=y+ySpacing, font);
  addTextField("lgOffset5", x, y=y+ySpacing, font);
  addTextField("lgOffset6", x, y=y+ySpacing, font);
  
  y = initY + ySpacing;
  addToggle("lgVisible1", x=30, y,            graphColors[0]);
  addToggle("lgVisible2", x,    y=y+ySpacing, graphColors[1]);
  addToggle("lgVisible3", x,    y=y+ySpacing, graphColors[2]);
  addToggle("lgVisible4", x,    y=y+ySpacing, graphColors[3]);
  addToggle("lgVisible5", x,    y=y+ySpacing, graphColors[4]);
  addToggle("lgVisible6", x,    y=y+ySpacing, graphColors[5]);
  
}

byte[] inBuffer = new byte[1024]; // holds serial message
int i = 0; // loop variable
void draw() {
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
    }
    else {
      myString = mockupSerialFunction();
    }

    //println(myString);

    // split the string at delimiter (space)
    String[] nums = split(myString, ' ');
    
    // count number of bars and line graphs to hide
    int numberOfInvisibleBars = 0;
    for (i=0; i<6; i++) {
      if (int(getPlotterConfigString("bcVisible"+(i+1))) == 0) {
        numberOfInvisibleBars++;
      }
    }
    int numberOfInvisibleLineGraphs = 0;
    for (i=0; i<6; i++) {
      if (int(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
        numberOfInvisibleLineGraphs++;
      }
    }

    // build the arrays for bar charts and line graphs
    int barchartIndex = 0;
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

  // draw the line graph
  LineGraph.DrawAxis();
  for (int i=0;i<lineGraphValues.length; i++) {
    LineGraph.GraphColor = graphColors[i];
    if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
      LineGraph.LineGraph(lineGraphSampleNumbers, lineGraphValues[i]);
  }
}

// called each time the chart settings are changed by the user 
void setChartSettings() {
  LineGraph.xLabel=" Samples ";
  LineGraph.yLabel="Value";
  LineGraph.Title="Serial Plotter v. 1.0";  
  LineGraph.xDiv=10;  
  LineGraph.xMax=0; 
  LineGraph.xMin=-200;  
  LineGraph.yMax=int(getPlotterConfigString("lgMaxY")); 
  LineGraph.yMin=int(getPlotterConfigString("lgMinY"));
}

// handle gui actions
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class) || theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
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

// get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}
