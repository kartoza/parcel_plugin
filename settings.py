"""
File: settings.py
Description: stores local settings used by the qgis python plugin
Author: Robert Moerman
Contact: robert@afrispatial.co.za
Company: AfriSpatial
"""

# Database settings
DATABASE_HOST = "localhost"
DATABASE_PORT = "5432"
DATABASE_NAME = "sml"
DATABASE_USER = "robert"
DATABASE_PASSWORD = "1CanHaz"
DATABASE_SCHEMA = "public"
DATABASE_LAYERS = {}

# Define database layers
# DATABASE_LAYERS[<Layer Type>] = {
#     "schema":<Schema Name>,
#     "table":<Table Name>,
#     "name":<Layer Singular Name>,
#     "name_plural":<Layer Plural Name>,
#     "pkey":<Primary Key>,
#     "the_geom":<Geometry Field Name>,
#     "the_geom_type":<Geometry Field Type>,
#     "sql": {
#         "select":<{id}>
#         "delete":<{object_id}>
#         "insert":<>
#         "unique":<{object_id}>
#     }
# }
DATABASE_LAYERS["points"] = {
    "schema":"public",
    "table":"beacons",
    "name":"Beacon",
    "name_plural":"Beacons",
    "pkey":"gid", 
    "the_geom":"geom", 
    "the_geom_type":"points",
    "sql":{
        "select":"SELECT beacon FROM beacons WHERE gid = {id}",
        "delete":"DELETE FROM beacons WHERE beacon = '{object_id}';",
        "insert":"INSERT INTO beacons({fields}) VALUES ({values}) RETURNING gid;",
        "unique":"SELECT COUNT(*) FROM beacons WHERE {field} = {value};",
        "edit":"SELECT {fields} FROM beacons WHERE beacon = '{object_id}';"
    }
}
DATABASE_LAYERS["polygons"] = {
    "schema":"public",
    "table":"parcels",
    "name":"Parcel",
    "name_plural":"Parcels",
    "pkey":"id",
    "the_geom":"the_geom",
    "the_geom_type":"polygons",
    "sql":{
        "select":"SELECT parcel_id FROM parcels WHERE id = {id};",
        "delete":"DELETE FROM parcel_def WHERE parcel_id = '{object_id}';",
        "insert":"INSERT INTO parcel_def(parcel_id, beacon, sequence) VALUES ('{polygon_id}', '{point_id}', {sequence});",
        "unique":"SELECT COUNT(*) FROM parcel_lookup WHERE parcel_id = '{object_id}';",
        "edit":"SELECT b.gid FROM beacons b INNER JOIN parcel_def p ON b.beacon = p.beacon WHERE p.parcel_id = '{object_id}';",
        "available":"SELECT available FROM parcel_lookup WHERE parcel_id = '{object_id}'",
        "autocomplete":"SELECT parcel_id FROM parcel_lookup WHERE available;"
    }
}
# DB Triggers:
# - auto create parcel id in parcel_lookup if it does not exist on
# insert/update on parcel_def
# - auto update available field in parcel_lookup on insert/update/delete on
# parcel_def

DATABASE_LAYERS_ORDER = ["points", "polygons"]
