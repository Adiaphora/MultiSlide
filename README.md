# TileShow

Multi-pane slide show with JSON-to-layout generator.  
Run, pick folder, specify/choose a layout and enjoy.  
Useful for viewing reference images with periodical shuffling, while pausing some of it.  

## Features
* Ordered / random sequence
* Drag-n-drop images between panels
* Expand panel
* Fit / cover content

## CLI Usage
Win:  
`C:\images> tileshow.exe -l='{"v3":0}' -p='C:/images'`  
produces window with 3 columns

Switches:
* **p** path to image folder
* **l** layout json definition
* **t** timeout interval, in seconds
* **svg** layout defined by svg file with rectangles

## JSON syntax

The basic idea is to specify orientation + stops.
"v" is for vertical and "h" is for horizontal splits.  
"h3" will split given area into 3 even horizontal panels.  
"h.33.66" will split given area into 3 horizontal panels,  
divided on 33% and 66% stops.

Root key is a primary rects definition "v3" or "v.33.66" (without prefix).  
Subkeys must specify an index of affected panel.  
subkey example "0.h2" or "0.h.50"  

Simple layout: three vertical columns  
`{"v3": 0}`

Complex example:  
`{"v.10.30.70.90":{"0.h3":0,"1.h2":0,"3.h2":0,"4.h3":0}}`  
gives you the following layout:  
![Layout Preview](http://dk.org.ru/tile/vertica11.png)
