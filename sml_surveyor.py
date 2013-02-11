# -*- coding: utf-8 -*-
"""
/***************************************************************************
 sml_surveyor
                                 A QGIS plugin
 SML Surveyor Plugin
                              -------------------
        begin                : 2012-12-28
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

from PyQt4.QtCore import *
from PyQt4.QtGui import *
from qgis.core import *
import __init__ as meta
import database
import settings
from PyQt4Dialogs import *
import json
import os

class sml_surveyor:

    def __init__(self, iface):
        # Save reference to the QGIS interface
        self.iface = iface
        # initialize plugin directory
        self.plugin_dir = os.path.dirname(os.path.realpath(__file__))      
        # initialize locale
        localePath = ""
        locale = QSettings().value("locale/userLocale").toString()[0:2]
        if QFileInfo(self.plugin_dir).exists():
            localePath = os.path.join(self.plugin_dir, "i18n", "sml_surveyor_" + str(locale) + ".qm")
        if QFileInfo(localePath).exists():
            self.translator = QTranslator()
            self.translator.load(localePath)
            if qVersion() > '4.3.3':
                QCoreApplication.installTranslator(self.translator)
        # initialize instance variables
        self.layers = {}
        self.db = None

    def initGui(self):
        """ Initialize gui
        """
        # find database
        self.db = None
        try:
            self.db = database.manager(settings.DATABASE_PARAMS)
        except:
            QMessageBox.information(None, "Configure Database Settings", "Please define database parameters.")
            if not(self.manageDatabase()): raise Exception("Unspecied database parameters")
        # find layers
        self.getLayers()
        # add app toolbar
        self.createAppToolBar()
        
    def unload(self):
        """ Uninitialize gui
        """
        # remove layers
        #self.dropLayers()
        # remove app toolbar
        self.removeAppToolBar()

    def createAppToolBar(self):
        """ Create plugin toolbar to house buttons
        """
        # create app toolbar
        self.appToolBar = QToolBar(meta.name())
        self.appToolBar.setObjectName(meta.name())
        # create apps for toolbar
        self.actionBearDist = QAction(QIcon(os.path.join(self.plugin_dir, "images", "beardist.png")), "Manage Bearings and Distances", self.iface.mainWindow())
        self.actionBearDist.triggered.connect(self.manageBearDist)        
        self.actionBeacons = QAction(QIcon(os.path.join(self.plugin_dir, "images", "beacon.gif")), "Manage %s" %(settings.DATABASE_LAYERS["BEACONS"]["NAME_PLURAL"].title(),), self.iface.mainWindow())
        self.actionBeacons.triggered.connect(self.manageBeacons)
        self.actionParcels = QAction(QIcon(os.path.join(self.plugin_dir, "images", "parcel.png")), "Manage %s" %(settings.DATABASE_LAYERS["PARCELS"]["NAME_PLURAL"].title(),), self.iface.mainWindow())
        self.actionParcels.triggered.connect(self.manageParcels)
        # populate app toolbar
        #self.appToolBar.addAction(self.actionBearDist)
        self.appToolBar.addAction(self.actionBeacons)
        self.appToolBar.addAction(self.actionParcels)
        # add app toolbar to gui
        self.iface.mainWindow().addToolBar(self.appToolBar)

    def removeAppToolBar(self):
        """ Remove plugin toolbar which houses buttons
        """
        # remove app toolbar from gui
        if hasattr(self,"appToolBar"): self.iface.mainWindow().removeToolBar(self.appToolBar)

    def addLayers(self):
        """ Add postgres layers
        """
        uri = QgsDataSourceURI()
        uri.setConnection(settings.DATABASE_HOST, settings.DATABASE_PORT, settings.DATABASE_NAME, settings.DATABASE_USER, settings.DATABASE_PASSWORD)
        for name in reversed(settings.DATABASE_LAYERS_ORDER):
            lyr = settings.DATABASE_LAYERS[name]
            uri.setDataSource(lyr["SCHEMA"], lyr["TABLE"], lyr["GEOM"], "", lyr["PKEY"])
            self.iface.addVectorLayer(uri.uri(), lyr["NAME_PLURAL"], "postgres")
    
    def getLayers(self):
        """ Save reference to added postgis layers
        """
        self.layers = {}
        names = list(settings.DATABASE_LAYERS_ORDER)
        for l in self.iface.legendInterface().layers():
            for n in names:
                if settings.DATABASE_LAYERS[n]["NAME_PLURAL"].lower() == str(l.name()).lower(): 
                    self.layers[n] = l
                    names.remove(n)
    
    def showLayers(self):
        """ Show added postgis layers on map canvas
        """
        for n,l in self.layers.items():
            self.iface.legendInterface().setLayerVisible(l, True)
            l.loadNamedStyle(os.path.join(self.plugin_dir, "styles", "%s.qml" %(n.lower(),)))

    def dropLayers(self):
        """ Drop added postgis layers
        """        
        self.getLayers()
        QgsMapLayerRegistry.instance().removeMapLayers([l.id() for l in self.layers.values()])
            
    def manageBeacons(self):
        """ Portal which enables the management of beacons
        """
        self.manageLayers()
        p = Beacons(self.iface, self.layers, settings.DATABASE_LAYERS, self.db)
        p.run()
        self.iface.mapCanvas().refresh()

    def manageParcels(self):
        """ Portal which enables the management of parcels
        """
        self.manageLayers()
        p = Parcels(self.iface, self.layers, settings.DATABASE_LAYERS, self.db)
        p.run()
        self.iface.mapCanvas().refresh()

    def manageDatabase(self):
        """ Portal which enables configuration of database settings
        """
        dlg = dlg_FormDatabase()
        dlg.show()
        if bool(dlg.exec_()):            
            save, db, params = dlg.getReturn()
            # save new db reference
            self.db = db
            # save new params if needed
            if save:
                import os
                p = os.path.join(os.path.dirname(__file__), 'database_params.py')
                f = open(p, 'w')
                f.write('DATABASE_PARAMS = %s' %(json.dumps(params),))
                f.close()
                reload(settings.database_params)
                reload(settings)
            return True
        return False

    def manageBearDist(self):
        """
        """
        dlg = dlg_FormBearDist(self.db, settings.DATABASE_OTHER_SQL, settings.DATABASE_LAYERS["BEACONS"]["SQL"], self.db.getSchema(settings.DATABASE_LAYERS["BEACONS"]["TABLE"], [settings.DATABASE_LAYERS["BEACONS"]["GEOM"], settings.DATABASE_LAYERS["BEACONS"]["PKEY"]]))
        self.manageLayers()
        #dlg = dlg_FormBearDistLink(["lol","loll","lolly"])
        dlg.show()
        dlg.exec_()

    def manageLayers(self):
        """ Load layers if not yet loaded
        """
        self.getLayers()
        if len(self.layers.keys()) != len(settings.DATABASE_LAYERS.keys()):
            self.dropLayers()
            self.addLayers()
            self.getLayers()    
        self.showLayers()

class Parcels():
    """ Class managing parcels
    """

    def __init__(self, iface, layers, layersDict, db):
        self.iface = iface
        self.layers = layers
        self.layersDict = layersDict
        self.db = db
        
    def run(self):
        """ Main method
        """
        # display manager dialog
        mng = dlg_Manager(obj = {"NAME":self.layersDict["PARCELS"]["NAME"],})
        mng.show()
        if bool(mng.exec_()):
            if mng.getReturn() == 0:
                while True:
                    # create new parcel
                    autocomplete = [i[0] for i in self.db.query(self.layersDict["PARCELS"]["SQL"]["AUTOCOMPLETE"])]
                    frm = dlg_FormParcel(self.db, self.iface, self.layers, self.layersDict, autocomplete)
                    frm.show()
                    frm_ret = frm.exec_()
                    self.iface.mapCanvas().setMapTool(frm.tool)
                    if bool(frm_ret):
                        sql = ""
                        for i, beacon in enumerate(frm.getReturn()[1]["sequence"]):
                            sql += self.db.queryPreview(self.layersDict["PARCELS"]["SQL"]["INSERT"], (frm.getReturn()[1]["parcel_id"], beacon, i))
                        self.db.query(sql)
                        self.iface.mapCanvas().refresh()
                    else:
                        break
                for l in self.layers.values(): l.removeSelection()
            elif mng.getReturn() == 1:
                # edit existing parcel 
                obj = {"NAME":self.layersDict["PARCELS"]["NAME"],"PURPOSE":"EDITOR","ACTION":"EDIT"}
                slc = dlg_Selector(self.db, self.iface, self.layers["PARCELS"], self.layersDict["PARCELS"]["SQL"], obj = obj, preserve = True)
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    autocomplete = [i[0] for i in self.db.query(self.layersDict["PARCELS"]["SQL"]["AUTOCOMPLETE"])]
                    values = (lambda t: {"parcel_id":t[0], "sequence":t[1]})(self.db.query(self.layersDict["PARCELS"]["SQL"]["EDIT"], (slc.getReturn(),))[0])
                    frm = dlg_FormParcel(self.db, self.iface, self.layers, self.layersDict, autocomplete, values)
                    frm.show()
                    frm_ret = frm.exec_()
                    self.iface.mapCanvas().setMapTool(frm.tool)
                    if bool(frm_ret):
                        self.db.query(self.layersDict["PARCELS"]["SQL"]["DELETE"], (frm.getReturn()[0]["parcel_id"],))
                        sql = ""
                        for i, beacon in enumerate(frm.getReturn()[1]["sequence"]):
                            sql += self.db.queryPreview(self.layersDict["PARCELS"]["SQL"]["INSERT"], (frm.getReturn()[1]["parcel_id"], beacon, i))
                        self.db.query(sql)
                for l in self.layers.values(): l.removeSelection()
            elif mng.getReturn() == 2:
                # delete existing parcel
                obj = {"NAME":self.layersDict["PARCELS"]["NAME"],"PURPOSE":"REMOVER","ACTION":"REMOVE"}
                slc = dlg_Selector(self.db, self.iface, self.layers["PARCELS"], self.layersDict["PARCELS"]["SQL"], obj = obj, preserve = True)
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    self.db.query(self.layersDict["PARCELS"]["SQL"]["DELETE"], (self.db.query(self.layersDict["PARCELS"]["SQL"]["SELECT"], (slc.getReturn(),))[0][0],)) 
                for l in self.layers.values(): l.removeSelection()

class Beacons():
    """ Class managing beacons
    """

    def __init__(self, iface, layers, layersDict, db):
        self.iface = iface
        self.layers = layers
        self.layersDict = layersDict
        self.db = db

    def run(self):
        """ Main method
        """
        # display manager dialog
        mng = dlg_Manager(obj = {"NAME":self.layersDict["BEACONS"]["NAME"],})
        mng.show()
        if bool(mng.exec_()):
            if mng.getReturn() == 0:
                while True:
                    # create new beacon        
                    data = self.db.getSchema(self.layersDict["BEACONS"]["TABLE"], [self.layersDict["BEACONS"]["GEOM"], self.layersDict["BEACONS"]["PKEY"]])
                    frm = dlg_FormBeacon(self.db, data, self.layersDict["BEACONS"]["SQL"])
                    frm.show()
                    frm_ret = frm.exec_()
                    if bool(frm_ret):
                        values_old, values_new = frm.getReturn() 
                        self.db.query(self.layersDict["BEACONS"]["SQL"]["INSERT"].format(fields = ", ".join(sorted(values_new.keys())), values = ", ".join(["%s" for k in values_new.keys()])), [values_new[k] for k in sorted(values_new.keys())])
                        self.iface.mapCanvas().refresh()                    
                    else:
                        break
            elif mng.getReturn() == 1:
                # edit existing beacon
                obj = {"NAME":self.layersDict["BEACONS"]["NAME"],"PURPOSE":"EDITOR","ACTION":"EDIT"}
                slc = dlg_Selector(self.db, self.iface, self.layers["BEACONS"], self.layersDict["BEACONS"]["SQL"], obj = obj, preserve = True)
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    data = self.db.getSchema(self.layersDict["BEACONS"]["TABLE"], [self.layersDict["BEACONS"]["GEOM"], self.layersDict["BEACONS"]["PKEY"]])
                    fields = ",".join([f["NAME"] for f in data])
                    values = [v for v in self.db.query(self.layersDict["BEACONS"]["SQL"]["EDIT"].format(fields = fields), (slc.getReturn(),))[0]]
                    frm = dlg_FormBeacon(self.db, data, self.layersDict["BEACONS"]["SQL"], values)
                    frm.show()
                    frm_ret = frm.exec_()
                    if bool(frm_ret):
                        fields_old = []
                        fields_new = []
                        values_old = []
                        values_new = []
                        for f in data:
                            if frm.getReturn()[0][f["NAME"]] is not None:
                                fields_old.append(f["NAME"])
                                values_old.append(frm.getReturn()[0][f["NAME"]])
                            fields_new.append(f["NAME"])
                            values_new.append(frm.getReturn()[1][f["NAME"]])
                        set = ", ".join(["{field} = %s".format(field = f) for f in fields_new])
                        where = " AND ".join(["{field} = %s".format(field = f) for f in fields_old])
                        self.db.query(self.layersDict["BEACONS"]["SQL"]["UPDATE"].format(set = set, where = where), values_new + values_old)
                for l in self.layers.values(): l.removeSelection()
            elif mng.getReturn() == 2:
                # delete existing beacon
                obj = {"NAME":self.layersDict["BEACONS"]["NAME"],"PURPOSE":"REMOVER","ACTION":"REMOVE"}
                slc = dlg_Selector(self.db, self.iface, self.layers["BEACONS"], self.layersDict["BEACONS"]["SQL"], obj = obj, preserve = True)
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    self.db.query(self.layersDict["BEACONS"]["SQL"]["DELETE"], (slc.getReturn(),)) 
                for l in self.layers.values(): l.removeSelection()

