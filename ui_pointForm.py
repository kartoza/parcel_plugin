# -*- coding: utf-8 -*-
from PyQt4 import QtCore, QtGui

try:
    _fromUtf8 = QtCore.QString.fromUtf8
except AttributeError:
    _fromUtf8 = lambda s: s

class ui_dlg_pointForm(object):
    def setupUi(self, dlg_pointForm, pointFields):
        dlg_pointForm.setObjectName(_fromUtf8("dlg_pointForm"))
        dlg_pointForm.resize(233, 255)
        dlg_pointForm.setCursor(QtGui.QCursor(QtCore.Qt.PointingHandCursor))
        dlg_pointForm.setModal(True)
        self.gridLayout = QtGui.QGridLayout(dlg_pointForm)
        self.gridLayout.setSizeConstraint(QtGui.QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.verticalLayout = QtGui.QVBoxLayout()
        self.verticalLayout.setObjectName(_fromUtf8("verticalLayout"))
        self.formLayout = QtGui.QFormLayout()
        self.formLayout.setFieldGrowthPolicy(QtGui.QFormLayout.AllNonFixedFieldsGrow)
        self.formLayout.setObjectName(_fromUtf8("formLayout"))
        
        self.pointFields = pointFields
        self.lbls = []
        self.lnedts = []

        for index,fld in enumerate(self.pointFields):
            lbl = QtGui.QLabel(dlg_pointForm)
            lbl.setObjectName(_fromUtf8("lbl_%s" %(fld["name"],)))
            self.formLayout.setWidget(index, QtGui.QFormLayout.LabelRole, lbl)
            self.lbls.append(lbl)
            lnedt = QtGui.QLineEdit(dlg_pointForm)
            lnedt.setProperty("required", fld["required"])
            lnedt.setProperty("unique", fld["unique"])
            lnedt.setObjectName(_fromUtf8("lnedt_%s" %(fld["name"],)))
            self.formLayout.setWidget(index, QtGui.QFormLayout.FieldRole, lnedt)
            self.lnedts.append(lnedt)
        
        self.verticalLayout.addLayout(self.formLayout)
        self.line = QtGui.QFrame(dlg_pointForm)
        self.line.setFrameShape(QtGui.QFrame.HLine)
        self.line.setFrameShadow(QtGui.QFrame.Sunken)
        self.line.setObjectName(_fromUtf8("line"))
        self.verticalLayout.addWidget(self.line)
        self.label = QtGui.QLabel(dlg_pointForm)
        self.label.setObjectName(_fromUtf8("label"))
        self.verticalLayout.addWidget(self.label)
        self.line_2 = QtGui.QFrame(dlg_pointForm)
        self.line_2.setFrameShape(QtGui.QFrame.HLine)
        self.line_2.setFrameShadow(QtGui.QFrame.Sunken)
        self.line_2.setObjectName(_fromUtf8("line_2"))
        self.verticalLayout.addWidget(self.line_2)
        self.btnbx_options = QtGui.QDialogButtonBox(dlg_pointForm)
        self.btnbx_options.setStandardButtons(QtGui.QDialogButtonBox.Cancel|QtGui.QDialogButtonBox.Save)
        self.btnbx_options.setObjectName(_fromUtf8("btnbx_options"))
        self.verticalLayout.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout, 0, 0, 1, 1)

        self.retranslateUi(dlg_pointForm)
        QtCore.QMetaObject.connectSlotsByName(dlg_pointForm)

    def retranslateUi(self, dlg_pointForm):
        dlg_pointForm.setWindowTitle(QtGui.QApplication.translate("dlg_pointForm", "Beacon Form", None, QtGui.QApplication.UnicodeUTF8))
        
        for index,fld in enumerate(self.pointFields):
            self.lbls[index].setText(QtGui.QApplication.translate("dlg_pointForm", ("*" if bool(self.lnedts[index].property("required").toBool()) else "") + fld["name"].title(), None, QtGui.QApplication.UnicodeUTF8))
            self.lnedts[index].setProperty("type", QtGui.QApplication.translate("dlg_pointForm", str(fld["type"]), None, QtGui.QApplication.UnicodeUTF8))
        
        self.label.setText(QtGui.QApplication.translate("dlg_pointForm", "<html><head/><body><p><span style=\" color:#ff0000;\">*Required Field</span></p></body></html>", None, QtGui.QApplication.UnicodeUTF8))

