DELETE FROM parcel_lookup WHERE parcel_id LIKE 'test%';
DELETE FROM parcel_def WHERE parcel_id LIKE 'test%';

INSERT INTO parcel_lookup(parcel_id) VALUES('tmp');
INSERT INTO parcel_def(parcel_id, beacon, "sequence")
VALUES('tmp', 'PBA86801', 1);
INSERT INTO parcel_def(parcel_id, beacon, "sequence")
VALUES('tmp', 'PBA86802', 2);
INSERT INTO parcel_def(parcel_id, beacon, "sequence")
VALUES('tmp', 'PBA86803', 3);
INSERT INTO parcel_def(parcel_id, beacon, "sequence")
VALUES('tmp', 'PBA86804', 4);

