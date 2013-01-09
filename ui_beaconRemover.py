# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'ui_beaconRemover.ui'
#
# Created: Mon Jan  7 11:23:38 2013
#      by: PyQt4 UI code generator 4.9.3
#
# WARNING! All changes made in this file will be lost!

from PyQt4 import QtCore, QtGui

try:
    _fromUtf8 = QtCore.QString.fromUtf8
except AttributeError:
    _fromUtf8 = lambda s: s

class Ui_dlg_beaconRemover(object):
    def setupUi(self, dlg_beaconRemover):
        dlg_beaconRemover.setObjectName(_fromUtf8("dlg_beaconRemover"))
        dlg_beaconRemover.resize(310, 110)
        self.gridLayout = QtGui.QGridLayout(dlg_beaconRemover)
        self.gridLayout.setSizeConstraint(QtGui.QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.verticalLayout = QtGui.QVBoxLayout()
        self.verticalLayout.setObjectName(_fromUtf8("verticalLayout"))
        self.splitter = QtGui.QSplitter(dlg_beaconRemover)
        self.splitter.setOrientation(QtCore.Qt.Horizontal)
        self.splitter.setObjectName(_fromUtf8("splitter"))
        self.widget = QtGui.QWidget(self.splitter)
        self.widget.setObjectName(_fromUtf8("widget"))
        self.formLayout = QtGui.QFormLayout(self.widget)
        self.formLayout.setMargin(0)
        self.formLayout.setObjectName(_fromUtf8("formLayout"))
        self.lbl_beaconId = QtGui.QLabel(self.widget)
        self.lbl_beaconId.setObjectName(_fromUtf8("lbl_beaconId"))
        self.formLayout.setWidget(0, QtGui.QFormLayout.LabelRole, self.lbl_beaconId)
        self.lnedt_beaconId = QtGui.QLineEdit(self.widget)
        self.lnedt_beaconId.setEnabled(False)
        self.lnedt_beaconId.setObjectName(_fromUtf8("lnedt_beaconId"))
        self.formLayout.setWidget(0, QtGui.QFormLayout.FieldRole, self.lnedt_beaconId)
        self.pshbtn_re = QtGui.QPushButton(self.splitter)
        self.pshbtn_re.setObjectName(_fromUtf8("pshbtn_re"))
        self.verticalLayout.addWidget(self.splitter)
        self.chkbx_confirm = QtGui.QCheckBox(dlg_beaconRemover)
        self.chkbx_confirm.setObjectName(_fromUtf8("chkbx_confirm"))
        self.verticalLayout.addWidget(self.chkbx_confirm)
        self.btnbx_options = QtGui.QDialogButtonBox(dlg_beaconRemover)
        self.btnbx_options.setStandardButtons(QtGui.QDialogButtonBox.Cancel|QtGui.QDialogButtonBox.Ok)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.verticalLayout.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout, 0, 0, 1, 1)

        self.retranslateUi(dlg_beaconRemover)
        QtCore.QMetaObject.connectSlotsByName(dlg_beaconRemover)

    def retranslateUi(self, dlg_beaconRemover):
        dlg_beaconRemover.setWindowTitle(QtGui.QApplication.translate("dlg_beaconRemover", "Beacon Remover", None, QtGui.QApplication.UnicodeUTF8))
        self.lbl_beaconId.setText(QtGui.QApplication.translate("dlg_beaconRemover", "Beacon ID", None, QtGui.QApplication.UnicodeUTF8))
        self.pshbtn_re.setText(QtGui.QApplication.translate("dlg_beaconRemover", "Re-select", None, QtGui.QApplication.UnicodeUTF8))
        self.chkbx_confirm.setText(QtGui.QApplication.translate("dlg_beaconRemover", "I am sure I want to delete this beacon", None, QtGui.QApplication.UnicodeUTF8))

