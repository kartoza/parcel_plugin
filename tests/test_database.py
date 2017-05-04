# coding=utf-8
"""Test database."""

import unittest
import psycopg2
from database import Manager


class TestDatabase(unittest.TestCase):

    def test_connection(self):
        """Test connection using database manager class."""
        parameters = {
            'HOST': 'localhost',
            'NAME': 'sml',
            'USER': 'postgres',
            'PASSWORD': 'postgres',
            'PORT': '5432'
        }

        expected_connection = psycopg2.connect(
            "host='{HOST}' dbname='{NAME}' user='{USER}' "
            "password='{PASSWORD}' port='{PORT}'".format(
                HOST=parameters["HOST"],
                NAME=parameters["NAME"],
                USER=parameters["USER"],
                PASSWORD=parameters["PASSWORD"],
                PORT=parameters["PORT"]))

        # connect to postgresql instance

        connection_manager = Manager(parameters)
        connection_manager.connect(parameters)

        actual_connection = connection_manager.connection

        self.assertIsNotNone(actual_connection)

        self.assertEqual(expected_connection.dsn, actual_connection.dsn)
