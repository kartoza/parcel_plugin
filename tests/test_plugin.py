# coding=utf-8
"""Test plugin."""

import unittest
from plugin import SMLSurveyor
from tests.utilities import qgis_iface

IFACE = qgis_iface()


class TestPlugin(unittest.TestCase):

    def test_toolbar(self):
        """Test SML Surveyor toolbar functionality."""
        sml_plugin = SMLSurveyor(IFACE)
        sml_plugin.create_plugin_toolbar()

        self.assertIsNotNone(sml_plugin.plugin_toolbar)
        self.assertIsNotNone(sml_plugin.bearing_distance_action)
        self.assertIsNotNone(sml_plugin.beacons_action)
        self.assertIsNotNone(sml_plugin.parcels_action)
