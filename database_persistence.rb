require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "contacts")
    setup_schema
    @logger = logger
  end

# Parses contact info into a hash
  def parse_contact(result)
      result.map do |tuple|
      contact_id = tuple["id"].to_i

      {id: contact_id, 
      first_name: tuple["first_name"], 
      last_name: tuple["last_name"],
      email: tuple["email"],
      phone: tuple["phone"],
      category: tuple["category"]
    }
    end
  end

# checks if table exists, creates it if it doesn't exist
# Might change category data type to only have category options but it is redundent 
  def setup_schema
    result = @db.exec <<~SQL
    SELECT EXISTS ( SELECT 1 FROM pg_tables WHERE tablename = 'contacts' ) AS table_existence;
    SQL

    if result.first["table_existence"] == "f"
      @db.exec <<~SQL
      CREATE TABLE contacts (
        id serial PRIMARY KEY,
        first_name varchar(50) NOT NULL,
        last_name varchar(50) NOT NULL,
        email varchar(75) NOT NULL,
        phone text NOT NULL CHECK (LENGTH(phone) BETWEEN 8 AND 12),
        category text
        );
      SQL
    end
  end

# Gathers all contacts
  def all_contacts
    sql = "SELECT * FROM contacts"
    result = query(sql)

    parse_contact(result)
  end

# Gathers Single Contact
  def single_contact(id)
    sql = "SELECT * FROM contacts WHERE id = $1"
    result = query(sql, id)
    
    parse_contact(result)[0]
  end

# Creates new contact
  def add_contact(contact_info)
    sql = "INSERT INTO contacts (first_name, last_name, email, phone, category) VALUES ($1, $2, $3, $4, $5)"
    query(sql, contact_info[:first_name], contact_info[:last_name], contact_info[:email], contact_info[:phone], contact_info[:category])
  end

# Updates contact information. Likely a better way to do this. Maybe interation
  def update_single_contact(id, contact_info)
    query("UPDATE contacts SET first_name = $1 WHERE id = $2", contact_info[:first_name], id)
    query("UPDATE contacts SET last_name = $1 WHERE id = $2", contact_info[:last_name], id)
    query("UPDATE contacts SET email = $1 WHERE id = $2", contact_info[:email], id)
    query("UPDATE contacts SET phone = $1 WHERE id = $2", contact_info[:phone], id)
    query("UPDATE contacts SET category = $1 WHERE id = $2", contact_info[:category], id)
  end

# Deletes Contact
  def delete_contact(id)
    sql = "DELETE FROM contacts WHERE id = $1"
    query(sql, id)
  end

# Does PSQL queries
  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end
end