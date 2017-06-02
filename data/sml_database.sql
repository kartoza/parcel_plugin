--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA IF NOT EXISTS topology;


ALTER SCHEMA topology OWNER TO postgres;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


SET search_path = public, pg_catalog;

--
-- Name: beacons_views_mat_view(); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION beacons_views_mat_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY beacons_views;
  RETURN NULL;
END $$;


ALTER FUNCTION public.beacons_views_mat_view() OWNER TO docker;

--
-- Name: beardistinsert(character varying, double precision, double precision, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION beardistinsert(arg_plan_no character varying, arg_bearing double precision, arg_distance double precision, arg_beacon_from character varying, arg_beacon_to character varying, arg_location character varying, arg_name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
    the_x    double precision;
    the_y    double precision;
    the_geom geometry(Point,26331);
  BEGIN
    SELECT x INTO the_x FROM beacons WHERE beacon = arg_beacon_from;
    SELECT y INTO the_y FROM beacons WHERE beacon = arg_beacon_from;
    the_geom := pointfrombearinganddistance(the_x, the_y, arg_bearing, arg_distance, 3, 26331);
    INSERT INTO beacons(beacon, y, x, "location", "name")
    VALUES(arg_beacon_to, st_y(the_geom), st_x(the_geom), arg_location, arg_name);
    INSERT INTO beardist(plan_no, bearing, distance, beacon_from, beacon_to)
    VALUES(arg_plan_no, arg_bearing, arg_distance, arg_beacon_from, arg_beacon_to);
  END
$$;


ALTER FUNCTION public.beardistinsert(arg_plan_no character varying, arg_bearing double precision, arg_distance double precision, arg_beacon_from character varying, arg_beacon_to character varying, arg_location character varying, arg_name character varying) OWNER TO docker;

--
-- Name: beardistupdate(character varying, double precision, double precision, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION beardistupdate(arg_plan_no character varying, arg_bearing double precision, arg_distance double precision, arg_beacon_from character varying, arg_beacon_to character varying, arg_location character varying, arg_name character varying, arg_index integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
    the_id_beardist integer;
    the_id_beacons  integer;
    the_x           double precision;
    the_y           double precision;
    the_geom_       geometry(Point, 26331);
  BEGIN
    SELECT i.id INTO the_id_beardist FROM (
      SELECT bd.id, row_number() over(ORDER BY bd.id) -1 as index
      FROM beardist bd
      INNER JOIN beacons b ON bd.beacon_to = b.beacon
      WHERE bd.plan_no = arg_plan_no
    ) AS i
    WHERE i.index = arg_index;
    SELECT gid INTO the_id_beacons FROM beacons b INNER JOIN beardist bd ON b.beacon = bd.beacon_to WHERE bd.id = the_id_beardist;
    SELECT x INTO the_x FROM beacons WHERE beacon = arg_beacon_from;
    SELECT y INTO the_y FROM beacons WHERE beacon = arg_beacon_from;
    SELECT pointfrombearinganddistance(the_x, the_y, arg_bearing, arg_distance, 3, 26331) INTO the_geom_;
    UPDATE beacons SET
      beacon = arg_beacon_to,
      y = st_y(the_geom_),
      x = st_x(the_geom_),
      "location" = arg_location,
      "name" = arg_name
    WHERE gid = the_id_beacons;
    UPDATE beardist SET
      plan_no = arg_plan_no,
      bearing = arg_bearing,
      distance = arg_distance,
      beacon_from = arg_beacon_from,
      beacon_to = arg_beacon_to
    WHERE id = the_id_beardist;
  END
$$;


ALTER FUNCTION public.beardistupdate(arg_plan_no character varying, arg_bearing double precision, arg_distance double precision, arg_beacon_from character varying, arg_beacon_to character varying, arg_location character varying, arg_name character varying, arg_index integer) OWNER TO docker;

--
-- Name: calc_point(); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION calc_point() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    NEW.the_geom:=ST_SetSRID(ST_MakePoint(new.x, new.y), 26331) ;
  RETURN NEW;
  END
  $$;


ALTER FUNCTION public.calc_point() OWNER TO docker;

--
-- Name: fn_beacons_after_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_beacons_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO hist_beacons (
		gid,
		beacon,
		y,
		x,
		the_geom,
		location,
		name,
		hist_user,
		hist_action,
		hist_time
	) VALUES (
		NEW."gid",
		NEW."beacon",
		NEW."y",
		NEW."x",
		NEW."the_geom",
		NEW."location",
		NEW."name",
  		NEW."last_modified_by",
		'INSERT',
		NOW()
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_beacons_after_insert() OWNER TO postgres;

--
-- Name: fn_beacons_before_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_beacons_before_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO hist_beacons (
		gid,
		beacon,
		y,
		x,
		the_geom,
		location,
		name,
		hist_user,
		hist_action,
		hist_time
	) VALUES (
		OLD."gid",
		OLD."beacon",
		OLD."y",
		OLD."x",
		OLD."the_geom",
		OLD."location",
		OLD."name",
  		OLD."last_modified_by",
		'DELETE',
		NOW()
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_beacons_before_delete() OWNER TO postgres;

--
-- Name: fn_beacons_before_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fn_beacons_before_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO hist_beacons (
		gid,
		beacon,
		y,
		x,
		the_geom,
		location,
		name,
		hist_user,
		hist_action,
		hist_time
	) VALUES (
		OLD."gid",
		OLD."beacon",
		OLD."y",
		OLD."x",
		OLD."the_geom",
		OLD."location",
		OLD."name",
  		NEW."last_modified_by",
		'EDIT',
		NOW()
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_beacons_before_update() OWNER TO postgres;

--
-- Name: fn_updateprintjobs(); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION fn_updateprintjobs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.created IS NOT NULL THEN
    	NEW.created = NEW.created + interval '2 hours';
    END IF;
	IF NEW.done IS NOT NULL THEN
    	NEW.done = NEW.done + interval '2 hours';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_updateprintjobs() OWNER TO docker;

--
-- Name: parcel_lookup_availability_trigger(); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION parcel_lookup_availability_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    UPDATE parcel_lookup SET available = TRUE;
    UPDATE parcel_lookup SET available = FALSE WHERE parcel_id IN (SELECT parcel_id FROM parcel_def GROUP BY parcel_id);
    RETURN NEW;
  END
$$;


ALTER FUNCTION public.parcel_lookup_availability_trigger() OWNER TO docker;

--
-- Name: parcel_lookup_define_parcel_trigger(); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION parcel_lookup_define_parcel_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    IF (SELECT COUNT(*)::integer FROM parcel_lookup  WHERE parcel_id = NEW.parcel_id) = 0 THEN
      INSERT INTO parcel_lookup (parcel_id) VALUES (NEW.parcel_id);
    END IF;
    RETURN NEW;
  END
$$;


ALTER FUNCTION public.parcel_lookup_define_parcel_trigger() OWNER TO docker;

--
-- Name: parcel_overlap_mat_view(); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION parcel_overlap_mat_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY parcel_overlap_matviews;
  RETURN NULL;
END $$;


ALTER FUNCTION public.parcel_overlap_mat_view() OWNER TO docker;

--
-- Name: parcels_matview_refresh_row(integer); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION parcels_matview_refresh_row(integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
BEGIN
  DELETE FROM parcels_matview WHERE parcel_id = $1;
  INSERT INTO parcels_matview SELECT * FROM parcels WHERE parcel_id = $1;
  RETURN;
END
$_$;


ALTER FUNCTION public.parcels_matview_refresh_row(integer) OWNER TO docker;

--
-- Name: pointfrombearinganddistance(double precision, double precision, double precision, double precision, integer, integer); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION pointfrombearinganddistance(dstarte double precision, dstartn double precision, dbearing double precision, ddistance double precision, "precision" integer, srid integer) RETURNS geometry
    LANGUAGE plpgsql
    AS $$
  DECLARE
      dangle1    double precision;
      dangle1rad double precision;
      ddeltan    double precision;
      ddeltae    double precision;
      dende      double precision;
      dendn      double precision;
      "precision" int;
      srid int;
BEGIN
    precision := CASE WHEN precision IS NULL THEN 3 ELSE precision END;
    srid := CASE WHEN srid IS NULL THEN 4326 ELSE srid END;
  BEGIN
    IF
      dstarte   IS NULL OR
      dstartn   IS NULL OR
      dbearing  IS NULL OR
      ddistance IS NULL
    THEN RETURN NULL;
    END IF;
    IF dbearing < 90
    THEN
      dangle1    := 90 - dbearing;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance;
      ddeltan    := Sin(dangle1rad) * ddistance;
    END if;
    IF dbearing < 180
    THEN
      dangle1    := dbearing - 90;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance;
      ddeltan    := Sin(dangle1rad) * ddistance * -1;
    END if;
    IF dbearing < 270
    THEN
      dangle1    := 270 - dbearing;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance * -1;
      ddeltan    := Sin(dangle1rad) * ddistance * -1;
    END if;
    IF dbearing <= 360
    THEN
      dangle1    := dbearing - 270;
      dangle1rad := dangle1 * PI() / 180;
      ddeltae    := Cos(dangle1rad) * ddistance * -1;
      ddeltan    := Sin(dangle1rad) * ddistance;
    END IF;
    dende := ddeltae + dstarte;
    dendn := ddeltan + dstartn;
    RETURN ST_SetSRID(ST_MakePoint(round(dende::numeric, precision), round(dendn::numeric, precision)), 26331);
  END;
END;
$$;


ALTER FUNCTION public.pointfrombearinganddistance(dstarte double precision, dstartn double precision, dbearing double precision, ddistance double precision, "precision" integer, srid integer) OWNER TO docker;

--
-- Name: pois_view_mat_view(); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION pois_view_mat_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY pois_view;
  RETURN NULL;
END $$;


ALTER FUNCTION public.pois_view_mat_view() OWNER TO docker;

--
-- Name: refresh_beacons_intersect_view(); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION refresh_beacons_intersect_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY beacons_intersect;
  RETURN NULL;
END $$;


ALTER FUNCTION public.refresh_beacons_intersect_view() OWNER TO docker;

--
-- Name: refresh_mat_view(); Type: FUNCTION; Schema: public; Owner: docker
--

CREATE FUNCTION refresh_mat_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY parcels_intersect;
  RETURN NULL;
END $$;


ALTER FUNCTION public.refresh_mat_view() OWNER TO docker;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: Industrial_Minerals; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE "Industrial_Minerals" (
    gid integer NOT NULL,
    "Id" integer,
    "Type" character varying(80),
    "TypeId" integer,
    the_geom geometry(Point,26331)
);


ALTER TABLE "Industrial_Minerals" OWNER TO docker;

--
-- Name: Industrial_Minerals_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE "Industrial_Minerals_gid_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Industrial_Minerals_gid_seq" OWNER TO docker;

--
-- Name: Industrial_Minerals_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE "Industrial_Minerals_gid_seq" OWNED BY "Industrial_Minerals".gid;


--
-- Name: lut_poi_cat; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE lut_poi_cat (
    sc_name character varying(255),
    sc_code numeric(10,0),
    tc_name character varying(255),
    tc_code numeric(10,0),
    icon character varying(255),
    id integer NOT NULL
);


ALTER TABLE lut_poi_cat OWNER TO docker;

--
-- Name: Ogun_state_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE "Ogun_state_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Ogun_state_id_seq" OWNER TO docker;

--
-- Name: Ogun_state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE "Ogun_state_id_seq" OWNED BY lut_poi_cat.id;


--
-- Name: ogunadmin; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogunadmin (
    gid integer NOT NULL,
    iso_code character varying(3),
    country character varying(75),
    state character varying(75),
    lg_name character varying(75),
    hasc character varying(15),
    type character varying(50),
    remarks character varying(100),
    "Shape_Leng" double precision,
    "Shape_Area" double precision,
    the_geom geometry(Polygon,26331),
    sen_district integer,
    lg_hq integer
);


ALTER TABLE ogunadmin OWNER TO docker;

--
-- Name: Ogunadmin_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE "Ogunadmin_gid_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Ogunadmin_gid_seq" OWNER TO docker;

--
-- Name: Ogunadmin_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE "Ogunadmin_gid_seq" OWNED BY ogunadmin.gid;


--
-- Name: SenatorialDistrict; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE "SenatorialDistrict" (
    gid integer NOT NULL,
    "ISO" character varying(3),
    "NAME_0" character varying(75),
    "NAME_1" character varying(75),
    "NAME_2" character varying(75),
    "District" character varying(80),
    "Sen_Dist" integer,
    "TYPE_2" character varying(50),
    "Shape_Leng" double precision,
    "Shape_Area" double precision,
    the_geom geometry(Polygon,26331)
);


ALTER TABLE "SenatorialDistrict" OWNER TO docker;

--
-- Name: SenatorialDistrict_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE "SenatorialDistrict_gid_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "SenatorialDistrict_gid_seq" OWNER TO docker;

--
-- Name: SenatorialDistrict_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE "SenatorialDistrict_gid_seq" OWNED BY "SenatorialDistrict".gid;


--
-- Name: allocation_cat; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE allocation_cat (
    description character varying(50) NOT NULL,
    allocation_cat integer NOT NULL
);


ALTER TABLE allocation_cat OWNER TO docker;

--
-- Name: allocation_cat_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE allocation_cat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE allocation_cat_id_seq OWNER TO docker;

--
-- Name: allocation_cat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE allocation_cat_id_seq OWNED BY allocation_cat.allocation_cat;


--
-- Name: applicants; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE applicants (
    name character varying NOT NULL,
    id integer NOT NULL,
    email character varying(50),
    mobile character varying(15)
);


ALTER TABLE applicants OWNER TO docker;

--
-- Name: applicants_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE applicants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE applicants_id_seq OWNER TO docker;

--
-- Name: applicants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE applicants_id_seq OWNED BY applicants.id;


--
-- Name: arakanga_reserve; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE arakanga_reserve (
    gid integer NOT NULL,
    wdpaid numeric(10,0),
    objectid numeric(10,0),
    wdpa_pid numeric(10,0),
    country character varying(80),
    sub_loc character varying(80),
    name character varying(254),
    orig_name character varying(254),
    desig character varying(254),
    desig_eng character varying(254),
    desig_type character varying(254),
    iucn_cat character varying(254),
    marine smallint,
    rep_m_area numeric,
    rep_area numeric,
    status character varying(254),
    status_yr numeric(10,0),
    gov_type character varying(254),
    mang_auth character varying(254),
    int_crit character varying(80),
    mang_plan character varying(80),
    official smallint,
    is_point smallint,
    no_take character varying(254),
    no_tk_area numeric,
    metadata_i numeric(10,0),
    action character varying(80),
    geom geometry(MultiPolygon,26331)
);


ALTER TABLE arakanga_reserve OWNER TO docker;

--
-- Name: arakanga_reserve_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE arakanga_reserve_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE arakanga_reserve_gid_seq OWNER TO docker;

--
-- Name: arakanga_reserve_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE arakanga_reserve_gid_seq OWNED BY arakanga_reserve.gid;


--
-- Name: beacons; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE beacons (
    gid integer NOT NULL,
    beacon character varying(80) NOT NULL,
    y double precision NOT NULL,
    x double precision NOT NULL,
    the_geom geometry(Point,26331) NOT NULL,
    location character varying(180),
    name character varying(100),
    last_modified_by character varying
);


ALTER TABLE beacons OWNER TO docker;

--
-- Name: beacons_extra; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE beacons_extra (
    gid integer,
    beacon character varying(80),
    planno character varying(180),
    blockno character varying(180)
);


ALTER TABLE beacons_extra OWNER TO docker;

--
-- Name: beacons_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE beacons_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE beacons_gid_seq OWNER TO docker;

--
-- Name: beacons_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE beacons_gid_seq OWNED BY beacons.gid;


--
-- Name: parcel_def; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE parcel_def (
    id integer NOT NULL,
    beacon character varying(20) NOT NULL,
    sequence integer NOT NULL,
    parcel_id integer
);


ALTER TABLE parcel_def OWNER TO docker;

--
-- Name: parcel_lookup; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE parcel_lookup (
    plot_sn character varying,
    available boolean DEFAULT true NOT NULL,
    scheme integer,
    block character varying,
    local_govt integer,
    prop_type integer,
    file_number character varying,
    allocation integer,
    manual_no character varying,
    deeds_file character varying,
    parcel_id integer NOT NULL,
    official_area double precision,
    private boolean DEFAULT false,
    status integer
);


ALTER TABLE parcel_lookup OWNER TO docker;

--
-- Name: COLUMN parcel_lookup.plot_sn; Type: COMMENT; Schema: public; Owner: docker
--

COMMENT ON COLUMN parcel_lookup.plot_sn IS 'plot serial no within a block. Forms part of the parcel no';


--
-- Name: beacons_views; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW beacons_views AS
 SELECT DISTINCT ON (b.gid) b.gid,
    b.beacon,
    b.y,
    b.x,
    b.the_geom,
    b.location,
    b.name,
    pl.private,
    pl.parcel_id
   FROM ((beacons b
     JOIN parcel_def pd USING (beacon))
     JOIN parcel_lookup pl USING (parcel_id))
  WITH NO DATA;


ALTER TABLE beacons_views OWNER TO docker;

--
-- Name: deeds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE deeds (
    fileno character varying(40),
    planno character varying(40),
    instrument text,
    grantor text,
    grantee text,
    block character varying(80),
    plot character varying(80),
    location text,
    deed_sn integer NOT NULL
);


ALTER TABLE deeds OWNER TO postgres;

--
-- Name: schemes; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE schemes (
    id integer NOT NULL,
    scheme_name character varying(50) NOT NULL,
    "Scheme" smallint
);


ALTER TABLE schemes OWNER TO docker;

--
-- Name: COLUMN schemes."Scheme"; Type: COMMENT; Schema: public; Owner: docker
--

COMMENT ON COLUMN schemes."Scheme" IS 'line';


--
-- Name: parcels; Type: VIEW; Schema: public; Owner: docker
--

CREATE VIEW parcels AS
 SELECT parcel.parcel_id,
    parcel.the_geom,
    (round((st_area(parcel.the_geom))::numeric, 3))::double precision AS comp_area,
    description.official_area,
    description.parcel_number,
    description.block,
    description.serial_no,
    description.scheme,
    description.file_number,
    description.allocation,
    description.owner,
    (((('<a href="http://192.168.10.12/geoserver/'::text || (description.deeds_file)::text) || '" target="blank_">'::text) || (description.deeds_file)::text) || '</a>'::text) AS deeds_file,
    description.private
   FROM (( SELECT vl.parcel_id,
            (st_makepolygon(st_addpoint(st_makeline(vl.the_geom), st_startpoint(st_makeline(vl.the_geom)))))::geometry(Polygon,26331) AS the_geom
           FROM ( SELECT pd.id,
                    pd.parcel_id,
                    pd.beacon,
                    pd.sequence,
                    b.the_geom
                   FROM (beacons b
                     JOIN parcel_def pd ON (((b.beacon)::text = (pd.beacon)::text)))
                  ORDER BY pd.parcel_id, pd.sequence) vl
          GROUP BY vl.parcel_id
         HAVING (st_npoints(st_collect(vl.the_geom)) > 1)) parcel
     JOIN ( SELECT p.parcel_id,
            ((p.local_govt || (p.prop_type)::text) || p.parcel_id) AS parcel_number,
            p.allocation,
            p.block,
            p.plot_sn AS serial_no,
            p.official_area,
            s.scheme_name AS scheme,
            p.file_number,
            d.grantee AS owner,
            p.deeds_file,
            p.private
           FROM ((parcel_lookup p
             LEFT JOIN deeds d ON (((p.file_number)::text = (d.fileno)::text)))
             LEFT JOIN schemes s ON ((p.scheme = s.id)))
          WHERE ((p.block)::text <> ALL (ARRAY[('perimeter'::character varying)::text, ('acquisition'::character varying)::text, ('agriculture'::character varying)::text, ('education'::character varying)::text]))) description USING (parcel_id))
  WHERE st_isvalid(parcel.the_geom);


ALTER TABLE parcels OWNER TO docker;

--
-- Name: beacons_intersect; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW beacons_intersect AS
 SELECT a.beacon,
    a.the_geom,
    a.x,
    a.y,
    b.parcel_id,
    a.private
   FROM (beacons_views a
     LEFT JOIN parcels b ON ((a.parcel_id = b.parcel_id)))
  WITH NO DATA;


ALTER TABLE beacons_intersect OWNER TO docker;

--
-- Name: beardist; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE beardist (
    id integer NOT NULL,
    plan_no character varying(20) NOT NULL,
    bearing double precision NOT NULL,
    distance double precision NOT NULL,
    beacon_from character varying(20) NOT NULL,
    beacon_to character varying(20) NOT NULL
);


ALTER TABLE beardist OWNER TO docker;

--
-- Name: beardist_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE beardist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE beardist_id_seq OWNER TO docker;

--
-- Name: beardist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE beardist_id_seq OWNED BY beardist.id;


--
-- Name: bearing_labels; Type: VIEW; Schema: public; Owner: docker
--

CREATE VIEW bearing_labels AS
 SELECT b.id,
    b.geom,
    c.plan_no,
    c.bearing,
    c.distance
   FROM (( SELECT a.id,
            st_makeline(a.the_geom) AS geom
           FROM ( SELECT bd.id,
                    bd.beacon,
                    bd.orderby,
                    b_1.the_geom
                   FROM (( SELECT beardist.id,
                            beardist.beacon_from AS beacon,
                            1 AS orderby
                           FROM beardist
                        UNION
                         SELECT beardist.id,
                            beardist.beacon_to AS beacon,
                            2 AS orderby
                           FROM beardist) bd
                     JOIN beacons b_1 USING (beacon))
                  ORDER BY bd.orderby) a
          GROUP BY a.id) b
     JOIN beardist c USING (id));


ALTER TABLE bearing_labels OWNER TO docker;

--
-- Name: billboards; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE billboards (
    gid integer NOT NULL,
    sn numeric(10,0),
    company_na character varying(80),
    no character varying(80),
    lat numeric,
    lon numeric,
    height numeric,
    the_geom geometry(Point,26331),
    duevalid integer
);


ALTER TABLE billboards OWNER TO docker;

--
-- Name: billboards_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE billboards_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE billboards_gid_seq OWNER TO docker;

--
-- Name: billboards_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE billboards_gid_seq OWNED BY billboards.gid;


--
-- Name: conflict_cat; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE conflict_cat (
    conflict_cat integer NOT NULL,
    description character varying NOT NULL
);


ALTER TABLE conflict_cat OWNER TO docker;

--
-- Name: conflict_cat_conflict_cat_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE conflict_cat_conflict_cat_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE conflict_cat_conflict_cat_seq OWNER TO docker;

--
-- Name: conflict_cat_conflict_cat_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE conflict_cat_conflict_cat_seq OWNED BY conflict_cat.conflict_cat;


--
-- Name: conflicts; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE conflicts (
    id integer NOT NULL,
    conflict integer NOT NULL,
    transaction character varying(10) NOT NULL
);


ALTER TABLE conflicts OWNER TO docker;

--
-- Name: conflicts_conflict_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE conflicts_conflict_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE conflicts_conflict_seq OWNER TO docker;

--
-- Name: conflicts_conflict_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE conflicts_conflict_seq OWNED BY conflicts.conflict;


--
-- Name: conflicts_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE conflicts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE conflicts_id_seq OWNER TO docker;

--
-- Name: conflicts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE conflicts_id_seq OWNED BY conflicts.id;


--
-- Name: controls; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE controls (
    gid integer NOT NULL,
    pillars character varying(80),
    y double precision,
    x double precision,
    height double precision,
    "order" integer,
    the_geom geometry(Point,26331)
);


ALTER TABLE controls OWNER TO docker;

--
-- Name: controls_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE controls_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE controls_gid_seq OWNER TO docker;

--
-- Name: controls_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE controls_gid_seq OWNED BY controls.gid;


--
-- Name: deeds_deed_sn_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE deeds_deed_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE deeds_deed_sn_seq OWNER TO postgres;

--
-- Name: deeds_deed_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE deeds_deed_sn_seq OWNED BY deeds.deed_sn;


--
-- Name: developed_area; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE developed_area (
    gid integer NOT NULL,
    id numeric(10,0),
    settlement character varying(80),
    the_geom geometry(MultiPolygon,26331)
);


ALTER TABLE developed_area OWNER TO docker;

--
-- Name: education; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE education (
    gid integer NOT NULL,
    bsn numeric(10,0),
    pc character varying(80),
    pc_code numeric(10,0),
    sc character varying(80),
    sc_code numeric(10,0),
    entity_typ character varying(80),
    tc_code character varying(80),
    name character varying(80),
    schl_regno character varying(80),
    str_name character varying(80),
    rd_type character varying(80),
    area character varying(80),
    location character varying(80),
    lga character varying(80),
    latitude character varying(80),
    longitude numeric,
    altitude numeric,
    the_geom geometry(Point,26331)
);


ALTER TABLE education OWNER TO docker;

--
-- Name: education_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE education_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE education_gid_seq OWNER TO docker;

--
-- Name: education_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE education_gid_seq OWNED BY education.gid;


--
-- Name: fac_numbers; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE fac_numbers (
    da_id integer NOT NULL,
    sn integer
);


ALTER TABLE fac_numbers OWNER TO docker;

--
-- Name: fac_numbers_da_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE fac_numbers_da_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE fac_numbers_da_id_seq OWNER TO docker;

--
-- Name: fac_numbers_da_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE fac_numbers_da_id_seq OWNED BY fac_numbers.da_id;


--
-- Name: geologyogun; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE geologyogun (
    gid integer NOT NULL,
    td integer,
    type character varying(10),
    name character varying(80),
    id_1 integer,
    names character varying(50),
    id_2 integer,
    id_1_1 integer,
    the_geom geometry(MultiPolygon,26331)
);


ALTER TABLE geologyogun OWNER TO docker;

--
-- Name: geologyogun_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE geologyogun_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE geologyogun_gid_seq OWNER TO docker;

--
-- Name: geologyogun_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE geologyogun_gid_seq OWNED BY geologyogun.gid;


--
-- Name: health_centres; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE health_centres (
    gid integer NOT NULL,
    name character varying(250),
    lga character varying(80),
    ownership character varying(80),
    doctors character varying(80),
    nurses character varying(80),
    bed_space character varying(80),
    pharmacist character varying(80),
    "para-medic" character varying(80),
    no_ofpatients character varying(80),
    classifica character varying(80),
    photogragh character varying(80),
    location character varying(80),
    latitude character varying(80),
    longitude character varying(80),
    photograph character varying(80),
    categories character varying(80),
    the_geom geometry(Point,26331),
    facility_type integer
);


ALTER TABLE health_centres OWNER TO docker;

--
-- Name: health_centres_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE health_centres_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE health_centres_gid_seq OWNER TO docker;

--
-- Name: health_centres_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE health_centres_gid_seq OWNED BY health_centres.gid;


--
-- Name: hist_beacons; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE hist_beacons (
    hist_id bigint NOT NULL,
    gid integer DEFAULT nextval('beacons_gid_seq'::regclass) NOT NULL,
    beacon character varying(80) NOT NULL,
    y double precision NOT NULL,
    x double precision NOT NULL,
    the_geom geometry(Point,26331) NOT NULL,
    location character varying(180),
    name character varying(100),
    hist_user character varying,
    hist_action character varying,
    hist_time timestamp without time zone
);


ALTER TABLE hist_beacons OWNER TO postgres;

--
-- Name: hist_beacons_hist_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE hist_beacons_hist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hist_beacons_hist_id_seq OWNER TO postgres;

--
-- Name: hist_beacons_hist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE hist_beacons_hist_id_seq OWNED BY hist_beacons.hist_id;


--
-- Name: ilaro_reserve; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ilaro_reserve (
    gid integer NOT NULL,
    wdpaid numeric(10,0),
    objectid numeric(10,0),
    wdpa_pid numeric(10,0),
    country character varying(80),
    sub_loc character varying(80),
    name character varying(254),
    orig_name character varying(254),
    desig character varying(254),
    desig_eng character varying(254),
    desig_type character varying(254),
    iucn_cat character varying(254),
    marine smallint,
    rep_m_area numeric,
    rep_area numeric,
    status character varying(254),
    status_yr numeric(10,0),
    gov_type character varying(254),
    mang_auth character varying(254),
    int_crit character varying(80),
    mang_plan character varying(80),
    official smallint,
    is_point smallint,
    no_take character varying(254),
    no_tk_area numeric,
    metadata_i numeric(10,0),
    action character varying(80),
    geom geometry(MultiPolygon,26331)
);


ALTER TABLE ilaro_reserve OWNER TO docker;

--
-- Name: ilaro_reserve_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ilaro_reserve_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ilaro_reserve_gid_seq OWNER TO docker;

--
-- Name: ilaro_reserve_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ilaro_reserve_gid_seq OWNED BY ilaro_reserve.gid;


--
-- Name: instrument_cat; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE instrument_cat (
    instrument_cat integer NOT NULL,
    description character varying NOT NULL
);


ALTER TABLE instrument_cat OWNER TO docker;

--
-- Name: instrument_cat_instrument_cat_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE instrument_cat_instrument_cat_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE instrument_cat_instrument_cat_seq OWNER TO docker;

--
-- Name: instrument_cat_instrument_cat_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE instrument_cat_instrument_cat_seq OWNED BY instrument_cat.instrument_cat;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE jobs (
    id character varying(100) DEFAULT ''::character varying NOT NULL,
    userid character varying(1024) NOT NULL,
    path character varying(1024),
    params text,
    feattype character varying(254),
    featid character varying(254),
    bbox box,
    private boolean DEFAULT false,
    created timestamp without time zone,
    accessed integer DEFAULT 0,
    title character varying(254),
    status character varying(30) DEFAULT 'pending'::character varying,
    url character varying(1024),
    done timestamp(0) without time zone,
    size double precision,
    pages bigint,
    layout character varying,
    resolution character varying,
    scale character varying,
    amount double precision
);


ALTER TABLE jobs OWNER TO docker;

--
-- Name: keytowns; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE keytowns (
    gid integer NOT NULL,
    id integer,
    "MajorTowns" character varying(80),
    the_geom geometry(Point,26331)
);


ALTER TABLE keytowns OWNER TO docker;

--
-- Name: keytowns_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE keytowns_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE keytowns_gid_seq OWNER TO docker;

--
-- Name: keytowns_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE keytowns_gid_seq OWNED BY keytowns.gid;


--
-- Name: legal; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE legal (
    gid integer NOT NULL,
    bsn integer,
    pc_code integer,
    sc_name character varying(80),
    sc_codes integer,
    tc_name character varying(80),
    tc_codes integer,
    entity character varying(80),
    streetname character varying(80),
    roadtype character varying(80),
    "Aarea" character varying(80),
    location character varying(80),
    lga character varying(80),
    latitude double precision,
    longitude double precision,
    altitude double precision,
    the_geom geometry(Point)
);


ALTER TABLE legal OWNER TO docker;

--
-- Name: legal_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE legal_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE legal_gid_seq OWNER TO docker;

--
-- Name: legal_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE legal_gid_seq OWNED BY legal.gid;


--
-- Name: lg_hqtrs; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE lg_hqtrs (
    hq_sn integer NOT NULL,
    hq_code integer NOT NULL,
    hq_desc text
);


ALTER TABLE lg_hqtrs OWNER TO docker;

--
-- Name: lg_hqtrs_hq_sn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE lg_hqtrs_hq_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE lg_hqtrs_hq_sn_seq OWNER TO docker;

--
-- Name: lg_hqtrs_hq_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE lg_hqtrs_hq_sn_seq OWNED BY lg_hqtrs.hq_sn;


--
-- Name: local_govt; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE local_govt (
    id integer NOT NULL,
    local_govt_name character varying(50) NOT NULL
);


ALTER TABLE local_govt OWNER TO docker;

--
-- Name: local_govt_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE local_govt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE local_govt_id_seq OWNER TO docker;

--
-- Name: local_govt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE local_govt_id_seq OWNED BY local_govt.id;


--
-- Name: localmotclass_code_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE localmotclass_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE localmotclass_code_seq OWNER TO postgres;

--
-- Name: localmotclass; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE localmotclass (
    code integer DEFAULT nextval('localmotclass_code_seq'::regclass) NOT NULL,
    "desc" text
);


ALTER TABLE localmotclass OWNER TO postgres;

--
-- Name: localrdclass_code_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE localrdclass_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE localrdclass_code_seq OWNER TO postgres;

--
-- Name: localrdclass; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE localrdclass (
    code integer DEFAULT nextval('localrdclass_code_seq'::regclass) NOT NULL,
    "desc" text
);


ALTER TABLE localrdclass OWNER TO postgres;

--
-- Name: med_ownership; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE med_ownership (
    medsn integer NOT NULL,
    medcode integer NOT NULL,
    med_desc text
);


ALTER TABLE med_ownership OWNER TO docker;

--
-- Name: med_ownership_medsn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE med_ownership_medsn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE med_ownership_medsn_seq OWNER TO docker;

--
-- Name: med_ownership_medsn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE med_ownership_medsn_seq OWNED BY med_ownership.medsn;


--
-- Name: medical_master_data; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE medical_master_data (
    gid integer DEFAULT nextval('health_centres_gid_seq'::regclass) NOT NULL,
    ownership integer,
    classification integer,
    photo integer,
    doctors integer,
    nurses integer,
    paramedic integer,
    pharamcist integer,
    bed_space integer,
    med_fac integer
);


ALTER TABLE medical_master_data OWNER TO docker;

--
-- Name: medical_partners; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE medical_partners (
    p_sn integer NOT NULL,
    partner_code text,
    partner_desc text
);


ALTER TABLE medical_partners OWNER TO docker;

--
-- Name: medical_partners_p_sn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE medical_partners_p_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE medical_partners_p_sn_seq OWNER TO docker;

--
-- Name: medical_partners_p_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE medical_partners_p_sn_seq OWNED BY medical_partners.p_sn;


--
-- Name: medical_services; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE medical_services (
    service_sn integer NOT NULL,
    service_desc text,
    service_code text
);


ALTER TABLE medical_services OWNER TO docker;

--
-- Name: medical_services_history; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE medical_services_history (
    facility_code integer,
    med_services integer,
    med_partner integer,
    med_sn integer NOT NULL
);


ALTER TABLE medical_services_history OWNER TO docker;

--
-- Name: medical_services_med_sn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE medical_services_med_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE medical_services_med_sn_seq OWNER TO docker;

--
-- Name: medical_services_med_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE medical_services_med_sn_seq OWNED BY medical_services_history.med_sn;


--
-- Name: medical_services_service_sn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE medical_services_service_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE medical_services_service_sn_seq OWNER TO docker;

--
-- Name: medical_services_service_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE medical_services_service_sn_seq OWNED BY medical_services.service_sn;


--
-- Name: mine_operation_type; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE mine_operation_type (
    operation_id integer NOT NULL,
    operation_desc text
);


ALTER TABLE mine_operation_type OWNER TO docker;

--
-- Name: mine_operation_type_operation_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE mine_operation_type_operation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mine_operation_type_operation_id_seq OWNER TO docker;

--
-- Name: mine_operation_type_operation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE mine_operation_type_operation_id_seq OWNED BY mine_operation_type.operation_id;


--
-- Name: mine_operator; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE mine_operator (
    operator_sn integer NOT NULL,
    operator_name text,
    operator_email text,
    operator_address text,
    operation_year_start date,
    operation_year_end date,
    reg_date date,
    comment text,
    operator_tel text
);


ALTER TABLE mine_operator OWNER TO docker;

--
-- Name: mine_operator_operator_sn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE mine_operator_operator_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mine_operator_operator_sn_seq OWNER TO docker;

--
-- Name: mine_operator_operator_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE mine_operator_operator_sn_seq OWNED BY mine_operator.operator_sn;


--
-- Name: minerals_list; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE minerals_list (
    mineral_id integer NOT NULL,
    mineral_desc text
);


ALTER TABLE minerals_list OWNER TO docker;

--
-- Name: minerals_list_mineral_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE minerals_list_mineral_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE minerals_list_mineral_id_seq OWNER TO docker;

--
-- Name: minerals_list_mineral_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE minerals_list_mineral_id_seq OWNED BY minerals_list.mineral_id;


--
-- Name: mines_database; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE mines_database (
    mine_sn integer NOT NULL,
    target_mineral integer,
    mine_location text,
    y double precision,
    x double precision,
    the_geom geometry(Point,26331),
    operation_type integer,
    mine_operator integer,
    mine_id integer,
    name_of_mine text
);


ALTER TABLE mines_database OWNER TO docker;

--
-- Name: mines_database_mine_sn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE mines_database_mine_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mines_database_mine_sn_seq OWNER TO docker;

--
-- Name: mines_database_mine_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE mines_database_mine_sn_seq OWNED BY mines_database.mine_sn;


--
-- Name: mines_operator_register; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE mines_operator_register (
    log_sn integer NOT NULL,
    mine_id integer,
    miner_id integer,
    operations_startdate date,
    operations_enddate date,
    suspended integer,
    suspension_date date,
    suspension_lift_date date,
    comment text
);


ALTER TABLE mines_operator_register OWNER TO docker;

--
-- Name: mines_operator_register_log_sn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE mines_operator_register_log_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mines_operator_register_log_sn_seq OWNER TO docker;

--
-- Name: mines_operator_register_log_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE mines_operator_register_log_sn_seq OWNED BY mines_operator_register.log_sn;


--
-- Name: new_ogunroadnetwork; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE new_ogunroadnetwork (
    id integer NOT NULL,
    the_geom geometry(MultiLineString,26331)
);


ALTER TABLE new_ogunroadnetwork OWNER TO docker;

--
-- Name: new_ogunroadnetwork_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE new_ogunroadnetwork_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE new_ogunroadnetwork_id_seq OWNER TO docker;

--
-- Name: new_ogunroadnetwork_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE new_ogunroadnetwork_id_seq OWNED BY new_ogunroadnetwork.id;


--
-- Name: nirboundaries; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE nirboundaries (
    gid integer NOT NULL,
    "ISO" character varying(7),
    "NAME_0" character varying(54),
    "NAME_1" character varying(47),
    "VARNAME_1" character varying(100),
    "TYPE_1" character varying(50),
    "HASC_1" character varying(10),
    the_geom geometry(Polygon,26331)
);


ALTER TABLE nirboundaries OWNER TO docker;

--
-- Name: nirboundaries_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE nirboundaries_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE nirboundaries_gid_seq OWNER TO docker;

--
-- Name: nirboundaries_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE nirboundaries_gid_seq OWNED BY nirboundaries.gid;


--
-- Name: official_gazzette; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE official_gazzette (
    gid integer NOT NULL,
    "NAME" character varying(80),
    "F_CLASS" character varying(80),
    "F_DESIG" character varying(80),
    "LAT" double precision,
    "LONG" double precision,
    "ADM1" character varying(80),
    "ADM2" character varying(80),
    the_geom geometry(Point),
    settlement_type integer
);


ALTER TABLE official_gazzette OWNER TO docker;

--
-- Name: official_gazzette_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE official_gazzette_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE official_gazzette_gid_seq OWNER TO docker;

--
-- Name: official_gazzette_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE official_gazzette_gid_seq OWNED BY official_gazzette.gid;


--
-- Name: ogun_25m_contour; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogun_25m_contour (
    gid integer NOT NULL,
    id integer,
    elev double precision,
    the_geom geometry(MultiLineString,26331)
);


ALTER TABLE ogun_25m_contour OWNER TO docker;

--
-- Name: ogun_25m_contour_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ogun_25m_contour_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ogun_25m_contour_gid_seq OWNER TO docker;

--
-- Name: ogun_25m_contour_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ogun_25m_contour_gid_seq OWNED BY ogun_25m_contour.gid;


--
-- Name: ogun_admin; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogun_admin (
    gid integer NOT NULL,
    "ISO" character varying(7),
    "NAME" character varying(47),
    "TYPE" character varying(50),
    "ISOCODE" character varying(10),
    the_geom geometry(Polygon,26331),
    "SenDistrict" character varying(50)
);


ALTER TABLE ogun_admin OWNER TO docker;

--
-- Name: ogun_admin_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ogun_admin_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ogun_admin_gid_seq OWNER TO docker;

--
-- Name: ogun_admin_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ogun_admin_gid_seq OWNED BY ogun_admin.gid;


--
-- Name: ogun_water; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogun_water (
    gid integer NOT NULL,
    "NATURAL" character varying(9),
    "NAME" character varying(32),
    the_geom geometry(Polygon,26331)
);


ALTER TABLE ogun_water OWNER TO docker;

--
-- Name: ogun_water_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ogun_water_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ogun_water_gid_seq OWNER TO docker;

--
-- Name: ogun_water_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ogun_water_gid_seq OWNED BY ogun_water.gid;


--
-- Name: oguncontours; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE oguncontours (
    gid integer NOT NULL,
    id integer,
    elev double precision,
    id_0 integer,
    iso character varying(3),
    name_0 character varying(75),
    id_1 integer,
    name_1 character varying(75),
    id_2 integer,
    name_2 character varying(75),
    varname_2 character varying(150),
    nl_name_2 character varying(75),
    hasc_2 character varying(15),
    cc_2 character varying(15),
    type_2 character varying(50),
    engtype_2 character varying(50),
    validfr_2 character varying(25),
    validto_2 character varying(25),
    remarks_2 character varying(100),
    shape_leng numeric,
    shape_area numeric,
    the_geom geometry(MultiLineString,26331)
);


ALTER TABLE oguncontours OWNER TO docker;

--
-- Name: oguncontours_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE oguncontours_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE oguncontours_gid_seq OWNER TO docker;

--
-- Name: oguncontours_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE oguncontours_gid_seq OWNED BY oguncontours.gid;


--
-- Name: ogungazzette; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogungazzette (
    gid integer NOT NULL,
    "NAME" character varying(80),
    "F_CLASS" character varying(80),
    "F_DESIG" character varying(80),
    "LAT" double precision,
    "LONG" double precision,
    "ADM1" character varying(80),
    "ADM2" character varying(80),
    the_geom geometry(Point,26331)
);


ALTER TABLE ogungazzette OWNER TO docker;

--
-- Name: ogungazzette_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ogungazzette_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ogungazzette_gid_seq OWNER TO docker;

--
-- Name: ogungazzette_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ogungazzette_gid_seq OWNED BY ogungazzette.gid;


--
-- Name: ogunpoi; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogunpoi (
    gid integer NOT NULL,
    id numeric(10,0),
    poi_subcod character varying(80),
    poi_name character varying(150),
    poi_code_ smallint,
    the_geom geometry(Point,26331)
);


ALTER TABLE ogunpoi OWNER TO docker;

--
-- Name: ogunpoi_gid_seq1; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ogunpoi_gid_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ogunpoi_gid_seq1 OWNER TO docker;

--
-- Name: ogunpoi_gid_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ogunpoi_gid_seq1 OWNED BY ogunpoi.gid;


--
-- Name: ogunrailnetwork; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogunrailnetwork (
    gid integer NOT NULL,
    id integer,
    the_geom geometry(MultiLineString,26331)
);


ALTER TABLE ogunrailnetwork OWNER TO docker;

--
-- Name: ogunrailnetwork_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ogunrailnetwork_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ogunrailnetwork_gid_seq OWNER TO docker;

--
-- Name: ogunrailnetwork_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ogunrailnetwork_gid_seq OWNED BY ogunrailnetwork.gid;


--
-- Name: ogunriver_polygon; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogunriver_polygon (
    gid integer NOT NULL,
    id integer,
    name character varying(100),
    the_geom geometry(Polygon,26331)
);


ALTER TABLE ogunriver_polygon OWNER TO docker;

--
-- Name: ogunriver_polygon_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ogunriver_polygon_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ogunriver_polygon_gid_seq OWNER TO docker;

--
-- Name: ogunriver_polygon_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ogunriver_polygon_gid_seq OWNED BY ogunriver_polygon.gid;


--
-- Name: ogunroadnetwork; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogunroadnetwork (
    gid integer NOT NULL,
    type character varying(14),
    oneway character varying(4),
    lanes numeric,
    surface numeric(10,0),
    postcode numeric(10,0),
    str_type numeric(10,0),
    a_name character varying(100),
    rd_hrky character varying(1),
    rdcode numeric(10,0),
    str_name numeric(10,0),
    the_geom geometry(MultiLineString,26331),
    trafdir boolean DEFAULT true
);


ALTER TABLE ogunroadnetwork OWNER TO docker;

--
-- Name: ogunroadnetwork_old; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogunroadnetwork_old (
    gid integer NOT NULL,
    type character varying(14),
    oneway character varying(4),
    lanes numeric,
    surface numeric(10,0),
    postcode numeric(10,0),
    str_type numeric(10,0),
    a_name character varying(100),
    the_geom geometry(MultiLineString,26331),
    rd_hrky character varying(1),
    rdcode integer,
    str_name integer
);


ALTER TABLE ogunroadnetwork_old OWNER TO docker;

--
-- Name: ogunroadnetwork_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ogunroadnetwork_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ogunroadnetwork_gid_seq OWNER TO docker;

--
-- Name: ogunroadnetwork_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ogunroadnetwork_gid_seq OWNED BY ogunroadnetwork_old.gid;


--
-- Name: ogunroadnetwork_gid_seq1; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ogunroadnetwork_gid_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ogunroadnetwork_gid_seq1 OWNER TO docker;

--
-- Name: ogunroadnetwork_gid_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ogunroadnetwork_gid_seq1 OWNED BY ogunroadnetwork.gid;


--
-- Name: ogunwater; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE ogunwater (
    gid integer NOT NULL,
    "NATURAL" character varying(9),
    "NAME" character varying(32),
    the_geom geometry(Polygon,26331)
);


ALTER TABLE ogunwater OWNER TO docker;

--
-- Name: ogunwater_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE ogunwater_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ogunwater_gid_seq OWNER TO docker;

--
-- Name: ogunwater_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE ogunwater_gid_seq OWNED BY ogunwater.gid;


--
-- Name: olokemeji_reserve; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE olokemeji_reserve (
    gid integer NOT NULL,
    wdpaid numeric(10,0),
    objectid numeric(10,0),
    wdpa_pid numeric(10,0),
    country character varying(80),
    sub_loc character varying(80),
    name character varying(254),
    orig_name character varying(254),
    desig character varying(254),
    desig_eng character varying(254),
    desig_type character varying(254),
    iucn_cat character varying(254),
    marine smallint,
    rep_m_area numeric,
    rep_area numeric,
    status character varying(254),
    status_yr numeric(10,0),
    gov_type character varying(254),
    mang_auth character varying(254),
    int_crit character varying(80),
    mang_plan character varying(80),
    official smallint,
    is_point smallint,
    no_take character varying(254),
    no_tk_area numeric,
    metadata_i numeric(10,0),
    action character varying(80),
    geom geometry(MultiPolygon,26331)
);


ALTER TABLE olokemeji_reserve OWNER TO docker;

--
-- Name: olokemeji_reserve_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE olokemeji_reserve_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE olokemeji_reserve_gid_seq OWNER TO docker;

--
-- Name: olokemeji_reserve_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE olokemeji_reserve_gid_seq OWNED BY olokemeji_reserve.gid;


--
-- Name: oneway; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE oneway (
    code integer NOT NULL,
    "desc" text
);


ALTER TABLE oneway OWNER TO postgres;

--
-- Name: parcel_def_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE parcel_def_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE parcel_def_id_seq OWNER TO docker;

--
-- Name: parcel_def_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE parcel_def_id_seq OWNED BY parcel_def.id;


--
-- Name: parcel_lookup_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE parcel_lookup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE parcel_lookup_id_seq OWNER TO docker;

--
-- Name: parcel_lookup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE parcel_lookup_id_seq OWNED BY parcel_lookup.plot_sn;


--
-- Name: parcel_lookup_parcel_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE parcel_lookup_parcel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE parcel_lookup_parcel_id_seq OWNER TO docker;

--
-- Name: parcel_lookup_parcel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE parcel_lookup_parcel_id_seq OWNED BY parcel_lookup.parcel_id;


--
-- Name: perimeters; Type: VIEW; Schema: public; Owner: docker
--

CREATE VIEW perimeters AS
 SELECT parcel.parcel_id,
    parcel.the_geom,
    (round((st_area(parcel.the_geom))::numeric, 3))::double precision AS comp_area,
    description.official_area,
    description.parcel_number,
    description.block,
    description.serial_no,
    description.scheme,
    description.file_number,
    description.allocation,
    description.owner,
    (((('<a href="http://192.168.10.12/geoserver/'::text || (description.deeds_file)::text) || '" target="blank_">'::text) || (description.deeds_file)::text) || '</a>'::text) AS deeds_file,
    description.private
   FROM (( SELECT vl.parcel_id,
            (st_makepolygon(st_addpoint(st_makeline(vl.the_geom), st_startpoint(st_makeline(vl.the_geom)))))::geometry(Polygon,26331) AS the_geom
           FROM ( SELECT pd.id,
                    pd.parcel_id,
                    pd.beacon,
                    pd.sequence,
                    b.the_geom
                   FROM (beacons b
                     JOIN parcel_def pd ON (((b.beacon)::text = (pd.beacon)::text)))
                  ORDER BY pd.parcel_id, pd.sequence) vl
          GROUP BY vl.parcel_id
         HAVING (st_npoints(st_collect(vl.the_geom)) > 1)) parcel
     JOIN ( SELECT p.parcel_id,
            ((p.local_govt || (p.prop_type)::text) || p.parcel_id) AS parcel_number,
            p.allocation,
            p.block,
            p.plot_sn AS serial_no,
            p.official_area,
            s.scheme_name AS scheme,
            p.file_number,
            d.grantee AS owner,
            p.deeds_file,
            p.private
           FROM ((parcel_lookup p
             LEFT JOIN deeds d ON (((p.file_number)::text = (d.fileno)::text)))
             LEFT JOIN schemes s ON ((p.scheme = s.id)))
          WHERE ((p.block)::text = ANY (ARRAY[('perimeter'::character varying)::text, ('acquisition'::character varying)::text, ('agriculture'::character varying)::text, ('education'::character varying)::text]))) description USING (parcel_id))
  WHERE st_isvalid(parcel.the_geom);


ALTER TABLE perimeters OWNER TO docker;

--
-- Name: parcel_overlap_matviews; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW parcel_overlap_matviews AS
 SELECT DISTINCT ON (a.parcel_id) a.parcel_id,
    a.the_geom,
    a.comp_area,
    a.official_area,
    a.parcel_number,
    a.block,
    a.serial_no,
    a.scheme,
    a.file_number,
    a.allocation,
    a.owner,
    a.deeds_file,
    a.private
   FROM parcels a,
    perimeters b
  WHERE (st_overlaps(a.the_geom, b.the_geom) = true)
  WITH NO DATA;


ALTER TABLE parcel_overlap_matviews OWNER TO docker;

--
-- Name: parcels_intersect; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW parcels_intersect AS
 SELECT DISTINCT ON (a.parcel_id) a.parcel_id,
    a.the_geom,
    a.comp_area,
    a.official_area,
    a.parcel_number,
    a.block,
    a.serial_no,
    a.scheme,
    a.file_number,
    a.allocation,
    a.owner,
    a.deeds_file,
    a.private
   FROM (parcels a
     LEFT JOIN parcels b ON (st_intersects(a.the_geom, b.the_geom)))
  WHERE ((a.parcel_id <> b.parcel_id) AND (b.parcel_id IS NOT NULL) AND (NOT st_touches(a.the_geom, b.the_geom)))
  WITH NO DATA;


ALTER TABLE parcels_intersect OWNER TO docker;

--
-- Name: perimeters_original; Type: VIEW; Schema: public; Owner: docker
--

CREATE VIEW perimeters_original AS
 SELECT parcel.parcel_id,
    parcel.the_geom,
    (round((st_area(parcel.the_geom))::numeric, 3))::double precision AS comp_area,
    description.official_area,
    description.parcel_number,
    description.block,
    description.serial_no,
    description.scheme,
    description.file_number,
    description.allocation,
    description.owner,
    (((('<a href="http://192.168.10.12/geoserver/'::text || (description.deeds_file)::text) || '" target="blank_">'::text) || (description.deeds_file)::text) || '</a>'::text) AS deeds_file
   FROM (( SELECT vl.parcel_id,
            (st_makepolygon(st_addpoint(st_makeline(vl.the_geom), st_startpoint(st_makeline(vl.the_geom)))))::geometry(Polygon,26331) AS the_geom
           FROM ( SELECT pd.id,
                    pd.parcel_id,
                    pd.beacon,
                    pd.sequence,
                    b.the_geom
                   FROM (beacons b
                     JOIN parcel_def pd ON (((b.beacon)::text = (pd.beacon)::text)))
                  ORDER BY pd.parcel_id, pd.sequence) vl
          GROUP BY vl.parcel_id
         HAVING (st_npoints(st_collect(vl.the_geom)) > 1)) parcel
     JOIN ( SELECT p.parcel_id,
            ((p.local_govt || (p.prop_type)::text) || p.parcel_id) AS parcel_number,
            p.allocation,
            p.block,
            p.plot_sn AS serial_no,
            p.official_area,
            s.scheme_name AS scheme,
            p.file_number,
            d.grantee AS owner,
            p.deeds_file
           FROM ((parcel_lookup p
             LEFT JOIN deeds d ON (((p.file_number)::text = (d.fileno)::text)))
             LEFT JOIN schemes s ON ((p.scheme = s.id)))
          WHERE ((p.block)::text = ANY (ARRAY[('perimeter'::character varying)::text, ('acquisition'::character varying)::text, ('agriculture'::character varying)::text, ('education'::character varying)::text]))) description USING (parcel_id))
  WHERE st_isvalid(parcel.the_geom)
 LIMIT 1;


ALTER TABLE perimeters_original OWNER TO docker;

--
-- Name: poi; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE poi (
    gid integer NOT NULL,
    bsn integer,
    pc_name character varying(80),
    pc_codes integer,
    sc_name character varying(80),
    sc_codes integer,
    tc_name character varying(80),
    tc_codes integer,
    entity text,
    site_cond character varying(80),
    bldgtype character varying(80),
    drainage character varying(80),
    rd_cond character varying(80),
    rd_surface character varying(80),
    rd_carriage character varying(80),
    electric character varying(80),
    rd_type character varying(80),
    rd_feature character varying(80),
    str_furnit character varying(80),
    refuse_disp character varying(80),
    area character varying(80),
    location character varying(80),
    str_name character varying(80),
    lga character varying(80),
    latitude character varying(80),
    longitude double precision,
    altitude double precision,
    the_geom geometry(Point,26331)
);


ALTER TABLE poi OWNER TO docker;

--
-- Name: poi_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE poi_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE poi_gid_seq OWNER TO docker;

--
-- Name: poi_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE poi_gid_seq OWNED BY poi.gid;


--
-- Name: pois; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE pois (
    id integer NOT NULL,
    the_geom geometry(Point,4326),
    serial_no integer,
    bsn integer,
    pc_name character varying,
    pc_code integer,
    sc_name character varying,
    sc_code integer,
    tc_name character varying,
    tc_code integer,
    entity character varying,
    local_govt character varying,
    latitude double precision,
    longitude double precision,
    altitude double precision,
    site_condition character varying,
    building_type character varying,
    drainage character varying,
    road_condition character varying,
    road_surface character varying,
    road_carriage character varying,
    electricity character varying,
    road_type character varying,
    road_feature character varying,
    street_furniture character varying,
    refuse_disposal character varying,
    area character varying,
    location character varying,
    street_name character varying
);


ALTER TABLE pois OWNER TO docker;

--
-- Name: pois_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE pois_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pois_id_seq OWNER TO docker;

--
-- Name: pois_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE pois_id_seq OWNED BY pois.id;


--
-- Name: pois_view; Type: MATERIALIZED VIEW; Schema: public; Owner: docker
--

CREATE MATERIALIZED VIEW pois_view AS
 SELECT DISTINCT ON (p.id) p.id,
    p.the_geom AS geom,
    p.serial_no,
    p.bsn,
    p.pc_name,
    p.pc_code,
    p.sc_name,
    p.sc_code,
    p.tc_name,
    p.tc_code,
    p.entity,
    p.local_govt,
    p.latitude,
    p.longitude,
    p.altitude,
    p.site_condition,
    p.building_type,
    p.drainage,
    p.road_condition,
    p.road_surface,
    p.road_carriage,
    p.electricity,
    p.road_type,
    p.road_feature,
    p.street_furniture,
    p.refuse_disposal,
    p.area,
    p.location,
    p.street_name,
    l.icon
   FROM (pois p
     JOIN lut_poi_cat l USING (sc_code, tc_code))
  WITH NO DATA;


ALTER TABLE pois_view OWNER TO docker;

--
-- Name: pop_figures; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE pop_figures (
    pop_id integer NOT NULL,
    pop_year integer,
    lga_code integer,
    pop integer
);


ALTER TABLE pop_figures OWNER TO docker;

--
-- Name: pop_figures_pop_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE pop_figures_pop_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pop_figures_pop_id_seq OWNER TO docker;

--
-- Name: pop_figures_pop_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE pop_figures_pop_id_seq OWNED BY pop_figures.pop_id;


--
-- Name: pop_year; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE pop_year (
    popyear integer,
    pop_sn integer NOT NULL
);


ALTER TABLE pop_year OWNER TO docker;

--
-- Name: pop_year_pop_sn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE pop_year_pop_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pop_year_pop_sn_seq OWNER TO docker;

--
-- Name: pop_year_pop_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE pop_year_pop_sn_seq OWNED BY pop_year.pop_sn;


--
-- Name: precious_minerals; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE precious_minerals (
    id integer,
    type character varying(80),
    type_id integer,
    the_geom geometry(Point,26331),
    gid integer NOT NULL
);


ALTER TABLE precious_minerals OWNER TO docker;

--
-- Name: precious_minerals_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE precious_minerals_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE precious_minerals_gid_seq OWNER TO docker;

--
-- Name: precious_minerals_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE precious_minerals_gid_seq OWNED BY precious_minerals.gid;


--
-- Name: prop_types; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE prop_types (
    id integer NOT NULL,
    code character varying(2) NOT NULL,
    prop_type_name character varying(50) NOT NULL
);


ALTER TABLE prop_types OWNER TO docker;

--
-- Name: prop_types_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE prop_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE prop_types_id_seq OWNER TO docker;

--
-- Name: prop_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE prop_types_id_seq OWNED BY prop_types.id;


--
-- Name: streetname; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE streetname (
    streetname character varying(250),
    auth_lga integer,
    st_id integer NOT NULL,
    area text
);


ALTER TABLE streetname OWNER TO docker;

--
-- Name: rdntwrk; Type: VIEW; Schema: public; Owner: docker
--

CREATE VIEW rdntwrk AS
 SELECT a.the_geom,
    a.rdcode,
    b.streetname AS strname
   FROM (ogunroadnetwork_old a
     JOIN streetname b ON ((a.str_name = b.st_id)));


ALTER TABLE rdntwrk OWNER TO docker;

--
-- Name: reference_view; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE reference_view (
    id integer,
    plan_no character varying(20),
    ref_beacon character varying(20),
    scheme integer,
    parcel_id integer,
    the_geom geometry(Point,26331),
    x double precision,
    y double precision
);


ALTER TABLE reference_view OWNER TO docker;

--
-- Name: road_code; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE road_code (
    code_id integer NOT NULL,
    rdcode text
);


ALTER TABLE road_code OWNER TO docker;

--
-- Name: road_code_code_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE road_code_code_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE road_code_code_id_seq OWNER TO docker;

--
-- Name: road_code_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE road_code_code_id_seq OWNED BY road_code.code_id;


--
-- Name: roadclass; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE roadclass (
    code character varying(1) NOT NULL,
    "desc" text
);


ALTER TABLE roadclass OWNER TO postgres;

--
-- Name: roadstatus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE roadstatus (
    code character varying(1) NOT NULL,
    "desc" text
);


ALTER TABLE roadstatus OWNER TO postgres;

--
-- Name: schemes_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE schemes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE schemes_id_seq OWNER TO docker;

--
-- Name: schemes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE schemes_id_seq OWNED BY schemes.id;


--
-- Name: security_agencies; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE security_agencies (
    gid integer NOT NULL,
    bsn integer,
    pc_codes integer,
    sc_name character varying(80),
    sc_codes integer,
    tc_name character varying(80),
    tc_codes integer,
    entity character varying(80),
    streetname character varying(80),
    road_type character varying(80),
    location character varying(80),
    area character varying(80),
    "local govt" character varying(80),
    latitude double precision,
    longitude double precision,
    altitude double precision,
    the_geom geometry(Point)
);


ALTER TABLE security_agencies OWNER TO docker;

--
-- Name: security_agencies_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE security_agencies_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE security_agencies_gid_seq OWNER TO docker;

--
-- Name: security_agencies_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE security_agencies_gid_seq OWNED BY security_agencies.gid;


--
-- Name: sen_districts; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE sen_districts (
    sen_id integer NOT NULL,
    sen_code integer NOT NULL,
    sen_desc text
);


ALTER TABLE sen_districts OWNER TO docker;

--
-- Name: sen_district; Type: VIEW; Schema: public; Owner: docker
--

CREATE VIEW sen_district AS
 SELECT a.lg_name AS lga,
    a.gid,
    a.the_geom,
    a.sen_district,
    b.sen_desc AS senatorial_district,
    c.hq_desc AS hqtrs
   FROM ((ogunadmin a
     JOIN sen_districts b ON ((a.sen_district = b.sen_code)))
     JOIN lg_hqtrs c ON ((a.lg_hq = c.hq_code)));


ALTER TABLE sen_district OWNER TO docker;

--
-- Name: sen_districts_sen_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE sen_districts_sen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sen_districts_sen_id_seq OWNER TO docker;

--
-- Name: sen_districts_sen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE sen_districts_sen_id_seq OWNED BY sen_districts.sen_id;


--
-- Name: settlement_type; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE settlement_type (
    sn integer NOT NULL,
    sett_type text
);


ALTER TABLE settlement_type OWNER TO docker;

--
-- Name: settlement_type_sn_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE settlement_type_sn_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE settlement_type_sn_seq OWNER TO docker;

--
-- Name: settlement_type_sn_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE settlement_type_sn_seq OWNED BY settlement_type.sn;


--
-- Name: settlements_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE settlements_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE settlements_gid_seq OWNER TO docker;

--
-- Name: settlements_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE settlements_gid_seq OWNED BY developed_area.gid;


--
-- Name: speed_code_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE speed_code_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE speed_code_seq OWNER TO postgres;

--
-- Name: speed; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE speed (
    speedlimit integer,
    code integer DEFAULT nextval('speed_code_seq'::regclass) NOT NULL
);


ALTER TABLE speed OWNER TO postgres;

--
-- Name: status_cat; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE status_cat (
    status_cat integer NOT NULL,
    description character varying NOT NULL
);


ALTER TABLE status_cat OWNER TO docker;

--
-- Name: status_cat_status_cat_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE status_cat_status_cat_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE status_cat_status_cat_seq OWNER TO docker;

--
-- Name: status_cat_status_cat_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE status_cat_status_cat_seq OWNED BY status_cat.status_cat;


--
-- Name: str_type_strid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE str_type_strid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE str_type_strid_seq OWNER TO postgres;

--
-- Name: str_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE str_type (
    strcode text,
    strdesc text,
    strid integer DEFAULT nextval('str_type_strid_seq'::regclass) NOT NULL
);


ALTER TABLE str_type OWNER TO postgres;

--
-- Name: street_centreline; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE street_centreline (
    gid integer NOT NULL,
    "MED_DESCRI" character varying(254),
    "RTT_DESCRI" character varying(254),
    "F_CODE_DES" character varying(10),
    "ISO" character varying(7),
    "ISOCOUNTRY" character varying(54),
    "ISO_2" character varying(7),
    "NAME_0" character varying(54),
    "NAME_1" character varying(47),
    "VARNAME_1" character varying(100),
    "TYPE_1" character varying(50),
    "HASC_1" character varying(10),
    "Road_Name" character varying(30),
    "Road_Code" character varying(10),
    "Length_Rd" double precision,
    the_geom geometry(LineString,26331)
);


ALTER TABLE street_centreline OWNER TO docker;

--
-- Name: street_centreline_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE street_centreline_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE street_centreline_gid_seq OWNER TO docker;

--
-- Name: street_centreline_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE street_centreline_gid_seq OWNED BY street_centreline.gid;


--
-- Name: streetname_stkey_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE streetname_stkey_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE streetname_stkey_seq OWNER TO docker;

--
-- Name: streetname_stkey_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE streetname_stkey_seq OWNED BY streetname.st_id;


--
-- Name: surfacetype; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE surfacetype (
    code integer NOT NULL,
    "desc" text
);


ALTER TABLE surfacetype OWNER TO postgres;

--
-- Name: survey; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE survey (
    id integer NOT NULL,
    plan_no character varying(20) NOT NULL,
    ref_beacon character varying(20) NOT NULL,
    scheme integer,
    description character varying(255)
);


ALTER TABLE survey OWNER TO docker;

--
-- Name: survey_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE survey_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE survey_id_seq OWNER TO docker;

--
-- Name: survey_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE survey_id_seq OWNED BY survey.id;


--
-- Name: the_ogunroadnetwork; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE the_ogunroadnetwork (
    id integer NOT NULL,
    the_geom geometry(MultiLineString,26331)
);


ALTER TABLE the_ogunroadnetwork OWNER TO docker;

--
-- Name: the_ogunroadnetwork_id_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE the_ogunroadnetwork_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE the_ogunroadnetwork_id_seq OWNER TO docker;

--
-- Name: the_ogunroadnetwork_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE the_ogunroadnetwork_id_seq OWNED BY the_ogunroadnetwork.id;


--
-- Name: theogunrivernetwork; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE theogunrivernetwork (
    gid integer NOT NULL,
    "TypeId" integer,
    name character varying(100),
    the_geom geometry(MultiLineString,26331)
);


ALTER TABLE theogunrivernetwork OWNER TO docker;

--
-- Name: theogunrivernetwork_gid_seq; Type: SEQUENCE; Schema: public; Owner: docker
--

CREATE SEQUENCE theogunrivernetwork_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE theogunrivernetwork_gid_seq OWNER TO docker;

--
-- Name: theogunrivernetwork_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: docker
--

ALTER SEQUENCE theogunrivernetwork_gid_seq OWNED BY theogunrivernetwork.gid;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: docker
--

CREATE TABLE transactions (
    id character varying(10) NOT NULL,
    parcel_id integer NOT NULL,
    capture_officer integer NOT NULL,
    approval_officer integer,
    date timestamp without time zone DEFAULT now() NOT NULL,
    instrument integer NOT NULL,
    survey integer NOT NULL
);


ALTER TABLE transactions OWNER TO docker;

--
-- Name: Industrial_Minerals gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY "Industrial_Minerals" ALTER COLUMN gid SET DEFAULT nextval('"Industrial_Minerals_gid_seq"'::regclass);


--
-- Name: SenatorialDistrict gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY "SenatorialDistrict" ALTER COLUMN gid SET DEFAULT nextval('"SenatorialDistrict_gid_seq"'::regclass);


--
-- Name: allocation_cat allocation_cat; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY allocation_cat ALTER COLUMN allocation_cat SET DEFAULT nextval('allocation_cat_id_seq'::regclass);


--
-- Name: applicants id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY applicants ALTER COLUMN id SET DEFAULT nextval('applicants_id_seq'::regclass);


--
-- Name: arakanga_reserve gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY arakanga_reserve ALTER COLUMN gid SET DEFAULT nextval('arakanga_reserve_gid_seq'::regclass);


--
-- Name: beacons gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beacons ALTER COLUMN gid SET DEFAULT nextval('beacons_gid_seq'::regclass);


--
-- Name: beardist id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist ALTER COLUMN id SET DEFAULT nextval('beardist_id_seq'::regclass);


--
-- Name: billboards gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY billboards ALTER COLUMN gid SET DEFAULT nextval('billboards_gid_seq'::regclass);


--
-- Name: conflict_cat conflict_cat; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY conflict_cat ALTER COLUMN conflict_cat SET DEFAULT nextval('conflict_cat_conflict_cat_seq'::regclass);


--
-- Name: conflicts id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY conflicts ALTER COLUMN id SET DEFAULT nextval('conflicts_id_seq'::regclass);


--
-- Name: conflicts conflict; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY conflicts ALTER COLUMN conflict SET DEFAULT nextval('conflicts_conflict_seq'::regclass);


--
-- Name: controls gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY controls ALTER COLUMN gid SET DEFAULT nextval('controls_gid_seq'::regclass);


--
-- Name: deeds deed_sn; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deeds ALTER COLUMN deed_sn SET DEFAULT nextval('deeds_deed_sn_seq'::regclass);


--
-- Name: developed_area gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY developed_area ALTER COLUMN gid SET DEFAULT nextval('settlements_gid_seq'::regclass);


--
-- Name: education gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY education ALTER COLUMN gid SET DEFAULT nextval('education_gid_seq'::regclass);


--
-- Name: fac_numbers da_id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY fac_numbers ALTER COLUMN da_id SET DEFAULT nextval('fac_numbers_da_id_seq'::regclass);


--
-- Name: geologyogun gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY geologyogun ALTER COLUMN gid SET DEFAULT nextval('geologyogun_gid_seq'::regclass);


--
-- Name: health_centres gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY health_centres ALTER COLUMN gid SET DEFAULT nextval('health_centres_gid_seq'::regclass);


--
-- Name: hist_beacons hist_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hist_beacons ALTER COLUMN hist_id SET DEFAULT nextval('hist_beacons_hist_id_seq'::regclass);


--
-- Name: ilaro_reserve gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ilaro_reserve ALTER COLUMN gid SET DEFAULT nextval('ilaro_reserve_gid_seq'::regclass);


--
-- Name: instrument_cat instrument_cat; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY instrument_cat ALTER COLUMN instrument_cat SET DEFAULT nextval('instrument_cat_instrument_cat_seq'::regclass);


--
-- Name: keytowns gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY keytowns ALTER COLUMN gid SET DEFAULT nextval('keytowns_gid_seq'::regclass);


--
-- Name: legal gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY legal ALTER COLUMN gid SET DEFAULT nextval('legal_gid_seq'::regclass);


--
-- Name: lg_hqtrs hq_sn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY lg_hqtrs ALTER COLUMN hq_sn SET DEFAULT nextval('lg_hqtrs_hq_sn_seq'::regclass);


--
-- Name: local_govt id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY local_govt ALTER COLUMN id SET DEFAULT nextval('local_govt_id_seq'::regclass);


--
-- Name: lut_poi_cat id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY lut_poi_cat ALTER COLUMN id SET DEFAULT nextval('"Ogun_state_id_seq"'::regclass);


--
-- Name: med_ownership medsn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY med_ownership ALTER COLUMN medsn SET DEFAULT nextval('med_ownership_medsn_seq'::regclass);


--
-- Name: medical_partners p_sn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY medical_partners ALTER COLUMN p_sn SET DEFAULT nextval('medical_partners_p_sn_seq'::regclass);


--
-- Name: medical_services service_sn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY medical_services ALTER COLUMN service_sn SET DEFAULT nextval('medical_services_service_sn_seq'::regclass);


--
-- Name: medical_services_history med_sn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY medical_services_history ALTER COLUMN med_sn SET DEFAULT nextval('medical_services_med_sn_seq'::regclass);


--
-- Name: mine_operation_type operation_id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY mine_operation_type ALTER COLUMN operation_id SET DEFAULT nextval('mine_operation_type_operation_id_seq'::regclass);


--
-- Name: mine_operator operator_sn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY mine_operator ALTER COLUMN operator_sn SET DEFAULT nextval('mine_operator_operator_sn_seq'::regclass);


--
-- Name: minerals_list mineral_id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY minerals_list ALTER COLUMN mineral_id SET DEFAULT nextval('minerals_list_mineral_id_seq'::regclass);


--
-- Name: mines_database mine_sn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY mines_database ALTER COLUMN mine_sn SET DEFAULT nextval('mines_database_mine_sn_seq'::regclass);


--
-- Name: mines_operator_register log_sn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY mines_operator_register ALTER COLUMN log_sn SET DEFAULT nextval('mines_operator_register_log_sn_seq'::regclass);


--
-- Name: new_ogunroadnetwork id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY new_ogunroadnetwork ALTER COLUMN id SET DEFAULT nextval('new_ogunroadnetwork_id_seq'::regclass);


--
-- Name: nirboundaries gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY nirboundaries ALTER COLUMN gid SET DEFAULT nextval('nirboundaries_gid_seq'::regclass);


--
-- Name: official_gazzette gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY official_gazzette ALTER COLUMN gid SET DEFAULT nextval('official_gazzette_gid_seq'::regclass);


--
-- Name: ogun_25m_contour gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogun_25m_contour ALTER COLUMN gid SET DEFAULT nextval('ogun_25m_contour_gid_seq'::regclass);


--
-- Name: ogun_admin gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogun_admin ALTER COLUMN gid SET DEFAULT nextval('ogun_admin_gid_seq'::regclass);


--
-- Name: ogun_water gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogun_water ALTER COLUMN gid SET DEFAULT nextval('ogun_water_gid_seq'::regclass);


--
-- Name: ogunadmin gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunadmin ALTER COLUMN gid SET DEFAULT nextval('"Ogunadmin_gid_seq"'::regclass);


--
-- Name: oguncontours gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY oguncontours ALTER COLUMN gid SET DEFAULT nextval('oguncontours_gid_seq'::regclass);


--
-- Name: ogungazzette gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogungazzette ALTER COLUMN gid SET DEFAULT nextval('ogungazzette_gid_seq'::regclass);


--
-- Name: ogunpoi gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunpoi ALTER COLUMN gid SET DEFAULT nextval('ogunpoi_gid_seq1'::regclass);


--
-- Name: ogunrailnetwork gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunrailnetwork ALTER COLUMN gid SET DEFAULT nextval('ogunrailnetwork_gid_seq'::regclass);


--
-- Name: ogunriver_polygon gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunriver_polygon ALTER COLUMN gid SET DEFAULT nextval('ogunriver_polygon_gid_seq'::regclass);


--
-- Name: ogunroadnetwork gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunroadnetwork ALTER COLUMN gid SET DEFAULT nextval('ogunroadnetwork_gid_seq1'::regclass);


--
-- Name: ogunroadnetwork_old gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunroadnetwork_old ALTER COLUMN gid SET DEFAULT nextval('ogunroadnetwork_gid_seq'::regclass);


--
-- Name: ogunwater gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunwater ALTER COLUMN gid SET DEFAULT nextval('ogunwater_gid_seq'::regclass);


--
-- Name: olokemeji_reserve gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY olokemeji_reserve ALTER COLUMN gid SET DEFAULT nextval('olokemeji_reserve_gid_seq'::regclass);


--
-- Name: parcel_def id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_def ALTER COLUMN id SET DEFAULT nextval('parcel_def_id_seq'::regclass);


--
-- Name: parcel_lookup parcel_id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup ALTER COLUMN parcel_id SET DEFAULT nextval('parcel_lookup_parcel_id_seq'::regclass);


--
-- Name: poi gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY poi ALTER COLUMN gid SET DEFAULT nextval('poi_gid_seq'::regclass);


--
-- Name: pois id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY pois ALTER COLUMN id SET DEFAULT nextval('pois_id_seq'::regclass);


--
-- Name: pop_figures pop_id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY pop_figures ALTER COLUMN pop_id SET DEFAULT nextval('pop_figures_pop_id_seq'::regclass);


--
-- Name: pop_year pop_sn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY pop_year ALTER COLUMN pop_sn SET DEFAULT nextval('pop_year_pop_sn_seq'::regclass);


--
-- Name: precious_minerals gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY precious_minerals ALTER COLUMN gid SET DEFAULT nextval('precious_minerals_gid_seq'::regclass);


--
-- Name: prop_types id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY prop_types ALTER COLUMN id SET DEFAULT nextval('prop_types_id_seq'::regclass);


--
-- Name: road_code code_id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY road_code ALTER COLUMN code_id SET DEFAULT nextval('road_code_code_id_seq'::regclass);


--
-- Name: schemes id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY schemes ALTER COLUMN id SET DEFAULT nextval('schemes_id_seq'::regclass);


--
-- Name: security_agencies gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY security_agencies ALTER COLUMN gid SET DEFAULT nextval('security_agencies_gid_seq'::regclass);


--
-- Name: sen_districts sen_id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY sen_districts ALTER COLUMN sen_id SET DEFAULT nextval('sen_districts_sen_id_seq'::regclass);


--
-- Name: settlement_type sn; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY settlement_type ALTER COLUMN sn SET DEFAULT nextval('settlement_type_sn_seq'::regclass);


--
-- Name: status_cat status_cat; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY status_cat ALTER COLUMN status_cat SET DEFAULT nextval('status_cat_status_cat_seq'::regclass);


--
-- Name: street_centreline gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY street_centreline ALTER COLUMN gid SET DEFAULT nextval('street_centreline_gid_seq'::regclass);


--
-- Name: streetname st_id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY streetname ALTER COLUMN st_id SET DEFAULT nextval('streetname_stkey_seq'::regclass);


--
-- Name: survey id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey ALTER COLUMN id SET DEFAULT nextval('survey_id_seq'::regclass);


--
-- Name: the_ogunroadnetwork id; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY the_ogunroadnetwork ALTER COLUMN id SET DEFAULT nextval('the_ogunroadnetwork_id_seq'::regclass);


--
-- Name: theogunrivernetwork gid; Type: DEFAULT; Schema: public; Owner: docker
--

ALTER TABLE ONLY theogunrivernetwork ALTER COLUMN gid SET DEFAULT nextval('theogunrivernetwork_gid_seq'::regclass);


--
-- Name: Industrial_Minerals Industrial_Minerals_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY "Industrial_Minerals"
    ADD CONSTRAINT "Industrial_Minerals_pkey" PRIMARY KEY (gid);


--
-- Name: ogunadmin Ogunadmin_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunadmin
    ADD CONSTRAINT "Ogunadmin_pkey" PRIMARY KEY (gid);


--
-- Name: SenatorialDistrict SenatorialDistrict_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY "SenatorialDistrict"
    ADD CONSTRAINT "SenatorialDistrict_pkey" PRIMARY KEY (gid);


--
-- Name: allocation_cat allocation_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY allocation_cat
    ADD CONSTRAINT allocation_cat_pkey PRIMARY KEY (allocation_cat);


--
-- Name: applicants applicants_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY applicants
    ADD CONSTRAINT applicants_pkey PRIMARY KEY (id);


--
-- Name: arakanga_reserve arakanga_reserve_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY arakanga_reserve
    ADD CONSTRAINT arakanga_reserve_pkey PRIMARY KEY (gid);


--
-- Name: beacons beacons_beacon_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beacons
    ADD CONSTRAINT beacons_beacon_key UNIQUE (beacon);


--
-- Name: beacons beacons_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beacons
    ADD CONSTRAINT beacons_pkey PRIMARY KEY (gid);


--
-- Name: beardist beardist_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_pkey PRIMARY KEY (id);


--
-- Name: billboards billboards_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY billboards
    ADD CONSTRAINT billboards_pkey PRIMARY KEY (gid);


--
-- Name: surfacetype code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY surfacetype
    ADD CONSTRAINT code_key PRIMARY KEY (code);


--
-- Name: conflict_cat conflict_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY conflict_cat
    ADD CONSTRAINT conflict_cat_pkey PRIMARY KEY (conflict_cat);


--
-- Name: conflicts conflicts_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY conflicts
    ADD CONSTRAINT conflicts_pkey PRIMARY KEY (id);


--
-- Name: controls controls_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY controls
    ADD CONSTRAINT controls_pkey PRIMARY KEY (gid);


--
-- Name: fac_numbers dk_ey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY fac_numbers
    ADD CONSTRAINT dk_ey PRIMARY KEY (da_id);


--
-- Name: deeds dkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deeds
    ADD CONSTRAINT dkey PRIMARY KEY (deed_sn);


--
-- Name: education education_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY education
    ADD CONSTRAINT education_pkey PRIMARY KEY (gid);


--
-- Name: geologyogun geologyogun_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY geologyogun
    ADD CONSTRAINT geologyogun_pkey PRIMARY KEY (gid);


--
-- Name: health_centres health_centres_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY health_centres
    ADD CONSTRAINT health_centres_pkey PRIMARY KEY (gid);


--
-- Name: hist_beacons hist_beacons_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hist_beacons
    ADD CONSTRAINT hist_beacons_pkey PRIMARY KEY (hist_id);


--
-- Name: lg_hqtrs hq_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY lg_hqtrs
    ADD CONSTRAINT hq_pkey PRIMARY KEY (hq_code);


--
-- Name: ilaro_reserve ilaro_reserve_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ilaro_reserve
    ADD CONSTRAINT ilaro_reserve_pkey PRIMARY KEY (gid);


--
-- Name: instrument_cat instrument_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY instrument_cat
    ADD CONSTRAINT instrument_cat_pkey PRIMARY KEY (instrument_cat);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: keytowns keytowns_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY keytowns
    ADD CONSTRAINT keytowns_pkey PRIMARY KEY (gid);


--
-- Name: legal legal_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY legal
    ADD CONSTRAINT legal_pkey PRIMARY KEY (gid);


--
-- Name: local_govt local_govt_id_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY local_govt
    ADD CONSTRAINT local_govt_id_key UNIQUE (local_govt_name);


--
-- Name: local_govt local_govt_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY local_govt
    ADD CONSTRAINT local_govt_pkey PRIMARY KEY (id);


--
-- Name: localrdclass local_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY localrdclass
    ADD CONSTRAINT local_key PRIMARY KEY (code);


--
-- Name: lut_poi_cat lut_poi_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY lut_poi_cat
    ADD CONSTRAINT lut_poi_cat_pkey PRIMARY KEY (id);


--
-- Name: medical_master_data med_centres_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY medical_master_data
    ADD CONSTRAINT med_centres_pkey PRIMARY KEY (gid);


--
-- Name: medical_partners medical_partners_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY medical_partners
    ADD CONSTRAINT medical_partners_pkey PRIMARY KEY (p_sn);


--
-- Name: medical_services_history medical_services_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY medical_services_history
    ADD CONSTRAINT medical_services_pkey PRIMARY KEY (med_sn);


--
-- Name: medical_services medical_services_pkey1; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY medical_services
    ADD CONSTRAINT medical_services_pkey1 PRIMARY KEY (service_sn);


--
-- Name: med_ownership medkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY med_ownership
    ADD CONSTRAINT medkey PRIMARY KEY (medcode);


--
-- Name: mine_operator mine_operator_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY mine_operator
    ADD CONSTRAINT mine_operator_pkey PRIMARY KEY (operator_sn);


--
-- Name: mine_operation_type minepk; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY mine_operation_type
    ADD CONSTRAINT minepk PRIMARY KEY (operation_id);


--
-- Name: minerals_list minerals_list_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY minerals_list
    ADD CONSTRAINT minerals_list_pkey PRIMARY KEY (mineral_id);


--
-- Name: mines_database mines_database_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY mines_database
    ADD CONSTRAINT mines_database_pkey PRIMARY KEY (mine_sn);


--
-- Name: mines_operator_register mines_operator_register_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY mines_operator_register
    ADD CONSTRAINT mines_operator_register_pkey PRIMARY KEY (log_sn);


--
-- Name: localmotclass mot_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY localmotclass
    ADD CONSTRAINT mot_key PRIMARY KEY (code);


--
-- Name: new_ogunroadnetwork new_ogunroadnetwork_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY new_ogunroadnetwork
    ADD CONSTRAINT new_ogunroadnetwork_pkey PRIMARY KEY (id);


--
-- Name: nirboundaries nirboundaries_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY nirboundaries
    ADD CONSTRAINT nirboundaries_pkey PRIMARY KEY (gid);


--
-- Name: official_gazzette official_gazzette_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY official_gazzette
    ADD CONSTRAINT official_gazzette_pkey PRIMARY KEY (gid);


--
-- Name: ogun_25m_contour ogun_25m_contour_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogun_25m_contour
    ADD CONSTRAINT ogun_25m_contour_pkey PRIMARY KEY (gid);


--
-- Name: ogun_admin ogun_admin_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogun_admin
    ADD CONSTRAINT ogun_admin_pkey PRIMARY KEY (gid);


--
-- Name: ogun_water ogun_water_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogun_water
    ADD CONSTRAINT ogun_water_pkey PRIMARY KEY (gid);


--
-- Name: oguncontours oguncontours_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY oguncontours
    ADD CONSTRAINT oguncontours_pkey PRIMARY KEY (gid);


--
-- Name: ogungazzette ogungazzette_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogungazzette
    ADD CONSTRAINT ogungazzette_pkey PRIMARY KEY (gid);


--
-- Name: ogunpoi ogunpoi_pkey1; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunpoi
    ADD CONSTRAINT ogunpoi_pkey1 PRIMARY KEY (gid);


--
-- Name: ogunrailnetwork ogunrailnetwork_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunrailnetwork
    ADD CONSTRAINT ogunrailnetwork_pkey PRIMARY KEY (gid);


--
-- Name: ogunriver_polygon ogunriver_polygon_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunriver_polygon
    ADD CONSTRAINT ogunriver_polygon_pkey PRIMARY KEY (gid);


--
-- Name: ogunroadnetwork_old ogunroadnetwork_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunroadnetwork_old
    ADD CONSTRAINT ogunroadnetwork_pkey PRIMARY KEY (gid);


--
-- Name: ogunroadnetwork ogunroadnetwork_pkey1; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunroadnetwork
    ADD CONSTRAINT ogunroadnetwork_pkey1 PRIMARY KEY (gid);


--
-- Name: ogunwater ogunwater_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunwater
    ADD CONSTRAINT ogunwater_pkey PRIMARY KEY (gid);


--
-- Name: olokemeji_reserve olokemeji_reserve_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY olokemeji_reserve
    ADD CONSTRAINT olokemeji_reserve_pkey PRIMARY KEY (gid);


--
-- Name: oneway one_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY oneway
    ADD CONSTRAINT one_key PRIMARY KEY (code);


--
-- Name: parcel_def parcel_def_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_def
    ADD CONSTRAINT parcel_def_pkey PRIMARY KEY (id);


--
-- Name: parcel_lookup parcel_lookup_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_pkey PRIMARY KEY (parcel_id);


--
-- Name: settlement_type pk_stt; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY settlement_type
    ADD CONSTRAINT pk_stt PRIMARY KEY (sn);


--
-- Name: poi poi_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY poi
    ADD CONSTRAINT poi_pkey PRIMARY KEY (gid);


--
-- Name: pois pois_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY pois
    ADD CONSTRAINT pois_pkey PRIMARY KEY (id);


--
-- Name: pop_figures pop_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY pop_figures
    ADD CONSTRAINT pop_key PRIMARY KEY (pop_id);


--
-- Name: pop_year popsn; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY pop_year
    ADD CONSTRAINT popsn PRIMARY KEY (pop_sn);


--
-- Name: prop_types prop_type_code_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY prop_types
    ADD CONSTRAINT prop_type_code_key UNIQUE (code);


--
-- Name: prop_types prop_type_id_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY prop_types
    ADD CONSTRAINT prop_type_id_key UNIQUE (prop_type_name);


--
-- Name: prop_types prop_type_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY prop_types
    ADD CONSTRAINT prop_type_pkey PRIMARY KEY (id);


--
-- Name: road_code rdkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY road_code
    ADD CONSTRAINT rdkey PRIMARY KEY (code_id);


--
-- Name: roadclass road_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY roadclass
    ADD CONSTRAINT road_key PRIMARY KEY (code);


--
-- Name: schemes schemes_id_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY schemes
    ADD CONSTRAINT schemes_id_key UNIQUE (scheme_name);


--
-- Name: schemes schemes_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY schemes
    ADD CONSTRAINT schemes_pkey PRIMARY KEY (id);


--
-- Name: security_agencies security_agencies_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY security_agencies
    ADD CONSTRAINT security_agencies_pkey PRIMARY KEY (gid);


--
-- Name: sen_districts sen_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY sen_districts
    ADD CONSTRAINT sen_key PRIMARY KEY (sen_code);


--
-- Name: developed_area settlements_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY developed_area
    ADD CONSTRAINT settlements_pkey PRIMARY KEY (gid);


--
-- Name: speed speed_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY speed
    ADD CONSTRAINT speed_key PRIMARY KEY (code);


--
-- Name: status_cat status_cat_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY status_cat
    ADD CONSTRAINT status_cat_pkey PRIMARY KEY (status_cat);


--
-- Name: roadstatus status_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY roadstatus
    ADD CONSTRAINT status_key PRIMARY KEY (code);


--
-- Name: streetname stk_ey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY streetname
    ADD CONSTRAINT stk_ey PRIMARY KEY (st_id);


--
-- Name: str_type str_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY str_type
    ADD CONSTRAINT str_key PRIMARY KEY (strid);


--
-- Name: street_centreline street_centreline_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY street_centreline
    ADD CONSTRAINT street_centreline_pkey PRIMARY KEY (gid);


--
-- Name: survey survey_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_pkey PRIMARY KEY (id);


--
-- Name: survey survey_plan_no_key; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_plan_no_key UNIQUE (plan_no);


--
-- Name: survey survey_plan_no_key1; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_plan_no_key1 UNIQUE (plan_no);


--
-- Name: the_ogunroadnetwork the_ogunroadnetwork_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY the_ogunroadnetwork
    ADD CONSTRAINT the_ogunroadnetwork_pkey PRIMARY KEY (id);


--
-- Name: theogunrivernetwork theogunrivernetwork_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY theogunrivernetwork
    ADD CONSTRAINT theogunrivernetwork_pkey PRIMARY KEY (gid);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: medical_master_data unik; Type: CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY medical_master_data
    ADD CONSTRAINT unik UNIQUE (med_fac);


--
-- Name: arakanga_reserve_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX arakanga_reserve_geom_gist ON arakanga_reserve USING gist (geom);


--
-- Name: beacons_beacon_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX beacons_beacon_idx ON beacons USING btree (beacon);


--
-- Name: beardist_beacon_from_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX beardist_beacon_from_idx ON beardist USING btree (beacon_from);


--
-- Name: beardist_beacon_to_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX beardist_beacon_to_idx ON beardist USING btree (beacon_to);


--
-- Name: beardist_ndx1; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX beardist_ndx1 ON beardist USING btree (beacon_from);


--
-- Name: beardist_plan_no_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX beardist_plan_no_idx ON beardist USING btree (plan_no);


--
-- Name: billboards_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX billboards_geom_gist ON billboards USING gist (the_geom);


--
-- Name: education_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX education_geom_gist ON education USING gist (the_geom);


--
-- Name: fki_conflicts_conflict_fkey; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX fki_conflicts_conflict_fkey ON conflicts USING btree (conflict);


--
-- Name: fki_conflicts_transaction_fkey; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX fki_conflicts_transaction_fkey ON conflicts USING btree (transaction);


--
-- Name: fki_parcel_lookup_status_cat_fkey; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX fki_parcel_lookup_status_cat_fkey ON parcel_lookup USING btree (status);


--
-- Name: fki_transactions_instrument_fkey; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX fki_transactions_instrument_fkey ON transactions USING btree (instrument);


--
-- Name: fki_transactions_parcel_fkey; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX fki_transactions_parcel_fkey ON transactions USING btree (parcel_id);


--
-- Name: fki_transactions_survey_fkey; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX fki_transactions_survey_fkey ON transactions USING btree (survey);


--
-- Name: geologyogun_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX geologyogun_geom_gist ON geologyogun USING gist (the_geom);


--
-- Name: hist_beacons_idx1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX hist_beacons_idx1 ON hist_beacons USING btree (gid);


--
-- Name: hist_beacons_idx2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX hist_beacons_idx2 ON hist_beacons USING btree (hist_time);


--
-- Name: idp_beacons_intersect; Type: INDEX; Schema: public; Owner: docker
--

CREATE UNIQUE INDEX idp_beacons_intersect ON beacons_intersect USING btree (beacon);


--
-- Name: idp_beacons_mtview; Type: INDEX; Schema: public; Owner: docker
--

CREATE UNIQUE INDEX idp_beacons_mtview ON beacons_views USING btree (gid);


--
-- Name: idp_parcel_overlap_matviews; Type: INDEX; Schema: public; Owner: docker
--

CREATE UNIQUE INDEX idp_parcel_overlap_matviews ON parcel_overlap_matviews USING btree (parcel_id);


--
-- Name: idp_parcels_intersect; Type: INDEX; Schema: public; Owner: docker
--

CREATE UNIQUE INDEX idp_parcels_intersect ON parcels_intersect USING btree (parcel_id);


--
-- Name: idp_pois_view; Type: INDEX; Schema: public; Owner: docker
--

CREATE UNIQUE INDEX idp_pois_view ON pois_view USING btree (id);


--
-- Name: idx_beacons_intersect_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX idx_beacons_intersect_geom ON beacons_intersect USING gist (the_geom);


--
-- Name: idx_beacons_matviews_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX idx_beacons_matviews_geom ON beacons_views USING gist (the_geom);


--
-- Name: idx_parcels_intersects_new_matviews_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX idx_parcels_intersects_new_matviews_geom ON parcels_intersect USING gist (the_geom);


--
-- Name: ilaro_reserve_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX ilaro_reserve_geom_gist ON ilaro_reserve USING gist (geom);


--
-- Name: jobs_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX jobs_idx ON jobs USING btree (userid);


--
-- Name: jobs_idx1; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX jobs_idx1 ON jobs USING btree (created);


--
-- Name: jobs_idx2; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX jobs_idx2 ON jobs USING btree (done);


--
-- Name: ndx_applicants1; Type: INDEX; Schema: public; Owner: docker
--

CREATE UNIQUE INDEX ndx_applicants1 ON applicants USING btree (name);


--
-- Name: ndx_schemes1; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX ndx_schemes1 ON schemes USING gin (to_tsvector('english'::regconfig, (COALESCE(scheme_name, ''::character varying))::text));


--
-- Name: ogun_25m_contour_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX ogun_25m_contour_geom_gist ON ogun_25m_contour USING gist (the_geom);


--
-- Name: oguncontours_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX oguncontours_geom_gist ON oguncontours USING gist (the_geom);


--
-- Name: ogunpoi_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX ogunpoi_geom_gist ON ogunpoi USING gist (the_geom);


--
-- Name: ogunrailnetwork_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX ogunrailnetwork_geom_gist ON ogunrailnetwork USING gist (the_geom);


--
-- Name: ogunroadnetwork_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX ogunroadnetwork_geom_gist ON ogunroadnetwork USING gist (the_geom);


--
-- Name: ogunroadnetwork_geom_gistt; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX ogunroadnetwork_geom_gistt ON ogunroadnetwork_old USING gist (the_geom);


--
-- Name: olokemeji_reserve_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX olokemeji_reserve_geom_gist ON olokemeji_reserve USING gist (geom);


--
-- Name: parcel_over_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX parcel_over_idx ON parcel_overlap_matviews USING gist (the_geom);


--
-- Name: pois_over_idx; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX pois_over_idx ON pois_view USING gist (geom);


--
-- Name: precious_minerals_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX precious_minerals_geom_gist ON precious_minerals USING gist (the_geom);


--
-- Name: settlements_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX settlements_geom_gist ON developed_area USING gist (the_geom);


--
-- Name: sidx_beacons_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX sidx_beacons_geom ON beacons USING gist (the_geom);


--
-- Name: sidx_pois_geom; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX sidx_pois_geom ON pois USING gist (the_geom);


--
-- Name: theogunrivernetwork_geom_gist; Type: INDEX; Schema: public; Owner: docker
--

CREATE INDEX theogunrivernetwork_geom_gist ON theogunrivernetwork USING gist (the_geom);


--
-- Name: parcels beacons_intersect_parcels_ref_row; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER beacons_intersect_parcels_ref_row AFTER INSERT OR DELETE OR UPDATE ON parcels FOR EACH STATEMENT EXECUTE PROCEDURE refresh_beacons_intersect_view();


--
-- Name: beacons insert_nodes_geom; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER insert_nodes_geom BEFORE INSERT OR UPDATE ON beacons FOR EACH ROW EXECUTE PROCEDURE calc_point();


--
-- Name: nirboundaries insert_nodes_geom; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER insert_nodes_geom BEFORE INSERT OR UPDATE ON nirboundaries FOR EACH ROW EXECUTE PROCEDURE calc_point();


--
-- Name: jobs jobs_tr; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER jobs_tr BEFORE INSERT OR UPDATE ON jobs FOR EACH ROW EXECUTE PROCEDURE fn_updateprintjobs();


--
-- Name: lut_poi_cat lut_poi_cat_view_ref_row; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER lut_poi_cat_view_ref_row AFTER INSERT OR DELETE OR UPDATE ON lut_poi_cat FOR EACH STATEMENT EXECUTE PROCEDURE pois_view_mat_view();


--
-- Name: parcel_def parcel_lookup_define_parcel; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER parcel_lookup_define_parcel BEFORE INSERT OR UPDATE ON parcel_def FOR EACH ROW EXECUTE PROCEDURE parcel_lookup_define_parcel_trigger();


--
-- Name: parcels parcel_overlap_matview_ref_row; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER parcel_overlap_matview_ref_row AFTER INSERT OR DELETE OR UPDATE ON parcels FOR EACH STATEMENT EXECUTE PROCEDURE parcel_overlap_mat_view();


--
-- Name: parcels parcels_intersect_view; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER parcels_intersect_view AFTER INSERT OR DELETE OR UPDATE ON parcels FOR EACH STATEMENT EXECUTE PROCEDURE refresh_mat_view();


--
-- Name: beacons perimeters_beacons_ref_row; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER perimeters_beacons_ref_row AFTER INSERT OR DELETE OR UPDATE ON beacons FOR EACH STATEMENT EXECUTE PROCEDURE beacons_views_mat_view();


--
-- Name: perimeters perimeters_overlap_matview_ref_row; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER perimeters_overlap_matview_ref_row AFTER INSERT OR DELETE OR UPDATE ON perimeters FOR EACH STATEMENT EXECUTE PROCEDURE parcel_overlap_mat_view();


--
-- Name: parcel_def perimeters_parcel_def_ref_row; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER perimeters_parcel_def_ref_row AFTER INSERT OR DELETE OR UPDATE ON parcel_def FOR EACH STATEMENT EXECUTE PROCEDURE beacons_views_mat_view();


--
-- Name: parcel_lookup perimeters_parcel_lookup_ref_row; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER perimeters_parcel_lookup_ref_row AFTER INSERT OR DELETE OR UPDATE ON parcel_lookup FOR EACH STATEMENT EXECUTE PROCEDURE beacons_views_mat_view();


--
-- Name: pois pois_view_ref_row; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER pois_view_ref_row AFTER INSERT OR DELETE OR UPDATE ON pois FOR EACH STATEMENT EXECUTE PROCEDURE pois_view_mat_view();


--
-- Name: beacons trg_beacons_after_insert; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER trg_beacons_after_insert AFTER INSERT ON beacons FOR EACH ROW EXECUTE PROCEDURE fn_beacons_after_insert();


--
-- Name: beacons trg_beacons_before_delete; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER trg_beacons_before_delete BEFORE DELETE ON beacons FOR EACH ROW EXECUTE PROCEDURE fn_beacons_before_delete();


--
-- Name: beacons trg_beacons_before_update; Type: TRIGGER; Schema: public; Owner: docker
--

CREATE TRIGGER trg_beacons_before_update BEFORE UPDATE ON beacons FOR EACH ROW EXECUTE PROCEDURE fn_beacons_before_update();


--
-- Name: beardist beardist_beacon_from_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_from_fkey FOREIGN KEY (beacon_from) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_beacon_from_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_from_fkey1 FOREIGN KEY (beacon_from) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_beacon_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_to_fkey FOREIGN KEY (beacon_to) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_beacon_to_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_beacon_to_fkey1 FOREIGN KEY (beacon_to) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_plan_no_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_plan_no_fkey FOREIGN KEY (plan_no) REFERENCES survey(plan_no) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beardist beardist_plan_no_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY beardist
    ADD CONSTRAINT beardist_plan_no_fkey1 FOREIGN KEY (plan_no) REFERENCES survey(plan_no) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: conflicts conflicts_conflict_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY conflicts
    ADD CONSTRAINT conflicts_conflict_fkey FOREIGN KEY (conflict) REFERENCES conflict_cat(conflict_cat);


--
-- Name: conflicts conflicts_transaction_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY conflicts
    ADD CONSTRAINT conflicts_transaction_fkey FOREIGN KEY (transaction) REFERENCES transactions(id);


--
-- Name: pop_figures frgn_key; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY pop_figures
    ADD CONSTRAINT frgn_key FOREIGN KEY (lga_code) REFERENCES ogunadmin(gid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ogunadmin hq_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY ogunadmin
    ADD CONSTRAINT hq_fkey FOREIGN KEY (lg_hq) REFERENCES lg_hqtrs(hq_code);


--
-- Name: mines_database mine_fk; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY mines_database
    ADD CONSTRAINT mine_fk FOREIGN KEY (mine_operator) REFERENCES mine_operator(operator_sn) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_def parcel_def_beacon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_def
    ADD CONSTRAINT parcel_def_beacon_fkey FOREIGN KEY (beacon) REFERENCES beacons(beacon) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_def parcel_def_parcel_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_def
    ADD CONSTRAINT parcel_def_parcel_id_fkey FOREIGN KEY (parcel_id) REFERENCES parcel_lookup(parcel_id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_allocation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_allocation_id_fkey FOREIGN KEY (allocation) REFERENCES allocation_cat(allocation_cat) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_local_govt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_local_govt_id_fkey FOREIGN KEY (local_govt) REFERENCES local_govt(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_prop_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_prop_type_id_fkey FOREIGN KEY (prop_type) REFERENCES prop_types(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_scheme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_scheme_id_fkey FOREIGN KEY (scheme) REFERENCES schemes(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: parcel_lookup parcel_lookup_status_cat_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY parcel_lookup
    ADD CONSTRAINT parcel_lookup_status_cat_fkey FOREIGN KEY (status) REFERENCES status_cat(status_cat);


--
-- Name: survey survey_ref_beacon_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_ref_beacon_fkey FOREIGN KEY (ref_beacon) REFERENCES beacons(beacon);


--
-- Name: survey survey_scheme_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY survey
    ADD CONSTRAINT survey_scheme_fkey FOREIGN KEY (scheme) REFERENCES schemes(id);


--
-- Name: transactions transactions_instrument_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_instrument_fkey FOREIGN KEY (instrument) REFERENCES instrument_cat(instrument_cat);


--
-- Name: transactions transactions_parcel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_parcel_fkey FOREIGN KEY (parcel_id) REFERENCES parcel_lookup(parcel_id);


--
-- Name: transactions transactions_survey_fkey; Type: FK CONSTRAINT; Schema: public; Owner: docker
--

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_survey_fkey FOREIGN KEY (survey) REFERENCES survey(id);


--
-- PostgreSQL database dump complete
--

