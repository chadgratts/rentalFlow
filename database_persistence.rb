require "pg"

class DatabasePersistence
  BUILDINGS_PER_PAGE = 5
  APARTMENTS_PER_PAGE = 5

  def initialize(logger)
    @db = PG.connect(dbname: "apartment_rental_manager")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def building(building_id, params)
    sql = "SELECT * FROM buildings WHERE id = $1"
    result = query(sql, building_id)
    return nil if result.first.nil?
    name = result.first["name"]
    id = result.first["id"]

    { id: id, name: name, apartments: apartments(building_id, params) }
  end

  def apartment(building_id, apartment_id)
    sql = "SELECT * FROM apartments WHERE id = $1 AND building_id = $2"
    result = query(sql, apartment_id, building_id)
    return nil if result.first.nil?
    
    tuple = result.first
    { id: tuple["id"],
      name: tuple["name"],
      bed: tuple["bed"],
      bath: tuple["bath"],
      sq_ft: tuple["sq_ft"],
      price: tuple["price"],
      building_id: tuple["building_id"] }
  end

  def query_all_buildings(page)
    <<~SQL
      SELECT * FROM buildings
      ORDER BY name
      LIMIT #{BUILDINGS_PER_PAGE}
      OFFSET #{BUILDINGS_PER_PAGE * page}
    SQL
  end

  def all_buildings(params)
    page = load_page_number(params)
    sql = query_all_buildings(page)
    result = query(sql)

    result.map do |building_tuple|
      id = building_tuple["id"].to_i
      name = building_tuple["name"]
      { id: id, name: name, apartments: [] }
    end
  end

  def load_page_number(params)
    page = params.fetch(:page, 0).to_i
    page < 1 ? 0 : page
  end

  def query_apartments(page)
    <<~SQL
      SELECT * FROM apartments WHERE building_id = $1
      ORDER BY name
      LIMIT #{APARTMENTS_PER_PAGE}
      OFFSET #{APARTMENTS_PER_PAGE * page}
    SQL
  end

  def apartments(building_id, params)
    page = load_page_number(params)
    sql = query_apartments(page)
    result = query(sql, building_id)

    result.map do |tuple|
      { id: tuple["id"],
        name: tuple["name"],
        bed: tuple["bed"],
        bath: tuple["bath"],
        sq_ft: tuple["sq_ft"],
        price: tuple["price"],
        building_id: tuple["building_id"] }
    end
  end

  def add_new_building(new_name)
    sql = "INSERT INTO buildings (name) VALUES ($1)"
    query(sql, new_name)
  end

  def delete_building(id)
    query("DELETE FROM apartments WHERE building_id = $1", id)
    query("DELETE FROM buildings WHERE id = $1", id)
  end

  def update_building_name(id, new_building_name)
    sql = "UPDATE buildings SET name = $1 WHERE id = $2"
    query(sql, new_building_name, id)
  end

  def add_new_apartment(building_id, features)
    name, bed, bath, sq_ft, price = features
    sql = <<~SQL
      INSERT INTO apartments (name, bed, bath, sq_ft, price, building_id)
      VALUES ($1, $2, $3, $4, $5, $6)
    SQL
    query(sql, name, bed, bath, sq_ft, price, building_id)
  end

  def delete_apartment(building_id, apartment_id)
    sql = "DELETE FROM apartments WHERE building_id = $1 AND id = $2"
    query(sql, building_id, apartment_id)
  end

  def update_apartment_features(building_id, apartment_id, features)
    name, bed, bath, sq_ft, price = features
    sql = <<~SQL
      UPDATE apartments
      SET name = $1, bed = $2, bath = $3, sq_ft = $4, price = $5
      WHERE building_id = $6 AND id = $7
    SQL
    query(sql, name, bed, bath, sq_ft, price, building_id, apartment_id)
  end
end