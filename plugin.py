# -*- coding: utf-8 -*-
"""
/***************************************************************************
 SMLSurveyor
                                 A QGIS plugin
 SML Surveyor Plugin
                              -------------------
        begin                : 2012-12-28
        modified last        : 2014-01-07
        copyright            : (C) 2012 by AfriSpatial
        email                : robert@afrispatial.co.za
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
"""
from __future__ import absolute_import

# python imports
import os
from datetime import datetime

# qgis imports
from PyQt5.QtCore import QSettings, Qt
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QToolBar, QAction, QMessageBox
from qgis.core import QgsCoordinateReferenceSystem, QgsProject, QgsVectorLayer, QgsCredentials, QgsDataSourceUri
from qgis.utils import iface

from . import database
from .cogo_dialogs import BearingDistanceFormDialog, SelectorDialog, FormParcelDialog, ManagerDialog, \
    FormBeaconDialog, DatabaseConnectionDialog
from .constants import *
from .utilities import validate_plugin_actions, get_path


# user imports


class RequiredLayer(object):

    def __init__(
            self,
            name,
            name_plural,
            table,
            primary_key,
            geometry_type,
            geometry_column='the_geom',
            schema='public',
            layer=None):
        self.name = name
        self.name_plural = name_plural
        self.table = table
        self.primary_key = primary_key
        self.geometry_type = geometry_type
        self.geometry_column = geometry_column
        self.schema = schema
        self.layer = layer


class Mode(object):

    def __init__(self, actor, action):
        self.actor = actor
        self.action = action


class SMLSurveyor(object):

    def __init__(self, iface):
        # save reference to the QGIS interface
        self.iface = iface
        # get plugin directory
        self.plugin_dir = os.path.dirname(os.path.realpath(__file__))
        self.uri = None
        self.connection = None
        self.crs = None
        self.database = None
        self.datetime = datetime.now()
        self.required_non_spatial_layers = []
        self.required_layers = []
        # 1. beacons
        # 2. parcels
        self.required_non_spatial_layers.append(RequiredLayer(
            'Instrument_cat', 'Instrument_cat', 'instrument_cat', 'instrument_cat', None
        ))
        self.required_non_spatial_layers.append(RequiredLayer(
            'Allocation_cat', 'Allocation_cat', 'allocation_cat', 'allocation_cat', None
        ))
        self.required_non_spatial_layers.append(RequiredLayer(
            'Local_govt', 'Local_govt', 'local_govt', 'id', None
        ))
        self.required_non_spatial_layers.append(RequiredLayer(
            'Status_cat', 'Status_cat', 'status_cat', 'status_cat', None
        ))
        self.required_non_spatial_layers.append(RequiredLayer(
            'Prop_types', 'Prop_types', 'prop_types', 'id', None
        ))
        self.required_non_spatial_layers.append(RequiredLayer(
            'Schemes', 'Schemes', 'schemes', 'id', None
        ))
        self.required_non_spatial_layers.append(RequiredLayer(
            'Deeds', 'Deeds', 'deeds', 'deed_sn', None
        ))
        self.required_non_spatial_layers.append(RequiredLayer(
            'Survey', 'Survey', 'survey', 'id', None
        ))
        self.required_non_spatial_layers.append(RequiredLayer(
            'Parcel_lookup', 'Parcel_lookup', 'parcel_lookup', 'parcel_id', None
        ))

        self.required_layers.append(RequiredLayer(
            'Beacon', 'Beacons', 'beacons', 'gid', 'points'
        ))
        self.required_layers.append(RequiredLayer(
            'Parcel', 'Parcels', 'parcels', 'parcel_id', 'polygons'
        ))

    def initGui(self):
        """ Initialize gui
        """
        # create plugin toolbar
        self.create_plugin_toolbar()

    def unload(self):
        """ Uninitialize gui
        """
        # remove plugin toolbar
        self.remove_plugin_toolbar()
        # remove layers
        self.refresh_layers()
        for l in self.required_layers:
            if bool(l.layer):
                QgsProject.instance().removeMapLayers([l.layer.id()])

    def create_plugin_toolbar(self):
        """ Create plugin toolbar to house buttons
        """
        # create plugin toolbar

        self.plugin_toolbar = QToolBar('Parcel Plugin')
        self.plugin_toolbar.setObjectName('Parcel Plugin')
        # create Database Selection button
        self.select_database_action = QAction(
            QIcon(os.path.join(self.plugin_dir, "images", "database.png")),
            "Select Database Connection",
            self.iface.mainWindow())
        self.select_database_action.setWhatsThis(
            "Select database connection")
        self.select_database_action.setStatusTip(
            "Select database connection")
        self.select_database_action.triggered.connect(
            self.manage_database_connection)
        # create Beardist button
        self.bearing_distance_action = QAction(
            QIcon(os.path.join(self.plugin_dir, "images", "beardist.png")),
            "Manage Bearings and Distances",
            self.iface.mainWindow())
        self.bearing_distance_action.setWhatsThis(
            "Manage bearings and distances")
        self.bearing_distance_action.setStatusTip(
            "Manage bearings and distances")
        self.bearing_distance_action.triggered.connect(
            self.manage_bearing_distance)
        # create Beacons button
        self.beacons_action = QAction(
            QIcon(os.path.join(self.plugin_dir, "images", "beacon.gif")),
            "Manage Beacons",
            self.iface.mainWindow())
        self.beacons_action.setWhatsThis("Manage beacons")
        self.beacons_action.setStatusTip("Manage beacons")
        self.beacons_action.triggered.connect(self.manage_beacons)
        # create Parcels button
        self.parcels_action = QAction(
            QIcon(os.path.join(self.plugin_dir, "images", "parcel.png")),
            "Manage Parcels",
            self.iface.mainWindow())
        self.parcels_action.setWhatsThis("Manage parcels")
        self.parcels_action.setStatusTip("Manage parcels")
        self.parcels_action.triggered.connect(self.manage_parcels)
        # populate plugin toolbar
        self.plugin_toolbar.addAction(self.select_database_action)
        self.plugin_toolbar.addAction(self.bearing_distance_action)
        self.plugin_toolbar.addAction(self.beacons_action)
        self.plugin_toolbar.addAction(self.parcels_action)
        # add plugin toolbar to gui
        self.iface.mainWindow().addToolBar(self.plugin_toolbar)

    def remove_plugin_toolbar(self):
        """ Remove plugin toolbar which houses buttons
        """
        # remove app toolbar from gui
        if hasattr(self, "pluginToolBar"):
            self.iface.mainWindow().removeToolBar(self.plugin_toolbar)
            self.plugin_toolbar.hide()

    def set_database_connection(self, connection=None, crs=None):
        """ Create a database connection
        """
        # fetch settings
        settings_plugin = QSettings()
        settings_postgis = QSettings()
        settings_plugin.beginGroup('CoGo Plugin')
        settings_postgis.beginGroup('PostgreSQL/connections')
        self.connection = connection
        if not bool(self.connection):
            # fetch pre-chosen database connection
            self.connection = settings_plugin.value("DatabaseConnection", None)
        # check if still exists
        if bool(self.connection):
            if self.connection not in settings_postgis.childGroups():
                settings_plugin.setValue("DatabaseConnection", "")
                self.connection = None
        # fetch from user if necessary
        if not bool(self.connection):
            dialog = DatabaseConnectionDialog()
            dialog.show()
            if bool(dialog.exec_()):
                self.connection = dialog.get_database_connection()
                if dialog.get_crs():
                    self.crs = QgsCoordinateReferenceSystem(
                        dialog.get_crs().get('auth_id'))
                settings_plugin.setValue("DatabaseConnection", self.connection)
        # validate database connection
        if bool(self.connection):
            db_service = settings_postgis.value(self.connection + '/service')
            db_host = settings_postgis.value(self.connection + '/host')
            db_port = settings_postgis.value(self.connection + '/port')
            db_name = settings_postgis.value(self.connection + '/database')
            db_username = settings_postgis.value(self.connection + '/username')
            db_password = settings_postgis.value(self.connection + '/password')

            max_attempts = 3
            self.uri = QgsDataSourceUri()
            self.uri.setConnection(
                db_host,
                db_port,
                db_name,
                db_username,
                db_password)

            if db_username and db_password:
                for i in range(max_attempts):
                    error_message = self.connect_to_db(
                        db_service,
                        db_host,
                        db_port,
                        db_name,
                        db_username,
                        db_password)
                    if error_message:
                        ok, db_username, db_password = (
                            QgsCredentials.instance().get(
                                self.uri.connectionInfo(),
                                db_username,
                                db_password,
                                error_message))
                        if not ok:
                            break
                    else:
                        break

            else:
                msg = "Please enter the username and password."
                for i in range(max_attempts):
                    ok, db_username, db_password = (
                        QgsCredentials.instance().get(
                            self.uri.connectionInfo(),
                            db_username,
                            db_password,
                            msg))
                    if not ok:
                        break
                    error_message = self.connect_to_db(
                        db_service,
                        db_host,
                        db_port,
                        db_name,
                        db_username,
                        db_password)
                    if not error_message:
                        break

        settings_plugin.endGroup()
        settings_postgis.endGroup()

    def connect_to_db(self, service, host, port, name, username, password):
        username.replace(" ", "")
        password.replace(" ", "")
        try:
            self.database = database.Manager({
                "CONNECTION": self.connection,
                "SERVICE": service,
                "HOST": host,
                "NAME": name,
                "PORT": port,
                "USER": username,
                "PASSWORD": password
            })
            self.uri.setConnection(
                host,
                port,
                name,
                username,
                password)
            self.datetime = datetime.now()
            return None
        except Exception as e:
            self.database = None
            msg = "Invalid username and password."
            return msg

    def refresh_layers(self):
        """ Ensure all required layers exist
        """
        if bool(self.database):
            # Comment out below section because connection name is better
            # to be a group name than crs name IMHO.

            # # first, we need to check the layer group for the crs used by
            # # current database
            # query = "SELECT Find_SRID('public', 'beacons', 'the_geom');"
            # self.database.connect(self.database.parameters)
            # cursor = self.database.cursor
            # cursor.execute(query)
            # crs_id = int(cursor.fetchall()[0][0])
            # del cursor
            # group_name = None
            # for key, value in crs_options.iteritems():
            #     if value == crs_id:
            #         group_name = key

            group_name = self.connection
            group_name_non_spatial_layers = self.connection + '_' + 'lookup'

            target_group = self.insert_group(group_name, 0)
            target_group_non_spatial = self.insert_group(group_name_non_spatial_layers, 1)

            self.populate_tables(target_group, self.required_layers)
            self.populate_tables(target_group_non_spatial, self.required_non_spatial_layers)
            self.style_lookup_tables(self.required_non_spatial_layers, target_group_non_spatial)

    def populate_tables(self, layer_group, layers):
        for required_layer in reversed(layers):
            for layer_node in layer_group.findLayers():
                layer = layer_node.layer()
                if required_layer.name_plural.lower() == \
                        layer.name().lower():
                    layer_group.removeLayer(layer)

        for required_layer in layers:
            if layer_group.name() == self.connection:
                geom_column = required_layer.geometry_column
            else:
                geom_column = None
            self.uri.setDataSource(
                required_layer.schema,
                required_layer.table,
                geom_column,
                '',
                required_layer.primary_key)
            added_layer = QgsVectorLayer(
                self.uri.uri(), required_layer.name_plural, "postgres")
            QgsProject.instance().addMapLayer(added_layer, False)
            layer_group.addLayer(added_layer)
            for layer_node in layer_group.findLayers():
                layer = layer_node.layer()
                if required_layer.name_plural == layer.name():
                    required_layer.layer = layer
                    layer_node.setItemVisibilityChecked(Qt.Checked)
                    if self.crs:
                        layer.setCrs(self.crs)
            self.iface.zoomToActiveLayer()

    def insert_group(self, group_name, position):
        root = QgsProject.instance().layerTreeRoot()
        target_group = root.findGroup(group_name)
        if not bool(target_group):
            target_group = root.insertGroup(position, group_name)
        target_group.setItemVisibilityChecked(Qt.Checked)
        return target_group

    def layer_srid(self):
        for layer in iface.mapCanvas().layers():
            if layer.name() == 'Beacons':
                layer_csr = layer.crs().authid()
                srs = layer_csr.replace("EPSG", "")
            else:
                pass
            return srs

    def style_lookup_tables(self, layers, layer_group):
        crs = self.layer_srid()
        settings_postgis = QSettings()
        settings_postgis.beginGroup('PostgreSQL/connections')
        db_host = settings_postgis.value(self.connection + '/host')
        db_port = settings_postgis.value(self.connection + '/port')
        db_name = settings_postgis.value(self.connection + '/database')
        db_username = settings_postgis.value(self.connection + '/username')
        db_password = settings_postgis.value(self.connection + '/password')

        for required_layer in reversed(layers):
            for layer_node in layer_group.findLayers():
                layer = layer_node.layer()

                if required_layer.name_plural.lower() == layer.name().lower():
                    qml_style = layer.name().lower() + '.qml'
                    full_path = (get_path("documents", "styles", "lookups", qml_style))

                    query = open(full_path, "r").read()
                    query = query.replace(":CRS", "{CRS}").replace(":DATABASE", "{DATABASE}").replace(
                        ":DBOWNER", "{DBOWNER}") \
                        .replace(":DB_HOST", "{DB_HOST}").replace(":DB_PORT", "{DB_PORT}").replace(":DB_PASS",
                                                                                                   "{DB_PASS}")
                    modified_qml = query.format(CRS=crs, DATABASE=db_name, DBOWNER=db_username, DB_HOST=db_host,
                                                DB_PORT=db_port, DB_PASS=db_password)

                    layer.loadNamedStyle(full_path)

    def manage_beacons(self):
        """ Portal which enables the management of beacons
        """
        if self.datetime.date() != datetime.now().date():
            self.database = None
        if self.database is None:
            self.set_database_connection()
            if self.database is None:
                return
        BeaconManager(self.iface, self.database, self.required_layers)
        validate_plugin_actions(self, self.database)
        self.iface.mapCanvas().refresh()

    def manage_parcels(self):
        """ Portal which enables the management of parcels
        """
        if self.datetime.date() != datetime.now().date():
            self.database = None
        if self.database is None:
            self.set_database_connection()
            if self.database is None:
                return
        ParcelManager(self.iface, self.database, self.required_layers)
        validate_plugin_actions(self, self.database)
        self.iface.mapCanvas().refresh()

    def manage_bearing_distance(self):
        """ Portal which enables the management of
        bearings and distances
        """
        if self.datetime.date() != datetime.now().date():
            self.database = None
        if self.database is None:
            self.set_database_connection()
            if self.database is None:
                return

        result = validate_plugin_actions(self, self.database)
        if not result:
            QMessageBox.warning(
                None,
                "SML Surveyor",
                ("No Beacons available in the table. "
                 "Please use Beacon Manager tool to create a Beacon."))
        else:
            BearDistManager(self.iface, self.database, self.required_layers)

        self.iface.mapCanvas().refresh()

    def manage_database_connection(self):
        """ Action to select the db connection to work with.
        """
        database_manager = DatabaseManager()
        connection = database_manager.get_current_connection()
        crs = database_manager.get_current_crs()
        if connection:
            self.set_database_connection(connection=connection, crs=crs)
            self.refresh_layers()
        if self.database:
            validate_plugin_actions(self, self.database)


class DatabaseManager(object):

    def __init__(self):
        self.dialog = DatabaseConnectionDialog()
        self.dialog.show()
        self.current_connection = None
        self.current_crs = None
        if bool(self.dialog.exec_()):
            self.current_connection = self.dialog.get_database_connection()
            self.current_crs = self.dialog.get_crs()
            settings_plugin = QSettings()
            settings_plugin.beginGroup('CoGo Plugin')
            settings_plugin.setValue(
                "DatabaseConnection", self.current_connection)

    def get_current_connection(self):
        return self.current_connection

    def get_current_crs(self):
        return self.current_crs


class BeaconManager(object):

    def __init__(self, iface, database, required_layers):
        self.iface = iface
        self.database = database
        self.required_layers = required_layers
        self.run()

    def run(self):
        """ Main method
        """
        # display manager dialog
        manager_dialog = ManagerDialog(self.required_layers[0])
        manager_dialog.show()
        manager_dialog_ret = manager_dialog.exec_()
        if bool(manager_dialog_ret):

            if manager_dialog.get_option() == 0:  # create new beacon
                while True:
                    # get fields
                    fields = self.database.get_schema(
                        self.required_layers[0].table, [
                            self.required_layers[0].geometry_column,
                            self.required_layers[0].primary_key
                        ])
                    # display form
                    form_dialog = FormBeaconDialog(
                        self.database,
                        SQL_BEACONS["UNIQUE"],
                        fields
                    )
                    form_dialog.show()
                    form_dialog_ret = form_dialog.exec_()
                    if bool(form_dialog_ret):
                        # add beacon to database
                        old_values, new_values = form_dialog.get_values()
                        self.database.query(
                            SQL_BEACONS["INSERT"].format(
                                fields=", ".join(sorted(new_values.keys())),
                                values=", ".join(
                                    ["%s" for k in list(new_values.keys())])),
                            [new_values[k] for k in sorted(new_values.keys())])
                        self.iface.mapCanvas().refresh()
                    else:
                        break

            elif manager_dialog.get_option() == 1:  # edit existing beacon
                # select beacon
                mode = Mode("EDITOR", "EDIT")
                query = SQL_BEACONS["SELECT"]
                selector_dialog = SelectorDialog(
                    self.database,
                    self.iface,
                    self.required_layers[0],
                    mode,
                    query,
                    preserve=True)
                selector_dialog.show()
                selector_dialog_ret = selector_dialog.exec_()
                self.iface.mapCanvas().setMapTool(selector_dialog.tool)
                if bool(selector_dialog_ret):
                    feat_id = selector_dialog.get_feature_id()
                    # check if defined by a bearing and distance
                    if self.database.query(
                            SQL_BEACONS["BEARDIST"], (feat_id,))[0][0]:
                        QMessageBox.warning(
                            None,
                            "Bearing and Distance Definition",
                            "Cannot edit beacon defined by distance "
                            "and bearing via this tool")
                        for required_layer in self.required_layers:
                            required_layer.layer.removeSelection()
                        return
                    # get fields
                    fields = self.database.get_schema(
                        self.required_layers[0].table, [
                            self.required_layers[0].geometry_column,
                            self.required_layers[0].primary_key
                        ])
                    # get values
                    values = [value for value in self.database.query(
                        SQL_BEACONS["EDIT"].format(
                            fields=",".join([field.name for field in fields])),
                        (feat_id,))[0]]
                    # display form
                    form_dialog = FormBeaconDialog(
                        self.database,
                        SQL_BEACONS["UNIQUE"],
                        fields,
                        values)
                    form_dialog.show()
                    form_dialog_ret = form_dialog.exec_()
                    if bool(form_dialog_ret):
                        # edit beacon in database
                        fields_old = []
                        fields_new = []
                        old_values = []
                        new_values = []
                        for field in fields:
                            if form_dialog.get_values()[0][field.name] \
                                    is not None:
                                fields_old.append(field.name)
                                old_values.append(
                                    form_dialog.get_values()[0][field.name])
                            fields_new.append(field.name)
                            new_values.append(
                                form_dialog.get_values()[1][field.name])
                        set = ", ".join(
                            ["{field} = %s".format(field=field)
                             for field in fields_new])
                        where = " AND ".join(
                            ["{field} = %s".format(field=field)
                             for field in fields_old])
                        self.database.query(
                            SQL_BEACONS["UPDATE"].format(
                                set=set,
                                where=where),
                            new_values + old_values)
                for required_layer in self.required_layers:
                    required_layer.layer.removeSelection()

            elif manager_dialog.get_option() == 2:  # delete existing beacon
                # select beacon
                mode = Mode("REMOVER", "REMOVE")
                query = SQL_BEACONS["SELECT"]
                selector_dialog = SelectorDialog(
                    self.database,
                    self.iface,
                    self.required_layers[0],
                    mode,
                    query,
                    preserve=True)
                selector_dialog.show()
                selector_dialog_ret = selector_dialog.exec_()
                self.iface.mapCanvas().setMapTool(selector_dialog.tool)
                if bool(selector_dialog_ret):
                    feat_id = selector_dialog.get_feature_id()
                    # check if defined by a bearing and distance
                    if self.database.query(
                            SQL_BEACONS["BEARDIST"],
                            (feat_id,))[0][0]:
                        QMessageBox.warning(
                            None,
                            "Bearing and Distance Definition",
                            "Cannot delete beacon defined by distance "
                            "and bearing via this tool")
                        for required_layer in self.required_layers:
                            required_layer.layer.removeSelection()
                        return
                    # delete beacon from database
                    self.database.query(SQL_BEACONS["DELETE"], (feat_id,))
                for required_layer in self.required_layers:
                    required_layer.layer.removeSelection()


class ParcelManager(object):

    def __init__(self, iface, database, required_layers):
        self.iface = iface
        self.database = database
        self.required_layers = required_layers
        self.run()

    def run(self):
        """ Main method
        """
        # display manager dialog
        manager_dialog = ManagerDialog(self.required_layers[1])
        manager_dialog.show()
        manager_dialog_ret = manager_dialog.exec_()
        if bool(manager_dialog_ret):

            if manager_dialog.get_option() == 0:  # create new parcel
                while True:
                    # show parcel form
                    auto_complete = [
                        str(i[0]) for i in self.database.query(
                            SQL_PARCELS["AUTOCOMPLETE"])]
                    form_dialog = FormParcelDialog(
                        self.database,
                        self.iface,
                        self.required_layers,
                        SQL_BEACONS,
                        SQL_PARCELS,
                        auto_complete)
                    form_dialog.show()
                    form_dialog_ret = form_dialog.exec_()
                    self.iface.mapCanvas().setMapTool(form_dialog.tool)
                    if bool(form_dialog_ret):
                        # add parcel to database
                        points = []
                        for i, beacon in enumerate(
                                form_dialog.get_values()[1]["sequence"]):
                            points.append((
                                form_dialog.get_values()[1]["parcel_id"],
                                beacon,
                                i))
                        sql = self.database.preview_query(
                            SQL_PARCELS["INSERT_GENERAL"],
                            data=points,
                            multi_data=True)
                        self.database.query(sql)
                        self.iface.mapCanvas().refresh()
                    else:
                        break
                for required_layer in self.required_layers:
                    required_layer.layer.removeSelection()

            elif manager_dialog.get_option() == 1:  # edit existing parcel
                # select parcel
                mode = Mode("EDITOR", "EDIT")
                query = SQL_PARCELS["SELECT"]
                selector_dialog = SelectorDialog(
                    self.database,
                    self.iface,
                    self.required_layers[1],
                    mode,
                    query,
                    preserve=True)
                selector_dialog.show()
                selector_dialog_ret = selector_dialog.exec_()
                self.iface.mapCanvas().setMapTool(selector_dialog.tool)
                if bool(selector_dialog_ret):
                    # show parcel form
                    auto_complete = [
                        str(i[0]) for i in self.database.query(
                            SQL_PARCELS["AUTOCOMPLETE"])]
                    data = (lambda t: {"parcel_id": t[0], "sequence": t[1]})(
                        self.database.query(
                            SQL_PARCELS["EDIT"],
                            (selector_dialog.get_feature_id(),))[0])
                    form_dialog = FormParcelDialog(
                        self.database,
                        self.iface,
                        self.required_layers,
                        SQL_BEACONS,
                        SQL_PARCELS,
                        auto_complete,
                        data)
                    form_dialog.show()
                    form_dialog_ret = form_dialog.exec_()
                    self.iface.mapCanvas().setMapTool(form_dialog.tool)
                    if bool(form_dialog_ret):
                        # edit parcel in database
                        self.database.query(
                            SQL_PARCELS["DELETE"],
                            (form_dialog.get_values()[0]["parcel_id"],))
                        points = []
                        for i, beacon in enumerate(
                                form_dialog.get_values()[1]["sequence"]):
                            points.append((
                                form_dialog.get_values()[1]["parcel_id"],
                                beacon,
                                i))
                        sql = self.database.preview_query(
                            SQL_PARCELS["INSERT_GENERAL"],
                            data=points,
                            multi_data=True)
                        self.database.query(sql)
                for required_layer in self.required_layers:
                    required_layer.layer.removeSelection()

            elif manager_dialog.get_option() == 2:  # delete existing parcel
                # select parcel
                mode = Mode("REMOVER", "REMOVE")
                query = SQL_PARCELS["SELECT"]
                selector_dialog = SelectorDialog(
                    self.database,
                    self.iface,
                    self.required_layers[1],
                    mode,
                    query,
                    preserve=True)
                selector_dialog.show()
                selector_dialog_ret = selector_dialog.exec_()
                self.iface.mapCanvas().setMapTool(selector_dialog.tool)
                if bool(selector_dialog_ret):
                    # delete parcel from database
                    feat_id = selector_dialog.get_feature_id()
                    self.database.query(
                        SQL_PARCELS["DELETE"],
                        (self.database.query(
                            SQL_PARCELS["SELECT"],
                            (feat_id,))[0][0],))
                for required_layer in self.required_layers:
                    required_layer.layer.removeSelection()


class BearDistManager(object):

    def __init__(self, iface, database, required_layers):
        self.iface = iface
        self.database = database
        self.required_layers = required_layers
        self.run()

    def run(self):
        """ Main method
        """
        dialog = BearingDistanceFormDialog(
            self.database,
            SQL_BEARDIST,
            SQL_BEACONS,
            self.required_layers)
        dialog.show()
        dialog_ret = dialog.exec_()
        if bool(dialog_ret):
            survey_plan, reference_beacon, beardist_chain = dialog.get_return()
            # check whether survey plan is defined otherwise define it
            if not self.database.query(
                    SQL_BEARDIST["IS_SURVEYPLAN"],
                    (survey_plan,))[0][0]:
                self.database.query(
                    SQL_BEARDIST["INSERT_SURVEYPLAN"],
                    (survey_plan, reference_beacon))
            # get list of existing links
            existing_chain = []
            for index, link in enumerate(
                    self.database.query(
                        SQL_BEARDIST["EXIST_BEARDISTCHAINS"],
                        (survey_plan,))):
                existing_chain.append([list(link), "NULL", index])
            # perform appropriate action for each link in the beardist chain
            new = []
            old = []
            for link in beardist_chain:
                if link[2] is None:
                    new.append(link)
                else:
                    old.append(link)
            # sort out old links
            temp = list(existing_chain)
            for existing_link in existing_chain:
                for old_link in old:
                    if existing_link[2] == old_link[2]:
                        if old_link[1] == "NULL":
                            temp.remove(existing_link)
                            break
                        self.database.query(
                            SQL_BEARDIST["UPDATE_LINK"],
                            [survey_plan] + old_link[0] + [old_link[2]])
                        temp.remove(existing_link)
                        break
            existing_chain = temp
            for existing_link in existing_chain:
                self.database.query(
                    SQL_BEARDIST["DELETE_LINK"],
                    (existing_link[0][3],))
            # sort out new links
            for new_link in new:
                self.database.query(
                    SQL_BEARDIST["INSERT_LINK"],
                    [survey_plan] + new_link[0])
