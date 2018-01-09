# coding=utf-8
"""This module contains utilities."""

import os
from PyQt4 import uic
from PyQt4.QtCore import Qt
from PyQt4.QtGui import QCompleter, QComboBox, QSortFilterProxyModel


crs_options = {
    'Minna / UTM zone 31N': 26331,
    'Minna / UTM zone 32N': 26332
}

def images_path(*args):
    """Get the path to our resources folder.

    .. versionadded:: 3.0

    Note that in version 3.0 we removed the use of Qt Resource files in
    favour of directly accessing on-disk resources.

    :param args List of path elements e.g. ['img', 'logos', 'image.png']
    :type args: list[str]

    :return: Absolute path to the resources folder.
    :rtype: str
    """
    path = os.path.dirname(__file__)
    path = os.path.abspath(
        os.path.join(path, 'images'))
    for item in args:
        path = os.path.abspath(os.path.join(path, item))

    return path

def get_path(*args):
    """Get the path to our specific folder from plugin folder.

    .. versionadded:: 3.0

    Note that in version 3.0 we removed the use of Qt Resource files in
    favour of directly accessing on-disk resources.

    :param args List of path elements e.g. ['img', 'logos', 'image.png']
    :type args: list[str]

    :return: Absolute path to the resources folder.
    :rtype: str
    """
    path = os.path.dirname(__file__)
    for item in args:
        path = os.path.abspath(os.path.join(path, item))

    return path

def get_ui_class(ui_file):
    """Get UI Python class from .ui file.

       Can be filename.ui or subdirectory/filename.ui

    :param ui_file: The file of the ui in safe.gui.ui
    :type ui_file: str
    """
    os.path.sep.join(ui_file.split('/'))
    ui_file_path = os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            ui_file
        )
    )
    return uic.loadUiType(ui_file_path, from_imports=True)[0]

def validate_plugin_actions(toolbar, database):
    """Check DB schema for actions availability. eg: Manage bearing and
    distance action needs Beacon to be created first.

    :param database: Database instance
    :type database: database.Manager

    :param toolbar: plugin toolbar
    :type toolbar: SMLSurveyor

    :return: Query result
    :rtype: tuple
    """
    query = "select * from survey limit 1;"
    try:
        result = database.query(query=query)
    except Exception as e:
        raise Exception(
            'Backend database query failed!\nError raised: %s.' % (str(e),))
    if result:
        toolbar.bearing_distance_action.setEnabled(True)
    else:
        toolbar.bearing_distance_action.setEnabled(False)
    return result


class ExtendedComboBox(QComboBox):
    """Extended class of QComboBox so we can perform a filtering of items.
    """
    def __init__(self, parent=None):
        super(ExtendedComboBox, self).__init__(parent)

        self.setFocusPolicy(Qt.StrongFocus)
        self.setEditable(True)

        # add a filter model to filter matching items
        self.pFilterModel = QSortFilterProxyModel(self)
        self.pFilterModel.setFilterCaseSensitivity(Qt.CaseInsensitive)
        self.pFilterModel.setSourceModel(self.model())

        # add a completer, which uses the filter model
        self.completer = QCompleter(self.pFilterModel, self)
        # always show all (filtered) completions
        self.completer.setCompletionMode(QCompleter.UnfilteredPopupCompletion)
        self.setCompleter(self.completer)

        # connect signals
        self.lineEdit().textEdited[unicode].connect(
            self.pFilterModel.setFilterFixedString)
        self.completer.activated.connect(self.on_completer_activated)


    # on selection of an item from the completer,
    # select the corresponding item from combobox
    def on_completer_activated(self, text):
        if text:
            index = self.findText(text)
            self.setCurrentIndex(index)


    # on model change, update the models of the filter and completer as well
    def setModel(self, model):
        super(ExtendedComboBox, self).setModel(model)
        self.pFilterModel.setSourceModel(model)
        self.completer.setModel(self.pFilterModel)


    # on model column change, update the model column of
    # the filter and completer as well
    def setModelColumn(self, column):
        self.completer.setCompletionColumn(column)
        self.pFilterModel.setFilterKeyColumn(column)
        super(ExtendedComboBox, self).setModelColumn(column)
