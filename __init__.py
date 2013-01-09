# -*- coding: utf-8 -*-
"""
/***************************************************************************
 sml_surveyor
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
    return "SML Surveyor"


def description():
    return "SML Surveyor Plugin"


def version():
    return "Version 0.1"


def icon():
    return "icon.png"


def qgisMinimumVersion():
    return "1.8"

def author():
    return "AfriSpatial"

def email():
    return "robert@afrispatial.co.za"

def classFactory(iface):
    # load sml_surveyor class from file sml_surveyor
    from sml_surveyor import sml_surveyor
    return sml_surveyor(iface)
