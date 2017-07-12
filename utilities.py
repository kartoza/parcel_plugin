# coding=utf-8
"""This module contains utilities."""

import os
from PyQt4 import uic


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
    return uic.loadUiType(ui_file_path)[0]
