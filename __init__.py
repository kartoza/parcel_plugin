# -*- coding: utf-8 -*-
"""
/***************************************************************************
 SMLSurveyor
                                 A QGIS plugin
 SML Surveyor Plugin
                             -------------------
        begin                : 2012-12-28
        copyright            : (C) 2012 by AfriSpatial
        email                : robert@afrispatial.co.za
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
 This script initializes the plugin, making it known to QGIS.
"""


def name():
    return "CoGo Plugin Toolbar"


def description():
    return "CoGo Plugin"


def version():
    return "Version 0.1"


def icon():
    return "icon.png"


def qgisMinimumVersion():
    return "2.0"


def author():
    return "AfriSpatial"


def email():
    return "robert@afrispatial.co.za"


def classFactory(iface):
    # load SMLSurveyor class from file SMLSurveyor
    from plugin import SMLSurveyor
    return SMLSurveyor(iface)
