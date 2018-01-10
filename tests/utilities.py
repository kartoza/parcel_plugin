# coding=utf-8
"""Helper module for gui test suite."""

QGIS_APP = None  # Static variable used to hold hand to running QGIS app
CANVAS = None
PARENT = None
IFACE = None


def qgis_iface():
    """Helper method to get the iface for testing.
    :return: The QGIS interface.
    :rtype: QgsInterface
    """
    from qgis.utils import iface
    if iface is not None:
        return iface
    else:
        from qgis.testing.mocked import get_iface
        return get_iface()
