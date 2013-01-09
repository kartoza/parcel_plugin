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
from ui_beaconForm import Ui_dlg_beaconForm
from ui_beaconRemover import Ui_dlg_beaconRemover
# Plugin imports
import database

# ========== ========== ==========
# ========== Main Class ==========
# ========== ========== ==========

class controller():
    """ Class responsible for managing beacons
    """
    
    def __init__(self, objectName, iface, layers):
        self.objectName = objectName
        self.iface = iface
        self.layers = layers

    def run(self):
        # get management option
        dlg = ui_manager(self.objectName)
        dlg.show()
        dlg.exec_()
        option = dlg.option
        # execute management option
        if option == 0: self.createPoint()
        elif option == 1: self.editPoint()
        elif option == 2: self.deletePoint()

    def createPoint(self):
        """ Create new point
        """
        #dlg = ui_form()
        #dlg.show()
        #dlg.exec_()
        pass

    def editPoint(self):
        """ Edit existing point
        """
        QMessageBox.information(None, "Construction", "Under Construction!")
        pass

    def deletePoint(self):
        """ Delete existing point
        """
        #dlg = ui_remover(self.iface, self.layers["beacons"])
        #dlg.show()
        #dlg.exec_()
        #self.iface.mapCanvas().setMapTool(dlg.oldTool)
        #self.layers["beacons"].removeSelection()


# ========== ============ ==========
# ========== UI Handelers ==========
# ========== ============ ==========

class ui_manager(QDialog):
    """ Retrieve option for managing points
    0. Create New Point
    1. Edit Existing Point
    2. Delete Existing Point
    """

    def __init__(self, objectName):
        # initialize dialog
        QDialog.__init__(self)
        self.ui = ui_dlg_objectManager()
        self.ui.setupUi(self, objectName)
        # save option reference
        self.option = -1
        # add event signal to initialized dialog
        self.connect(self.ui.btnbx_options, SIGNAL("clicked(QAbstractButton*)"), self.executeOption)
        # blackout during development
        self.ui.rdbtn_add.setEnabled(False)
        self.ui.rdbtn_edit.setEnabled(False)
        self.ui.rdbtn_del.setEnabled(False)

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

# unchecked

class ui_form(QDialog):

    def __init__(self):
        # initialize dialog
        QDialog.__init__(self, None, Qt.WindowStaysOnTopHint)
        self.ui = Ui_dlg_beaconForm()
        self.ui.setupUi(self)
        # save other references
        self.dbmanager = database.dbmanager()
        # add event signals to initialized dialog
        self.connect(self.ui.btnbx_options, SIGNAL("clicked(QAbstractButton*)"), self.executeOption)
        # color coding stuffs
        self.colours = {
            "empty":"background-color: rgba(255, 107, 107, 150);",
            "invalid":"background-color: rgba(107, 107, 255, 150);"
        }
    
    def executeOption(self, button):
        """ Check and execute selected option
        """
        if self.ui.btnbx_options.standardButton(button) == QDialogButtonBox.Save:
            # form validation
            valid = False
            try:
                # check required fields
                valid = True
                for wdgt in self.findChildren(QLineEdit):
                    if bool(wdgt.property("required").toBool()):
                        if str(wdgt.text()).strip() is "":
                            wdgt.setStyleSheet(self.colours["empty"])
                            valid = False
                        else: wdgt.setStyleSheet("")
                if not valid: raise Exception("Empty Required Fields", "Please ensure that all required fields are completed.") 
                # check correct field types
                valid = True
                for wdgt in self.findChildren(QLineEdit):
                    try:
                        cast = str(wdgt.property("type").toString())
                        if cast == "double": float(wdgt.text())
                    except ValueError:
                        wdgt.setStyleSheet(self.colours["invalid"])
                        valid = False
                if not valid: raise Exception("Invalid Field Types", "Please ensure that fields are completed with valid types.")
                valid = True
            except Exception as e:
                title, msg = e.args
                QMessageBox.information(None, title, msg)
            if valid:
                # construct query
                data = {}
                for wdgt in self.findChildren(QLineEdit):
                    if str(wdgt.text()) != "":
                        data[str(wdgt.property("db_field").toString())] = (lambda s,t: "'%s'"%(s,) if t == "string" else "%s"%(s,))(str(wdgt.text()), str(wdgt.property("type").toString()))
                sql = "INSERT INTO beacons({fields}) VALUES({values})".format(fields = ", ".join(sorted(data.keys())), values = ", ".join([data[i] for i in sorted(data.keys())]))
                # execute query
                self.dbmanager.query(sql)
                self.accept()
        else:
            self.reject()

class ui_remover(QDialog):

    def __init__(self, iface, layer):
        # initialize dialog
        QDialog.__init__(self, None, Qt.WindowStaysOnTopHint)
        self.ui = Ui_dlg_beaconRemover()
        self.ui.setupUi(self)
        # save additional qgis references
        self.iface = iface
        self.layer = layer
        # clear selections
        self.layer.removeSelection()
        # save other references
        self.dbmanager = database.dbmanager()
        self.beacon_id = None
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

    def executeOption(self, button):
        """ Check and execute selected option
        """
        if self.ui.btnbx_options.standardButton(button) == QDialogButtonBox.Ok:
            valid = False
            try:
                # check that a parcel has been selected
                if self.beacon_id is None: raise Exception("No Beacon Selected", "Please select a beacon.")
                # check confirmation
                if not self.confirmed: raise Exception("No Confirmation", "Please tick the confimation check box.")
                valid = True
            except Exception as e:
                title, msg = e.args
                QMessageBox.information(None, title, msg)
            if valid:
                # construct query
                sql = "DELETE FROM beacons WHERE beacon = '{beacon_id}';".format(beacon_id = self.beacon_id)
                # execute query
                self.dbmanager.query(sql)
                self.iface.mapCanvas().setMapTool(self.oldTool)
                self.layer.removeSelection()
                self.accept()

        else: 
            self.iface.mapCanvas().setMapTool(self.oldTool)
            self.layer.removeSelection()
            self.reject()

    def capture(self, point, button):
        # check capturing status
        if self.capturing:
            # check active layer
            curlyr = self.iface.activeLayer()
            if curlyr != self.layer:
                QMessageBox.information(None, "Incorrect Selection Layer", "Please select the 'Beacons' vector layer.")
                return 
            # get selected feature
            pnt_geom = QgsGeometry.fromPoint(point)
            pnt_buffer = pnt_geom.buffer((self.iface.mapCanvas().mapUnitsPerPixel()*3),0)
            pnt_rect = pnt_buffer.boundingBox()
            curlyr.select([], pnt_rect)
            feat = QgsFeature()
            while curlyr.nextFeature(feat):
                self.beacon_id = self.dbmanager.query("SELECT beacon FROM beacons WHERE gid = {id};".format(id = feat.id()))[0][0]
                curlyr.setSelectedFeatures([feat.id(),])
                self.ui.lnedt_beaconId.setText(self.beacon_id)
                self.capturing = False
                # perform button stuffs
                self.ui.pshbtn_re.setEnabled(True)
                self.ui.chkbx_confirm.setEnabled(True)
        
    def reselect(self):
        """ Re-enable capturing
        """
        self.ui.pshbtn_re.setEnabled(False)
        self.ui.chkbx_confirm.setEnabled(False)
        self.ui.lnedt_beaconId.setText("")
        self.layer.removeSelection()
        self.beacon_id = None
        self.capturing = True


    def confirm(self, state):
        """ Change deletion confirmation state
        """
        self.ui.pshbtn_re.setEnabled(not bool(state))
        self.confirmed = bool(state)
