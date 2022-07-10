# DigameSerialPlotter
A utility that plots streaming data coming in on a serial connection using the "Processing" application framework: 

  https://processing.org/

## Overview

I've been using the Arduino IDE for a while and like the Serial Plotter feature. However, it has some limitiations. 

I decided to roll my own version after discovering Sebastian Nilsson's spiffy serial plotting utility for Processing: 

  https://github.com/sebnil/RealtimePlotter

I based this app on his BasicRealTimePlotter example. Like his code, this code relies on the excellent library of UI controls developed by Andreas Schlegel:

  https://sojamo.de/libraries/controlP5

### Modifications: 
  * For my work, I didn't need the bar chart included in Sebastian's example so I removed it. 
  * Added a 'terminator' variable so we can accomodate different message terminations. I'm using '\n' (linefeed)
  in my app.
  * Did some playing with fonts / styles to make it a bit more readable for my old eyes. ;)
  * Added an 'offset' UI element in addition to Sebastian's 'multiplier' so we can shift 
    traces relative to each other on the fly.
  * Some re-factoring of the UI setup code to improve readability.
  * Added data logging to a file. 

## Installation

### Using Processing Environment

  * Download and install Processing from the link above.
  * Download and uncompress Andreas' ControlP5 library from the link above into your sketches 'libraries' folder. 
  * Clone the project into your Processing sketches location (OS dependent)
  * Open Processing, load the sketch, change the `serialPortname` variable to match your configuration
  * Run it. If your micro is sending data in the form `data1 data2 data3 data4 ... data6\n` you should see data plotted. 
  * Adjust the Y min / max values to match the data you are sending. 

## Next Steps? 
  * Easier configuration of serial port. (Currently a command line argument)
  * Suggestions, forks/pull requests welcome!

## Code available on: 
  https://github.com/digamesystems/DigameSerialPlotter
  
<img src="/doc/screenshot.jpg"/>

