CREATE TABLE buildings (
  id serial PRIMARY KEY,
  name text NOT NULL UNIQUE
);

CREATE TABLE apartments (
  id serial PRIMARY KEY,
  name text NOT NULL,
  bed integer NOT NULL,
  bath integer NOT NULL,
  sq_ft text NOT NULL,
  price text NOT NULL,
  building_id integer NOT NULL REFERENCES buildings(id)
);

INSERT INTO buildings (name)
VALUES ('ARO'),
  ('8 Spruce'),
  ('111 Murray'),
  ('Central Park Tower'),
  ('19 Dutch');

INSERT INTO apartments (name, bed, bath, sq_ft, price, building_id)
VALUES ('39A', 2, 2, '850', '7,550', 1),
  ('54F', 1, 1, '654', '6,195', 1),
  ('30E', 2, 2, '890', '7,250', 1),
  ('15J', 1, 1, '690', '4,825', 1),
  ('60D', 2, 2, '1,116', '8,995', 1);

INSERT INTO apartments (name, bed, bath, sq_ft, price, building_id)
VALUES ('48J', 1, 1, '796', '6,765', 2),
  ('36T', 2, 2, '971', '7,495', 2),
  ('64C', 2, 2, '1,051', '8,600', 2);

INSERT INTO apartments (name, bed, bath, sq_ft, price, building_id)
VALUES ('48W', 4, 5.5, '3,228', '39,500', 3);

INSERT INTO apartments (name, bed, bath, sq_ft, price, building_id)
VALUES ('46E', 1, 1, '678', '5,733', 5),
  ('23I', 1, 1, '778', '5,967', 5),
  ('35B', 1, 1, '737', '5,534', 5),
  ('57G', 1, 1, '758', '7,357', 5),
  ('21B', 0, 1, '514', '4,433', 5),
  ('41A', 1, 1, '657', '6,816', 5),
  ('19D', 0, 1, '443', '3,579', 5),
  ('49B', 1, 1, '748', '6,092', 5);