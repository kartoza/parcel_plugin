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
# PyQt and QGIS imports
from PyQt4.QtCore import *
from PyQt4.QtGui import *
from qgis.core import *
# Plugin imports
import __init__ as meta
from settings import *
import database
# UI imports
import polygons 
import points 

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
        self.dbmanager = database.dbmanager()
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
        self.actionPoints = QAction(QIcon(self.plugin_dir + "/images/point"), "Manage %s" %(DATABASE_LAYERS["points"]["name_plural"],), self.iface.mainWindow())
        QObject.connect(self.actionPoints, SIGNAL("triggered()"), self.managePoints)
        self.actionPolygons = QAction(QIcon(self.plugin_dir + "/images/polygon"), "Manage %s" %(DATABASE_LAYERS["polygons"]["name_plural"],), self.iface.mainWindow())
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
            uri.setDataSource(lyr["schema"], lyr["table"], lyr["the_geom"], "", lyr["pkey"])
            self.iface.addVectorLayer(uri.uri(), lyr["name_plural"], "postgres")
    
    def getLayers(self):
        """ Save reference to added postgis layers
        """
        self.layers = {}
        for lyr in self.iface.mapCanvas().layers():
            for typ in DATABASE_LAYERS.keys():
                if DATABASE_LAYERS[typ]["name_plural"] == lyr.name(): self.layers[typ] = lyr

    def dropLayers(self):
        """ Drop added postgis layers
        """        
        self.getLayers()
        QgsMapLayerRegistry.instance().removeMapLayers([lyr.id() for lyr in self.layers.values()])
            
    def managePoints(self):
        """ Portal which enables the management of points
        """
        pnts = points.controller(DATABASE_LAYERS["points"], self.iface, self.layers)
        pnts.run()
        pass

    def managePolygons(self):
        """ Portal which enables the management of polygons
        """
        plygns = polygons.controller(DATABASE_LAYERS["polygons"], DATABASE_LAYERS["points"], self.iface, self.layers)
        plygns.run()
        pass
