INSERT INTO beacons(beacon, y, x, location, name)
VALUES ('MB1416',735460.877,488470.404,'East','Test');

INSERT INTO beacons (x,y,beacon) VALUES (488444.861,735443.135, 'MB1417');
INSERT INTO beacons (x,y,beacon) VALUES (488440.719,735456.299, 'MB1418');
INSERT INTO beacons (x,y,beacon) VALUES (488458.679,735472.068, 'MB1419');

INSERT INTO instrument_cat(description) 
VALUES('Deed of Assignment'),('Certificate Of Occupancy'),('Deed of Conveyance');

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




