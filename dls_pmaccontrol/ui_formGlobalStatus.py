# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'dls_pmaccontrol/formGlobalStatus.ui'
#
# Created by: PyQt5 UI code generator 5.12.2
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets


class Ui_formGlobalStatus(object):
    def setupUi(self, formGlobalStatus):
        formGlobalStatus.setObjectName("formGlobalStatus")
        formGlobalStatus.resize(122, 144)
        self.gridlayout = QtWidgets.QGridLayout(formGlobalStatus)
        self.gridlayout.setContentsMargins(11, 11, 11, 11)
        self.gridlayout.setSpacing(6)
        self.gridlayout.setObjectName("gridlayout")
        self.ledGroup = QtWidgets.QGroupBox(formGlobalStatus)
        self.ledGroup.setObjectName("ledGroup")
        self.gridlayout1 = QtWidgets.QGridLayout(self.ledGroup)
        self.gridlayout1.setContentsMargins(11, 11, 11, 11)
        self.gridlayout1.setSpacing(6)
        self.gridlayout1.setObjectName("gridlayout1")
        self.gridlayout.addWidget(self.ledGroup, 0, 0, 1, 2)

        self.retranslateUi(formGlobalStatus)
        QtCore.QMetaObject.connectSlotsByName(formGlobalStatus)

    def retranslateUi(self, formGlobalStatus):
        _translate = QtCore.QCoreApplication.translate
        formGlobalStatus.setWindowTitle(_translate("formGlobalStatus", "Status bits"))
        self.ledGroup.setTitle(_translate("formGlobalStatus", "Global Status"))
