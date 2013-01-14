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
from settings import *
import database
from PyQt4Dialogs import *

class sml_surveyor:

    def __init__(self, iface):
        # Save reference to the QGIS interface
        self.iface = iface
        # initialize plugin directory
        self.plugin_dir = QFileInfo(QgsApplication.qgisUserDbFilePath()).path() + "/python/plugins/sml_surveyor"
        # initialize locale
        localePath = ""
        locale = QSettings().value("locale/userLocale").toString()[0:2]

        if QFileInfo(self.plugin_dir).exists():
            localePath = self.plugin_dir + "/i18n/sml_surveyor_" + locale + ".qm"

        if QFileInfo(localePath).exists():
            self.translator = QTranslator()
            self.translator.load(localePath)

            if qVersion() > '4.3.3':
                QCoreApplication.installTranslator(self.translator)

    def initGui(self):
        """ Initialize gui
        """
        # test db access
        self.db = database.manager()
        # add layers
        self.addLayers()
        self.getLayers()
        # add app toolbar
        self.createAppToolBar()
        
    def unload(self):
        """ Uninitialize gui
        """
        # remove layers
        self.dropLayers()
        # remove app toolbar
        self.removeAppToolBar()

    def createAppToolBar(self):
        """ Create plugin toolbar to house buttons
        """
        # create app toolbar
        self.appToolBar = QToolBar(meta.name())
        self.appToolBar.setObjectName(meta.name())
        # create apps for toolbar
        self.actionPoints = QAction(QIcon(self.plugin_dir + "/images/point"), "Manage %s" %(DATABASE_LAYERS["POINTS"]["NAME_PLURAL"].title(),), self.iface.mainWindow())
        QObject.connect(self.actionPoints, SIGNAL("triggered()"), self.managePoints)
        self.actionPolygons = QAction(QIcon(self.plugin_dir + "/images/polygon"), "Manage %s" %(DATABASE_LAYERS["POLYGONS"]["NAME_PLURAL"].title(),), self.iface.mainWindow())
        QObject.connect(self.actionPolygons, SIGNAL("triggered()"), self.managePolygons)
        # populate app toolbar
        self.appToolBar.addAction(self.actionPoints)
        self.appToolBar.addAction(self.actionPolygons)
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
        uri.setConnection(DATABASE_HOST, DATABASE_PORT, DATABASE_NAME, DATABASE_USER, DATABASE_PASSWORD)
        for name in reversed(DATABASE_LAYERS_ORDER):
            lyr = DATABASE_LAYERS[name]
            uri.setDataSource(lyr["SCHEMA"], lyr["TABLE"], lyr["GEOM"], "", lyr["PKEY"])
            self.iface.addVectorLayer(uri.uri(), lyr["NAME_PLURAL"], "postgres")
    
    def getLayers(self):
        """ Save reference to added postgis layers
        """
        self.layers = {}
        for lyr in self.iface.mapCanvas().layers():
            for typ in DATABASE_LAYERS_ORDER:
                if DATABASE_LAYERS[typ]["NAME_PLURAL"] == lyr.name(): self.layers[typ] = lyr

    def dropLayers(self):
        """ Drop added postgis layers
        """        
        self.getLayers()
        QgsMapLayerRegistry.instance().removeMapLayers([lyr.id() for lyr in self.layers.values()])
            
    def managePoints(self):
        """ Portal which enables the management of points
        """
        p = Points(self.iface, self.layers, DATABASE_LAYERS, self.db)
        p.run()
        self.iface.mapCanvas().refresh()

    def managePolygons(self):
        """ Portal which enables the management of polygons
        """
        p = Polygons(self.iface, self.layers, DATABASE_LAYERS, self.db)
        p.run()
        self.iface.mapCanvas().refresh()

class Polygons():
    def __init__(self, iface, layers, layersDict, db):
        self.iface = iface
        self.layers = layers
        self.layersDict = layersDict
        self.db = db
        
    def run(self):
        mng = dlg_Manager(obj = {"NAME":self.layersDict["POLYGONS"]["NAME"],})
        mng.show()
        if bool(mng.exec_()):
            if mng.getReturn() == 0:
                # create new polygon
                autocomplete = [i[0] for i in self.db.query(self.layersDict["POLYGONS"]["SQL"]["AUTOCOMPLETE"])]
                frm = dlg_FormPolygon(self.db, self.iface, self.layers, self.layersDict, autocomplete)
                frm.show()
                frm_ret = frm.exec_()
                self.iface.mapCanvas().setMapTool(frm.tool)
                if bool(frm_ret):
                    sql = ""
                    for i, point in enumerate(frm.getReturn()[1]["sequence"]):
                        sql += self.db.queryPreview(self.layersDict["POLYGONS"]["SQL"]["INSERT"], (frm.getReturn()[1]["polygon_id"], point, i))
                    self.db.query(sql)
                for l in self.layers.values(): l.removeSelection()
            elif mng.getReturn() == 1:
                # edit existing polygon 
                obj = {"NAME":self.layersDict["POLYGONS"]["NAME"],"PURPOSE":"EDITOR","ACTION":"EDIT"}
                slc = dlg_Selector(self.db, self.iface, self.layers["POLYGONS"], self.layersDict["POLYGONS"]["SQL"], obj = obj, preserve = True)
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    autocomplete = [i[0] for i in self.db.query(self.layersDict["POLYGONS"]["SQL"]["AUTOCOMPLETE"])]
                    values = (lambda t: {"polygon_id":t[0], "sequence":t[1]})(self.db.query(self.layersDict["POLYGONS"]["SQL"]["EDIT"], (slc.getReturn(),))[0])
                    frm = dlg_FormPolygon(self.db, self.iface, self.layers, self.layersDict, autocomplete, values)
                    frm.show()
                    frm_ret = frm.exec_()
                    self.iface.mapCanvas().setMapTool(frm.tool)
                    if bool(frm_ret):
                        self.db.query(self.layersDict["POLYGONS"]["SQL"]["DELETE"], (frm.getReturn()[0]["polygon_id"],))
                        sql = ""
                        for i, point in enumerate(frm.getReturn()[1]["sequence"]):
                            sql += self.db.queryPreview(self.layersDict["POLYGONS"]["SQL"]["INSERT"], (values["polygon_id"], point, i))
                        self.db.query(sql)
                for l in self.layers.values(): l.removeSelection()
            elif mng.getReturn() == 2:
                # delete existing polygon
                obj = {"NAME":self.layersDict["POLYGONS"]["NAME"],"PURPOSE":"REMOVER","ACTION":"REMOVE"}
                slc = dlg_Selector(self.db, self.iface, self.layers["POLYGONS"], self.layersDict["POLYGONS"]["SQL"], obj = obj, preserve = True)
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    self.db.query(self.layersDict["POLYGONS"]["SQL"]["DELETE"], (self.db.query(self.layersDict["POLYGONS"]["SQL"]["SELECT"], (slc.getReturn(),))[0][0],)) 
                for l in self.layers.values(): l.removeSelection()

class Points():
    def __init__(self, iface, layers, layersDict, db):
        self.iface = iface
        self.layers = layers
        self.layersDict = layersDict
        self.db = db

    def run(self):
        mng = dlg_Manager(obj = {"NAME":self.layersDict["POINTS"]["NAME"],})
        mng.show()
        if bool(mng.exec_()):
            if mng.getReturn() == 0:
                # create new point
                data = self.db.getSchema(self.layersDict["POINTS"]["TABLE"], [self.layersDict["POINTS"]["GEOM"], self.layersDict["POINTS"]["PKEY"]])
                frm = dlg_FormPoint(self.db, data, self.layersDict["POINTS"]["SQL"])
                frm.show()
                frm_ret = frm.exec_()
                if bool(frm_ret):
                    values = [frm.getReturn()[1][f["NAME"]] for f in data]
                    query = self.layersDict["POINTS"]["SQL"]["INSERT"].format(fields = ", ".join([f["NAME"] for f in data]), values = ", ".join("%s" for v in values))
                    self.db.query(query, values)
            elif mng.getReturn() == 1:
                # edit existing point
                obj = {"NAME":self.layersDict["POINTS"]["NAME"],"PURPOSE":"EDITOR","ACTION":"EDIT"}
                slc = dlg_Selector(self.db, self.iface, self.layers["POINTS"], self.layersDict["POINTS"]["SQL"], obj = obj, preserve = True)
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    data = self.db.getSchema(self.layersDict["POINTS"]["TABLE"], [self.layersDict["POINTS"]["GEOM"], self.layersDict["POINTS"]["PKEY"]])
                    fields = ",".join([f["NAME"] for f in data])
                    values = [v for v in self.db.query(self.layersDict["POINTS"]["SQL"]["EDIT"].format(fields = fields), (slc.getReturn(),))[0]]
                    frm = dlg_FormPoint(self.db, data, self.layersDict["POINTS"]["SQL"], values)
                    frm.show()
                    frm_ret = frm.exec_()
                    if bool(frm_ret):
                        set = ", ".join(["{field} = %s".format(field = f["NAME"]) for f in data])
                        where = " AND ".join(["{field} = %s".format(field = f["NAME"]) for f in data])
                        values_old = []
                        values_new = []
                        for f in data:
                            values_old.append(frm.getReturn()[0][f["NAME"]])
                            values_new.append(frm.getReturn()[1][f["NAME"]])
                        self.db.query(self.layersDict["POINTS"]["SQL"]["UPDATE"].format(set = set, where = where), values_new + values_old)
                for l in self.layers.values(): l.removeSelection()
            elif mng.getReturn() == 2:
                # delete existing point
                obj = {"NAME":self.layersDict["POINTS"]["NAME"],"PURPOSE":"REMOVER","ACTION":"REMOVE"}
                slc = dlg_Selector(self.db, self.iface, self.layers["POINTS"], self.layersDict["POINTS"]["SQL"], obj = obj, preserve = True)
                slc.show()
                slc_ret = slc.exec_()
                self.iface.mapCanvas().setMapTool(slc.tool)
                if bool(slc_ret):
                    self.db.query(self.layersDict["POINTS"]["SQL"]["DELETE"], (slc.getReturn(),)) 
                for l in self.layers.values(): l.removeSelection()

