# -*- coding: utf-8 -*-
"""
Author: Robert Moerman
Contact: robert@afrispatial.co.za
Company: AfriSpatial

This is a collection of custom QDialogs.

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
from qgis.core import *
from qgisToolbox import *
from database import *

try:
    _fromUtf8 = QString.fromUtf8
except AttributeError:
    _fromUtf8 = lambda s: s

# All dialogs using selector tool have a captured function
# All dialogs have a getReturn function

class dlg_Selector(QDialog):

    def __init__(self, db, iface, layer, query, obj={"NAME":"NONAME", "PURPOSE":"NOPURPOSE", "ACTION":"NOACTION"}, preserve = False, parent = None):
        super(dlg_Selector, self).__init__(parent, Qt.WindowStaysOnTopHint)
        self.setupUi(obj)
        self.db = db
        self.iface = iface
        self.layer = layer
        self.query = query
        self.obj = obj
        self.preserve = preserve
        self.confirmed = False
        self.featID = None
        self.selector = featureSelector(iface, layer, True, self)
        self.tool = self.selector.parentTool
    
    def getReturn(self):
        return self.featID

    def executeOption(self, button):
        if self.btnbx_options.standardButton(button) == QDialogButtonBox.Ok:
            # check that a feature has been selected
            if self.featID is None: 
                QMessageBox.information(self, "No %s Selected" %(self.obj["NAME"].title(),), "Please select a %s." %(self.obj["NAME"].lower(),))
                return
            # check confirmation
            if not self.confirmed: 
                QMessageBox.information(self, "No Confirmation", "Please tick the confimation check box.")
                return
            self.iface.mapCanvas().setMapTool(self.tool)
            if not self.preserve: self.layer.removeSelection()
            self.accept()
        else: 
            self.iface.mapCanvas().setMapTool(self.tool)
            self.layer.removeSelection()
            self.reject()
    
    def captured(self, selected):
        self.selector.disableCapturing()
        self.featID = selected[0]
        self.lnedt_featID.setText(str(self.db.query(self.query["SELECT"], (self.featID,))[0][0]))
        self.pshbtn_re.setEnabled(True)
        self.chkbx_confirm.setEnabled(True)
        
    def reselect(self):
        self.pshbtn_re.setEnabled(False)
        self.chkbx_confirm.setEnabled(False)
        self.lnedt_featID.setText("")
        self.featID = None
        self.selector.clearSelection()
        self.selector.enableCapturing()

    def confirm(self, state): 
        self.pshbtn_re.setEnabled(not bool(state))
        self.confirmed = bool(state)

    def setupUi(self, obj):
        # define ui widgets
        self.setObjectName(_fromUtf8("dlg_Selector"))
        self.setCursor(QCursor(Qt.PointingHandCursor))
        self.gridLayout = QGridLayout(self)
        self.gridLayout.setSizeConstraint(QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.verticalLayout = QVBoxLayout()
        self.verticalLayout.setObjectName(_fromUtf8("verticalLayout"))
        self.splitter = QSplitter(self)
        self.splitter.setOrientation(Qt.Horizontal)
        self.splitter.setObjectName(_fromUtf8("splitter"))
        self.widget = QWidget(self.splitter)
        self.widget.setObjectName(_fromUtf8("widget"))
        self.formLayout = QFormLayout(self.widget)
        self.formLayout.setMargin(0)
        self.formLayout.setObjectName(_fromUtf8("formLayout"))
        self.lbl_featID = QLabel(self.widget)
        self.lbl_featID.setObjectName(_fromUtf8("lbl_featID"))
        self.formLayout.setWidget(0, QFormLayout.LabelRole, self.lbl_featID)      
        self.lnedt_featID = QLineEdit(self.widget)
        self.lnedt_featID.setEnabled(False)
        self.lnedt_featID.setObjectName(_fromUtf8("lnedt_featID"))
        self.formLayout.setWidget(0, QFormLayout.FieldRole, self.lnedt_featID)
        self.pshbtn_re = QPushButton(self.splitter)
        self.pshbtn_re.setEnabled(False)
        self.pshbtn_re.setObjectName(_fromUtf8("pshbtn_re"))
        self.verticalLayout.addWidget(self.splitter)
        self.chkbx_confirm = QCheckBox(self)
        self.chkbx_confirm.setEnabled(False)
        self.chkbx_confirm.setObjectName(_fromUtf8("chkbx_confirm"))
        self.verticalLayout.addWidget(self.chkbx_confirm)
        self.btnbx_options = QDialogButtonBox(self)
        self.btnbx_options.setStandardButtons(QDialogButtonBox.Cancel|QDialogButtonBox.Ok)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.verticalLayout.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout, 0, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(QApplication.translate("dlg_Selector", "%s %s" %(obj["NAME"].title(), obj["PURPOSE"].title()), None, QApplication.UnicodeUTF8))
        self.lbl_featID.setText(QApplication.translate("dlg_Selector", "%s ID" %(obj["NAME"].title(),), None, QApplication.UnicodeUTF8))
        self.pshbtn_re.setText(QApplication.translate("dlg_Selector", "Re-select", None, QApplication.UnicodeUTF8))
        self.chkbx_confirm.setText(QApplication.translate("dlg_Selector", "I am sure I want to %s this %s" %(obj["ACTION"].lower(), obj["NAME"].lower()), None, QApplication.UnicodeUTF8))
        # connect ui widgets
        self.pshbtn_re.clicked.connect(self.reselect)
        self.chkbx_confirm.stateChanged.connect(self.confirm)
        self.btnbx_options.clicked.connect(self.executeOption)
        QMetaObject.connectSlotsByName(self)

class dlg_Manager(QDialog):

    def __init__(self, obj={"NAME":"NONAME",}, parent = None):
        super(dlg_Manager, self).__init__(parent, Qt.WindowStaysOnTopHint)
        self.setupUi(obj)
        self.obj = obj
        self.option = None

    def getReturn(self):
        return self.option

    def executeOption(self, button):
        if self.btnbx_options.standardButton(button) == QDialogButtonBox.Ok:
            for i, rdbtn in enumerate(self.findChildren(QRadioButton)): 
                if rdbtn.isChecked(): 
                    self.option = i
                    break
            if self.option is not None: self.accept()
            else: QMessageBox.information(self, "Invalid Selection", "Please select an option before clicking OK")
        else:
            self.reject()
    
    def setupUi(self, obj):
        # define ui widgets
        self.setObjectName(_fromUtf8("dlg_Manager"))
        self.setCursor(QCursor(Qt.PointingHandCursor))
        self.setModal(True)
        self.mainlyt = QGridLayout(self)
        self.mainlyt.setSizeConstraint(QLayout.SetFixedSize)
        self.mainlyt.setObjectName(_fromUtf8("mainlyt"))
        self.vrtlyt = QVBoxLayout()
        self.vrtlyt.setObjectName(_fromUtf8("vrtlyt"))
        self.grdlyt = QGridLayout()
        self.grdlyt.setObjectName(_fromUtf8("grdlyt"))
        self.rdbtn_add = QRadioButton(self)
        self.rdbtn_add.setObjectName(_fromUtf8("rdbtn_add"))
        self.grdlyt.addWidget(self.rdbtn_add, 0, 0, 1, 1)
        self.rdbtn_edit = QRadioButton(self)
        self.rdbtn_edit.setObjectName(_fromUtf8("rdbtn_edit"))
        self.grdlyt.addWidget(self.rdbtn_edit, 1, 0, 1, 1)
        self.rdbtn_del = QRadioButton(self)
        self.rdbtn_del.setObjectName(_fromUtf8("rdbtn_del"))
        self.grdlyt.addWidget(self.rdbtn_del, 2, 0, 1, 1)
        self.vrtlyt.addLayout(self.grdlyt)
        self.btnbx_options = QDialogButtonBox(self)
        self.btnbx_options.setStandardButtons(QDialogButtonBox.Cancel|QDialogButtonBox.Ok)
        self.btnbx_options.setCenterButtons(False)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.vrtlyt.addWidget(self.btnbx_options)
        self.mainlyt.addLayout(self.vrtlyt, 0, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(QApplication.translate("dlg_Manager", "%s Manager" %(obj["NAME"].title(),), None, QApplication.UnicodeUTF8))
        self.rdbtn_add.setText(QApplication.translate("dlg_Manager", "Create New %s" %(obj["NAME"].title(),), None, QApplication.UnicodeUTF8))
        self.rdbtn_edit.setText(QApplication.translate("dlg_Manager", "Edit Existing %s" %(obj["NAME"].title(),), None, QApplication.UnicodeUTF8))
        self.rdbtn_del.setText(QApplication.translate("dlg_Manager", "Delete Existing %s" %(obj["NAME"].title(),), None, QApplication.UnicodeUTF8))
        # connect ui widgets
        self.btnbx_options.clicked.connect(self.executeOption)
        QMetaObject.connectSlotsByName(self)

class dlg_FormPolygon(QDialog):

    def __init__(self, db, iface, layers, layersDict, autocomplete = [], values = {}, parent = None):
        super(dlg_FormPolygon, self).__init__(parent, Qt.WindowStaysOnTopHint)
        self.setupUi(autocomplete, layersDict)
        self.db = db
        self.iface = iface
        self.layers = layers
        self.layersDict = layersDict
        self.autocomplete = autocomplete
        self.values_old = {}
        self.values_new = {}
        self.new_accepted = False
        self.selector = featureSelector(iface, layers["POINTS"], False, self)
        self.tool = self.selector.parentTool
        if bool(values): 
            self.populateForm(values)
            self.pshbtn_reset.setEnabled(True)

    def getReturn(self):
        return (self.values_old, self.values_new)
    
    def populateForm(self, values):
        # get values
        checker = lambda d, v: d[v] if v in d.keys() else None
        feat_id = checker(values, "polygon_id")
        feat_sequence = checker(values, "sequence")
        # use values
        if bool(feat_id): 
            # populate polygon_id
            self.values_old["polygon_id"] = self.db.query(self.layersDict["POLYGONS"]["SQL"]["SELECT"], (feat_id,))[0][0]
            self.lnedt_polygonID.setText(str(self.values_old["polygon_id"]))
            self.highlightFeature(self.layers["POLYGONS"], feat_id)
        if bool(feat_sequence):
            # populate sequence
            self.values_old["sequence"] = []
            for point_id in feat_sequence:
                self.values_old["sequence"].append(self.db.query(self.layersDict["POINTS"]["SQL"]["SELECT"], (point_id,))[0][0])
                self.lstwdg_sequence.addItem(QString(str(self.values_old["sequence"][-1])))
            self.highlightFeatures(self.layers["POINTS"], feat_sequence)
            # update selected
            self.selector.selected = feat_sequence

    def highlightFeature(self, layer, feature):
        self.highlightFeatures(layer, [feature,])

    def highlightFeatures(self, layer, features):
        layer.setSelectedFeatures(features)
            
    def executeOption(self, button):
        if self.btnbx_options.standardButton(button) == QDialogButtonBox.Save:
            polygon_id = str(self.lnedt_polygonID.text()).strip()
            # check that polygon id exists
            if polygon_id == "": 
                QMessageBox.information(self, "Invalid %s ID" %(self.layersDict["POLYGONS"]["NAME"].title(),), "Please enter a %s ID." %(self.layersDict["POLYGONS"]["NAME"].lower(),))
                return
            # check that polygon id is valid (i.e. current, unique, available)
            if "polygon_id" in self.values_old.keys() and self.values_old["polygon_id"] == polygon_id:
                pass
            elif not bool(int(self.db.query(self.layersDict["POLYGONS"]["SQL"]["UNIQUE"], (polygon_id,))[0][0])):
                if not self.new_accepted and QMessageBox.question(self, 'Confirm New %s ID' %(self.layersDict["POLYGONS"]["NAME"].title(),), "Are you sure you want to create a new %s ID?" %(self.layersDict["POLYGONS"]["NAME"].lower(),), QMessageBox.Yes, QMessageBox.No) == QMessageBox.No: 
                    return
                self.new_accepted = True
            else:
                if not bool(self.db.query(self.layersDict["POLYGONS"]["SQL"]["AVAILABLE"], (polygon_id,))[0][0]):
                    QMessageBox.information(self, "Duplicated %s ID" %(self.layersDict["POLYGONS"]["NAME"].title(),), "Please enter a unique or available %s ID." %(self.layersDict["POLYGONS"]["NAME"].lower(),))
                    return
            # check that at least 3 points exist within the sequence
            if len(self.selector.selected) < 3: 
                QMessageBox.information(self, "Too Few %s" %(self.layersDict["POINTS"]["NAME_PLURAL"].title(),), "Please ensure that there are at least 3 %s listed in the sequence." %(self.layersDict["POINTS"]["NAME_PLURAL"].lower(),))
                return
            # save polygon id
            self.values_new["polygon_id"] = polygon_id
            # save sequence
            sequence = []
            for i in self.selector.selected:
                sequence.append(self.db.query(self.layersDict["POINTS"]["SQL"]["SELECT"], (i,))[0][0])
            self.values_new["sequence"] = sequence
            self.iface.mapCanvas().setMapTool(self.tool)
            self.layers["POINTS"].removeSelection()
            self.layers["POLYGONS"].removeSelection()
            self.accept()
        else:
            self.iface.mapCanvas().setMapTool(self.tool)
            self.layers["POINTS"].removeSelection()
            self.layers["POLYGONS"].removeSelection()
            self.reject()

    def captured(self, selected):
        # clear sequence
        self.lstwdg_sequence.clear()
        # create sequence
        for i in selected:
            self.lstwdg_sequence.addItem(QString(str(self.db.query(self.layersDict["POINTS"]["SQL"]["SELECT"], (i,))[0][0]))) 

    def newPoint(self):
        # disable self
        self.setEnabled(False)
        # present point form
        data = self.db.getSchema(self.layersDict["POINTS"]["TABLE"], [self.layersDict["POINTS"]["GEOM"], self.layersDict["POINTS"]["PKEY"]])
        frm = dlg_FormPoint(self.db, data, self.layersDict["POINTS"]["SQL"], parent = self)
        frm.show()
        frm_ret = frm.exec_()
        if bool(frm_ret):
            # save new point
            id = self.db.query(self.layersDict["POINTS"]["SQL"]["INSERT"].format(fields = ", ".join([f["NAME"] for f in data]), values = ", ".join(["%s" for f in data])), [frm.getReturn()[1][f["NAME"]] for f in data])[0][0]
            self.selector.appendSelection(id)
        # enable self
        self.setEnabled(True)

    def startSeq(self):
        """ Start sequence capturing
        """
        # enable capturing
        self.selector.enableCapturing()
        # perform button stuffs
        self.pshbtn_start.setEnabled(False)
        self.pshbtn_reset.setEnabled(False)
        self.pshbtn_stop.setEnabled(True)
        self.pshbtn_new.setEnabled(True)
    
    def stopSeq(self):
        """ Stop sequence capturing
        """
        # disable capturing
        self.selector.disableCapturing()
        # perform button stuffs
        self.pshbtn_stop.setEnabled(False)
        self.pshbtn_start.setEnabled(True)
        self.pshbtn_reset.setEnabled(True)
        self.pshbtn_new.setEnabled(False)
    
    def resetSeq(self):
        """ Reset captured sequence
        """
        # clear selection
        self.selector.clearSelection()
        # clear sequence
        self.lstwdg_sequence.clear()
        # perform button stuffs
        self.pshbtn_reset.setEnabled(False)
        self.pshbtn_start.setEnabled(True)

    def setupUi(self, autocomplete, layersDict):
        # define ui widgets
        self.setObjectName(_fromUtf8("dlg_FormPolygon"))
        self.setCursor(QCursor(Qt.PointingHandCursor))
        self.gridLayout = QGridLayout(self)
        self.gridLayout.setSizeConstraint(QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.verticalLayout_2 = QVBoxLayout()
        self.verticalLayout_2.setObjectName(_fromUtf8("verticalLayout_2"))
        self.formLayout = QFormLayout()
        self.formLayout.setObjectName(_fromUtf8("formLayout"))
        self.lbl_polygonID = QLabel(self)
        self.lbl_polygonID.setObjectName(_fromUtf8("lbl_polygonID"))
        self.formLayout.setWidget(0, QFormLayout.LabelRole, self.lbl_polygonID)
        self.lnedt_polygonID = QLineEdit(self)
        self.lnedt_polygonID.setObjectName(_fromUtf8("lnedt_polygonID"))
        self.formLayout.setWidget(0, QFormLayout.FieldRole, self.lnedt_polygonID)
        model = QStringListModel()
        model.setStringList(autocomplete)
        completer = QCompleter()        
        completer.setCaseSensitivity(Qt.CaseInsensitive)
        completer.setModel(model)
        self.lnedt_polygonID.setCompleter(completer)
        self.verticalLayout_2.addLayout(self.formLayout)
        self.horizontalLayout_2 = QHBoxLayout()
        self.horizontalLayout_2.setObjectName(_fromUtf8("horizontalLayout_2"))
        self.lbl_sequence = QLabel(self)
        self.lbl_sequence.setObjectName(_fromUtf8("lbl_sequence"))
        self.horizontalLayout_2.addWidget(self.lbl_sequence)
        spacerItem_1 = QSpacerItem(40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)
        self.horizontalLayout_2.addItem(spacerItem_1)
        self.pshbtn_new = QPushButton(self)
        self.pshbtn_new.setEnabled(False)
        self.pshbtn_new.setObjectName(_fromUtf8("pshbtn_new"))
        self.horizontalLayout_2.addWidget(self.pshbtn_new)
        self.verticalLayout_2.addLayout(self.horizontalLayout_2)
        self.horizontalLayout_1 = QHBoxLayout()
        self.horizontalLayout_1.setObjectName(_fromUtf8("horizontalLayout_1"))
        self.verticalLayout_1 = QVBoxLayout()
        self.verticalLayout_1.setObjectName(_fromUtf8("verticalLayout_1"))
        self.pshbtn_start = QPushButton(self)
        self.pshbtn_start.setEnabled(True)
        self.pshbtn_start.setObjectName(_fromUtf8("pshbtn_start"))
        self.verticalLayout_1.addWidget(self.pshbtn_start)
        self.pshbtn_stop = QPushButton(self)
        self.pshbtn_stop.setEnabled(False)
        self.pshbtn_stop.setObjectName(_fromUtf8("pshbtn_stop"))
        self.verticalLayout_1.addWidget(self.pshbtn_stop)
        self.pshbtn_reset = QPushButton(self)
        self.pshbtn_reset.setEnabled(False)
        self.pshbtn_reset.setObjectName(_fromUtf8("pshbtn_reset"))
        self.verticalLayout_1.addWidget(self.pshbtn_reset)
        spacerItem_2 = QSpacerItem(20, 40, QSizePolicy.Minimum, QSizePolicy.Expanding)
        self.verticalLayout_1.addItem(spacerItem_2)
        self.horizontalLayout_1.addLayout(self.verticalLayout_1)
        self.lstwdg_sequence = QListWidget(self)
        self.lstwdg_sequence.setEnabled(False)
        self.lstwdg_sequence.setObjectName(_fromUtf8("lstwdg_sequence"))
        self.horizontalLayout_1.addWidget(self.lstwdg_sequence)
        self.verticalLayout_2.addLayout(self.horizontalLayout_1)
        self.btnbx_options = QDialogButtonBox(self)
        self.btnbx_options.setStandardButtons(QDialogButtonBox.Cancel|QDialogButtonBox.Save)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.verticalLayout_2.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout_2, 0, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(QApplication.translate("dlg_FormPolygon", "%s Form" %(layersDict["POLYGONS"]["NAME"].title(),), None, QApplication.UnicodeUTF8))
        self.lbl_polygonID.setText(QApplication.translate("dlg_FormPolygon", "%s ID" %(layersDict["POLYGONS"]["NAME"].title(),), None, QApplication.UnicodeUTF8))
        self.lbl_sequence.setText(QApplication.translate("dlg_FormPolygon", "%s Sequence" %(layersDict["POINTS"]["NAME"].title(),), None, QApplication.UnicodeUTF8))
        self.pshbtn_new.setText(QApplication.translate("dlg_FormPolygon", "New %s" %(layersDict["POINTS"]["NAME"].title(),), None, QApplication.UnicodeUTF8))
        self.pshbtn_start.setText(QApplication.translate("dlg_FormPolygon", "Start", None, QApplication.UnicodeUTF8))
        self.pshbtn_stop.setText(QApplication.translate("dlg_FormPolygon", "Stop", None, QApplication.UnicodeUTF8))
        self.pshbtn_reset.setText(QApplication.translate("dlg_FormPolygon", "Reset", None, QApplication.UnicodeUTF8))
        # connect ui widgets
        self.pshbtn_new.clicked.connect(self.newPoint)
        self.pshbtn_start.clicked.connect(self.startSeq)
        self.pshbtn_stop.clicked.connect(self.stopSeq)
        self.pshbtn_reset.clicked.connect(self.resetSeq)
        self.btnbx_options.clicked.connect(self.executeOption)
        QMetaObject.connectSlotsByName(self)

class dlg_FormPoint(QDialog):

    def __init__(self, db, data, query, values = [], parent = None):
        super(dlg_FormPoint, self).__init__(parent, Qt.WindowStaysOnTopHint)
        self.setupUi(data)
        self.db = db
        self.data = data
        self.query = query
        self.values_old = {}
        self.values_new = {}
        self.colours = {
            "REQUIRED":"background-color: rgba(255, 107, 107, 150);",
            "TYPE":"background-color: rgba(107, 107, 255, 150);",
            "UNIQUE":"background-color: rgba(107, 255, 107, 150);"
        }
        if bool(values): 
            self.populateForm(values)
    
    def getReturn(self):
        return (self.values_old, self.values_new)

    def populateForm(self, values):
        for index,value in enumerate(values):
            self.lnedts[index].setText(str(value))
            self.values_old[self.data[index]["NAME"]] = value

    def executeOption(self, button):
        if self.btnbx_options.standardButton(button) == QDialogButtonBox.Save:
            values_new = {}
            # check required fields        
            valid = True
            for lnedt in self.lnedts:
                if bool(lnedt.property("REQUIRED").toBool()):
                    if str(lnedt.text()).strip() is "":
                        lnedt.setStyleSheet(self.colours["REQUIRED"])
                        valid = False
                    else: lnedt.setStyleSheet("")
            if not valid: 
                QMessageBox.information(self, "Empty Required Fields", "Please ensure that all required fields are completed.")
                return
            # check correct field types
            valid = True
            for index,lnedt in enumerate(self.lnedts):
                try:
                    if str(lnedt.text()).strip() is not "":
                        cast = self.data[index]["TYPE"]
                        tmp = cast(str(lnedt.text()))
                        values_new[self.data[index]["NAME"]] = tmp
                        lnedt.setStyleSheet("")
                    else:
                        values_new[self.data[index]["NAME"]] = None
                except Exception as e:
                    lnedt.setStyleSheet(self.colours["TYPE"])
                    valid = False
            if not valid: 
                QMessageBox.information(self, "Invalid Field Types", "Please ensure that fields are completed with valid types.")
                return
            # check unique fields
            valid = True
            for index,lnedt in enumerate(self.lnedts):
                if str(lnedt.text()).strip() is "": continue
                if bool(lnedt.property("UNIQUE").toBool()):
                    if self.data[index]["NAME"] in self.values_old.keys() and values_new[self.data[index]["NAME"]] == self.values_old[self.data[index]["NAME"]]:
                        lnedt.setStyleSheet("")
                    elif bool(int(self.db.query(self.query["UNIQUE"] %(self.data[index]["NAME"], "%s"), (values_new[self.data[index]["NAME"]],))[0][0])): 
                        lnedt.setStyleSheet(self.colours["UNIQUE"])
                        valid = False
                    else: lnedt.setStyleSheet("")
            if not valid: 
                QMessageBox.information(self, "Fields Not Unique", "Please ensure that fields are given unique values.")
                return
            # save values
            self.values_new = values_new
            self.accept()

        else:self.reject()

    def setupUi(self, data):
        # define ui widgets
        self.setObjectName(_fromUtf8("dlg_FormPoint"))
        self.setCursor(QCursor(Qt.PointingHandCursor))
        self.setModal(True)
        self.gridLayout = QGridLayout(self)
        self.gridLayout.setSizeConstraint(QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.verticalLayout = QVBoxLayout()
        self.verticalLayout.setObjectName(_fromUtf8("verticalLayout"))
        self.formLayout = QFormLayout()
        self.formLayout.setFieldGrowthPolicy(QFormLayout.AllNonFixedFieldsGrow)
        self.formLayout.setObjectName(_fromUtf8("formLayout"))        
        self.data = data
        self.lbls = []
        self.lnedts = []
        for index,field in enumerate(self.data):
            lbl = QLabel(self)
            lbl.setObjectName(_fromUtf8("lbl_%s" %(field["NAME"],)))
            self.formLayout.setWidget(index, QFormLayout.LabelRole, lbl)
            self.lbls.append(lbl)
            lnedt = QLineEdit(self)
            lnedt.setProperty("REQUIRED", field["REQUIRED"])
            lnedt.setProperty("UNIQUE", field["UNIQUE"])
            lnedt.setObjectName(_fromUtf8("lnedt_%s" %(field["NAME"],)))
            self.formLayout.setWidget(index, QFormLayout.FieldRole, lnedt)
            self.lnedts.append(lnedt)
            lbl.setText(QApplication.translate("dlg_FormPoint", ("*" if bool(self.lnedts[index].property("REQUIRED").toBool()) else "") + field["NAME"].title(), None, QApplication.UnicodeUTF8))
            lnedt.setProperty("TYPE", QApplication.translate("dlg_FormPoint", str(field["TYPE"]), None, QApplication.UnicodeUTF8))
        self.verticalLayout.addLayout(self.formLayout)
        self.line_1 = QFrame(self)
        self.line_1.setFrameShape(QFrame.HLine)
        self.line_1.setFrameShadow(QFrame.Sunken)
        self.line_1.setObjectName(_fromUtf8("line_1"))
        self.verticalLayout.addWidget(self.line_1)
        self.label = QLabel(self)
        self.label.setObjectName(_fromUtf8("label"))
        self.verticalLayout.addWidget(self.label)
        self.line_2 = QFrame(self)
        self.line_2.setFrameShape(QFrame.HLine)
        self.line_2.setFrameShadow(QFrame.Sunken)
        self.line_2.setObjectName(_fromUtf8("line_2"))
        self.verticalLayout.addWidget(self.line_2)
        self.btnbx_options = QDialogButtonBox(self)
        self.btnbx_options.setStandardButtons(QDialogButtonBox.Cancel|QDialogButtonBox.Save)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.verticalLayout.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout, 0, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(QApplication.translate("dlg_FormPoint", "Beacon Form", None, QApplication.UnicodeUTF8))        
        self.label.setText(QApplication.translate("dlg_FormPoint", "<html><head/><body><p><span style=\" color:#ff0000;\">*Required Field</span></p></body></html>", None, QApplication.UnicodeUTF8))
        # connect ui widgets
        self.btnbx_options.clicked.connect(self.executeOption)
        QMetaObject.connectSlotsByName(self)
        
class dlg_FormDatabase(QDialog):

    def __init__(self, parent = None):
        super(dlg_FormDatabase, self).__init__(parent, Qt.WindowStaysOnTopHint)
        self.setupUi()
        self.save = False
        self.db = None
        self.params = {}
        self.colours = {
            "EMPTY":"background-color: rgba(255, 107, 107, 150);",
        }
    
    def getReturn(self):
        return (self.save, self.db, self.params)

    def executeOption(self, button):
        if self.btnbx_options.standardButton(button) == QDialogButtonBox.Ok:
            # validate fields
            params = {}
            valid = True
            for lnedt in self.findChildren(QLineEdit):
                if str(lnedt.text()).strip() is "":
                    lnedt.setStyleSheet(self.colours["EMPTY"])
                    valid = False
                else: 
                    lnedt.setStyleSheet("")
                    params[str(lnedt.property("KEY").toString())] = str(lnedt.text())
            if not valid: 
                QMessageBox.information(self, "Empty Database Fields", "Please ensure that all database fields are completed.")
                return
            # test connection
            db = None
            try:
                import database
                db = database.manager(params)
            except Exception:
                QMessageBox.information(self, "Invalid Database Settings", "Please ensure that the supplied database settings are correct.")
                return
            # save db
            self.db = db
            # save parameters
            self.params = params
            self.accept()
        else:
            self.reject()

    def saveConnection(self, state):
        self.save = bool(state)

    def setupUi(self):
        # define ui widgets
        fields = ["HOST","PORT","NAME","USER","PASSWORD"]
        self.setObjectName(_fromUtf8("dlg_FormDatabase"))
        self.setCursor(QCursor(Qt.PointingHandCursor))
        self.setModal(True)
        self.gridLayout = QGridLayout(self)
        self.gridLayout.setSizeConstraint(QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.verticalLayout = QVBoxLayout()
        self.verticalLayout.setObjectName(_fromUtf8("verticalLayout"))
        self.formLayout = QFormLayout()
        self.formLayout.setObjectName(_fromUtf8("formLayout"))
        self.lbls = []
        self.lnedts = []
        for index, field in enumerate(fields):
            lbl = QLabel(self)
            lbl.setObjectName(_fromUtf8("lbl_%s" %(field.lower(),)))
            lbl.setText(QApplication.translate("dlg_FormDatabase", field.title(), None, QApplication.UnicodeUTF8))
            self.formLayout.setWidget(index, QFormLayout.LabelRole, lbl)
            lnedt = QLineEdit(self)
            lnedt.setObjectName(_fromUtf8("lnedt_%s" %(field.lower(),)))
            lnedt.setProperty("KEY", field)
            if field == "PASSWORD": lnedt.setEchoMode(QLineEdit.Password)
            self.formLayout.setWidget(index, QFormLayout.FieldRole, lnedt)
            self.lbls.append(lbl)
            self.lnedts.append(lnedt)
        self.verticalLayout.addLayout(self.formLayout)
        self.horizontalLayout = QHBoxLayout()
        self.horizontalLayout.setObjectName(_fromUtf8("horizontalLayout"))
        self.chkbx_save = QCheckBox(self)
        self.chkbx_save.setObjectName(_fromUtf8("chkbx_save"))
        self.horizontalLayout.addWidget(self.chkbx_save)
        self.verticalLayout.addLayout(self.horizontalLayout)
        self.btnbx_options = QDialogButtonBox(self)
        self.btnbx_options.setStandardButtons(QDialogButtonBox.Cancel|QDialogButtonBox.Ok)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.verticalLayout.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout, 0, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(QApplication.translate("dlg_FormDatabase", "Database Settings", None, QApplication.UnicodeUTF8))
        self.chkbx_save.setText(QApplication.translate("dlg_FormDatabase", "Save Connection", None, QApplication.UnicodeUTF8))
        # connect ui widgets
        self.chkbx_save.stateChanged.connect(self.saveConnection)
        self.btnbx_options.clicked.connect(self.executeOption)
        QMetaObject.connectSlotsByName(self)

