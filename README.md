# DigameSerialPlotter
A serial plotting utility for Processing

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

Code available on: https://github.com/digamesystems/DigameSerialPlotter

<img src="/doc/screenshot.jpg"/>

