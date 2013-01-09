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
from ui_pointForm import ui_dlg_pointForm
from ui_objectRemover import ui_dlg_objectRemover
# Plugin imports
import database

# ========== ========== ==========
# ========== Main Class ==========
# ========== ========== ==========

class controller():
    """ Class responsible for managing beacons
    """
    
    # checked
    def __init__(self, pointDict, iface, layers):
        self.pointDict = pointDict
        self.iface = iface
        self.layers = layers
    
    # checked
    def run(self):
        # get management option
        dlg = ui_manager(self.pointDict)
        dlg.show()
        dlg.exec_()
        option = dlg.option
        # execute management option
        if option == 0: self.createPoint()
        elif option == 1: self.editPoint()
        elif option == 2: self.deletePoint()

    # checked
    def createPoint(self):
        """ Create new point
        """
        dlg = ui_form(self.pointDict)
        dlg.show()
        dlg.exec_()
        
    def editPoint(self):
        """ Edit existing point
        """
        QMessageBox.information(None, "Construction", "Under Construction!")
        pass

    # checked
    def deletePoint(self):
        """ Delete existing point
        """
        dlg = ui_remover(self.pointDict, self.iface, self.layers["points"])
        dlg.show()
        dlg.exec_()
        self.iface.mapCanvas().setMapTool(dlg.oldTool)
        self.layers["points"].removeSelection()


# ========== ============ ==========
# ========== UI Handelers ==========
# ========== ============ ==========

# checked
class ui_manager(QDialog):
    """ Retrieve option for managing points
    0. Create New Point
    1. Edit Existing Point
    2. Delete Existing Point
    """

    # checked
    def __init__(self, pointDict):
        # initialize dialog
        QDialog.__init__(self)
        self.ui = ui_dlg_objectManager()
        self.ui.setupUi(self, pointDict["name"])
        # save option reference
        self.option = -1
        # add event signal to initialized dialog
        self.connect(self.ui.btnbx_options, SIGNAL("clicked(QAbstractButton*)"), self.executeOption)
        # blackout during development
        self.ui.rdbtn_edit.setEnabled(False)
    
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
    def __init__(self, pointDict):
        # initialize dialog
        QDialog.__init__(self, None, Qt.WindowStaysOnTopHint)
        # save other references
        self.pointDict = pointDict
        self.dbmanager = database.dbmanager()
        self.pointFields = self.dbmanager.getSchema(pointDict["table"], [pointDict["the_geom"], pointDict["pkey"]])
        # initialize dialog
        self.ui = ui_dlg_pointForm()
        self.ui.setupUi(self, self.pointFields)
        # add event signals to initialized dialog
        self.connect(self.ui.btnbx_options, SIGNAL("clicked(QAbstractButton*)"), self.executeOption)
        # color coding stuffs
        self.colours = {
            "empty":"background-color: rgba(255, 107, 107, 150);",
            "invalid":"background-color: rgba(107, 107, 255, 150);"
        }
    
    # checked
    def executeOption(self, button):
        """ Check and execute selected option
        """
        if self.ui.btnbx_options.standardButton(button) == QDialogButtonBox.Save:
            data = {}
            # form validation
            valid = False
            try:
                # check required fields
                valid = True
                for lnedt in self.ui.lnedts:
                    if bool(lnedt.property("required").toBool()):
                        if str(lnedt.text()).strip() is "":
                            lnedt.setStyleSheet(self.colours["empty"])
                            valid = False
                        else: lnedt.setStyleSheet("")
                if not valid: raise Exception("Empty Required Fields", "Please ensure that all required fields are completed.") 
                # check correct field types
                valid = True
                for index,lnedt in enumerate(self.ui.lnedts):
                    try:
                        if str(lnedt.text()).strip() is not "":
                            cast = self.pointFields[index]["type"]
                            tmp = cast(str(lnedt.text()))
                            data[self.pointFields[index]["name"]] = tmp
                            lnedt.setStyleSheet("")
                    except Exception as e:
                        lnedt.setStyleSheet(self.colours["invalid"])
                        valid = False
                if not valid: raise Exception("Invalid Field Types", "Please ensure that fields are completed with valid types.")
                valid = True
            except Exception as e:
                title, msg = e.args
                QMessageBox.information(None, title, msg)
            if valid:
                # construct query
                sql = self.pointDict["sql"]["insert"].format(fields = ", ".join(sorted(data.keys())), values = ", ".join(["%s" for i in sorted(data.keys())]))
                # execute query
                self.dbmanager.query(sql, [data[k] for k in sorted(data.keys())])
                self.accept()
        else:
            self.reject()

# checked
class ui_remover(QDialog):
    
    # checked
    def __init__(self, pointDict, iface, layer):
        # initialize dialog
        QDialog.__init__(self, None, Qt.WindowStaysOnTopHint)
        self.ui = ui_dlg_objectRemover()
        self.ui.setupUi(self, pointDict["name"])
        # save additional qgis references
        self.pointDict = pointDict
        self.iface = iface
        self.layer = layer
        # clear selections
        self.layer.removeSelection()
        # save other references
        self.dbmanager = database.dbmanager()
        self.point_id = None
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

    # check
    def executeOption(self, button):
        """ Check and execute selected option
        """
        if self.ui.btnbx_options.standardButton(button) == QDialogButtonBox.Ok:
            valid = False
            try:
                # check that a point has been selected
                if self.point_id is None: raise Exception("No %s Selected" %(self.pointDict["name"],), "Please select a %s." %(self.pointDict["name"].lower(),))
                # check confirmation
                if not self.confirmed: raise Exception("No Confirmation", "Please tick the confimation check box.")
                valid = True
            except Exception as e:
                title, msg = e.args
                QMessageBox.information(None, title, msg)
            if valid:
                # construct query
                sql = self.pointDict["sql"]["delete"].format(object_id = self.point_id)
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
                self.point_id = str(self.dbmanager.query(self.pointDict["sql"]["select"].format(id = feat.id()))[0][0])
                curlyr.setSelectedFeatures([feat.id(),])
                self.ui.lnedt_objectID.setText(self.point_id)
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
        self.point_id = None
        self.capturing = True

    # checked
    def confirm(self, state):
        """ Change deletion confirmation state
        """
        self.ui.pshbtn_re.setEnabled(not bool(state))
        self.confirmed = bool(state)
