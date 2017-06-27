# -*- coding: utf8 -*-
"""
Author: Robert Moerman
Contact: robert@afrispatial.co.za
Company: AfriSpatial

This is a collection of custom QDialogs.

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
from qgis.gui import *
from qgis.core import *
from qgisToolbox import FeatureSelector
from PyQt4Widgets import XQPushButton, XQDialogButtonBox
from database import *
from utilities import images_path, get_ui_class, get_path

UI_CLASS = get_ui_class("ui_pgnewconnection.ui")


def _from_utf8(s):
    return s

# All dialogs using selector tool have a captured function
# All dialogs have a get_return function


class NewDatabaseConnectionDialog(QDialog, UI_CLASS):
    """Dialog implementation class for new db connection."""

    def __init__(self, parent):
        """Constructor"""

        ssl_disable = {
            'name': 'disable',
            'value': 0
        }
        ssl_allow = {
            'name': 'allow',
            'value': 1
        }
        ssl_prefer = {
            'name': 'prefer',
            'value': 2
        }
        ssl_require = {
            'name': 'require',
            'value': 3
        }
        ssl_verify_ca = {
            'name': 'verify_ca',
            'value': 4
        }
        ssl_verify_full = {
            'name': 'verify_full',
            'value': 5
        }

        QDialog.__init__(self, None)
        self.setupUi(self)

        self.parent = parent

        # add ssl mode option
        self.cbxSSLmode.addItem(
            ssl_disable['name'], ssl_disable['value'])
        self.cbxSSLmode.addItem(
            ssl_allow['name'], ssl_allow['value'])
        self.cbxSSLmode.addItem(
            ssl_prefer['name'], ssl_prefer['value'])
        self.cbxSSLmode.addItem(
            ssl_require['name'], ssl_require['value'])
        self.cbxSSLmode.addItem(
            ssl_verify_ca['name'], ssl_verify_ca['value'])
        self.cbxSSLmode.addItem(
            ssl_verify_full['name'], ssl_verify_full['value'])

        self.auth_config = QgsAuthConfigSelect(self, "postgres")
        self.tabAuthentication.insertTab(1, self.auth_config, "Configurations")

    def accept(self):

        settings = QSettings()
        base_key = "/PostgreSQL/connections/"
        settings.setValue(base_key + "selected", self.txtName.text())
        auth_config = self.auth_config.configId()

        if not auth_config and self.chkStorePassword.isChecked():
            message = ("WARNING: You have opted to save your password. "
                       "It will be stored in unsecured plain text in your "
                       "project files and in your home directory "
                       "(Unix-like OS) or user profile (Windows). "
                       "If you want to avoid this, press Cancel and "
                       "either:\n\na) Don't save a password in the connection "
                       "settings — it will be requested interactively when "
                       "needed;\nb) Use the Configuration tab to add your "
                       "credentials in an HTTP Basic Authentication method "
                       "and store them in an encrypted database.")
            answer = QMessageBox.question(self,
                                          "Saving passwords",
                                          message,
                                          QMessageBox.Ok | QMessageBox.Cancel)
            if answer == QMessageBox.Cancel:
                return

        if settings.contains(base_key + self.txtName.text() + "/service") or \
                settings.contains(base_key + self.txtName.text() + "/host"):
            message = ("Should the existing connection %s be overwritten?")
            answer = QMessageBox.question(self,
                                          "Saving connection",
                                          message % (self.txtName.text()),
                                          QMessageBox.Ok | QMessageBox.Cancel)
            if answer == QMessageBox.Cancel:
                return

        base_key += self.txtName.text()
        settings.setValue(base_key + "/service", self.txtService.text())
        settings.setValue(base_key + "/host", self.txtHost.text())
        settings.setValue(base_key + "/port", self.txtPort.text())
        settings.setValue(base_key + "/database", self.txtDatabase.text())
        settings.setValue(base_key + "/authcfg", self.auth_config.configId())
        settings.setValue(
            base_key + "/publicOnly", self.cb_publicSchemaOnly.isChecked())
        settings.setValue(
            base_key + "/geometryColumnsOnly",
            self.cb_geometryColumnsOnly.isChecked())
        settings.setValue(
            base_key + "/dontResolveType", self.cb_dontResolveType.isChecked())
        settings.setValue(
            base_key + "/allowGeometrylessTables",
            self.cb_allowGeometrylessTables.isChecked())
        settings.setValue(
            base_key + "/sslmode",
            self.cbxSSLmode.itemData(self.cbxSSLmode.currentIndex()))
        settings.setValue(
            base_key + "/estimatedMetadata",
            self.cb_useEstimatedMetadata.isChecked())

        if self.chkStoreUsername.isChecked():
            settings.setValue(base_key + "/username", self.txtUsername.text())
            settings.setValue(base_key + "/saveUsername", "true")
        else:
            settings.setValue(base_key + "/username", "")
            settings.setValue(base_key + "/saveUsername", "false")

        if self.chkStorePassword.isChecked():
            settings.setValue(base_key + "/password", self.txtPassword.text())
            settings.setValue(base_key + "/savePassword", "true")
        else:
            settings.setValue(base_key + "/password", "")
            settings.setValue(base_key + "/savePassword", "false")

        settings.remove(base_key + "/save")

        self.parent.populate_database_choices()
        new_index = self.parent.cmbbx_conn.findText(
            self.txtName.text(), Qt.MatchExactly)
        if new_index >= 0:
            self.parent.cmbbx_conn.setCurrentIndex(new_index)

        QDialog.accept(self)


class DatabaseConnectionDialog(QDialog):
    """ This dialog enables the user to choose a database connection
    defined through DB Manager
    """

    def __init__(self):
        # initialize QDialog class
        super(
            DatabaseConnectionDialog, self).__init__(
            None, Qt.WindowStaysOnTopHint)
        # initialize ui
        self.connection = None
        self.crs = None
        self.setup_ui()
        self.populate_database_choices()

    def get_database_connection(self):
        return self.connection

    def get_crs(self):
        return self.crs

    def populate_database_choices(self):
        """ Populate database connection choices
        """
        self.cmbbx_conn.clear()
        settings = QSettings()
        settings.beginGroup('PostgreSQL/connections')
        for index, database in enumerate(settings.childGroups()):
            self.cmbbx_conn.addItem(database)

    def test_database_connection(self):
        """ Test database connection has necessary tables
        """
        connection = str(self.cmbbx_conn.currentText())
        if not bool(connection.replace(" ", "")):
            QMessageBox.information(
                self,
                "Database Connection",
                "Please select a database connection")
        else:
            self.connection = connection

        if self.connection:
            ok = self.test_database_schema()
            if not ok:
                return
            self.accept()

    def test_database_schema(self):
        """Test whether co-go schema is applied in the database."""
        query = "SELECT EXISTS (SELECT 1 AS result FROM pg_tables " \
                "WHERE schemaname = 'public' AND tablename = 'beacons')"

        settings_postgis = QSettings()
        settings_postgis.beginGroup('PostgreSQL/connections')
        max_attempts = 3
        is_credential_exist = True

        db_service = settings_postgis.value(self.connection + '/service')
        db_host = settings_postgis.value(self.connection + '/host')
        db_port = settings_postgis.value(self.connection + '/port')
        db_name = settings_postgis.value(self.connection + '/database')
        db_username = settings_postgis.value(self.connection + '/username')
        db_password = settings_postgis.value(self.connection + '/password')

        uri = QgsDataSourceURI()
        uri.setConnection(
            db_host,
            db_port,
            db_name,
            db_username,
            db_password)

        if not db_username and not db_password:
            msg = "Please enter the username and password."
            for i in range(max_attempts):
                ok, db_username, db_password = (
                    QgsCredentials.instance().get(
                        uri.connectionInfo(),
                        db_username,
                        db_password,
                        msg
                    ))

        connection = None
        if is_credential_exist:
            if db_service:
                connection = psycopg2.connect(
                    "service='{SERVICE}' user='{USER}' "
                    "password='{PASSWORD}'".format(
                        SERVICE=db_service,
                        USER=db_username,
                        PASSWORD=db_password
                    ))
            else:
                connection = psycopg2.connect(
                    "host='{HOST}' dbname='{NAME}' user='{USER}' "
                    "password='{PASSWORD}' port='{PORT}'".format(
                        HOST=db_host,
                        NAME=db_name,
                        USER=db_username,
                        PASSWORD=db_password,
                        PORT=db_port
                    ))

        if connection:
            cursor = connection.cursor()
            cursor.execute(query)
            is_schema_valid = cursor.fetchall()[0][0]
            del cursor

            if not is_schema_valid:

                message = ("WARNING: The selected database does not contain "
                           "tables and functions required for use of "
                           "the plugin. Please select a CRS and click "
                           "OK to procees setting up a database using "
                           "the chosen CRS.")
                crs_options = {
                    'WGS 84 / UTM zone 31N': 32631,
                    'WGS 84 / UTM zone 32N': 32632
                }
                items = crs_options.keys()

                item, ok = QInputDialog.getItem(
                    self, "Setup Database Schema", message, items, 0, False)

                if item and ok:
                    query = open(
                        get_path("scripts","database_setup.sql"), "r").read()
                    query = query.replace(":CRS", "{CRS}")
                    cursor = connection.cursor()
                    cursor.execute(query.format(CRS=crs_options[item]))
                    connection.commit()

                return ok

    def setup_ui(self):
        """ Initialize ui
        """
        # define ui widgets
        self.setObjectName(_from_utf8("DatabaseConnectionDialog"))
        self.resize(370, 200)
        self.setCursor(QCursor(Qt.ArrowCursor))
        self.setModal(True)
        self.gridLayout = QGridLayout(self)
        self.gridLayout.setObjectName(_from_utf8("gridLayout"))
        self.verticalLayout = QVBoxLayout()
        self.verticalLayout.setObjectName(_from_utf8("verticalLayout"))
        self.lbl_instr = QLabel(self)
        self.lbl_instr.setWordWrap(True)
        self.lbl_instr.setObjectName(_from_utf8("lbl_instr"))
        self.verticalLayout.addWidget(self.lbl_instr)
        self.formLayout = QFormLayout()
        self.formLayout.setObjectName(_from_utf8("formLayout"))
        self.lbl_conn = QLabel(self)
        self.lbl_conn.setObjectName(_from_utf8("lbl_conn"))
        self.formLayout.setWidget(0, QFormLayout.LabelRole, self.lbl_conn)
        self.cmbbx_conn = QComboBox(self)
        self.cmbbx_conn.setObjectName(_from_utf8("cmbbx_conn"))
        self.formLayout.setWidget(0, QFormLayout.FieldRole, self.cmbbx_conn)
        self.verticalLayout.addLayout(self.formLayout)
        self.horizontalLayout = QHBoxLayout()
        self.btn_new_conn = QPushButton("")
        self.btn_new_conn.setObjectName(_from_utf8("new_conn"))
        self.btn_new_conn.setMaximumSize(32, 32)
        self.btn_new_conn.setIcon(QIcon(images_path("icons", "add.png")))
        self.btn_refresh_conn = QPushButton("")
        self.btn_refresh_conn.setObjectName(_from_utf8("refresh_conn"))
        self.btn_refresh_conn.setMaximumSize(32, 32)
        self.btn_refresh_conn.setIcon(
            QIcon(images_path("icons", "refresh.png")))
        self.horizontalLayout.addWidget(self.btn_new_conn)
        self.horizontalLayout.addWidget(self.btn_refresh_conn)
        self.horizontalLayout.setAlignment(Qt.AlignRight)
        self.formLayout.setContentsMargins(0, 0, 0, 0)
        self.horizontalLayout.setContentsMargins(0, 0, 0, 0)
        self.formLayout.setLayout(
            1, QFormLayout.FieldRole, self.horizontalLayout)
        self.verticalLayout.addSpacerItem(QSpacerItem(50, 10))
        self.btnbx_options = XQDialogButtonBox(self)
        self.btnbx_options.setOrientation(Qt.Horizontal)
        self.btnbx_options.setStandardButtons(
            XQDialogButtonBox.Cancel | XQDialogButtonBox.Ok)
        self.btnbx_options.setObjectName(_from_utf8("btnbx_options"))
        self.verticalLayout.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout, 0, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(QApplication.translate(
            "DatabaseConnectionDialog",
            "Database Connection",
            None,
            QApplication.UnicodeUTF8
        ))
        self.lbl_conn.setText(QApplication.translate(
            "DatabaseConnectionDialog",
            "Connection: ",
            None
        ))
        self.lbl_instr.setText(QApplication.translate(
            "DatabaseConnectionDialog",
            "A database connection has not yet been selected or "
            "is no longer valid. Please select a database connection or "
            "define a new connection.",
            None
        ))
        self.btn_new_conn.setToolTip(QApplication.translate(
            "DatabaseConnectionDialog",
            "Add new PostgreSQL connection",
            None
        ))
        self.btn_refresh_conn.setToolTip(QApplication.translate(
            "DatabaseConnectionDialog",
            "Refresh available PostgreSQL connection",
            None
        ))
        # connect ui widgets
        self.btnbx_options.accepted.connect(self.test_database_connection)
        self.btnbx_options.rejected.connect(self.reject)
        self.btn_new_conn.clicked.connect(self.create_new_connection)
        self.btn_refresh_conn.clicked.connect(self.populate_database_choices)
        QMetaObject.connectSlotsByName(self)

    def create_new_connection(self):
        dialog = NewDatabaseConnectionDialog(self)
        dialog.exec_()


class SelectorDialog(QDialog):
    """ This dialog enables the selection of single features on a
    vector layer by means of the feature selector tool defined in
    qgisToolbox
    """

    def __init__(self,
                 database,
                 iface,
                 required_layer,
                 mode,
                 query,
                 preserve=False,
                 parent=None):

        # initialize QDialog class
        super(SelectorDialog, self).__init__(parent, Qt.WindowStaysOnTopHint)
        # initialize ui
        self.setup_ui(required_layer, mode)
        self.database = database
        self.iface = iface
        self.layer = required_layer
        self.mode = mode
        self.query = query
        self.preserve = preserve
        self.confirmed = False
        self.feat_id = None
        # initialize selector tool
        self.selector = FeatureSelector(
            iface, required_layer.layer, True, self)
        # save qgis tool
        self.tool = self.selector.parent_tool

    def get_feature_id(self):
        return self.feat_id

    def execute_option(self, button):
        """ Perform validation and close the dialog
        """
        if self.btnbx_options.standardButton(button) == QDialogButtonBox.Ok:
            # check that a feature has been selected
            if self.feat_id is None:
                QMessageBox.information(
                    self,
                    "No %s Selected" % (self.layer.name.title(),),
                    "Please select a %s." % (self.layer.name.lower()))
                return
            # check confirmation
            if not self.confirmed:
                QMessageBox.information(
                    self,
                    "No Confirmation",
                    "Please tick the confimation check box.")
                return
            # reset qgis tool
            self.iface.mapCanvas().setMapTool(self.tool)
            # remove selection if needed
            if not self.preserve:
                self.layer.layer.removeSelection()
            # accept dialog
            self.accept()
        else:
            # reset qgis tool
            self.iface.mapCanvas().setMapTool(self.tool)
            # remove selection
            self.layer.layer.removeSelection()
            # reject dialog
            self.reject()

    def captured(self, selected):
        """ Notify the dialog of a feature selection and disable selecting
        """
        # disable selector tool
        self.selector.disable_capturing()
        # update dialog
        self.feat_id = selected[0]
        self.lnedt_featID.setText(
            str(self.database.query(self.query, (self.feat_id,))[0][0]))
        self.pshbtn_re.setEnabled(True)
        self.chkbx_confirm.setEnabled(True)

    def reselect(self):
        """ Blat original selection and re-enable selecting
        """
        # update dialog
        self.pshbtn_re.setEnabled(False)
        self.chkbx_confirm.setEnabled(False)
        self.lnedt_featID.setText("")
        self.feat_id = None
        # clear selector tool selection
        self.selector.clear_selection()
        # enable selector tool
        self.selector.enable_capturing()

    def confirm(self, state):
        """ Confirm that the selected feature is correct
        """
        self.pshbtn_re.setEnabled(not bool(state))
        self.confirmed = bool(state)

    def setup_ui(self, layer, mode):
        """ Initialize ui
        """
        # define ui widgets
        self.setObjectName(_from_utf8("SelectorDialog"))
        self.setCursor(QCursor(Qt.ArrowCursor))
        self.gridLayout = QGridLayout(self)
        self.gridLayout.setSizeConstraint(QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_from_utf8("gridLayout"))
        self.verticalLayout = QVBoxLayout()
        self.verticalLayout.setObjectName(_from_utf8("verticalLayout"))
        self.splitter = QSplitter(self)
        self.splitter.setOrientation(Qt.Horizontal)
        self.splitter.setObjectName(_from_utf8("splitter"))
        self.widget = QWidget(self.splitter)
        self.widget.setObjectName(_from_utf8("widget"))
        self.formLayout = QFormLayout(self.widget)
        self.formLayout.setMargin(0)
        self.formLayout.setObjectName(_from_utf8("formLayout"))
        self.lbl_featID = QLabel(self.widget)
        self.lbl_featID.setObjectName(_from_utf8("lbl_featID"))
        self.formLayout.setWidget(0, QFormLayout.LabelRole, self.lbl_featID)
        self.lnedt_featID = QLineEdit(self.widget)
        self.lnedt_featID.setEnabled(False)
        self.lnedt_featID.setObjectName(_from_utf8("lnedt_featID"))
        self.formLayout.setWidget(0, QFormLayout.FieldRole, self.lnedt_featID)
        self.pshbtn_re = QPushButton(self.splitter)
        self.pshbtn_re.setEnabled(False)
        self.pshbtn_re.setObjectName(_from_utf8("pshbtn_re"))
        self.pshbtn_re.setCursor(QCursor(Qt.PointingHandCursor))
        self.verticalLayout.addWidget(self.splitter)
        self.chkbx_confirm = QCheckBox(self)
        self.chkbx_confirm.setEnabled(False)
        self.chkbx_confirm.setObjectName(_from_utf8("chkbx_confirm"))
        self.chkbx_confirm.setCursor(QCursor(Qt.PointingHandCursor))
        self.verticalLayout.addWidget(self.chkbx_confirm)
        self.btnbx_options = QDialogButtonBox(self)
        self.btnbx_options.setStandardButtons(
            QDialogButtonBox.Cancel | QDialogButtonBox.Ok)
        self.btnbx_options.setObjectName(_from_utf8("btnbx_options"))
        self.btnbx_options.setCursor(QCursor(Qt.PointingHandCursor))
        self.verticalLayout.addWidget(self.btnbx_options)
        self.gridLayout.addLayout(self.verticalLayout, 0, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(
            QApplication.translate(
                "SelectorDialog",
                "%s %s" % (layer.name.title(), mode.actor.title()),
                None,
                QApplication.UnicodeUTF8))
        self.lbl_featID.setText(
            QApplication.translate(
                "SelectorDialog",
                "%s ID" % (layer.name.title()),
                None,
                QApplication.UnicodeUTF8))
        self.pshbtn_re.setText(
            QApplication.translate(
                "SelectorDialog", "Re-select", None, QApplication.UnicodeUTF8))
        self.chkbx_confirm.setText(
            QApplication.translate(
                "SelectorDialog",
                "I am sure I want to %s this %s" % (
                    mode.action.lower(), layer.name.lower()),
                None,
                QApplication.UnicodeUTF8))
        # connect ui widgets
        self.pshbtn_re.clicked.connect(self.reselect)
        self.chkbx_confirm.stateChanged.connect(self.confirm)
        self.btnbx_options.clicked.connect(self.execute_option)
        QMetaObject.connectSlotsByName(self)


class ManagerDialog(QDialog):
    """ This dialog enables the user to select an option
    with regards to managing a vector layer
    """

    def __init__(self, required_layer, parent=None):
        super(ManagerDialog, self).__init__(parent, Qt.WindowStaysOnTopHint)
        self.setup_ui(required_layer)
        self.layer = required_layer
        self.option = None

    def get_option(self):
        return self.option

    def execute_option(self, button):
        """ Perform validation and close the dialog
        """
        if self.btnbx_options.standardButton(button) == QDialogButtonBox.Ok:
            # get selected option
            for index, radio_button in enumerate(
                    self.findChildren(QRadioButton)):
                if radio_button.isChecked():
                    self.option = index
                    break
            # check that an option was selected
            if self.option is not None:
                # accept dialog
                self.accept()
            else:
                QMessageBox.information(
                    self,
                    "Invalid Selection",
                    "Please select an option before clicking OK")
        else:
            # reject dialog
            self.reject()

    def setup_ui(self, layer):
        """ Initialize ui
        """
        # define ui widgets
        self.setObjectName(_from_utf8("ManagerDialog"))
        self.setCursor(QCursor(Qt.ArrowCursor))
        self.setModal(False)
        self.mainlyt = QGridLayout(self)
        self.mainlyt.setSizeConstraint(QLayout.SetFixedSize)
        self.mainlyt.setObjectName(_from_utf8("mainlyt"))
        self.vrtlyt = QVBoxLayout()
        self.vrtlyt.setObjectName(_from_utf8("vrtlyt"))
        self.grdlyt = QGridLayout()
        self.grdlyt.setObjectName(_from_utf8("grdlyt"))
        self.rdbtn_add = QRadioButton(self)
        self.rdbtn_add.setObjectName(_from_utf8("rdbtn_add"))
        self.rdbtn_add.setCursor(QCursor(Qt.PointingHandCursor))
        self.grdlyt.addWidget(self.rdbtn_add, 0, 0, 1, 1)
        self.rdbtn_edit = QRadioButton(self)
        self.rdbtn_edit.setObjectName(_from_utf8("rdbtn_edit"))
        self.rdbtn_edit.setCursor(QCursor(Qt.PointingHandCursor))
        self.grdlyt.addWidget(self.rdbtn_edit, 1, 0, 1, 1)
        self.rdbtn_del = QRadioButton(self)
        self.rdbtn_del.setObjectName(_from_utf8("rdbtn_del"))
        self.rdbtn_del.setCursor(QCursor(Qt.PointingHandCursor))
        self.grdlyt.addWidget(self.rdbtn_del, 2, 0, 1, 1)
        self.vrtlyt.addLayout(self.grdlyt)
        self.btnbx_options = QDialogButtonBox(self)
        self.btnbx_options.setStandardButtons(
            QDialogButtonBox.Cancel | QDialogButtonBox.Ok)
        self.btnbx_options.setCenterButtons(False)
        self.btnbx_options.setObjectName(_from_utf8("btnbx_options"))
        self.btnbx_options.setCursor(QCursor(Qt.PointingHandCursor))
        self.vrtlyt.addWidget(self.btnbx_options)
        self.mainlyt.addLayout(self.vrtlyt, 0, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(
            QApplication.translate(
                "ManagerDialog",
                "%s Manager" % (layer.name.title()),
                None,
                QApplication.UnicodeUTF8))
        self.rdbtn_add.setText(
            QApplication.translate(
                "ManagerDialog",
                "Create New %s" % (layer.name.title()),
                None,
                QApplication.UnicodeUTF8))
        self.rdbtn_edit.setText(
            QApplication.translate(
                "ManagerDialog",
                "Edit Existing %s" % (layer.name.title()),
                None,
                QApplication.UnicodeUTF8))
        self.rdbtn_del.setText(
            QApplication.translate(
                "ManagerDialog",
                "Delete Existing %s" % (layer.name.title()),
                None,
                QApplication.UnicodeUTF8))
        # connect ui widgets
        self.btnbx_options.clicked.connect(self.execute_option)
        QMetaObject.connectSlotsByName(self)


class FormBeaconDialog(QDialog):
    """ This dialog enables a user to define and modify a beacon
    """

    def __init__(self, database, query, fields, values=[], parent=None):
        # initialize QDialog class
        super(FormBeaconDialog, self).__init__(parent, Qt.WindowStaysOnTopHint)
        # initialize ui
        self.setup_ui(fields)
        # initialize instance variables
        self.db = database
        self.query = query
        self.fields = fields
        self.old_values = {}
        self.new_values = {}
        self.colours = {
            "REQUIRED": "background-color: rgba(255, 107, 107, 150);",
            "TYPE": "background-color: rgba(107, 107, 255, 150);",
            "UNIQUE": "background-color: rgba(107, 255, 107, 150);"
        }
        # populate form if values are given
        if bool(values):
            self.populate_form(values)

    def get_values(self):
        """ Return intended variable(s) after the dialog has been accepted
        """
        return (self.old_values, self.new_values)

    def populate_form(self, values):
        """ Populate form with given values
        """
        for index, value in enumerate(values):
            if value is not None:
                self.lnedts[index].setText(str(value))
            self.old_values[self.fields[index].name] = value

    def execute_option(self, button):
        """ Perform validation and close the dialog
        """
        if self.options_buttonbox.standardButton(button) == \
                QDialogButtonBox.Save:
            values_new = {}
            # check required fields
            valid = True
            for line_edit in self.lnedts:
                if bool(line_edit.property("REQUIRED")):
                    if str(line_edit.text()).strip() is "":
                        line_edit.setStyleSheet(self.colours["REQUIRED"])
                        valid = False
                    else:
                        line_edit.setStyleSheet("")
            if not valid:
                QMessageBox.information(
                    self,
                    "Empty Required Fields",
                    "Please ensure that all required fields are completed.")
                return
            # check correct field types
            valid = True
            for index, line_edit in enumerate(self.lnedts):
                try:
                    if str(line_edit.text()).strip() is not "":
                        cast = self.fields[index].type
                        tmp = cast(str(line_edit.text()).strip())
                        values_new[self.fields[index].name] = tmp
                        line_edit.setStyleSheet("")
                    else:
                        values_new[self.fields[index].name] = None
                except Exception as e:
                    line_edit.setStyleSheet(self.colours["TYPE"])
                    valid = False
            if not valid:
                QMessageBox.information(
                    self,
                    "Invalid Field Types",
                    "Please ensure that fields are completed with valid types."
                )
                return
            # check unique fields
            valid = True
            for index, line_edit in enumerate(self.lnedts):
                if str(line_edit.text()).strip() is "":
                    continue
                if bool(line_edit.property("UNIQUE")):
                    if self.fields[index].name in self.old_values.keys() and \
                                    values_new[self.fields[index].name] == \
                                    self.old_values[self.fields[index].name]:
                        line_edit.setStyleSheet("")
                    elif bool(int(self.db.query(self.query % (
                            self.fields[index].name, "%s"),
                            (values_new[self.fields[index].name],))[0][0])):
                        line_edit.setStyleSheet(self.colours["UNIQUE"])
                        valid = False
                    else:
                        line_edit.setStyleSheet("")
            if not valid:
                QMessageBox.information(
                    self,
                    "Fields Not Unique",
                    "Please ensure that fields are given unique values.")
                return
            # save values
            self.new_values = values_new
            # accept dialog
            self.accept()
        else:
            # reject dialog
            self.reject()

    def setup_ui(self, fields):
        """ Initialize ui
        """
        # define ui widgets
        self.setObjectName(_from_utf8("FormBeaconDialog"))
        self.setCursor(QCursor(Qt.ArrowCursor))
        self.setModal(True)
        self.gridLayout = QGridLayout(self)
        self.gridLayout.setSizeConstraint(QLayout.SetFixedSize)
        self.gridLayout.setObjectName(_from_utf8("gridLayout"))
        self.verticalLayout = QVBoxLayout()
        self.verticalLayout.setObjectName(_from_utf8("verticalLayout"))
        self.formLayout = QFormLayout()
        self.formLayout.setFieldGrowthPolicy(QFormLayout.AllNonFixedFieldsGrow)
        self.formLayout.setObjectName(_from_utf8("formLayout"))
        self.lbls = []
        self.lnedts = []
        # define form fields dynamically from the database schema
        for index, f in enumerate(fields):
            lbl = QLabel(self)
            lbl.setObjectName(_from_utf8("lbl_%s" % (f.name,)))
            self.formLayout.setWidget(index, QFormLayout.LabelRole, lbl)
            self.lbls.append(lbl)
            lnedt = QLineEdit(self)
            lnedt.setProperty("REQUIRED", f.required)
            lnedt.setProperty("UNIQUE", f.unique)
            lnedt.setObjectName(_from_utf8("lnedt_%s" % (f.name,)))
            self.formLayout.setWidget(index, QFormLayout.FieldRole, lnedt)
            self.lnedts.append(lnedt)
            lbl.setText(QApplication.translate(
                "FormBeaconDialog",
                ("*" if bool(self.lnedts[index].property("REQUIRED"))
                 else "") + f.name.title(),
                None,
                QApplication.UnicodeUTF8))
            lnedt.setProperty(
                "TYPE",
                QApplication.translate(
                    "FormBeaconDialog",
                    str(f.type),
                    None,
                    QApplication.UnicodeUTF8))
        self.verticalLayout.addLayout(self.formLayout)
        self.line_1 = QFrame(self)
        self.line_1.setFrameShape(QFrame.HLine)
        self.line_1.setFrameShadow(QFrame.Sunken)
        self.line_1.setObjectName(_from_utf8("line_1"))
        self.verticalLayout.addWidget(self.line_1)
        self.label = QLabel(self)
        self.label.setObjectName(_from_utf8("label"))
        self.verticalLayout.addWidget(self.label)
        self.line_2 = QFrame(self)
        self.line_2.setFrameShape(QFrame.HLine)
        self.line_2.setFrameShadow(QFrame.Sunken)
        self.line_2.setObjectName(_from_utf8("line_2"))
        self.verticalLayout.addWidget(self.line_2)
        self.options_buttonbox = QDialogButtonBox(self)
        self.options_buttonbox.setStandardButtons(
            QDialogButtonBox.Cancel | QDialogButtonBox.Save)
        self.options_buttonbox.setObjectName(_from_utf8("btnbx_options"))
        self.options_buttonbox.setCursor(QCursor(Qt.PointingHandCursor))
        self.verticalLayout.addWidget(self.options_buttonbox)
        self.gridLayout.addLayout(self.verticalLayout, 0, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(
            QApplication.translate(
                "FormBeaconDialog",
                "Beacon Form",
                None,
                QApplication.UnicodeUTF8))
        self.label.setText(
            QApplication.translate(
                "FormBeaconDialog",
                "<html><head/><body><p><span style=\" color:#ff0000;\">"
                "*Required Field</span></p></body></html>",
                None,
                QApplication.UnicodeUTF8))
        # connect ui widgets
        self.options_buttonbox.clicked.connect(self.execute_option)
        QMetaObject.connectSlotsByName(self)


class FormParcelDialog(QDialog):
    """ This dialog enables a user to define and modify a parcel
    """

    def __init__(
            self,
            database,
            iface,
            required_layers,
            SQL_BEACONS,
            SQL_PARCELS,
            autocomplete=[],
            data={},
            parent=None):
        # initialize QDialog class
        super(FormParcelDialog, self).__init__(parent, Qt.WindowStaysOnTopHint)
        # initialize ui
        self.setup_ui(autocomplete)
        self.database = database
        self.iface = iface
        self.layers = required_layers
        self.SQL_BEACONS = SQL_BEACONS
        self.SQL_PARCELS = SQL_PARCELS
        self.autocomplete = autocomplete
        self.old_values = {}
        self.new_values = {}
        self.sequence = []
        self.new_accepted = False
        # initialize selector tool
        self.selector = FeatureSelector(
            iface, required_layers[0].layer, False, self)
        # save qgis tool
        self.tool = self.selector.parent_tool
        # populate form if values are given
        if bool(data):
            self.populate_form(data)
            self.reset_pushbutton.setEnabled(True)

    def get_values(self):
        return (self.old_values, self.new_values)

    def populate_form(self, data):
        """ Populate form with values given
        """
        # get values
        def checker(data, key):
            return lambda data, key: data[key] if key in data.keys() else None
        feat_id = checker(data, "parcel_id")
        feat_sequence = checker(data, "sequence")
        # use values
        if bool(feat_id):
            # populate parcel_id
            self.old_values["parcel_id"] = self.database.query(
                self.SQL_PARCELS["SELECT"], (feat_id,))[0][0]
            self.parcel_id_lineedit.setText(str(self.old_values["parcel_id"]))
            self.highlight_feature(self.layers[1].layer, feat_id)
        if bool(feat_sequence):
            # populate sequence
            self.sequence = []
            self.old_values["sequence"] = []
            for id in feat_sequence:
                beacon_id = str(
                    self.database.query(
                        self.SQL_BEACONS["SELECT"], (id,))[0][0])
                self.sequence.append(beacon_id)
                self.old_values["sequence"].append(beacon_id)
                self.sequence_listwidget.addItem(beacon_id.replace("\n", ""))
            self.highlight_features(self.layers[0].layer, feat_sequence)
            self.selector.selected = feat_sequence
            # update selector selection
            self.selector.selected = feat_sequence

    def highlight_feature(self, layer, feature):
        """ Highlight a single feature on a vector layer
        """
        self.highlight_features(layer, [feature, ])

    def highlight_features(self, layer, features):
        """ Highlight multiple features on a vector layer
        """
        layer.setSelectedFeatures(features)

    def captured(self, selected):
        """ Notify the dialog of a feature selection and disable selecting
        """
        pass

    def execute_option(self, button):
        """ Perform validation and close the dialog
        """
        if self.options_buttonbox.standardButton(button) == \
                QDialogButtonBox.Save:
            parcel_id = str(self.parcel_id_lineedit.text()).strip()
            # check that parcel id exists
            if parcel_id == "":
                QMessageBox.information(
                    self,
                    "Invalid Parcel ID",
                    "Please enter a parcel ID.")
                return
            # check that parcel id is an int
            try:
                int(parcel_id)
            except ValueError:
                QMessageBox.information(
                    self,
                    "Invalid Parcel ID",
                    "Please enter a number for the parcel ID.")
                return
            # check that parcel id is valid (i.e. current, unique, available)
            if "parcel_id" in self.old_values.keys() and \
                    str(self.old_values["parcel_id"]) == parcel_id:
                pass
            elif not bool(
                    self.database.query(
                        self.SQL_PARCELS["UNIQUE"], (int(parcel_id),))[0][0]):
                if not self.new_accepted and QMessageBox.question(
                    self,
                    'Confirm New Parcel ID',
                    "Are you sure you want to create a new parcel ID?",
                    QMessageBox.Yes,
                    QMessageBox.No
                ) == QMessageBox.No:
                    return
                self.new_accepted = True
            else:
                if not bool(
                        self.database.query(
                            self.SQL_PARCELS["AVAILABLE"],
                            (parcel_id,))[0][0]):
                    QMessageBox.information(
                        self,
                        "Duplicated Parcel ID",
                        "Please enter a unique or available parcel ID.")
                    return
            # check that at least 3 beacons exist within the sequence
            if len(self.selector.selected) < 3:
                QMessageBox.information(
                    self,
                    "Too Few Beacons",
                    "Please ensure that there are at least "
                    "3 beacons listed in the sequence.")
                return
            # save parcel id
            self.new_values["parcel_id"] = parcel_id
            # save sequence
            self.new_values["sequence"] = self.sequence
            # refresh canvas and reset qgis tool
            self.iface.mapCanvas().refresh()
            self.iface.mapCanvas().setMapTool(self.tool)
            # remove selection
            for layer in self.layers:
                layer.layer.removeSelection()
            # accept dialog
            self.accept()
        else:
            # reset qgis tool
            self.iface.mapCanvas().setMapTool(self.tool)
            # remove selection
            for layer in self.layers:
                layer.layer.removeSelection()
            # accept dialog
            self.reject()

    def new_beacon(self):
        """ Define a new beacon on the fly to be added to the parcel sequence
        """
        # disable self
        self.setEnabled(False)
        # get fields
        fields = self.database.get_schema(
            self.layers[0].table, [
            self.layers[0].geometry_column,
            self.layers[0].primary_key
        ])
        # display form
        form = FormBeaconDialog(
            self.database,
            self.SQL_BEACONS["UNIQUE"],
            fields
        )
        form.show()
        form_ret = form.exec_()
        if bool(form_ret):
            # add beacon to database
            old_values, new_values = form.get_values()
            id = self.database.query(
                self.SQL_BEACONS["INSERT"].format(
                    fields=", ".join(sorted(new_values.keys())),
                    values=", ".join(["%s" for k in new_values.keys()])),
                [new_values[k] for k in sorted(new_values.keys())])[0][0]
            self.iface.mapCanvas().refresh()
            self.highlight_feature(self.layers[0].layer, id)
            self.selector.append_selection(id)
        # enable self
        self.setEnabled(True)

    def start_sequence(self):
        """ Start sequence capturing
        """
        # enable capturing
        self.selector.enable_capturing()
        # perform button stuffs
        self.start_pushbutton.setEnabled(False)
        self.reset_pushbutton.setEnabled(False)
        self.stop_pushbutton.setEnabled(True)
        self.new_pushbutton.setEnabled(True)

    def stop_sequence(self):
        """ Stop sequence capturing
        """
        # disable capturing
        self.selector.disable_capturing()
        # perform button stuffs
        self.stop_pushbutton.setEnabled(False)
        self.new_pushbutton.setEnabled(False)
        self.sequence_listwidget.clear()
        self.sequence = []
        for feature in self.selector.selected:
            beacon_id = str(
                self.database.query(
                    self.SQL_BEACONS["SELECT"], (feature,))[0][0])
            self.sequence.append(beacon_id)
            self.sequence_listwidget.addItem(beacon_id.replace("\n", ""))
        self.start_pushbutton.setEnabled(True)
        self.reset_pushbutton.setEnabled(True)

    def reset_sequence(self):
        """ Reset captured sequence
        """
        # clear selection
        self.selector.clear_selection()
        self.sequence = []
        # clear sequence
        self.sequence_listwidget.clear()
        # perform button stuffs
        self.reset_pushbutton.setEnabled(False)
        self.start_pushbutton.setEnabled(True)

    def setup_ui(self, autocomplete):
        """ Initialize ui
        """
        # define ui widgets
        self.setObjectName(_from_utf8("FormParcelDialog"))
        self.setCursor(QCursor(Qt.ArrowCursor))
        self.grid_layout = QGridLayout(self)
        self.grid_layout.setSizeConstraint(QLayout.SetFixedSize)
        self.grid_layout.setObjectName(_from_utf8("gridLayout"))
        self.vertical_layout_2 = QVBoxLayout()
        self.vertical_layout_2.setObjectName(_from_utf8("verticalLayout_2"))
        self.form_layout = QFormLayout()
        self.form_layout.setObjectName(_from_utf8("formLayout"))
        self.parcel_id_label = QLabel(self)
        self.parcel_id_label.setObjectName(_from_utf8("lbl_parcelID"))
        self.form_layout.setWidget(
            0, QFormLayout.LabelRole, self.parcel_id_label)
        self.parcel_id_lineedit = QLineEdit(self)
        self.parcel_id_lineedit.setObjectName(_from_utf8("lnedt_parcelID"))
        self.form_layout.setWidget(
            0, QFormLayout.FieldRole, self.parcel_id_lineedit)
        model = QStringListModel()
        model.setStringList(autocomplete)
        completer = QCompleter()
        completer.setCaseSensitivity(Qt.CaseInsensitive)
        completer.setModel(model)
        self.parcel_id_lineedit.setCompleter(completer)
        self.vertical_layout_2.addLayout(self.form_layout)
        self.horizontal_layout_2 = QHBoxLayout()
        self.horizontal_layout_2.setObjectName(
            _from_utf8("horizontalLayout_2"))
        self.sequence_label = QLabel(self)
        self.sequence_label.setObjectName(_from_utf8("lbl_sequence"))
        self.horizontal_layout_2.addWidget(self.sequence_label)
        spacer_item_1 = QSpacerItem(
            40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)
        self.horizontal_layout_2.addItem(spacer_item_1)
        self.new_pushbutton = QPushButton(self)
        self.new_pushbutton.setEnabled(False)
        self.new_pushbutton.setObjectName(_from_utf8("pshbtn_new"))
        self.new_pushbutton.setCursor(QCursor(Qt.PointingHandCursor))
        self.horizontal_layout_2.addWidget(self.new_pushbutton)
        self.vertical_layout_2.addLayout(self.horizontal_layout_2)
        self.horizontal_layout_1 = QHBoxLayout()
        self.horizontal_layout_1.setObjectName(
            _from_utf8("horizontalLayout_1"))
        self.vertical_layout_1 = QVBoxLayout()
        self.vertical_layout_1.setObjectName(_from_utf8("verticalLayout_1"))
        self.start_pushbutton = QPushButton(self)
        self.start_pushbutton.setEnabled(True)
        self.start_pushbutton.setObjectName(_from_utf8("pshbtn_start"))
        self.start_pushbutton.setCursor(QCursor(Qt.PointingHandCursor))
        self.vertical_layout_1.addWidget(self.start_pushbutton)
        self.stop_pushbutton = QPushButton(self)
        self.stop_pushbutton.setEnabled(False)
        self.stop_pushbutton.setObjectName(_from_utf8("pshbtn_stop"))
        self.stop_pushbutton.setCursor(QCursor(Qt.PointingHandCursor))
        self.vertical_layout_1.addWidget(self.stop_pushbutton)
        self.reset_pushbutton = QPushButton(self)
        self.reset_pushbutton.setEnabled(False)
        self.reset_pushbutton.setObjectName(_from_utf8("pshbtn_reset"))
        self.reset_pushbutton.setCursor(QCursor(Qt.PointingHandCursor))
        self.vertical_layout_1.addWidget(self.reset_pushbutton)
        spacer_item_2 = QSpacerItem(
            20, 40, QSizePolicy.Minimum, QSizePolicy.Expanding)
        self.vertical_layout_1.addItem(spacer_item_2)
        self.horizontal_layout_1.addLayout(self.vertical_layout_1)
        self.sequence_listwidget = QListWidget(self)
        self.sequence_listwidget.setEnabled(False)
        self.sequence_listwidget.setObjectName(_from_utf8("lstwdg_sequence"))
        self.horizontal_layout_1.addWidget(self.sequence_listwidget)
        self.vertical_layout_2.addLayout(self.horizontal_layout_1)
        self.options_buttonbox = QDialogButtonBox(self)
        self.options_buttonbox.setStandardButtons(
            QDialogButtonBox.Cancel | QDialogButtonBox.Save)
        self.options_buttonbox.setObjectName(_from_utf8("btnbx_options"))
        self.options_buttonbox.setCursor(QCursor(Qt.PointingHandCursor))
        self.vertical_layout_2.addWidget(self.options_buttonbox)
        self.grid_layout.addLayout(self.vertical_layout_2, 0, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(
            QApplication.translate(
                "FormParcelDialog",
                "Parcel Form",
                None,
                QApplication.UnicodeUTF8))
        self.parcel_id_label.setText(
            QApplication.translate(
                "FormParcelDialog",
                "Parcel ID",
                None,
                QApplication.UnicodeUTF8))
        self.sequence_label.setText(
            QApplication.translate(
                "FormParcelDialog",
                "Beacon Sequence",
                None,
                QApplication.UnicodeUTF8))
        self.new_pushbutton.setText(
            QApplication.translate(
                "FormParcelDialog",
                "New Beacon",
                None,
                QApplication.UnicodeUTF8))
        self.start_pushbutton.setText(
            QApplication.translate(
                "FormParcelDialog",
                "Start",
                None,
                QApplication.UnicodeUTF8))
        self.stop_pushbutton.setText(
            QApplication.translate(
                "FormParcelDialog",
                "Stop",
                None,
                QApplication.UnicodeUTF8))
        self.reset_pushbutton.setText(
            QApplication.translate(
                "FormParcelDialog",
                "Reset",
                None,
                QApplication.UnicodeUTF8))
        # connect ui widgets
        self.new_pushbutton.clicked.connect(self.new_beacon)
        self.start_pushbutton.clicked.connect(self.start_sequence)
        self.stop_pushbutton.clicked.connect(self.stop_sequence)
        self.reset_pushbutton.clicked.connect(self.reset_sequence)
        self.options_buttonbox.clicked.connect(self.execute_option)
        QMetaObject.connectSlotsByName(self)


class BearingDistanceFormDialog(QDialog):
    """ This dialog enables the user to define bearings and distances
    """

    def __init__(
            self,
            database,
            SQL_BEARDIST,
            SQL_BEACONS,
            required_layers,
            parent=None):
        # initialize QDialog class
        super(BearingDistanceFormDialog, self).\
            __init__(parent, Qt.WindowStaysOnTopHint)
        # initialize ui
        self.setupUi()
        self.database = database
        self.SQL_BEARDIST = SQL_BEARDIST
        self.SQL_BEACONS = SQL_BEACONS
        self.layers = required_layers
        self.auto = {
            "SURVEYPLAN": self.database.query(
                SQL_BEARDIST["AUTO_SURVEYPLAN"]
                )[0][0],
            "REFERENCEBEACON": self.database.query(
                SQL_BEARDIST["AUTO_REFERENCEBEACON"]
                )[0][0],
            "FROMBEACON": []
        }
        self.survey_plan = None
        self.reference_beacon = None
        self.bearing_distance_chain = []
        self.bearing_distance_string = (
            "%s" + u"\u00B0" + " and %sm from %s to %s")
        # initialize initial step
        self.init_item_survey_plan()

    def get_return(self):
        """ Return intended variable(s) after the dialog has been accepted
        @returns (
        <survey plan number>, <reference beacon>, <beardist chain>) (tuple)
        """
        return (
            self.survey_plan,
            self.reference_beacon,
            self.bearing_distance_chain)

    def set_current_item(self, index, clear=False, enabled=False):
        """ Set the current toolbox item and disable all other toolbox items
        """
        # clear editable fields if needed
        if clear:
            for widget in self.toolbox.widget(index).findChildren(QWidget):
                if type(widget) in [QLineEdit]:
                    widget.setText("")
        # enable editable fields if needed
        if enabled:
            for widget in self.toolbox.widget(index).findChildren(QWidget):
                if type(widget) in [QLineEdit]:
                    widget.setEnabled(True)
        # disable all items
        for i in range(self.count):
            self.toolbox.setItemEnabled(i, False)
        # enable and display desired item
        self.toolbox.setCurrentIndex(index)
        self.toolbox.setItemEnabled(index, True)

    def init_item_survey_plan(self, forward=True):
        """ Initialize form elements for the survey plan item
        """
        if not forward:
            if not self.confirm_back():
                return
        # update autocompletion
        model = QStringListModel()
        model.setStringList(self.auto["SURVEYPLAN"])
        completer = QCompleter()
        completer.setCaseSensitivity(Qt.CaseInsensitive)
        completer.setModel(model)
        self.plan_lineedit.setCompleter(completer)
        # reset variables associated with item
        self.survey_plan = None
        # display survey plan item
        self.set_current_item(0)

    def check_item_survey_plan(self, forward):
        """ Validate form elements before proceding from the survey plan item
        """
        # check direction
        if forward:
            # check that a server plan number was specified
            survey_plan = str(self.plan_lineedit.text()).strip()
            if survey_plan is "":
                QMessageBox.information(
                    self,
                    "Empty Survey Plan Number",
                    "Please enter a surver plan number.")
                return
            # set survey plan number
            self.survey_plan = survey_plan
            # display next toolbox item
            self.init_item_reference_beacon()
        else:
            pass

    def init_item_reference_beacon(self, forward=True):
        """ Initialize form elements for the reference beacon item
        """
        if not forward:
            if not self.confirm_back():
                return
        # update autocompletion
        model = QStringListModel()
        model.setStringList(self.auto["REFERENCEBEACON"])
        completer = QCompleter()
        completer.setCaseSensitivity(Qt.CaseInsensitive)
        completer.setModel(model)
        self.reference_lineedit.setCompleter(completer)
        # reset variables associated with items
        self.reference_beacon = None
        # check direction whence it came
        if forward:
            # check if survey plan number has a pre-defined reference beacon
            if self.survey_plan in self.auto["SURVEYPLAN"]:
                # update item contents
                self.reference_lineedit.setEnabled(False)
                self.reference_lineedit.setText(
                    str(self.database.query(
                        self.SQL_BEARDIST["EXIST_REFERENCEBEACON"],
                        (self.survey_plan,))[0][0]))
            else:
                # update item contents
                self.reference_lineedit.setEnabled(True)
                self.reference_lineedit.setText("")
        # display reference beacon item
        self.set_current_item(1)

    def check_item_reference_beacon(self, forward):
        """ Validate form elements before proceding from the reference beacon item
        """
        # check direction
        if forward:
            # check that a reference beacon was specified
            reference_beacon = str(self.reference_lineedit.text()).strip()
            if reference_beacon is "":
                QMessageBox.information(
                    self,
                    "Empty Reference Beacon",
                    "Please enter a reference beacon.")
                return
            # check if reference beacon exists
            if reference_beacon in self.auto["REFERENCEBEACON"]:
                # set reference beacon
                self.reference_beacon = reference_beacon
                # display next toolbox item
                self.init_item_bearing_distance_chain()
            else:
                # disable self
                self.setEnabled(False)
                # present beacon form
                column_index = self.database.query(
                    self.SQL_BEARDIST["INDEX_REFERENCEBEACON"])[0][0]
                # get fields
                fields = self.database.get_schema(
                    self.layers[0].table, [
                        self.layers[0].geometry_column,
                        self.layers[0].primary_key])
                # display form
                form = FormBeaconDialog(
                    self.database,
                    self.SQL_BEACONS["UNIQUE"],
                    fields,
                    parent=self)
                form.lnedts[column_index].setText(reference_beacon)
                form.lnedts[column_index].setEnabled(False)
                form.show()
                form_ret = form.exec_()
                if bool(form_ret):
                    # add beacon to database
                    old_values, new_values = form.get_values()
                    self.database.query(
                        self.SQL_BEACONS["INSERT"].format(
                            fields=", ".join(sorted(new_values.keys())),
                            values=", ".join(
                                ["%s" for index in new_values.keys()])),
                        [new_values[index] for index in (
                            sorted(new_values.keys()))])
                    # set reference beacon
                    self.reference_beacon = reference_beacon
                    self.auto["REFERENCEBEACON"].append(reference_beacon)
                    # enable self
                    self.setEnabled(True)
                    # display next toolbox item
                    self.init_item_bearing_distance_chain()
                else:
                    # enable self
                    self.setEnabled(True)
        else:
            self.init_item_survey_plan(False)

    def init_item_bearing_distance_chain(self, forward=True):
        """ Initialize form elements for the beardist chain item
        """
        # reset variables associated with items
        self.bearing_distance_chain = []
        self.auto["FROMBEACON"] = []
        self.chain_list.clear()
        self.auto["FROMBEACON"].append(self.reference_beacon)
        # perform button stuffs
        self.chain_edit_pushbutton.setEnabled(False)
        self.chain_delete_pushbutton.setEnabled(False)
        self.chain_finish_pushbutton.setEnabled(False)
        # check if reference beacon is predefined
        if self.reference_beacon in self.auto["REFERENCEBEACON"]:
            # check if survey plan number is predefined
            if self.survey_plan in self.auto["SURVEYPLAN"]:
                # get defined bearings and distances
                records = self.database.query(
                    self.SQL_BEARDIST["EXIST_BEARDISTCHAINS"],
                    (self.survey_plan,)
                )
                if records not in [None, []]:
                    for object_id, link in enumerate(records):
                        self.bearing_distance_chain.append(
                            [list(link), "NULL", object_id])
                    self.update_bearing_distance_chain_dependants()
                    self.chain_finish_pushbutton.setEnabled(True)
                    self.chain_edit_pushbutton.setEnabled(True)
                    self.chain_delete_pushbutton.setEnabled(True)
        # display beardist chain item
        self.set_current_item(2)

    def check_item_bearing_distance_chain(self, forward):
        """ Validate form elements before proceding from the beardist chain item
        """
        # check direction
        if forward:
            if not bool(self.survey_plan):
                QMessageBox.information(
                    self,
                    "No Survey Plan",
                    "Please specify a survey plan number")
                return
            if not bool(self.reference_beacon):
                QMessageBox.information(
                    self,
                    "No Reference Beacon",
                    "Please specify a reference beacon")
                return
            if not bool(self.bearing_distance_chain):
                QMessageBox.information(
                    self,
                    "No Bearing and Distance Chain",
                    "Please capture bearings and distances")
                return
            self.accept()
        else:
            self.init_item_reference_beacon(False)

    def is_beacon_reference_exist(self, beacon_name):
        while True:
            beacon_to = None
            for link in self.bearing_distance_chain:
                if beacon_name == link[0][3]:
                    beacon_to = link[0][2]
                    break
            if beacon_to is None:
                return False
            if beacon_to == beacon_name:
                return False
            if beacon_to == self.reference_beacon:
                return True

    def is_end_linked(self, index):
        """ Test whether or not the link is safe to edit or delete
        """
        beacon_to = self.bearing_distance_chain[index][0][3]
        for link in self.bearing_distance_chain:
            beacon_from = link[0][2]
            if beacon_to == beacon_from:
                return False
        return True

    def is_last_anchor_linked(self, index):
        """ Test whether or not the link is the only one using the reference beacon
        """
        beacon_reference = self.bearing_distance_chain[index][0][2]
        # check if reference beacon is used
        if beacon_reference != self.reference_beacon:
            return False
        # count number of reference beacon occurrences
        count = 0
        for link in self.bearing_distance_chain:
            beacon_from = link[0][2]
            if beacon_from == beacon_reference:
                count += 1
        # check count
        return True if count == 1 else False

    def get_selected_index(self, action):
        """ Captures selected link from the chain list
        """
        # get list of selected items
        items = self.chain_list.selectedItems()
        # check list is non-empty
        if len(items) == 0:
            QMessageBox.information(
                self,
                "No Link Selected",
                "Please select a link to edit")
            return None
        # check list does not contain more than one item
        if len(items) > 1:
            QMessageBox.information(
                self,
                "Too Many Links Selected",
                "Please select only one link to edit")
            return None
        # get item index
        index = self.chain_list.row(items[0])
        # check that index is of an end link
        if not bool(self.is_end_linked(index)):
            if QMessageBox.question(
                    self,
                    "Non End Link Selected", (
                            "The link you selected is not at the end of "
                            "a chain. If you {action} this link it will "
                            "{action} all links that depend on this one. "
                            "Are you sure you want to {action} this "
                            "link?".format(action=action.lower())),
                    QMessageBox.Yes, QMessageBox.No) == QMessageBox.No:
                return None
        # return index
        return index

    def update_bearing_distance_chain_dependants(self):
        """ Reinitialize all variables defined from the beardist chain
        """
        # clear dependants
        self.chain_list.clear()
        self.auto["FROMBEACON"] = [self.reference_beacon]
        # populate dependants
        for link in self.bearing_distance_chain:
            # QMessageBox.information(self,QString(','.join(link[0][:4])))
            self.chain_list.addItem(
                self.bearing_distance_string % tuple(link[0][:4]))
            self.auto["FROMBEACON"].append(link[0][3])
        self.auto["FROMBEACON"].sort()

    def add_link(self):
        """ Add a link to the beardist chain
        """
        while True:
            dialog = BearingDistanceLinkFormDialog(
                self.database,
                self.auto["FROMBEACON"],
                self.SQL_BEACONS["UNIQUE"],
                parent=self)
            dialog.show()
            dialog_ret = dialog.exec_()
            if bool(dialog_ret):
                values = dialog.get_values()
                self.bearing_distance_chain.append([values, "INSERT", None])
                self.update_bearing_distance_chain_dependants()
            else:
                break
        if len(self.bearing_distance_chain) >= 1:
            self.chain_finish_pushbutton.setEnabled(True)
            self.chain_edit_pushbutton.setEnabled(True)
            self.chain_delete_pushbutton.setEnabled(True)

    def edit_link(self):
        """ Edit a link from the beardist chain
        """
        # get selected index
        index = self.get_selected_index("edit")
        # check selection
        if index is not None:
            # display dialog
            dialog = BearingDistanceLinkFormDialog(
                self.database,
                self.auto["FROMBEACON"],
                self.SQL_BEACONS["UNIQUE"],
                values=self.bearing_distance_chain[index][0],
                parent=self)
            if self.is_last_anchor_linked(index):
                dialog.line_edits[2].setEnabled(False)
            dialog.show()
            dialog_ret = dialog.exec_()
            if bool(dialog_ret):
                values = dialog.get_values()
                # check if anything was changed
                if values == self.bearing_distance_chain[index][0]:
                    return
                # check if reference beacon can be found
                if not self.is_beacon_reference_exist(
                        self.bearing_distance_chain[index][0][3]):
                    QMessageBox.information(None, "", "oops")
                # recursively update beacon names if changed
                if self.bearing_distance_chain[index][0][3] != values[3]:
                    temp = []
                    for link in self.bearing_distance_chain:
                        if link[0][2] == (
                                self.bearing_distance_chain[index][0][3]):
                            link[0][2] = values[3]
                        temp.append(link)
                    self.bearing_distance_chain = temp
                # update beardist chain entry
                if self.bearing_distance_chain[index][1] in ["NULL", "UPDATE"]:
                    self.bearing_distance_chain[index] = [
                        values,
                        "UPDATE",
                        self.bearing_distance_chain[index][-1]]
                elif self.bearing_distance_chain[index][1] == "INSERT":
                    self.bearing_distance_chain[index] = [
                        values,
                        "INSERT",
                        None]
                self.update_bearing_distance_chain_dependants()

    def delete_link(self):
        """ Delete a link from the beardist chain
        """
        # get selected index
        index = self.get_selected_index("delete")
        # check selection
        if index is not None:
            # prevent last link to use reference beacon from being deleted
            if self.is_last_anchor_linked(index):
                QMessageBox.warning(
                    self,
                    "Last Link To Reference Beacon",
                    "Cannot remove last link to reference beacon")
                return
            # recursively delete dependant links
            self.delete_dependant_links(
                self.bearing_distance_chain[index][0][3])
            # delete link
            del self.bearing_distance_chain[index]
            self.update_bearing_distance_chain_dependants()
            if len(self.bearing_distance_chain) == 0:
                self.chain_finish_pushbutton.setEnabled(False)
                self.chain_edit_pushbutton.setEnabled(False)
                self.chain_delete_pushbutton.setEnabled(False)

    def delete_dependant_links(self, beacon_to):
        """ Recursively delete dependant links
        """
        gone = False
        while not gone:
            gone = True
            index = -1
            for i, link in enumerate(self.bearing_distance_chain):
                if link[0][2] == beacon_to:
                    if not self.is_last_anchor_linked(i):
                        index = i
                        gone = False
                        break
            if index != -1:
                if not self.is_end_linked(index):
                    self.delete_dependant_links(
                        self.bearing_distance_chain[index][0][3])
                del self.bearing_distance_chain[index]

    def setupUi(self):
        """ Initialize ui
        """
        # define dialog
        self.setObjectName(_from_utf8("BearingDistanceFormDialog"))
        self.resize(450, 540)
        self.setModal(True)
        # define dialog layout manager
        self.dialog_gridlayout = QGridLayout(self)
        self.dialog_gridlayout.setSizeConstraint(QLayout.SetDefaultConstraint)
        self.dialog_gridlayout.setObjectName(_from_utf8("grdlyt_dlg"))
        # define toolbox
        self.toolbox = QToolBox(self)
        self.toolbox.setFrameShape(QFrame.StyledPanel)
        self.toolbox.setObjectName(_from_utf8("tlbx"))
        self.count = 3
        # define first item: survey plan
        self.plan_widget = QWidget()
        self.plan_widget.setObjectName(_from_utf8("itm_plan"))
        self.plan_gridlayout = QGridLayout(self.plan_widget)
        self.plan_gridlayout.setObjectName(_from_utf8("grdlyt_chain"))
        self.plan_verticallayout = QVBoxLayout()
        self.plan_verticallayout.setObjectName(_from_utf8("vrtlyt_plan"))
        self.plan_formlayout = QFormLayout()
        self.plan_formlayout.setObjectName(_from_utf8("frmlyt_plan"))
        self.plan_label = QLabel(self.plan_widget)
        self.plan_label.setObjectName(_from_utf8("lbl_plan"))
        self.plan_formlayout.setWidget(
            0, QFormLayout.LabelRole, self.plan_label)
        self.plan_lineedit = QLineEdit(self.plan_widget)
        self.plan_lineedit.setObjectName(_from_utf8("lnedt_plan"))
        self.plan_formlayout.setWidget(
            0, QFormLayout.FieldRole, self.plan_lineedit)
        self.plan_verticallayout.addLayout(self.plan_formlayout)
        self.plan_verticalspacer = QSpacerItem(
            20, 40, QSizePolicy.Minimum, QSizePolicy.Expanding)
        self.plan_verticallayout.addItem(self.plan_verticalspacer)
        self.plan_horizonlayout = QHBoxLayout()
        self.plan_horizonlayout.setObjectName(_from_utf8("hrzlyt_plan"))
        self.plan_horizonspacer = QSpacerItem(
            40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)
        self.plan_horizonlayout.addItem(self.plan_horizonspacer)
        self.plan_next_pushbutton = XQPushButton(self.plan_widget)
        self.plan_next_pushbutton.setObjectName(_from_utf8("pshbtn_plan_next"))
        self.plan_horizonlayout.addWidget(self.plan_next_pushbutton)
        self.plan_verticallayout.addLayout(self.plan_horizonlayout)
        self.plan_gridlayout.addLayout(self.plan_verticallayout, 0, 0, 1, 1)
        self.toolbox.addItem(self.plan_widget, _from_utf8(""))
        # define second item: reference beacon
        self.reference_widget = QWidget()
        self.reference_widget.setObjectName(_from_utf8("itm_ref"))
        self.reference_gridlayout = QGridLayout(self.reference_widget)
        self.reference_gridlayout.setObjectName(_from_utf8("grdlyt_ref"))
        self.reference_verticallayout = QVBoxLayout()
        self.reference_verticallayout.setObjectName(_from_utf8("vrtlyt_ref"))
        self.reference_formlayout = QFormLayout()
        self.reference_formlayout.setObjectName(_from_utf8("frmlyt_ref"))
        self.reference_layout = QLabel(self.reference_widget)
        self.reference_layout.setObjectName(_from_utf8("lbl_ref"))
        self.reference_formlayout.setWidget(
            0, QFormLayout.LabelRole, self.reference_layout)
        self.reference_lineedit = QLineEdit(self.reference_widget)
        self.reference_lineedit.setObjectName(_from_utf8("lnedt_ref"))
        self.reference_formlayout.setWidget(
            0, QFormLayout.FieldRole, self.reference_lineedit)
        self.reference_verticallayout.addLayout(self.reference_formlayout)
        self.reference_verticalspacer = QSpacerItem(
            20, 40, QSizePolicy.Minimum, QSizePolicy.Expanding)
        self.reference_verticallayout.addItem(self.reference_verticalspacer)
        self.reference_horizonlayout = QHBoxLayout()
        self.reference_horizonlayout.setObjectName(_from_utf8("hrzlyt_ref"))
        self.reference_back_pushbutton = XQPushButton(self.reference_widget)
        self.reference_back_pushbutton.setObjectName(
            _from_utf8("pshbtn_ref_back"))
        self.reference_horizonlayout.addWidget(self.reference_back_pushbutton)
        self.reference_horizonspacer = QSpacerItem(
            40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)
        self.reference_horizonlayout.addItem(self.reference_horizonspacer)
        self.reference_next_pushbutton = XQPushButton(self.reference_widget)
        self.reference_next_pushbutton.setObjectName(
            _from_utf8("pshbtn_ref_next"))
        self.reference_horizonlayout.addWidget(self.reference_next_pushbutton)
        self.reference_verticallayout.addLayout(self.reference_horizonlayout)
        self.reference_gridlayout.addLayout(
            self.reference_verticallayout, 0, 0, 1, 1)
        self.toolbox.addItem(self.reference_widget, _from_utf8(""))
        # define third item: beardist chain
        self.chain_widget = QWidget()
        self.chain_widget.setObjectName(_from_utf8("itm_chain"))
        self.chain_gridlayout = QGridLayout(self.chain_widget)
        self.chain_gridlayout.setObjectName(_from_utf8("grdlyt_chain"))
        self.chain_verticallayout = QVBoxLayout()
        self.chain_verticallayout.setObjectName(_from_utf8("vrtlyt_chain"))
        self.chain_list = QListWidget(self.chain_widget)
        self.chain_list.setObjectName(_from_utf8("lst_chain"))
        self.chain_verticallayout.addWidget(self.chain_list)
        self.chain_link_horizonlayout = QHBoxLayout()
        self.chain_link_horizonlayout.setObjectName(
            _from_utf8("hrzlyt_chain_link"))
        self.chain_link_verticallayout = QVBoxLayout()
        self.chain_link_verticallayout.setObjectName(
            _from_utf8("vrtlyt_chain_link"))
        self.chain_add_pushbutton = XQPushButton(self.chain_widget)
        self.chain_add_pushbutton.setObjectName(_from_utf8("pshbtn_chain_add"))
        self.chain_link_verticallayout.addWidget(self.chain_add_pushbutton)
        self.chain_edit_pushbutton = XQPushButton(self.chain_widget)
        self.chain_edit_pushbutton.setObjectName(
            _from_utf8("pshbtn_chain_edt"))
        self.chain_link_verticallayout.addWidget(self.chain_edit_pushbutton)
        self.chain_delete_pushbutton = XQPushButton(self.chain_widget)
        self.chain_delete_pushbutton.setObjectName(
            _from_utf8("pshbtn_chain_del"))
        self.chain_link_verticallayout.addWidget(self.chain_delete_pushbutton)
        self.chain_link_horizonlayout.addLayout(self.chain_link_verticallayout)
        self.chain_link_horizonspacer = QSpacerItem(
            40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)
        self.chain_link_horizonlayout.addItem(self.chain_link_horizonspacer)
        self.chain_verticallayout.addLayout(self.chain_link_horizonlayout)
        self.chain_verticalspacer = QSpacerItem(
            20, 40, QSizePolicy.Minimum, QSizePolicy.Expanding)
        self.chain_verticallayout.addItem(self.chain_verticalspacer)
        self.chain_step_horizonlayout = QHBoxLayout()
        self.chain_step_horizonlayout.setObjectName(
            _from_utf8("hrzlyt_chain_step"))
        self.chain_back_pushbutton = XQPushButton(self.chain_widget)
        self.chain_back_pushbutton.setObjectName(
            _from_utf8("pshbtn_chain_back"))
        self.chain_step_horizonlayout.addWidget(self.chain_back_pushbutton)
        self.chain_step_horizonspacer = QSpacerItem(
            40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum)
        self.chain_step_horizonlayout.addItem(self.chain_step_horizonspacer)
        self.chain_finish_pushbutton = XQPushButton(self.chain_widget)
        self.chain_finish_pushbutton.setObjectName(
            _from_utf8("pshbtn_chain_finish"))
        self.chain_step_horizonlayout.addWidget(self.chain_finish_pushbutton)
        self.chain_verticallayout.addLayout(self.chain_step_horizonlayout)
        self.chain_gridlayout.addLayout(self.chain_verticallayout, 0, 0, 1, 1)
        self.toolbox.addItem(self.chain_widget, _from_utf8(""))
        # finish dialog definition
        self.dialog_gridlayout.addWidget(self.toolbox, 0, 0, 1, 1)
        self.options_buttonbox = XQDialogButtonBox(self)
        self.options_buttonbox.setOrientation(Qt.Horizontal)
        self.options_buttonbox.setStandardButtons(XQDialogButtonBox.Cancel)
        self.options_buttonbox.setObjectName(_from_utf8("btnbx_options"))
        self.dialog_gridlayout.addWidget(self.options_buttonbox, 1, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Bearings and Distances Form",
                None,
                QApplication.UnicodeUTF8))
        self.plan_label.setText(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Survey Plan",
                None,
                QApplication.UnicodeUTF8))
        self.plan_next_pushbutton.setText(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Next",
                None,
                QApplication.UnicodeUTF8))
        self.toolbox.setItemText(
            self.toolbox.indexOf(self.plan_widget),
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Step 1: Define Survey Plan",
                None,
                QApplication.UnicodeUTF8))
        self.reference_layout.setText(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Reference Beacon",
                None,
                QApplication.UnicodeUTF8))
        self.reference_back_pushbutton.setText(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Back",
                None,
                QApplication.UnicodeUTF8))
        self.reference_next_pushbutton.setText(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Next",
                None,
                QApplication.UnicodeUTF8))
        self.toolbox.setItemText(
            self.toolbox.indexOf(self.reference_widget),
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Step 2: Define Reference Beacon",
                None,
                QApplication.UnicodeUTF8))
        self.chain_add_pushbutton.setText(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Add Link",
                None,
                QApplication.UnicodeUTF8))
        self.chain_edit_pushbutton.setText(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Edit Link",
                None,
                QApplication.UnicodeUTF8))
        self.chain_delete_pushbutton.setText(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Delete Link",
                None,
                QApplication.UnicodeUTF8))
        self.chain_back_pushbutton.setText(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Back",
                None,
                QApplication.UnicodeUTF8))
        self.chain_finish_pushbutton.setText(
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Finish",
                None,
                QApplication.UnicodeUTF8))
        self.toolbox.setItemText(
            self.toolbox.indexOf(self.chain_widget),
            QApplication.translate(
                "BearingDistanceFormDialog",
                "Step 3: Define Bearings and Distances Chain",
                None,
                QApplication.UnicodeUTF8))
        # connect ui widgets
        self.options_buttonbox.accepted.connect(self.accept)
        self.options_buttonbox.rejected.connect(self.reject)
        self.chain_finish_pushbutton.clicked.connect(
            lambda: self.check_item_bearing_distance_chain(True))
        self.chain_back_pushbutton.clicked.connect(
            lambda: self.check_item_bearing_distance_chain(False))
        self.reference_next_pushbutton.clicked.connect(
            lambda: self.check_item_reference_beacon(True))
        self.reference_back_pushbutton.clicked.connect(
            lambda: self.check_item_reference_beacon(False))
        self.plan_next_pushbutton.clicked.connect(
            lambda : self.check_item_survey_plan(True))
        self.chain_add_pushbutton.clicked.connect(self.add_link)
        self.chain_edit_pushbutton.clicked.connect(self.edit_link)
        self.chain_delete_pushbutton.clicked.connect(self.delete_link)
        QMetaObject.connectSlotsByName(self)

    def confirm_back(self):
        return QMessageBox.question(
            self,
            "Going Back",
            ("Any changes made will be lost. "
             "Are your sure that you want to go back?"),
            QMessageBox.Yes, QMessageBox.No) == QMessageBox.Yes


class BearingDistanceLinkFormDialog(QDialog):
    """ This dialog enables the user to add a bearing and distance link
    """

    def __init__(self, database, from_beacons, query, values=[], parent=None):
        # initialize QDialog class
        super(BearingDistanceLinkFormDialog, self).\
            __init__(parent, Qt.WindowStaysOnTopHint)
        # initialize ui
        self.setup_ui(from_beacons)
        # initialize instance variables
        self.old_values = values
        self.new_values = []
        self.database = database
        self.query = query
        self.from_beacons = from_beacons
        self.colours = {
            "EMPTY": "background-color: rgba(255, 107, 107, 150);",
            "TYPE": "background-color: rgba(107, 107, 255, 150);",
            "BEACON": "background-color: rgba(107, 255, 107, 150);",
            "UNIQUE": "background-color: rgba(107, 255, 107, 150);"
        }
        # populate form if values are given
        if bool(values):
            self.populate_form(values)

    def populate_form(self, values):
        """ Populte form with values given
        """
        for index, line_edit in enumerate(self.line_edits):
            if values[index] is not None:
                line_edit.setText(str(values[index]))

    def get_values(self):
        return self.new_values

    def execute_option(self, button):
        """ Perform validation and close the dialog
        """
        if self.options_buttonbox.standardButton(button) == \
                QDialogButtonBox.Save:
            new_values = []
            # check required fields
            valid = True
            for index, line_edit in enumerate(self.line_edits):
                if self.fields[index].required:
                    if str(line_edit.text()).strip() is "":
                        line_edit.setStyleSheet(self.colours["EMPTY"])
                        valid = False
                    else:
                        line_edit.setStyleSheet("")
            if not valid:
                QMessageBox.information(
                    self,
                    "Empty Required Fields",
                    "Please ensure that all required fields are completed.")
                return
            # check correct field types
            valid = True
            for index, line_edit in enumerate(self.line_edits):
                try:
                    cast = self.fields[index].type
                    text = str(line_edit.text()).strip()
                    if text is "":
                        temp = None
                    else:
                        temp = cast(text)
                    new_values.append(temp)
                    line_edit.setStyleSheet("")
                except Exception as e:
                    line_edit.setStyleSheet(self.colours["TYPE"])
                    valid = False
            if not valid:
                QMessageBox.information(
                    self,
                    "Invalid Field Types",
                    "Please ensure that fields are completed with valid types."
                )
                return
            # check valid from beacon field
            valid = True
            for index, line_edit in enumerate(self.line_edits):
                if self.fields[index].name.lower() == "from":
                    if str(line_edit.text()) not in self.from_beacons:
                        line_edit.setStyleSheet(self.colours["BEACON"])
                        valid = False
            if not valid:
                QMessageBox.information(
                    self,
                    "Invalid Reference",
                    "Please ensure that specified beacons are valid.")
                return
            # check valid to beacon field
            valid = True
            for index, line_edit in enumerate(self.line_edits):
                if self.fields[index].name.lower() == "to":
                    if bool(self.old_values):
                        if str(line_edit.text()) not in self.old_values:
                            if str(line_edit.text()) in self.from_beacons:
                                line_edit.setStyleSheet(self.colours["UNIQUE"])
                                valid = False
                                break
                    elif not bool(self.old_values):
                        if str(line_edit.text()) in self.from_beacons:
                            line_edit.setStyleSheet(self.colours["UNIQUE"])
                            valid = False
                            break
                    if bool(
                            int(self.database.query(
                                        self.query % ('beacon', "%s"),
                            (str(line_edit.text()),))[0][0])):
                        line_edit.setStyleSheet(self.colours["UNIQUE"])
                        valid = False
                        break
            if not valid:
                QMessageBox.information(
                    self,
                    "Invalid Reference",
                    "Please ensure that the new beacon is unique.")
                return
            # save values
            self.new_values = new_values
            # accept dialog
            self.accept()
        else:
            # reject dialog
            self.reject()

    def setup_ui(self, from_beacons):
        """ Initialize ui
        """
        # define dialog
        self.grid_layout = QGridLayout(self)
        self.setModal(True)
        self.grid_layout.setSizeConstraint(QLayout.SetFixedSize)
        self.form_layout = QFormLayout()
        self.labels = []
        self.line_edits = []
        self.fields = [
            Field("Bearing", float, True, False),
            Field("Distance", float, True, False),
            Field("From", str, True, False),
            Field("To", str, True, False),
            Field("Location", str, False, False),
            Field("Surveyor", str, False, False)
        ]
        for index, field in enumerate(self.fields):
            label = QLabel(self)
            self.form_layout.setWidget(index, QFormLayout.LabelRole, label)
            label.setText(QApplication.translate(
                "dlg_FormBearDistEntry",
                ("*" if field.required else "") + field.name.title(),
                None,
                QApplication.UnicodeUTF8))
            self.labels.append(label)
            line_edit = QLineEdit(self)
            self.form_layout.setWidget(index, QFormLayout.FieldRole, line_edit)
            self.line_edits.append(line_edit)
            if field.name.lower() == "from":
                model = QStringListModel()
                model.setStringList(from_beacons)
                completer = QCompleter()
                completer.setCaseSensitivity(Qt.CaseInsensitive)
                completer.setModel(model)
                line_edit.setCompleter(completer)
        self.grid_layout.addLayout(self.form_layout, 0, 0, 1, 1)
        self.options_buttonbox = QDialogButtonBox(self)
        self.options_buttonbox.setCursor(QCursor(Qt.PointingHandCursor))
        self.options_buttonbox.setStandardButtons(
            QDialogButtonBox.Cancel | QDialogButtonBox.Save)
        self.grid_layout.addWidget(self.options_buttonbox, 1, 0, 1, 1)
        # translate ui widgets' text
        self.setWindowTitle(QApplication.translate(
            "dlg_FormBearDistEntry",
            "Link Form",
            None,
            QApplication.UnicodeUTF8))
        # connect ui widgets
        self.options_buttonbox.clicked.connect(self.execute_option)
        QMetaObject.connectSlotsByName(self)
