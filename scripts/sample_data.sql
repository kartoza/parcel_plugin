INSERT INTO beacons(beacon, y, x, location, name)
VALUES ('MB1416',735460.877,488470.404,'East','Test');


INSERT INTO allocation_cat(description) 
VALUES ('free and unallocated parcel'),('temporary allocation pending approval'),
('parcel allocated and approved'),('Private Survey pending approval'),('Private Survey approved');

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

INSERT INTO public.parcel_lookup(plot_sn, available, scheme, block, local_govt, prop_type, file_number, 
allocation, manual_no, deeds_file,official_area, private, status)  
VALUES ('1', true, 1, '0', 1, 1, 'HOC/PL/123', 1, '0', '', 680.510999999999967, true, 1);


