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

    def query(self, query):
        """ Execute query using given data against connection object
        @returns resultset (array structure)
        """
        try:
            self.connect()
            self.cursor.execute(query)
            records = None
            try:
                records = self.cursor.fetchall()
            except: 
                pass
            self.conn.commit()
            self.disconnect()
            return records
        except Exception as e:
            raise Exception('Backend database query failed!\nTried to execute: "%s".\nError raised: %s.' %(query, str(e)))

