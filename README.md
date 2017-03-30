# CoGo plugin for QGIS

First developed by Afrispatial cc in 2012

Sponsored by: SpatialMatrix, Lagos for Ogun State Government, Nigeria. 

Original authors: Robert Moerman, Gavin Fleming

Maintained by Kartoza (Pty) Ltd 

Copyright Kartoza 2017

2017 update for Niger State, Nigeria and potentially for general release. 

Licence:

# Description

This plugin was developed to enable efficient bulk capture of coordinate geometry off survey diagrams. 

It caters for addition, modification and deletion of cadastral properties.

## Bearings and distances

Where bearing and distance data are available, they can and should be used to defined property boundaries. An initial beacon coordinate is captured and then bearings and distances are captured to define all other beacons in a chain. 

Then properties are constructed by grouping beacons in a specific order to define a polygon. 

## Coordinates

Where bearings and distances are not available, coordinates can be used instead to define beacons. 

## Dependencies

This plugin depends on a PostGIS database with a predefined schema including tables, materialised views and triggers. 

# User manual

http://goo.gl/CY9TYn


# What's Next 
(Robert's old note - needs to be updated)

- Copy the entire directory containing your new plugin to the QGIS plugin directory
- Compile the ui file using pyuic4
- Compile the resources file using pyrcc4
- Test the plugin by enabling it in the QGIS plugin manager
- Customize it by editing the implementation file `sml_surveyor.py`
- Create your own custom icon, replacing the default `icon.png`
- Modify your user interface by opening `sml_surveyor.ui` in Qt Designer (don't forget to compile it with pyuic4 after changing it)
- You can use the `Makefile` to compile your Ui and resource files when you make changes. This requires GNU make (gmake)


