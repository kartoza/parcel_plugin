# coding=utf-8
"""
Test Suite for Cadasta.
Contact : etienne at kartoza dot com
.. note:: This program is free software; you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation; either version 2 of the License, or
     (at your option) any later version.
"""
from __future__ import print_function
from builtins import str

import sys
import os
import unittest
from osgeo import gdal
from qgis.core import Qgis


__author__ = 'etiennetrimaille'
__revision__ = '$Format:%H$'
__date__ = '14/06/2016'
__copyright__ = 'Copyright 2016, Cadasta'


def _run_tests(test_suite, package_name):
    """Core function to test a test suite."""
    count = test_suite.countTestCases()
    # fix_print_with_import
    print('########')
    # fix_print_with_import
    print('%s tests has been discovered in %s' % (count, package_name))
    # fix_print_with_import
    print('QGIS : %s' % str(Qgis.QGIS_VERSION_INT))
    # fix_print_with_import
    print('Python GDAL : %s' % gdal.VersionInfo('VERSION_NUM'))
    # fix_print_with_import
    print('Run slow tests : %s' % (not os.environ.get('ON_TRAVIS', False)))
    # fix_print_with_import
    print('########')
    unittest.TextTestRunner(verbosity=3, stream=sys.stdout).run(test_suite)


def test_package(package='parcel_plugin'):
    """Test package.
    This function is called by travis without arguments.
    :param package: The package to test.
    :type package: str
    """
    test_loader = unittest.defaultTestLoader
    try:
        test_suite = test_loader.discover(package)
    except ImportError:
        test_suite = unittest.TestSuite()
    _run_tests(test_suite, package)


if __name__ == '__main__':
    test_package()
