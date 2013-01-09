# -*- coding: utf-8 -*-
from PyQt4 import QtCore, QtGui

try:
    _fromUtf8 = QtCore.QString.fromUtf8
except AttributeError:
    _fromUtf8 = lambda s: s

class ui_dlg_objectManager(object):
    def setupUi(self, dlg_objectManager, objectName):
        dlg_objectManager.setObjectName(_fromUtf8("dlg_objectManager"))
        dlg_objectManager.resize(207, 133)
        dlg_objectManager.setCursor(QtGui.QCursor(QtCore.Qt.PointingHandCursor))
        dlg_objectManager.setModal(True)
        self.mainlyt = QtGui.QGridLayout(dlg_objectManager)
        self.mainlyt.setSizeConstraint(QtGui.QLayout.SetFixedSize)
        self.mainlyt.setObjectName(_fromUtf8("mainlyt"))
        self.vrtlyt = QtGui.QVBoxLayout()
        self.vrtlyt.setObjectName(_fromUtf8("vrtlyt"))
        self.grdlyt = QtGui.QGridLayout()
        self.grdlyt.setObjectName(_fromUtf8("grdlyt"))
        self.rdbtn_add = QtGui.QRadioButton(dlg_objectManager)
        self.rdbtn_add.setObjectName(_fromUtf8("rdbtn_add"))
        self.grdlyt.addWidget(self.rdbtn_add, 0, 0, 1, 1)
        self.rdbtn_edit = QtGui.QRadioButton(dlg_objectManager)
        self.rdbtn_edit.setObjectName(_fromUtf8("rdbtn_edit"))
        self.grdlyt.addWidget(self.rdbtn_edit, 1, 0, 1, 1)
        self.rdbtn_del = QtGui.QRadioButton(dlg_objectManager)
        self.rdbtn_del.setObjectName(_fromUtf8("rdbtn_del"))
        self.grdlyt.addWidget(self.rdbtn_del, 2, 0, 1, 1)
        self.vrtlyt.addLayout(self.grdlyt)
        self.btnbx_options = QtGui.QDialogButtonBox(dlg_objectManager)
        self.btnbx_options.setStandardButtons(QtGui.QDialogButtonBox.Cancel|QtGui.QDialogButtonBox.Ok)
        self.btnbx_options.setCenterButtons(False)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.vrtlyt.addWidget(self.btnbx_options)
        self.mainlyt.addLayout(self.vrtlyt, 0, 0, 1, 1)
        
        self.objectName = objectName

        self.retranslateUi(dlg_objectManager)
        QtCore.QMetaObject.connectSlotsByName(dlg_objectManager)

    def retranslateUi(self, dlg_objectManager):
        dlg_objectManager.setWindowTitle(QtGui.QApplication.translate("dlg_objectManager", "%s Manager" %(self.objectName,), None, QtGui.QApplication.UnicodeUTF8))
        self.rdbtn_add.setText(QtGui.QApplication.translate("dlg_objectManager", "Create New %s" %(self.objectName,), None, QtGui.QApplication.UnicodeUTF8))
        self.rdbtn_edit.setText(QtGui.QApplication.translate("dlg_objectManager", "Edit Existing %s" %(self.objectName,), None, QtGui.QApplication.UnicodeUTF8))
        self.rdbtn_del.setText(QtGui.QApplication.translate("dlg_objectManager", "Delete Existing %s" %(self.objectName,), None, QtGui.QApplication.UnicodeUTF8))

