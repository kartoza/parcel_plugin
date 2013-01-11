# -*- coding: utf-8 -*-
"""
Author: Robert Moerman
Contact: robert@afrispatial.co.za
Company: AfriSpatial

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
"""
# PyQt and QGIS imports
from PyQt4.QtGui import *
from PyQt4.QtCore import *
from qgis.gui import *
from qgis.core import *
# UI imports
from ui_objectManager import ui_dlg_objectManager
from ui_polygonForm import ui_dlg_polygonForm
from ui_objectSelector import ui_dlg_objectSelector
# Plugin imports
import database
import points

# ========== ========== ==========
# ========== Main Class ==========
# ========== ========== ==========

class controller():
    """ Class responsible for managing points
    """
    
    # checked
    def __init__(self, polygonDict, pointDict, iface, layers):
        self.polygonDict = polygonDict
        self.pointDict = pointDict
        self.iface = iface
        self.layers = layers
    
    # checked
    def run(self):
        # get management option
        dlg = ui_manager(self.polygonDict)
        dlg.show()
        dlg.exec_()
        option = dlg.option
        # execute management option
        if option == 0: self.createPolygon()
        elif option == 1: self.editPolygon()
        elif option == 2: self.deletePolygon()

    # checked
    def createPolygon(self):
        """ Create new polygon
        """
        dlg = ui_form(self.polygonDict, self.pointDict, self.iface, self.layers["points"])
        dlg.show()
        dlg.exec_()
        self.iface.mapCanvas().setMapTool(dlg.oldTool)
        self.layers["points"].removeSelection()

    def editPolygon(self):
        """ Edit existing polygon
        """
        dlg_sel = ui_editor(self.polygonDict, self.pointDict, self.iface, self.layers["polygons"])
        dlg_sel.show()
        dlg_sel.exec_()
        # display edit form
        dlg = ui_form(self.polygonDict, self.pointDict, self.iface, self.layers["points"], dlg_sel.points, dlg_sel.polygon_id, False, "update")
        dlg.show()
        dlg.exec_()
        self.iface.mapCanvas().setMapTool(dlg_sel.oldTool)
        self.layers["polygons"].removeSelection()
    
    # checked
    def deletePolygon(self):
        """ Delete existing polygon
        """
        dlg = ui_remover(self.polygonDict, self.iface, self.layers["polygons"])
        dlg.show()
        dlg.exec_()
        self.iface.mapCanvas().setMapTool(dlg.oldTool)
        self.layers["polygons"].removeSelection()

# ========== ============ ==========
# ========== UI Handelers ==========
# ========== ============ ==========

# checked
class ui_manager(QDialog):
    """ Retrieve option for managing polygons
    0. Create New Polygon
    1. Edit Existing Polygon
    2. Delete Existing Polygon
    """
    
    # checked
    def __init__(self, polygonDict):
        # initialize dialog
        QDialog.__init__(self)
        self.ui = ui_dlg_objectManager()
        self.ui.setupUi(self, polygonDict["name"])
        # save option reference
        self.option = -1
        # add event signal to initialized dialog
        self.connect(self.ui.btnbx_options, SIGNAL("clicked(QAbstractButton*)"), self.executeOption)

    # checked
    def executeOption(self, button):
        """ Check and execute selected option
        """
        if self.ui.btnbx_options.standardButton(button) == QDialogButtonBox.Ok:
            for i, rdbtn in enumerate(self.findChildren(QRadioButton)): 
                if rdbtn.isChecked(): 
                    self.option = i
                    break
            if self.option is not -1: QDialog.accept(self)
            else: QMessageBox.information(None, "Invalid Selection", "Please select an option before clicking OK")
        else:
            QDialog.reject(self)

# checked
class ui_form(QDialog):
    
    # checked
    def __init__(self, polygonDict, pointDict, iface, layer, selected = None, polygon_id = None, reshow = False, mode = "insert"):
        # initialize dialog
        QDialog.__init__(self, None, Qt.WindowStaysOnTopHint)
        self.ui = ui_dlg_polygonForm()
        self.ui.setupUi(self, polygonDict["name"], pointDict["name"])
        # save additional qgis references
        self.polygonDict = polygonDict
        self.pointDict = pointDict
        self.mode = mode
        self.iface = iface
        self.layer = layer
        # clear selections
        self.layer.removeSelection()
        # save other references
        self.dbmanager = database.dbmanager()
        self.capturing = False
        self.sequence = []
        self.selected = []
        # load custom tool
        self.oldTool = self.iface.mapCanvas().mapTool()
        self.newTool = QgsMapToolEmitPoint(self.iface.mapCanvas())
        QObject.connect( self.newTool, SIGNAL("canvasClicked(const QgsPoint, Qt::MouseButton)"), self.capture)
        self.iface.mapCanvas().setMapTool(self.newTool)
        # add event signals to initialized dialog
        self.connect(self.ui.pshbtn_new, SIGNAL("clicked()"), self.newPoint)
        self.connect(self.ui.pshbtn_start, SIGNAL("clicked()"), self.startSeq)
        self.connect(self.ui.pshbtn_stop, SIGNAL("clicked()"), self.stopSeq)
        self.connect(self.ui.pshbtn_reset, SIGNAL("clicked()"), self.resetSeq)
        self.connect(self.ui.btnbx_options, SIGNAL("clicked(QAbstractButton*)"), self.executeOption)
        # disable buttons
        self.ui.pshbtn_stop.setEnabled(False)
        self.ui.pshbtn_reset.setEnabled(False)
        self.ui.pshbtn_new.setEnabled(False)
        # add autocomplete functionality
        model = QStringListModel()
        model.setStringList([i[0] for i in self.dbmanager.query(self.polygonDict["sql"]["autocomplete"])])
        completer = QCompleter()        
        completer.setCaseSensitivity(Qt.CaseInsensitive)
        completer.setModel(model)
        self.ui.lnedt_polygonID.setCompleter(completer)
        # populate dialog if necessary
        if bool(selected):
            self.selected = selected
            for id in self.selected:
                point_id = str(self.dbmanager.query(self.pointDict["sql"]["select"].format(id = id))[0][0])
                self.sequence.append(point_id)
                self.ui.lstwdg_sequence.addItem(QString(point_id))
            self.layer.setSelectedFeatures(self.selected)
        if reshow: self.startSeq()
        if bool(polygon_id):
            self.ui.lnedt_polygonID.setText(str(polygon_id))
        if self.mode == "update": self.old_polygon_id = polygon_id
    
    # checked
    def executeOption(self, button):
        """ Check and execute selected option
        """
        if self.ui.btnbx_options.standardButton(button) == QDialogButtonBox.Save:
            valid = True
            polygon_id = str(self.ui.lnedt_polygonID.text()).strip()
            try:    
                # check that polygon id exists
                if polygon_id is "": raise Exception("Invalid %s ID" %(self.polygonDict["name"],), "Please enter a %s ID." %(self.polygonDict["name"],))
                # check that polygon id is valid
                unique = not bool(self.dbmanager.query(self.polygonDict["sql"]["unique"].format(object_id = polygon_id))[0][0])
                if unique:
                    # confirm new polygon id
                    reply = QMessageBox.question(None, 'Confirm New %s ID' %(self.polygonDict["name"],), "Are you sure you want to create a new %s ID?" %(self.polygonDict["name"],), QMessageBox.Yes, QMessageBox.No)
                    if reply == QMessageBox.No:
                        valid = False
                else:
                    # check old polygon id
                    available = bool(self.dbmanager.query(self.polygonDict["sql"]["available"].format(object_id = polygon_id))[0][0])
                    if not available: raise Exception("Duplicated %s ID" %(self.polygonDict["name"],), "Please enter a unique or available %s ID." %(self.polygonDict["name"],))
                # check that at least 3 points exist within the sequence
                if len(self.sequence) < 3: raise Exception("Too Few %s" %(self.pointDict["name_plural"],), "Please ensure that there are at least 3 %s listed in the sequence." %(self.pointDict["name_plural"].lower(),))
            except Exception as e:
                valid = False
                title, msg = e.args
                QMessageBox.information(None, title, msg)
            if valid:
                if self.mode == "update": self.dbmanager.query(self.polygonDict["sql"]["delete"].format(object_id = self.old_polygon_id))     
                self.dbmanager.query(" ".join([self.polygonDict["sql"]["insert"].format(polygon_id = polygon_id, point_id = point_id, sequence = self.sequence.index(point_id) + 1) for point_id in self.sequence]))
                self.iface.mapCanvas().setMapTool(self.oldTool)
                self.layer.removeSelection()
                self.accept()
        else:
            self.iface.mapCanvas().setMapTool(self.oldTool)
            self.layer.removeSelection()
            self.reject()
    
    # checked
    def capture(self, point, button):
        """ Perform sequence capture
        """
        # check capturing status
        if self.capturing:
            # check active layer
            curlyr = self.iface.activeLayer()
            if curlyr != self.layer:
                QMessageBox.information(None, "Incorrect Selection Layer", "Please select the '%s' vector layer." %(self.layer.name(),))
                return 
            # add selected feature to list of selected features
            pnt_geom = QgsGeometry.fromPoint(point)
            pnt_buffer = pnt_geom.buffer((self.iface.mapCanvas().mapUnitsPerPixel()*3),0)
            pnt_rect = pnt_buffer.boundingBox()
            curlyr.select([], pnt_rect)
            feat = QgsFeature()
            while curlyr.nextFeature(feat):
                point_id = str(self.dbmanager.query(self.pointDict["sql"]["select"].format(id = feat.id()))[0][0])
                if feat.id() in self.selected: 
                    # remove selection                    
                    index = self.selected.index(feat.id())
                    del self.selected[index]
                    tmp = self.ui.lstwdg_sequence.takeItem(index)
                    tmp = None
                    del self.sequence[index]
                else: 
                    # add selection
                    self.sequence.append(point_id)
                    self.ui.lstwdg_sequence.addItem(QString(point_id))
                    self.selected.append(feat.id())
            curlyr.setSelectedFeatures(self.selected)

    # checked
    def newPoint(self):
        if self.capturing:
            pos = self.pos()
            # hide polygon dialog
            self.hide()
            # show point dialog 
            pntdlg = points.ui_form(self.pointDict)
            pntdlg.show()
            pntdlg.exec_()
            # show polygon dialog
            plydlg = ui_form(self.polygonDict, self.pointDict, self.iface, self.layer, (lambda selected, point: selected + [point] if point is not None else selected)(self.selected, pntdlg.point_id), (lambda s: s if bool(s) else None)(str(self.ui.lnedt_polygonID.text())), True)
            plydlg.move(pos)            
            plydlg.show()
            plydlg.exec_()
            self.iface.mapCanvas().setMapTool(plydlg.oldTool)
            self.layer.removeSelection()

    # checked
    def startSeq(self):
        """ Start sequence capturing
        """
        # enable capturing
        self.capturing = True
        # perform button stuffs
        self.ui.pshbtn_start.setEnabled(False)
        self.ui.pshbtn_reset.setEnabled(False)
        self.ui.pshbtn_stop.setEnabled(True)
        self.ui.pshbtn_new.setEnabled(True)
    
    # checked
    def stopSeq(self):
        """ Stop sequence capturing
        """
        # disable capturing
        self.capturing = False
        # perform button stuffs
        self.ui.pshbtn_stop.setEnabled(False)
        self.ui.pshbtn_start.setEnabled(True)
        self.ui.pshbtn_reset.setEnabled(True)
        self.ui.pshbtn_new.setEnabled(False)
    
    # checked
    def resetSeq(self):
        """ Reset captured sequence
        """
        # clear selection
        self.layer.removeSelection()
        # clear sequence
        for i in range(len(self.sequence) -1, -1, -1):
            tmp = self.ui.lstwdg_sequence.takeItem(i)
            tmp = None
        self.sequence = []
        self.selected = []
        # perform button stuffs
        self.ui.pshbtn_reset.setEnabled(False)
        self.ui.pshbtn_start.setEnabled(True)

class ui_editor(QDialog):

    # checked
    def __init__(self, polygonDict, pointDict, iface, layer):
        # initialize dialog
        QDialog.__init__(self, None, Qt.WindowStaysOnTopHint)
        self.ui = ui_dlg_objectSelector()
        self.ui.setupUi(self, polygonDict["name"], "Editor", "edit")
        # save additional qgis references
        self.polygonDict = polygonDict
        self.pointDict = pointDict
        self.iface = iface
        self.layer = layer
        # clear selections
        self.layer.removeSelection()
        # save other references
        self.dbmanager = database.dbmanager()
        self.polygon_id = None
        self.capturing = True
        self.confirmed = False
        # load custom tool
        self.oldTool = self.iface.mapCanvas().mapTool()
        self.newTool = QgsMapToolEmitPoint(self.iface.mapCanvas())
        QObject.connect( self.newTool, SIGNAL("canvasClicked(const QgsPoint, Qt::MouseButton)"), self.capture)
        self.iface.mapCanvas().setMapTool(self.newTool)
        # add event signals to initialized dialog
        self.connect(self.ui.pshbtn_re, SIGNAL("clicked()"), self.reselect)
        self.connect(self.ui.chkbx_confirm, SIGNAL('stateChanged(int)'), self.confirm)
        self.connect(self.ui.btnbx_options, SIGNAL("clicked(QAbstractButton*)"), self.executeOption)
        # disable buttons
        self.ui.pshbtn_re.setEnabled(False)
        self.ui.chkbx_confirm.setEnabled(False)
    
    # checked
    def executeOption(self, button):
        """ Check and execute selected option
        """
        if self.ui.btnbx_options.standardButton(button) == QDialogButtonBox.Ok:
            valid = False
            try:
                # check that a polygon has been selected
                if self.polygon_id is None: raise Exception("No %s Selected" %(self.polygonDict["name"],), "Please select a %s." %(self.polygonDict["name"].lower(),))
                # check confirmation
                if not self.confirmed: raise Exception("No Confirmation", "Please tick the confimation check box.")
                valid = True
            except Exception as e:
                title, msg = e.args
                QMessageBox.information(None, title, msg)
            if valid:
                # get information for edit form
                self.points = [p[0] for p in self.dbmanager.query(self.polygonDict["sql"]["edit"].format(object_id = self.polygon_id))]
                self.accept()
        else: 
            self.iface.mapCanvas().setMapTool(self.oldTool)
            self.layer.removeSelection()
            self.reject()
    
    # checked
    def capture(self, point, button):
        # check capturing status
        if self.capturing:
            # check active layer
            curlyr = self.iface.activeLayer()
            if curlyr != self.layer:
                QMessageBox.information(None, "Incorrect Selection Layer", "Please select the '%s' vector layer." %(self.layer.name(),))
                return 
            # get selected feature
            pnt_geom = QgsGeometry.fromPoint(point)
            pnt_buffer = pnt_geom.buffer((self.iface.mapCanvas().mapUnitsPerPixel()*3),0)
            pnt_rect = pnt_buffer.boundingBox()
            curlyr.select([], pnt_rect)
            feat = QgsFeature()
            while curlyr.nextFeature(feat):
                self.polygon_id = str(self.dbmanager.query(self.polygonDict["sql"]["select"].format(id = feat.id()))[0][0])
                curlyr.setSelectedFeatures([feat.id(),])
                self.ui.lnedt_objectID.setText(self.polygon_id)
                self.capturing = False
                # perform button stuffs
                self.ui.pshbtn_re.setEnabled(True)
                self.ui.chkbx_confirm.setEnabled(True)
        
    # checked    
    def reselect(self):
        """ Re-enable capturing
        """
        self.ui.pshbtn_re.setEnabled(False)
        self.ui.chkbx_confirm.setEnabled(False)
        self.ui.lnedt_objectID.setText("")
        self.layer.removeSelection()
        self.polygon_id = None
        self.capturing = True

    # checked
    def confirm(self, state): 
        """ Change deletion confirmation state
        """
        self.ui.pshbtn_re.setEnabled(not bool(state))
        self.confirmed = bool(state)

# checked
class ui_remover(QDialog):
    
    # checked
    def __init__(self, polygonDict, iface, layer):
        # initialize dialog
        QDialog.__init__(self, None, Qt.WindowStaysOnTopHint)
        self.ui = ui_dlg_objectSelector()
        self.ui.setupUi(self, polygonDict["name"], "Remover", "delete")
        # save additional qgis references
        self.polygonDict = polygonDict
        self.iface = iface
        self.layer = layer
        # clear selections
        self.layer.removeSelection()
        # save other references
        self.dbmanager = database.dbmanager()
        self.polygon_id = None
        self.capturing = True
        self.confirmed = False
        # load custom tool
        self.oldTool = self.iface.mapCanvas().mapTool()
        self.newTool = QgsMapToolEmitPoint(self.iface.mapCanvas())
        QObject.connect( self.newTool, SIGNAL("canvasClicked(const QgsPoint, Qt::MouseButton)"), self.capture)
        self.iface.mapCanvas().setMapTool(self.newTool)
        # add event signals to initialized dialog
        self.connect(self.ui.pshbtn_re, SIGNAL("clicked()"), self.reselect)
        self.connect(self.ui.chkbx_confirm, SIGNAL('stateChanged(int)'), self.confirm)
        self.connect(self.ui.btnbx_options, SIGNAL("clicked(QAbstractButton*)"), self.executeOption)
        # disable buttons
        self.ui.pshbtn_re.setEnabled(False)
        self.ui.chkbx_confirm.setEnabled(False)
    
    # checked
    def executeOption(self, button):
        """ Check and execute selected option
        """
        if self.ui.btnbx_options.standardButton(button) == QDialogButtonBox.Ok:
            valid = False
            try:
                # check that a polygon has been selected
                if self.polygon_id is None: raise Exception("No %s Selected" %(self.polygonDict["name"],), "Please select a %s." %(self.polygonDict["name"].lower(),))
                # check confirmation
                if not self.confirmed: raise Exception("No Confirmation", "Please tick the confimation check box.")
                valid = True
            except Exception as e:
                title, msg = e.args
                QMessageBox.information(None, title, msg)
            if valid:
                # construct query
                sql = self.polygonDict["sql"]["delete"].format(object_id = self.polygon_id)
                # execute query
                self.dbmanager.query(sql)
                self.iface.mapCanvas().setMapTool(self.oldTool)
                self.layer.removeSelection()
                self.accept()

        else: 
            self.iface.mapCanvas().setMapTool(self.oldTool)
            self.layer.removeSelection()
            self.reject()
    
    # checked
    def capture(self, point, button):
        # check capturing status
        if self.capturing:
            # check active layer
            curlyr = self.iface.activeLayer()
            if curlyr != self.layer:
                QMessageBox.information(None, "Incorrect Selection Layer", "Please select the '%s' vector layer." %(self.layer.name(),))
                return 
            # get selected feature
            pnt_geom = QgsGeometry.fromPoint(point)
            pnt_buffer = pnt_geom.buffer((self.iface.mapCanvas().mapUnitsPerPixel()*3),0)
            pnt_rect = pnt_buffer.boundingBox()
            curlyr.select([], pnt_rect)
            feat = QgsFeature()
            while curlyr.nextFeature(feat):
                self.polygon_id = str(self.dbmanager.query(self.polygonDict["sql"]["select"].format(id = feat.id()))[0][0])
                curlyr.setSelectedFeatures([feat.id(),])
                self.ui.lnedt_objectID.setText(self.polygon_id)
                self.capturing = False
                # perform button stuffs
                self.ui.pshbtn_re.setEnabled(True)
                self.ui.chkbx_confirm.setEnabled(True)
        
    # checked    
    def reselect(self):
        """ Re-enable capturing
        """
        self.ui.pshbtn_re.setEnabled(False)
        self.ui.chkbx_confirm.setEnabled(False)
        self.ui.lnedt_objectID.setText("")
        self.layer.removeSelection()
        self.polygon_id = None
        self.capturing = True

    # checked
    def confirm(self, state): 
        """ Change deletion confirmation state
        """
        self.ui.pshbtn_re.setEnabled(not bool(state))
        self.confirmed = bool(state)
