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

# qgis imports
from PyQt4.QtCore import *
from PyQt4.QtGui import *
from qgis.core import *
# python imports
import os
# user imports
import __init__ as metadata
from PyQt4Dialogs import *
import database
from constants import *
from datetime import datetime


class RequiredLayer:

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


class Mode:

    def __init__(self, actor, action):
        self.actor = actor
        self.action = action


class SMLSurveyor:

    def __init__(self, iface):
        # save reference to the QGIS interface
        self.iface = iface
        # get plugin directory
        self.plugin_dir = os.path.dirname(os.path.realpath(__file__))
        self.uri = None
        self.database = None
        self.datetime = datetime.now()
        self.required_layers = []
        # 1. beacons
        # 2. parcels
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
                QgsMapLayerRegistry.instance().removeMapLayers([l.layer.id()])

    def create_plugin_toolbar(self):
        """ Create plugin toolbar to house buttons
        """
        # create plugin toolbar
        self.plugin_toolbar = QToolBar(metadata.name())
        self.plugin_toolbar.setObjectName(metadata.name())
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

    def set_database_connection(self):
        """ Create a database connection
        """
        # fetch settings
        settings_plugin = QSettings()
        settings_postgis = QSettings()
        settings_plugin.beginGroup(metadata.name().replace(" ", "_"))
        settings_postgis.beginGroup('PostgreSQL/connections')
        # fetch pre-chosen database connection
        connection = settings_plugin.value("DatabaseConnection", None)
        # check if still exists
        if bool(connection):
            if connection not in settings_postgis.childGroups():
                settings_plugin.setValue("DatabaseConnection", "")
                connection = None
        # fetch from user if necessary
        if not bool(connection):
            dialog = DatabaseConnectionDialog()
            dialog.show()
            if bool(dialog.exec_()):
                connection = dialog.get_database_connection()
                settings_plugin.setValue("DatabaseConnection", connection)
        # validate database connection
        if bool(connection):
            db_host = settings_postgis.value(connection + '/host')
            db_port = settings_postgis.value(connection + '/port')
            db_name = settings_postgis.value(connection + '/database')
            db_username = settings_postgis.value(connection + '/username')
            db_password = settings_postgis.value(connection + '/password')

            max_attempts = 3
            self.uri = QgsDataSourceURI()
            self.uri.setConnection(
                db_host,
                db_port,
                db_name,
                db_username,
                db_password)

            if db_username and db_password:
                for i in range(max_attempts):
                    error_message = self.connect_to_db(
                        db_host, db_port, db_name, db_username, db_password)
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
                        db_host, db_port, db_name, db_username, db_password)
                    if not error_message:
                        break

        settings_plugin.endGroup()
        settings_postgis.endGroup()

    def connect_to_db(self, host, port, name, username, password):
        username.replace(" ", "")
        password.replace(" ", "")
        try:
            self.database = database.Manager({
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
            for required_layer in reversed(self.required_layers):
                for layer in self.iface.legendInterface().layers():
                    if required_layer.name_plural.lower() == \
                            layer.name().lower():
                        required_layer.layer = layer
                        break
                if not bool(required_layer.layer):
                    self.uri.setDataSource(
                        required_layer.schema,
                        required_layer.table,
                        required_layer.geometry_column,
                        '',
                        required_layer.primary_key)
                    self.iface.addVectorLayer(
                        self.uri.uri(),
                        required_layer.name_plural,
                        "postgres")
                    for layer in self.iface.legendInterface().layers():
                        if required_layer.name_plural == layer.name():
                            required_layer.layer = layer
                            self.iface.legendInterface().setLayerVisible(
                                layer, True)
                    self.iface.zoomToActiveLayer()

    def manage_beacons(self):
        """ Portal which enables the management of beacons
        """
        if self.datetime.date() != datetime.now().date():
            self.database = None
        if self.database is None:
            self.set_database_connection()
            if self.database is None:
                return
        self.refresh_layers()
        BeaconManager(self.iface, self.database, self.required_layers)
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
        self.refresh_layers()
        ParcelManager(self.iface, self.database, self.required_layers)
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
        self.refresh_layers()
        BearDistManager(self.iface, self.database, self.required_layers)
        self.iface.mapCanvas().refresh()


class BeaconManager():

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
                                    ["%s" for k in new_values.keys()])),
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


class ParcelManager():

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


class BearDistManager():

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
