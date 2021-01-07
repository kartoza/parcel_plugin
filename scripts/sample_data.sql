-- Insert Reference beacon
INSERT INTO beacons(beacon, y, x, location, name)
VALUES ('MB1416',735460.877,488470.404,'East','Test');

-- Insert other beacons - This is optional but good for a quick demo

--INSERT INTO beacons (x,y,beacon) VALUES (488444.861,735443.135, 'MB1417');
--INSERT INTO beacons (x,y,beacon) VALUES (488440.719,735456.299, 'MB1418');
--INSERT INTO beacons (x,y,beacon) VALUES (488458.679,735472.068, 'MB1419');

-- Populate other tables as needed
INSERT INTO instrument_cat(description) 
VALUES('Deed of Assignment'),('Certificate Of Occupancy'),('Deed of Conveyance');

INSERT INTO public.allocation_cat(description, allocation_cat)
	VALUES ('Allocation Test', 1);

INSERT INTO local_govt( local_govt_name) 
VALUES ('Test province');

INSERT INTO status_cat(description) 
VALUES ('application'),('approved'),('rejected');

INSERT INTO prop_types(code, prop_type_name) 
VALUES ('AR','Allocation Residential'),('AC','Allocation Commercial');

INSERT INTO schemes(scheme_name) VALUES ('Garage');

INSERT INTO deeds(fileno, planno, instrument, grantor, grantee, block, plot, location)
VALUES ('IF SLR184','BC5 OG','COFO','OGSG','Olawale Olusoga Olubi',38,23,'RIVERVIEW');

INSERT INTO survey(plan_no, ref_beacon, scheme)
VALUES ('BC5 OG', 'MB1416', 1);

-- Insert records into parcel lookup to help with the parcel lookup table
INSERT INTO parcel_lookup(
	plot_sn, available, scheme, block, local_govt, prop_type, file_number, allocation, manual_no, deeds_file, official_area, private, status)
	VALUES ('AS 454', 'true', 1, 'AD243', 1, 2, 'FID123', 1, 'GIS123', 'STA123', 100, 'true',1);




