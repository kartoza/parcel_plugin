# -*- coding: utf-8 -*-
from PyQt4 import QtCore, QtGui

try:
    _fromUtf8 = QtCore.QString.fromUtf8
except AttributeError:
    _fromUtf8 = lambda s: s

class ui_dlg_objectRemover(object):
    def setupUi(self, dlg_objectRemover, objectName):
        dlg_objectRemover.setObjectName(_fromUtf8("dlg_objectRemover"))
        dlg_objectRemover.resize(302, 110)
        dlg_objectRemover.setCursor(QtGui.QCursor(QtCore.Qt.PointingHandCursor))
        dlg_objectRemover.setAccessibleName(_fromUtf8(""))
        self.gridLayout = QtGui.QGridLayout(dlg_objectRemover)
        self.gridLayout.setSizeConstraint(QtGui.QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.verticalLayout = QtGui.QVBoxLayout()
        self.verticalLayout.setObjectName(_fromUtf8("verticalLayout"))
        self.splitter = QtGui.QSplitter(dlg_objectRemover)
        self.splitter.setOrientation(QtCore.Qt.Horizontal)
        self.splitter.setObjectName(_fromUtf8("splitter"))
        self.widget = QtGui.QWidget(self.splitter)
        self.widget.setObjectName(_fromUtf8("widget"))
        self.formLayout = QtGui.QFormLayout(self.widget)
        self.formLayout.setMargin(0)
        self.formLayout.setObjectName(_fromUtf8("formLayout"))
        self.lbl_objectID = QtGui.QLabel(self.widget)
        self.lbl_objectID.setObjectName(_fromUtf8("lbl_objectID"))
        self.formLayout.setWidget(0, QtGui.QFormLayout.LabelRole, self.lbl_objectID)
        self.lnedt_objectID = QtGui.QLineEdit(self.widget)
        self.lnedt_objectID.setEnabled(False)
        self.lnedt_objectID.setObjectName(_fromUtf8("lnedt_objectID"))
        self.formLayout.setWidget(0, QtGui.QFormLayout.FieldRole, self.lnedt_objectID)
        self.pshbtn_re = QtGui.QPushButton(self.splitter)
        self.pshbtn_re.setObjectName(_fromUtf8("pshbtn_re"))
        self.verticalLayout.addWidget(self.splitter)
        self.chkbx_confirm = QtGui.QCheckBox(dlg_objectRemover)
        self.chkbx_confirm.setObjectName(_fromUtf8("chkbx_confirm"))
        self.verticalLayout.addWidget(self.chkbx_confirm)
        self.btnbx_options = QtGui.QDialogButtonBox(dlg_objectRemover)
        self.btnbx_options.setStandardButtons(QtGui.QDialogButtonBox.Cancel|QtGui.QDialogButtonBox.Ok)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.verticalLayout.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout, 0, 0, 1, 1)
        
        self.objectName = objectName

        self.retranslateUi(dlg_objectRemover)
        QtCore.QMetaObject.connectSlotsByName(dlg_objectRemover)

    def retranslateUi(self, dlg_objectRemover):
        dlg_objectRemover.setWindowTitle(QtGui.QApplication.translate("dlg_objectRemover", "%s Remover" %(self.objectName,), None, QtGui.QApplication.UnicodeUTF8))
        self.lbl_objectID.setText(QtGui.QApplication.translate("dlg_objectRemover", "%s ID" %(self.objectName,), None, QtGui.QApplication.UnicodeUTF8))
        self.pshbtn_re.setText(QtGui.QApplication.translate("dlg_objectRemover", "Re-select", None, QtGui.QApplication.UnicodeUTF8))
        self.chkbx_confirm.setText(QtGui.QApplication.translate("dlg_objectRemover", "I am sure I want to delete this %s" %(self.objectName.lower(),), None, QtGui.QApplication.UnicodeUTF8))

