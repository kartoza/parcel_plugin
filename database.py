# -*- coding: utf-8 -*-
"""
Author: Robert Moerman
Contact: robert@afrispatial.co.za
Company: AfriSpatial
"""
# Python imports
import psycopg2
# Plugin imports
from settings import *

class dbmanager():
    """ Class that enables the querying of a database using parameters defined in settings.py
    """

    def __init__(self):
        # test db settings
        self.connect()
        self.disconnect()

    def connect(self):
        """ Create a backend postgres database connection
        """
        try:
            # check if connection object exist  
            if not hasattr(self, 'conn') or self.conn is None:
                self.conn = psycopg2.connect("host='%s' dbname='%s' user='%s' password='%s' port='%s'" %(DATABASE_HOST, DATABASE_NAME, DATABASE_USER, DATABASE_PASSWORD, DATABASE_PORT))
            # check if cursor objet exists
            if not hasattr(self, 'cursor') or self.cursor is None:
                self.cursor = self.conn.cursor()
        except Exception as e:
            raise Exception('Could not connect to database!\nError raised: {error}.'.format(error = str(e)))
    
    def disconnect(self):
        """ Terminate a backend postgres database connection
        """
        try:
            # check if a cursor object exists 
            if hasattr(self, 'cursor') and self.cursor is not None: 
                self.cursor.close()
                self.cursor = None
            # check if a connection object exists
            if hasattr(self, 'conn') and self.conn is not None: 
                self.conn.close()
                self.conn = None
        except Exception as e:
            raise Exception('Could not disconnect from database!\nError raised: {error}.'.format(error = str(e)))

    def query(self, query, data=None):
        """ Execute query using given data against connection object
        @returns resultset (array structure)
        """
        try:
            self.connect()
            if data is None: self.cursor.execute(query)
            else: self.cursor.execute(query, data)
            records = None
            try:
                records = self.cursor.fetchall()
            except: 
                pass
            self.conn.commit()
            self.disconnect()
            return records
        except Exception as e:
            raise Exception('Backend database query failed!\nError raised: %s.' %(str(e),))
    
    def getSchema(self, tbl_name, fld_ignore):
        """ Get information abot a specific table 
        @returns [<Field Name>, <Field Type>, <Nullable>] (list)
        """
        info = [{"name":data[0], "type":self._pythonize_type(data[1]), "required":data[2], "unique":data[3]} for data in reversed(self.query("SELECT c.column_name, c.data_type, CASE WHEN c.is_nullable = 'NO' THEN TRUE ELSE FALSE END AS required, CASE WHEN u.column_name IS NOT NULL THEN TRUE ELSE FALSE END AS unique FROM information_schema.columns c LEFT JOIN (SELECT kcu.column_name, tc.table_name FROM information_schema.table_constraints tc LEFT JOIN information_schema.key_column_usage kcu ON tc.constraint_catalog = kcu.constraint_catalog AND tc.constraint_schema = kcu.constraint_schema AND tc.constraint_name = kcu.constraint_name WHERE tc.constraint_type IN ('UNIQUE', 'PRIMARY KEY') AND tc.table_name = '{table}') u ON u.column_name = c.column_name WHERE c.table_name = '{table}' AND c.column_name NOT IN ({ignore});".format(table = tbl_name, ignore = ", ".join("'%s'" %(i,) for i in fld_ignore))))] 
        return info

    def _pythonize_type(self, db_type):
        """ Get python type
        @returns type (type)
        """
        if "char" in db_type.lower(): return str
        elif "double" in db_type.lower(): return float
        elif "integer" in db_type.lower(): return int
        else: return object

