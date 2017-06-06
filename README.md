# CoGo plugin for QGIS

First developed by Afrispatial cc in 2012

Sponsored by: SpatialMatrix, Lagos for Ogun State Government, Nigeria [background presentation](https://drive.google.com/file/d/0B2pxNIZQUjL1TW5wR00zVC1aUjA/view?usp=sharing)

Contributors: Robert Moerman, Admire Nyakudya, Gavin Fleming, Muhammad Rohmat 

Maintained by Kartoza (Pty) Ltd 

Copyright Kartoza 2017

2017 update for Niger State, Nigeria and potentially for general release. 

Licence:

# Description

This plugin was developed to enable efficient bulk capture of coordinate geometry off survey diagrams. 

It caters for addition, modification and deletion of cadastral parcels.

## Bearings and distances

Where bearing and distance data are available, they can and should be used to defined property boundaries. An initial beacon coordinate is captured and then bearings and distances are captured to define all other beacons in a chain. 

Then properties are constructed by grouping beacons in a specific order to define a parcel polygon. 

## Coordinates

Where bearings and distances are not available, coordinates can be used instead to define beacons. 

## Dependencies

This plugin depends on a PostGIS database with a predefined schema including tables, materialised views and triggers. This schema will be created on initial setup when first running the plugin.  

# User manual

[User manual](http://goo.gl/CY9TYn)



