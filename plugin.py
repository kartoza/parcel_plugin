# -*- coding: utf-8 -*-
"""
/***************************************************************************
 sml_surveyor
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

    def __init__(self,
        name,
        name_plural,
        table,
        primary_key,
        geometry_type,
        geometry_column='the_geom',
        schema='public',
        layer=None
    ):
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


class sml_surveyor:

    def __init__(self, iface):
        # save reference to the QGIS interface
        self.iface = iface
        # get plugin directory
        self.plugin_dir = os.path.dirname(os.path.realpath(__file__))
        self.uri = None
        self.db = None
        self.datetime = datetime.now()
        self.requiredLayers = []
        # 1. beacons
        # 2. parcels
        self.requiredLayers.append(RequiredLayer(
            'Beacon', 'Beacons', 'beacons', 'gid', 'points'
        ))
        self.requiredLayers.append(RequiredLayer(
            'Parcel', 'Parcels', 'parcels', 'parcel_id', 'polygons'
        ))


    def initGui(self):
        """ Initialize gui
        """
        # create plugin toolbar
        self.createPluginToolBar()


    def unload(self):
        """ Uninitialize gui
        """
        # remove plugin toolbar
        self.removePluginToolBar()
        # remove layers
        self.refreshLayers()
        for l in self.requiredLayers:
            if bool(l.layer):
                QgsMapLayerRegistry.instance().removeMapLayers([l.layer.id(),])


    def createPluginToolBar(self):
        """ Create plugin toolbar to house buttons
        """
         # create plugin toolbar
        self.pluginToolBar = QToolBar(metadata.name())
        self.pluginToolBar.setObjectName(metadata.name())
        # create Beardist button
        self.actionBearDist = QAction(
            QIcon(os.path.join(self.plugin_dir, "images", "beardist.png")),
            "Manage Bearings and Distances",
            self.iface.mainWindow()
        )
        self.actionBearDist.setWhatsThis("Manage bearings and distances")
        self.actionBearDist.setStatusTip("Manage bearings and distances")
        self.actionBearDist.triggered.connect(self.manageBearDist)
        # create Beacons button
        self.actionBeacons = QAction(
            QIcon(os.path.join(self.plugin_dir, "images", "beacon.gif")),
            "Manage Beacons",
            self.iface.mainWindow()
        )
        self.actionBeacons.setWhatsThis("Manage beacons")
        self.actionBeacons.setStatusTip("Manage beacons")
        self.actionBeacons.triggered.connect(self.manageBeacons)
        # create Parcels button
        self.actionParcels = QAction(
            QIcon(os.path.join(self.plugin_dir, "images", "parcel.png")),
            "Manage Parcels",
            self.iface.mainWindow()
        )
        self.actionParcels.setWhatsThis("Manage parcels")
        self.actionParcels.setStatusTip("Manage parcels")
        self.actionParcels.triggered.connect(self.manageParcels)
        # populate plugin toolbar
        self.pluginToolBar.addAction(self.actionBearDist)
        self.pluginToolBar.addAction(self.actionBeacons)
        self.pluginToolBar.addAction(self.actionParcels)
        # add plugin toolbar to gui
        self.iface.mainWindow().addToolBar(self.pluginToolBar)


    def removePluginToolBar(self):
        """ Remove plugin toolbar which houses buttons
        """
        # remove app toolbar from gui
        if hasattr(self,"pluginToolBar"):
            self.iface.mainWindow().removeToolBar(self.pluginToolBar)
            self.pluginToolBar.hide()


    def setDatabaseConnection(self):
        """ Create a database connection
        """
        # fetch settings
        settings_plugin = QSettings()
        settings_postgis = QSettings()
        settings_plugin.beginGroup(metadata.name().replace(" ","_"))
        settings_postgis.beginGroup('PostgreSQL/connections')
        # fetch pre-chosen database connection
        conn = settings_plugin.value("DatabaseConnection", None)
        # check if still exists
        if bool(conn):
            if conn not in settings_postgis.childGroups():
                settings_plugin.setValue("DatabaseConnection", "")
                conn = None
        # fetch from user if necessary
        if not bool(conn):
            dlg = dlg_DatabaseConnection()
            dlg.show()
            if bool(dlg.exec_()):
                conn = dlg.getDatabaseConnection()
                settings_plugin.setValue("DatabaseConnection", conn)
        # validate database connection
        if bool(conn):
            db_host = settings_postgis.value(conn+'/host')
            db_port = settings_postgis.value(conn+'/port')
            db_name = settings_postgis.value(conn+'/database')
            db_username = ''
            db_password = ''
            self.uri = QgsDataSourceURI()
            self.uri.setConnection(
                db_host,
                db_port,
                db_name,
                db_username,
                db_password,
            )
            max_attempts = 3
            msg = "Please enter the username and password."
            for i in range(max_attempts):
                ok, db_username, db_password = QgsCredentials.instance().get(
                    self.uri.connectionInfo(),
                    db_username,
                    db_password,
                    msg
                )
                if not ok: break
                db_username.replace(" ", "")
                db_password.replace(" ", "")
                try:
                    self.db = database.Manager({
                        "HOST":db_host,
                        "NAME":db_name,
                        "PORT":db_port,
                        "USER":db_username,
                        "PASSWORD":db_password
                    })
                    self.uri.setConnection(
                        db_host,
                        db_port,
                        db_name,
                        db_username,
                        db_password,
                    )
                    self.datetime = datetime.now()
                    break
                except Exception as e:
                    msg = "Invalid username and password."
        settings_plugin.endGroup()
        settings_postgis.endGroup()


    def refreshLayers(self):
        """ Ensure all required layers exist
        """
        if bool(self.db):
            for l in reversed(self.requiredLayers):
                for layer in self.iface.legendInterface().layers():
                    if l.name_plural.lower() == layer.name().lower():
                        l.layer = layer
                        break
                if not bool(l.layer):
                    self.uri.setDataSource(
                        l.schema,
                        l.table,
                        l.geometry_column,
                        '',
                        l.primary_key
                    )
                    self.iface.addVectorLayer(
                        self.uri.uri(),
                        l.name_plural,
                        "postgres"
                    )
                    for layer in self.iface.legendInterface().layers():
                        if l.name_plural == layer.name(): l.layer = layer


    def manageBeacons(self):
        """ Portal which enables the management of beacons
        """
        if self.datetime.date() != datetime.now().date(): self.db = None
        if self.db is None:
            self.setDatabaseConnection()
            if self.db is None: return
        self.refreshLayers()
        BeaconManager(self.iface, self.db, self.requiredLayers)
        self.iface.mapCanvas().refresh()


    def manageParcels(self):
        """ Portal which enables the management of parcels
        """
        if self.datetime.date() != datetime.now().date(): self.db = None
        if self.db is None:
            self.setDatabaseConnection()
            if self.db is None: return
        self.refreshLayers()
        ParcelManager(self.iface, self.db, self.requiredLayers)
        self.iface.mapCanvas().refresh()


    def manageBearDist(self):
        """ Portal which enables the management of
        bearings and distances
        """
        if self.datetime.date() != datetime.now().date(): self.db = None
        if self.db is None:
            self.setDatabaseConnection()
            if self.db is None: return
        self.refreshLayers()
        BearDistManager(self.iface, self.db, self.requiredLayers)
        self.iface.mapCanvas().refresh()


class BeaconManager():

    def __init__(self, iface, db, requiredLayers):
        self.iface = iface
        self.db = db
        self.requiredLayers = requiredLayers
        self.run()


    def run(self):
        """ Main method
        """
        # display manager dialog
        mng = dlg_Manager(self.requiredLayers[0])
        mng.show()
        mng_ret = mng.exec_()
        if bool(mng_ret):

            if mng.getOption() == 0: # create new beacon
                while True:
                    # get fields
                    fields = self.db.getSchema(
                        self.requiredLayers[0].table, [
                        self.requiredLayers[0].geometry_column,
                        self.requiredLayers[0].primary_key
                    ])
                    # display form
                    frm = dlg_FormBeacon(
                        self.db,
                        SQL_BEACONS["UNIQUE"],
                        fields
                    )
                    frm.show()
                    frm_ret = frm.exec_()
                    if bool(frm_ret):
                        # add beacon to database
                        values_old, values_new = frm.getValues()
                        self.db.query(
                            SQL_BEACONS["INSERT"].format(fields = ", ".join(sorted(values_new.keys())), values = ", ".join(["%s" for k in values_new.keys()])), [values_new[k] for k in sorted(values_new.keys())])
                        self.iface.mapCanvas().refresh()
                    else: break

            elif mng.getOption() == 1: # edit existing beacon
                # select beacon
                mode = Mode("EDITOR","EDIT")
                query = SQL_BEACONS["SELECT"]
                slc = dlg_Selector(
                    self.db,
                    self.iface,
                    self.requiredLayers[0],
                    mode,
                    query,
                    preserve = True
                )
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    featID = slc.getFeatureId()
                    # check if defined by a bearing and distance
                    if self.db.query(SQL_BEACONS["BEARDIST"], (featID,))[0][0]:
                        QMessageBox.warning(
                            None,
                            "Bearing and Distance Definition",
                            "Cannot edit beacon defined by distance and bearing via this tool"
                        )
                        for l in self.requiredLayers: l.layer.removeSelection()
                        return
                    # get fields
                    fields = self.db.getSchema(
                        self.requiredLayers[0].table, [
                        self.requiredLayers[0].geometry_column,
                        self.requiredLayers[0].primary_key
                    ])
                    # get values
                    values = [v for v in self.db.query(SQL_BEACONS["EDIT"].format(fields = ",".join([f.name for f in fields])), (featID,))[0]]
                    # display form
                    frm = dlg_FormBeacon(
                        self.db,
                        SQL_BEACONS["UNIQUE"],
                        fields,
                        values
                    )
                    frm.show()
                    frm_ret = frm.exec_()
                    if bool(frm_ret):
                        # edit beacon in database
                        fields_old = []
                        fields_new = []
                        values_old = []
                        values_new = []
                        for f in fields:
                            if frm.getValues()[0][f.name] is not None:
                                fields_old.append(f.name)
                                values_old.append(frm.getValues()[0][f.name])
                            fields_new.append(f.name)
                            values_new.append(frm.getValues()[1][f.name])
                        set = ", ".join(["{field} = %s".format(field = f) for f in fields_new])
                        where = " AND ".join(["{field} = %s".format(field = f) for f in fields_old])
                        self.db.query(
                            SQL_BEACONS["UPDATE"].format(
                                set = set,
                                where = where
                            ), values_new + values_old
                        )
                for l in self.requiredLayers: l.layer.removeSelection()

            elif mng.getOption() == 2: # delete existing beacon
                # select beacon
                mode = Mode("REMOVER","REMOVE")
                query = SQL_BEACONS["SELECT"]
                slc = dlg_Selector(
                    self.db,
                    self.iface,
                    self.requiredLayers[0],
                    mode,
                    query,
                    preserve = True
                )
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    featID = slc.getFeatureId()
                    # check if defined by a bearing and distance
                    if self.db.query(SQL_BEACONS["BEARDIST"], (featID,))[0][0]:
                        QMessageBox.warning(None, "Bearing and Distance Definition", "Cannot delete beacon defined by distance and bearing via this tool")
                        for l in self.requiredLayers: l.layer.removeSelection()
                        return
                    # delete beacon from database
                    self.db.query(SQL_BEACONS["DELETE"], (featID,))
                for l in self.requiredLayers: l.layer.removeSelection()


class ParcelManager():

    def __init__(self, iface, db, requiredLayers):
        self.iface = iface
        self.db = db
        self.requiredLayers = requiredLayers
        self.run()


    def run(self):
        """ Main method
        """
        # display manager dialog
        mng = dlg_Manager(self.requiredLayers[1])
        mng.show()
        mng_ret = mng.exec_()
        if bool(mng_ret):

            if mng.getOption() == 0: # create new parcel
                while True:
                    # show parcel form
                    autocomplete = [str(i[0]) for i in self.db.query(
                        SQL_PARCELS["AUTOCOMPLETE"]
                    )]
                    frm = dlg_FormParcel(
                        self.db,
                        self.iface,
                        self.requiredLayers,
                        SQL_BEACONS,
                        SQL_PARCELS,
                        autocomplete
                    )
                    frm.show()
                    frm_ret = frm.exec_()
                    self.iface.mapCanvas().setMapTool(frm.tool)
                    if bool(frm_ret):
                        # add parcel to database
                        points = []
                        for i, beacon in enumerate(frm.getValues()[1]["sequence"]):
                            points.append(
                                (frm.getValues()[1]["parcel_id"], beacon, i))
                        sql = self.db.queryPreview(
                                SQL_PARCELS["INSERT"],
                                data=points,
                                multi_data=True
                        )
                        print sql
                        self.db.query(sql)
                        self.iface.mapCanvas().refresh()
                    else:
                        break
                for l in self.requiredLayers: l.layer.removeSelection()

            elif mng.getOption() == 1: # edit existing parcel
                # select parcel
                mode = Mode("EDITOR","EDIT")
                query = SQL_PARCELS["SELECT"]
                slc = dlg_Selector(
                    self.db,
                    self.iface,
                    self.requiredLayers[1],
                    mode,
                    query,
                    preserve = True
                )
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    # show parcel form
                    autocomplete = [str(i[0]) for i in self.db.query(
                        SQL_PARCELS["AUTOCOMPLETE"]
                    )]
                    data = (lambda t: {"parcel_id":t[0], "sequence":t[1]})(
                        self.db.query(
                            SQL_PARCELS["EDIT"], (slc.getFeatureId(),)
                        )[0]
                    )
                    frm = dlg_FormParcel(
                        self.db,
                        self.iface,
                        self.requiredLayers,
                        SQL_BEACONS,
                        SQL_PARCELS,
                        autocomplete,
                        data
                    )
                    frm.show()
                    frm_ret = frm.exec_()
                    self.iface.mapCanvas().setMapTool(frm.tool)
                    if bool(frm_ret):
                        # edit parcel in database
                        self.db.query(
                            SQL_PARCELS["DELETE"],
                            (frm.getValues()[0]["parcel_id"],)
                        )
                        sql = ""
                        for i, beacon in enumerate(frm.getValues()[1]["sequence"]):
                            sql += self.db.queryPreview(
                                SQL_PARCELS["INSERT"],
                                (frm.getValues()[1]["parcel_id"], beacon, i)
                            )
                        self.db.query(sql)
                for l in self.requiredLayers: l.layer.removeSelection()

            elif mng.getOption() == 2: # delete existing parcel
                # select parcel
                mode = Mode("REMOVER","REMOVE")
                query = SQL_PARCELS["SELECT"]
                slc = dlg_Selector(
                    self.db,
                    self.iface,
                    self.requiredLayers[1],
                    mode,
                    query,
                    preserve = True
                )
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    # delete parcel from database
                    featID = slc.getFeatureId()
                    self.db.query(SQL_PARCELS["DELETE"], (self.db.query(
                        SQL_PARCELS["SELECT"], (featID,)
                    )[0][0],))
                for l in self.requiredLayers: l.layer.removeSelection()


class BearDistManager():

    def __init__(self, iface, db, requiredLayers):
        self.iface = iface
        self.db = db
        self.requiredLayers = requiredLayers
        self.run()

    def run(self):
        """ Main method
        """
        dlg = dlg_FormBearDist(
            self.db,
            SQL_BEARDIST,
            SQL_BEACONS,
            self.requiredLayers
        )
        dlg.show()
        dlg_ret = dlg.exec_()
        if bool(dlg_ret):
            surveyPlan, referenceBeacon, beardistChain = dlg.getReturn()
            # check whether survey plan is defined otherwise define it
            if not self.db.query(
                SQL_BEARDIST["IS_SURVEYPLAN"],
                (surveyPlan,)
            )[0][0]:
                self.db.query(
                    SQL_BEARDIST["INSERT_SURVEYPLAN"],
                    (surveyPlan, referenceBeacon)
                )
            # get list of existing links
            beardistChainExisting = []
            for index, link in enumerate(self.db.query(SQL_BEARDIST["EXIST_BEARDISTCHAINS"],(surveyPlan,))):
                beardistChainExisting.append([list(link), "NULL", index])
            # perform appropriate action for each link in the beardist chain
            new = []
            old = []
            for link in beardistChain:
                if link[2] is None: new.append(link)
                else: old.append(link)
            # sort out old links
            tmp = list(beardistChainExisting)
            for elink in beardistChainExisting:
                for olink in old:
                    if elink[2] == olink[2]:
                        if olink[1] == "NULL":
                            tmp.remove(elink)
                            break;
                        self.db.query(
                            SQL_BEARDIST["UPDATE_LINK"],
                            [surveyPlan] + olink[0] + [olink[2]]
                        )
                        tmp.remove(elink)
                        break;
            beardistChainExisting = tmp
            for elink in beardistChainExisting:
                self.db.query(
                    SQL_BEARDIST["DELETE_LINK"],
                    (elink[0][3],)
                )
            # sort out new links
            for nlink in new:
                self.db.query(
                    SQL_BEARDIST["INSERT_LINK"],
                    [surveyPlan] + nlink[0]
                )
