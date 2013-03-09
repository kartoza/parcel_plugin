"""
File: settings.py
Description: stores local settings used by the qgis python plugin
Author: Robert Moerman
Contact: robert@afrispatial.co.za
Company: AfriSpatial
"""

import database_params

# Database settings
DATABASE_HOST = database_params.DATABASE_PARAMS["HOST"]
DATABASE_PORT = database_params.DATABASE_PARAMS["PORT"]
DATABASE_NAME = database_params.DATABASE_PARAMS["NAME"]
DATABASE_USER = database_params.DATABASE_PARAMS["USER"]
DATABASE_PASSWORD = database_params.DATABASE_PARAMS["PASSWORD"]
DATABASE_PARAMS = database_params.DATABASE_PARAMS
DATABASE_SCHEMA = "public"
DATABASE_LAYERS = {}

# Define database layers
DATABASE_LAYERS["BEACONS"] = {
    "SCHEMA":"public",
    "TABLE":"beacons",
    "NAME":"Beacon",
    "NAME_PLURAL":"Beacons",
    "PKEY":"gid", 
    "GEOM":"the_geom", 
    "GEOM_TYPE":"points",
    "SQL":{
        "SELECT":"SELECT beacon FROM beacons WHERE gid = %s;",
        "UNIQUE":"SELECT COUNT(*) FROM beacons WHERE %s = %s;",
        "EDIT":"SELECT {fields} FROM beacons WHERE gid = %s;",
        "DELETE":"DELETE FROM beacons WHERE gid = %s;",
        "INSERT":"INSERT INTO beacons({fields}) VALUES ({values}) RETURNING gid;",
        "UPDATE":"UPDATE beacons SET {set} WHERE {where};",
        "BEARDIST":"SELECT CASE WHEN count(*) = 0 THEN FALSE ELSE TRUE END FROM beardist WHERE beacon_to = (SELECT beacon FROM beacons WHERE gid = %s);"
        }
}
DATABASE_LAYERS["PARCELS"] = {
    "SCHEMA":"public",
    "TABLE":"parcels",
    "NAME":"Parcel",
    "NAME_PLURAL":"Parcels",
    "PKEY":"parcel_id",
    "GEOM":"the_geom",
    "GEOM_TYPE":"polygons",
    "SQL":{
        "SELECT":"SELECT parcel_id FROM parcel_lookup WHERE parcel_id = %s;",
        "EDIT":"SELECT l.parcel_id, array_agg(s.gid ORDER BY s.sequence) FROM ( SELECT b.gid, d.parcel_id, d.sequence FROM beacons b INNER JOIN parcel_def d ON d.beacon = b.beacon) s JOIN parcel_lookup l ON s.parcel_id = l.parcel_id WHERE l.parcel_id = %s GROUP BY l.parcel_id;",
        "AUTOCOMPLETE":"SELECT parcel_id FROM parcel_lookup WHERE available;",
        "UNIQUE":"SELECT COUNT(*) FROM parcel_lookup WHERE parcel_id = %s;",
        "AVAILABLE":"SELECT available FROM parcel_lookup WHERE parcel_id = %s;",
        "INSERT":"INSERT INTO parcel_def(parcel_id, beacon, sequence) VALUES (%s, %s, %s);",
        "DELETE":"DELETE FROM parcel_def WHERE parcel_id = %s;",
    }
}

# DB Triggers:
# - auto create parcel id in parcel_lookup if it does not exist on
# insert/update on parcel_def
# - auto update available field in parcel_lookup on insert/update/delete on
# parcel_def

DATABASE_LAYERS_ORDER = ["BEACONS", "PARCELS"]

# Define other sql commands
DATABASE_OTHER_SQL = {
    "AUTO_SURVEYPLAN":"SELECT array_agg(plan_no) FROM survey;",
    "AUTO_REFERENCEBEACON":"SELECT array_agg(beacon) FROM beacons WHERE beacon NOT IN (SELECT beacon_to FROM beardist WHERE beacon_to NOT IN (SELECT ref_beacon FROM survey));",
    "EXIST_REFERENCEBEACON":"SELECT ref_beacon FROM survey where plan_no = %s;",
    "EXIST_BEARDISTCHAINS":"SELECT bd.bearing, bd.distance, bd.beacon_from, bd.beacon_to, b.location, b.name FROM beardist bd INNER JOIN beacons b ON bd.beacon_to = b.beacon WHERE bd.plan_no = %s;",
    "INDEX_REFERENCEBEACON":"SELECT i.column_index::integer FROM (SELECT row_number() over(ORDER BY c.ordinal_position) -1 as column_index, c.column_name FROM information_schema.columns c WHERE c.table_name = 'beacons' AND c.column_name NOT IN ('geom', 'gid') ORDER BY c.ordinal_position) as i WHERE i.column_name = 'beacon';",
    "IS_SURVEYPLAN":"SELECT CASE WHEN COUNT(*) <> 0 THEN TRUE ELSE FALSE END FROM survey WHERE plan_no = %s;",
    "INSERT_SURVEYPLAN":"INSERT INTO survey(plan_no, ref_beacon) VALUES(%s, %s);",
    "UPDATE_LINK":"SELECT beardistupdate(%s, %s, %s, %s, %s, %s, %s, %s);",
    "DELETE_LINK":"DELETE FROM beacons WHERE beacon = %s;",
    "INSERT_LINK":"SELECT beardistinsert(%s, %s, %s, %s, %s, %s, %s);"
}
