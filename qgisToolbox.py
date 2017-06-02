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


class FeatureSelector():
    """ This tool enables the selection of a single feature or
    multiple features from a vector layer, returning the feature's id or
    features' ids after each selection via the captured method in the
    invoking class
    """

    def __init__(self, iface, layer, capturing=True, parent=None):
        # initialize instance valiables
        self.parent = parent  # assume parent has a captured method
        self.iface = iface
        self.layer = layer
        self.capturing = capturing
        self.selected = []
        # remember current tool
        self.parent_tool = self.iface.mapCanvas().mapTool()
        # create selection tool
        self.select_tool = QgsMapToolEmitPoint(self.iface.mapCanvas())
        self.select_tool.canvasClicked.connect(self.capture)
        # enable capturing if allowed
        if capturing:
            self.iface.mapCanvas().setMapTool(self.select_tool)
        # clear selection
        self.layer.removeSelection()

    def enable_capturing(self):
        """ Enable feature selection
        """
        self.capturing = True
        self.iface.mapCanvas().setMapTool(self.select_tool)

    def disable_capturing(self):
        """ Disable feature selection
        """
        self.capturing = False
        self.iface.mapCanvas().setMapTool(self.parent_tool)

    def clear_selection(self):
        """ Clear feature selection
        """
        self.selected = []
        self.layer.removeSelection()

    def append_selection(self, id):
        """ Append a feature to the list of currently selected features
        """
        # toggle selection
        self.selected.append(id)
        # notify parent of changed selection
        self.parent.captured(self.selected)

    def capture(self, point, button):
        """ Capture id of feature selected by the selector tool
        """
        # check that capturing has been enabled
        if self.capturing:
            point_geometry = QgsGeometry.fromPoint(point)
            point_buffer = point_geometry.buffer(
                (self.iface.mapCanvas().mapUnitsPerPixel() * 4), 0)
            point_rectangle = point_buffer.boundingBox()
            self.layer.invertSelectionInRectangle(point_rectangle)
            if bool(self.layer.selectedFeaturesIds()):
                for id in self.layer.selectedFeaturesIds():
                    if id not in self.selected:
                        self.selected.append(id)
                selected = self.selected
                for id in selected:
                    if id not in self.layer.selectedFeaturesIds():
                        self.selected.remove(id)
                self.parent.captured(self.selected)

            # self.layer.select([], point_rectangle, True, True)
            # feat = QgsFeature()
            # while self.layer.nextFeature(feat):
            #     self.append_selection(feat.id())
            #     break
