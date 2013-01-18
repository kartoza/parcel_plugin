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
    """ This tool enables the selection of a single feature or multiple features from a vector layer, returning the feature's id or features' ids after each selection via the captured method in the invoking class
    """
    
    def __init__(self, iface, layer, capturing = True, parent = None):
        # initialize instance valiables
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
        # enable capturing if allowed 
        if capturing: self.iface.mapCanvas().setMapTool(self.selectTool)
        # clear selection
        self.layer.removeSelection()

    def enableCapturing(self):
        """ Enable feature selection
        """
        self.capturing = True
        self.iface.mapCanvas().setMapTool(self.selectTool)

    def disableCapturing(self):
        """ Disable feature selection
        """
        self.capturing = False
        self.iface.mapCanvas().setMapTool(self.parentTool)

    def clearSelection(self):
        """ Clear feature selection
        """
        self.selected = []
        self.layer.removeSelection()

    def appendSelection(self, id):
        """ Append a feature to the list of currently selected features
        """
        # toggle selection 
        if id in self.selected: del self.selected[self.selected.index(id)]
        else: self.selected.append(id)
        self.layer.setSelectedFeatures(self.selected)
        # notify parent of changed selection
        if self.parent is not None: self.parent.captured(self.selected)
        
    def capture(self, point, button):
        """ Capture id of feature selected by the selector tool
        """
        # check that capturing has been enabled
        if self.capturing:
            pnt_geom = QgsGeometry.fromPoint(point)
            pnt_buffer = pnt_geom.buffer((self.iface.mapCanvas().mapUnitsPerPixel()*5),0)
            pnt_rect = pnt_buffer.boundingBox()
            self.layer.select([], pnt_rect, True, True)
            feat = QgsFeature()
            while self.layer.nextFeature(feat):
                self.appendSelection(feat.id())
                break
