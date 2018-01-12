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

## Sample Data

A sql script is provided which populates all the mandatory tables required by the plugin. In order to use the
sample data create the database with a CRS: `26332`. A sample survey is provided as a guideline on how to capture records.

# User manual

[User manual](http://goo.gl/CY9TYn)


## Credits

Cogo plugin was funded by [Spatial Matrix](http://www.spatialmatrix.com/) and 
developed by Afrispatial and subsequently  [Kartoza](http://www.kartoza.com/)

## License

Cogo plugin is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License version 3 (GPLv3) as
published by the Free Software Foundation.

The full GNU General Public License is available in LICENSE.txt or
http://www.gnu.org/licenses/gpl.html


## Disclaimer of Warranty (GPLv3)

There is no warranty for the program, to the extent permitted by
applicable law. Except when otherwise stated in writing the copyright
holders and/or other parties provide the program "as is" without warranty
of any kind, either expressed or implied, including, but not limited to,
the implied warranties of merchantability and fitness for a particular
purpose. The entire risk as to the quality and performance of the program
is with you. Should the program prove defective, you assume the cost of
all necessary servicing, repair or correction.

## Thank you

Thank you to the individual contributors who have helped to build cogo plugin:

* Gavin Fleming 
* Robert Mooerman
* Tobi Sowole 
* Muhammad Yarjuna Rohmat 
* Admire Nyakudya

