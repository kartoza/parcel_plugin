# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'ui_beaconForm.ui'
#
# Created: Mon Jan  7 10:51:37 2013
#      by: PyQt4 UI code generator 4.9.3
#
# WARNING! All changes made in this file will be lost!

from PyQt4 import QtCore, QtGui

try:
    _fromUtf8 = QtCore.QString.fromUtf8
except AttributeError:
    _fromUtf8 = lambda s: s

class Ui_dlg_beaconForm(object):
    def setupUi(self, dlg_beaconForm):
        dlg_beaconForm.setObjectName(_fromUtf8("dlg_beaconForm"))
        dlg_beaconForm.resize(233, 255)
        dlg_beaconForm.setCursor(QtGui.QCursor(QtCore.Qt.PointingHandCursor))
        dlg_beaconForm.setModal(True)
        self.gridLayout = QtGui.QGridLayout(dlg_beaconForm)
        self.gridLayout.setSizeConstraint(QtGui.QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.verticalLayout = QtGui.QVBoxLayout()
        self.verticalLayout.setObjectName(_fromUtf8("verticalLayout"))
        self.formLayout = QtGui.QFormLayout()
        self.formLayout.setFieldGrowthPolicy(QtGui.QFormLayout.AllNonFixedFieldsGrow)
        self.formLayout.setObjectName(_fromUtf8("formLayout"))
        self.lb_name = QtGui.QLabel(dlg_beaconForm)
        self.lb_name.setObjectName(_fromUtf8("lb_name"))
        self.formLayout.setWidget(0, QtGui.QFormLayout.LabelRole, self.lb_name)
        self.lnedt_name = QtGui.QLineEdit(dlg_beaconForm)
        self.lnedt_name.setProperty("required", True)
        self.lnedt_name.setObjectName(_fromUtf8("lnedt_name"))
        self.formLayout.setWidget(0, QtGui.QFormLayout.FieldRole, self.lnedt_name)
        self.lb_lat = QtGui.QLabel(dlg_beaconForm)
        self.lb_lat.setObjectName(_fromUtf8("lb_lat"))
        self.formLayout.setWidget(1, QtGui.QFormLayout.LabelRole, self.lb_lat)
        self.lnedt_lat = QtGui.QLineEdit(dlg_beaconForm)
        self.lnedt_lat.setProperty("required", True)
        self.lnedt_lat.setObjectName(_fromUtf8("lnedt_lat"))
        self.formLayout.setWidget(1, QtGui.QFormLayout.FieldRole, self.lnedt_lat)
        self.lbl_long = QtGui.QLabel(dlg_beaconForm)
        self.lbl_long.setObjectName(_fromUtf8("lbl_long"))
        self.formLayout.setWidget(2, QtGui.QFormLayout.LabelRole, self.lbl_long)
        self.lnedt_long = QtGui.QLineEdit(dlg_beaconForm)
        self.lnedt_long.setProperty("required", True)
        self.lnedt_long.setObjectName(_fromUtf8("lnedt_long"))
        self.formLayout.setWidget(2, QtGui.QFormLayout.FieldRole, self.lnedt_long)
        self.lbl_loc = QtGui.QLabel(dlg_beaconForm)
        self.lbl_loc.setObjectName(_fromUtf8("lbl_loc"))
        self.formLayout.setWidget(3, QtGui.QFormLayout.LabelRole, self.lbl_loc)
        self.lnedt_loc = QtGui.QLineEdit(dlg_beaconForm)
        self.lnedt_loc.setProperty("required", False)
        self.lnedt_loc.setObjectName(_fromUtf8("lnedt_loc"))
        self.formLayout.setWidget(3, QtGui.QFormLayout.FieldRole, self.lnedt_loc)
        self.lbl_surveyor = QtGui.QLabel(dlg_beaconForm)
        self.lbl_surveyor.setObjectName(_fromUtf8("lbl_surveyor"))
        self.formLayout.setWidget(4, QtGui.QFormLayout.LabelRole, self.lbl_surveyor)
        self.lnedt_surveyor = QtGui.QLineEdit(dlg_beaconForm)
        self.lnedt_surveyor.setProperty("required", False)
        self.lnedt_surveyor.setObjectName(_fromUtf8("lnedt_surveyor"))
        self.formLayout.setWidget(4, QtGui.QFormLayout.FieldRole, self.lnedt_surveyor)
        self.verticalLayout.addLayout(self.formLayout)
        self.line = QtGui.QFrame(dlg_beaconForm)
        self.line.setFrameShape(QtGui.QFrame.HLine)
        self.line.setFrameShadow(QtGui.QFrame.Sunken)
        self.line.setObjectName(_fromUtf8("line"))
        self.verticalLayout.addWidget(self.line)
        self.label = QtGui.QLabel(dlg_beaconForm)
        self.label.setObjectName(_fromUtf8("label"))
        self.verticalLayout.addWidget(self.label)
        self.line_2 = QtGui.QFrame(dlg_beaconForm)
        self.line_2.setFrameShape(QtGui.QFrame.HLine)
        self.line_2.setFrameShadow(QtGui.QFrame.Sunken)
        self.line_2.setObjectName(_fromUtf8("line_2"))
        self.verticalLayout.addWidget(self.line_2)
        self.btnbx_options = QtGui.QDialogButtonBox(dlg_beaconForm)
        self.btnbx_options.setStandardButtons(QtGui.QDialogButtonBox.Cancel|QtGui.QDialogButtonBox.Save)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.verticalLayout.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout, 0, 0, 1, 1)

        self.retranslateUi(dlg_beaconForm)
        QtCore.QMetaObject.connectSlotsByName(dlg_beaconForm)

    def retranslateUi(self, dlg_beaconForm):
        dlg_beaconForm.setWindowTitle(QtGui.QApplication.translate("dlg_beaconForm", "Beacon Form", None, QtGui.QApplication.UnicodeUTF8))
        self.lb_name.setText(QtGui.QApplication.translate("dlg_beaconForm", "*Name", None, QtGui.QApplication.UnicodeUTF8))
        self.lnedt_name.setProperty("type", QtGui.QApplication.translate("dlg_beaconForm", "string", None, QtGui.QApplication.UnicodeUTF8))
        self.lnedt_name.setProperty("db_field", QtGui.QApplication.translate("dlg_beaconForm", "beacon", None, QtGui.QApplication.UnicodeUTF8))
        self.lb_lat.setText(QtGui.QApplication.translate("dlg_beaconForm", "*Latitude", None, QtGui.QApplication.UnicodeUTF8))
        self.lnedt_lat.setProperty("type", QtGui.QApplication.translate("dlg_beaconForm", "double", None, QtGui.QApplication.UnicodeUTF8))
        self.lnedt_lat.setProperty("db_field", QtGui.QApplication.translate("dlg_beaconForm", "y", None, QtGui.QApplication.UnicodeUTF8))
        self.lbl_long.setText(QtGui.QApplication.translate("dlg_beaconForm", "*Longitude", None, QtGui.QApplication.UnicodeUTF8))
        self.lnedt_long.setProperty("type", QtGui.QApplication.translate("dlg_beaconForm", "double", None, QtGui.QApplication.UnicodeUTF8))
        self.lnedt_long.setProperty("db_field", QtGui.QApplication.translate("dlg_beaconForm", "x", None, QtGui.QApplication.UnicodeUTF8))
        self.lbl_loc.setText(QtGui.QApplication.translate("dlg_beaconForm", "Location", None, QtGui.QApplication.UnicodeUTF8))
        self.lnedt_loc.setProperty("type", QtGui.QApplication.translate("dlg_beaconForm", "string", None, QtGui.QApplication.UnicodeUTF8))
        self.lnedt_loc.setProperty("db_field", QtGui.QApplication.translate("dlg_beaconForm", "location", None, QtGui.QApplication.UnicodeUTF8))
        self.lbl_surveyor.setText(QtGui.QApplication.translate("dlg_beaconForm", "Surveyor", None, QtGui.QApplication.UnicodeUTF8))
        self.lnedt_surveyor.setProperty("type", QtGui.QApplication.translate("dlg_beaconForm", "string", None, QtGui.QApplication.UnicodeUTF8))
        self.lnedt_surveyor.setProperty("db_field", QtGui.QApplication.translate("dlg_beaconForm", "name", None, QtGui.QApplication.UnicodeUTF8))
        self.label.setText(QtGui.QApplication.translate("dlg_beaconForm", "<html><head/><body><p><span style=\" color:#ff0000;\">*Required Field</span></p></body></html>", None, QtGui.QApplication.UnicodeUTF8))

