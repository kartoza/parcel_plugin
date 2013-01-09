# -*- coding: utf-8 -*-
from PyQt4 import QtCore, QtGui

try:
    _fromUtf8 = QtCore.QString.fromUtf8
except AttributeError:
    _fromUtf8 = lambda s: s

class ui_dlg_polygonForm(object):
    def setupUi(self, dlg_polygonForm, polygonName, pointName):
        dlg_polygonForm.setObjectName(_fromUtf8("dlg_polygonForm"))
        dlg_polygonForm.resize(371, 317)
        dlg_polygonForm.setCursor(QtGui.QCursor(QtCore.Qt.PointingHandCursor))
        self.gridLayout = QtGui.QGridLayout(dlg_polygonForm)
        self.gridLayout.setSizeConstraint(QtGui.QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.verticalLayout_2 = QtGui.QVBoxLayout()
        self.verticalLayout_2.setObjectName(_fromUtf8("verticalLayout_2"))
        self.formLayout = QtGui.QFormLayout()
        self.formLayout.setObjectName(_fromUtf8("formLayout"))
        self.lbl_polygonID = QtGui.QLabel(dlg_polygonForm)
        self.lbl_polygonID.setObjectName(_fromUtf8("lbl_polygonID"))
        self.formLayout.setWidget(0, QtGui.QFormLayout.LabelRole, self.lbl_polygonID)
        self.lnedt_polygonID = QtGui.QLineEdit(dlg_polygonForm)
        self.lnedt_polygonID.setObjectName(_fromUtf8("lnedt_polygonID"))
        self.formLayout.setWidget(0, QtGui.QFormLayout.FieldRole, self.lnedt_polygonID)
        self.verticalLayout_2.addLayout(self.formLayout)
        self.horizontalLayout_2 = QtGui.QHBoxLayout()
        self.horizontalLayout_2.setObjectName(_fromUtf8("horizontalLayout_2"))
        self.lbl_sequence = QtGui.QLabel(dlg_polygonForm)
        self.lbl_sequence.setObjectName(_fromUtf8("lbl_sequence"))
        self.horizontalLayout_2.addWidget(self.lbl_sequence)
        spacerItem = QtGui.QSpacerItem(40, 20, QtGui.QSizePolicy.Expanding, QtGui.QSizePolicy.Minimum)
        self.horizontalLayout_2.addItem(spacerItem)
        self.pshbtn_new = QtGui.QPushButton(dlg_polygonForm)
        self.pshbtn_new.setObjectName(_fromUtf8("pshbtn_new"))
        self.horizontalLayout_2.addWidget(self.pshbtn_new)
        self.verticalLayout_2.addLayout(self.horizontalLayout_2)
        self.horizontalLayout = QtGui.QHBoxLayout()
        self.horizontalLayout.setObjectName(_fromUtf8("horizontalLayout"))
        self.verticalLayout = QtGui.QVBoxLayout()
        self.verticalLayout.setObjectName(_fromUtf8("verticalLayout"))
        self.pshbtn_start = QtGui.QPushButton(dlg_polygonForm)
        self.pshbtn_start.setEnabled(True)
        self.pshbtn_start.setObjectName(_fromUtf8("pshbtn_start"))
        self.verticalLayout.addWidget(self.pshbtn_start)
        self.pshbtn_stop = QtGui.QPushButton(dlg_polygonForm)
        self.pshbtn_stop.setObjectName(_fromUtf8("pshbtn_stop"))
        self.verticalLayout.addWidget(self.pshbtn_stop)
        self.pshbtn_reset = QtGui.QPushButton(dlg_polygonForm)
        self.pshbtn_reset.setObjectName(_fromUtf8("pshbtn_reset"))
        self.verticalLayout.addWidget(self.pshbtn_reset)
        spacerItem1 = QtGui.QSpacerItem(20, 40, QtGui.QSizePolicy.Minimum, QtGui.QSizePolicy.Expanding)
        self.verticalLayout.addItem(spacerItem1)
        self.horizontalLayout.addLayout(self.verticalLayout)
        self.lstwdg_sequence = QtGui.QListWidget(dlg_polygonForm)
        self.lstwdg_sequence.setEnabled(False)
        self.lstwdg_sequence.setObjectName(_fromUtf8("lstwdg_sequence"))
        self.horizontalLayout.addWidget(self.lstwdg_sequence)
        self.verticalLayout_2.addLayout(self.horizontalLayout)
        self.btnbx_options = QtGui.QDialogButtonBox(dlg_polygonForm)
        self.btnbx_options.setStandardButtons(QtGui.QDialogButtonBox.Cancel|QtGui.QDialogButtonBox.Save)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.verticalLayout_2.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout_2, 0, 0, 1, 1)
        
        self.polygonName = polygonName
        self.pointName = pointName

        self.retranslateUi(dlg_polygonForm)
        QtCore.QMetaObject.connectSlotsByName(dlg_polygonForm)

    def retranslateUi(self, dlg_polygonForm):
        dlg_polygonForm.setWindowTitle(QtGui.QApplication.translate("dlg_polygonForm", "%s Form" %(self.polygonName,), None, QtGui.QApplication.UnicodeUTF8))
        self.lbl_polygonID.setText(QtGui.QApplication.translate("dlg_polygonForm", "%s ID" %(self.polygonName,), None, QtGui.QApplication.UnicodeUTF8))
        self.lbl_sequence.setText(QtGui.QApplication.translate("dlg_polygonForm", "%s Sequence" %(self.pointName,), None, QtGui.QApplication.UnicodeUTF8))
        self.pshbtn_new.setText(QtGui.QApplication.translate("dlg_polygonForm", "New %s" %(self.pointName,), None, QtGui.QApplication.UnicodeUTF8))
        self.pshbtn_start.setText(QtGui.QApplication.translate("dlg_polygonForm", "Start", None, QtGui.QApplication.UnicodeUTF8))
        self.pshbtn_stop.setText(QtGui.QApplication.translate("dlg_polygonForm", "Stop", None, QtGui.QApplication.UnicodeUTF8))
        self.pshbtn_reset.setText(QtGui.QApplication.translate("dlg_polygonForm", "Reset", None, QtGui.QApplication.UnicodeUTF8))

