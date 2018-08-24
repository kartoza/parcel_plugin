# -*- coding: utf-8 -*-
"""
Author: Robert Moerman
Contact: robert@afrispatial.co.za
Company: AfriSpatial

This is a collection of custom QWidgets.

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
"""


from PyQt5.QtGui import QCursor
from PyQt5.QtCore import Qt
from PyQt5.QtWidgets import QPushButton, QDialogButtonBox


class XQPushButton(QPushButton):
    def __init__(self, parent=None):
        super(XQPushButton, self).__init__(parent)
        self.setCursor(QCursor(Qt.PointingHandCursor))


class XQDialogButtonBox(QDialogButtonBox):
    def __init__(self, parent=None):
        super(XQDialogButtonBox, self).__init__(parent)
        self.setCursor(QCursor(Qt.PointingHandCursor))
