# -*- coding: utf-8 -*-
"""
Author: Robert Moerman
Contact: robert@afrispatial.co.za
Company: AfriSpatial

This is a collection of custom qgis tools.

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
"""

from PyQt4.QtCore import *
from PyQt4.QtGui import *
from qgis.gui import *
from qgis.core import*

class featureSelector():
    
    def __init__(self, iface, layer, capturing = True, parent = None):
        # instance valiables
        self.parent = parent # assume parent has a captured method
        self.iface = iface
        self.layer = layer
        self.capturing = capturing
        self.selected = []
        # remember current tool
        self.parentTool = self.iface.mapCanvas().mapTool() 
        # create selection tool
        self.selectTool = QgsMapToolEmitPoint(self.iface.mapCanvas())
        self.selectTool.canvasClicked.connect(self.capture)
        if capturing: self.iface.mapCanvas().setMapTool(self.selectTool)
        # clear selection
        self.layer.removeSelection()

    def enableCapturing(self):
        self.capturing = True
        self.iface.mapCanvas().setMapTool(self.selectTool)

    def disableCapturing(self):
        self.capturing = False
        self.iface.mapCanvas().setMapTool(self.parentTool)

    def clearSelection(self):
        self.selected = []
        self.layer.removeSelection()

    def capture(self, point, button):
        if self.capturing:
            curlyr = self.layer 
            # perform feature selection
            pnt_geom = QgsGeometry.fromPoint(point)
            pnt_buffer = pnt_geom.buffer((self.iface.mapCanvas().mapUnitsPerPixel()*5),0)
            pnt_rect = pnt_buffer.boundingBox()
            curlyr.select([], pnt_rect, True, True)
            feat = QgsFeature()
            while curlyr.nextFeature(feat):
                if feat.id() in self.selected: del self.selected[self.selected.index(feat.id())]
                else: self.selected.append(feat.id())
                curlyr.setSelectedFeatures(self.selected)
                # notify parent of selection
                if self.parent is not None: self.parent.captured(self.selected)
                break
