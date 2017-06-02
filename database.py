# -*- coding: utf-8 -*-
"""
Author: Robert Moerman
Contact: robert@afrispatial.co.za
Company: AfriSpatial

This is a postgresql database manager.

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
"""
import psycopg2


class Field:

    def __init__(self, name, type, required, unique):
        self.name = name
        self.type = type
        self.required = required
        self.unique = unique


class Manager:

    def __init__(self, parameters):
        # test db settings
        self.parameters = parameters
        self.connect(parameters)
        self.disconnect()

    def connect(self, parameters):
        """ Create a backend postgres database connection
        """
        try:
            # check if connection object exist
            if not hasattr(self, 'conn') or self.connection is None:
                self.connection = psycopg2.connect(
                    "host='{HOST}' dbname='{NAME}' user='{USER}' "
                    "password='{PASSWORD}' port='{PORT}'".format(
                        HOST=parameters["HOST"],
                        NAME=parameters["NAME"],
                        USER=parameters["USER"],
                        PASSWORD=parameters["PASSWORD"],
                        PORT=parameters["PORT"]))
            # check if cursor objet exists
            if not hasattr(self, 'cursor') or self.cursor is None:
                self.cursor = self.connection.cursor()
        except Exception as e:
            raise Exception(
                'Could not connect to database!\n'
                'Error raised: {error}.'.format(error=str(e)))

    def disconnect(self):
        """ Terminate a backend postgres database connection
        """
        try:
            # check if a cursor object exists
            if hasattr(self, 'cursor') and self.cursor is not None:
                self.cursor.close()
                self.cursor = None
            # check if a connection object exists
            if hasattr(self, 'conn') and self.connection is not None:
                self.connection.close()
                self.connection = None
        except Exception as e:
            raise Exception(
                'Could not disconnect from database!\n'
                'Error raised: {error}.'.format(error=str(e)))

    def query(self, query, data=None):
        """ Execute query using given data against connection object
        @returns resultset (array structure)
        """
        try:
            self.connect(self.parameters)
            if data is None:
                self.cursor.execute(query)
            else:
                self.cursor.execute(query, data)
            records = None
            try:
                records = self.cursor.fetchall()
            except:
                pass
            self.connection.commit()
            self.disconnect()
            return records
        except Exception as e:
            raise Exception(
                'Backend database query failed!\n'
                'Error raised: %s.' % (str(e),))

    def preview_query(self, query, data=None, multi_data=False):
        """ Preview query
        @returns query (str)
        """
        try:
            self.connect(self.parameters)
            sql = ""
            if data is None:
                sql = self.cursor.mogrify(query)
            else:
                if multi_data:
                    placeholders = ','.join(['%s' for dummy in data])
                    query = query % (placeholders)
                    sql = self.cursor.mogrify(query, data)
                else:
                    sql = self.cursor.mogrify(query, data)
            self.disconnect()
            return sql
        except Exception as e:
            raise Exception(
                'Backend database mogrification failed!\n'
                'Error raised: %s.' % (str(e),))

    def get_schema(self, table_name, field_ignore):
        """ Get information abot a specific table
        @returns [<Field Name>, <Field Type>, <Nullable>] (list)
        """
        return [
            Field(
                data[0], self._pythonize_type(data[1]), data[2], data[3])
            for data in reversed(
                self.query(
                    "SELECT c.column_name, c.data_type, "
                    "CASE WHEN c.is_nullable = 'NO' "
                    "THEN TRUE ELSE FALSE END AS required, "
                    "CASE WHEN u.column_name IS NOT NULL "
                    "THEN TRUE ELSE FALSE END AS unique "
                    "FROM information_schema.columns c LEFT JOIN "
                    "(SELECT kcu.column_name, tc.table_name "
                    "FROM information_schema.table_constraints tc "
                    "LEFT JOIN information_schema.key_column_usage kcu "
                    "ON tc.constraint_catalog = kcu.constraint_catalog "
                    "AND tc.constraint_schema = kcu.constraint_schema "
                    "AND tc.constraint_name = kcu.constraint_name "
                    "WHERE tc.constraint_type IN ('UNIQUE', 'PRIMARY KEY') "
                    "AND tc.table_name = '{table}') u "
                    "ON u.column_name = c.column_name "
                    "WHERE c.table_name = '{table}' "
                    "AND c.column_name NOT IN ({ignore});"
                    .format(
                        table=table_name,
                        ignore=", ".join(
                            "'%s'" % (i,) for i in field_ignore))))]

    def _pythonize_type(self, database_type):
        """ Get python type
        @returns type (type)
        """
        if "char" in database_type.lower():
            return str
        elif "double" in database_type.lower():
            return float
        elif "integer" in database_type.lower():
            return int
        else:
            return object
