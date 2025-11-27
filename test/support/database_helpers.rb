module DatabaseHelpers
  def truncate_all_tables
    # Get all table names except schema_migrations and ar_internal_metadata
    tables = ActiveRecord::Base.connection.tables - ["schema_migrations", "ar_internal_metadata", "solid_queue_semaphores"]

    # Disable foreign key checks and truncate all tables
    ActiveRecord::Base.connection.execute("SET session_replication_role = 'replica';") if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"

    # Batch truncate for better performance
    if tables.any?
      table_list = tables.map { |t| ActiveRecord::Base.connection.quote_table_name(t) }.join(", ")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_list} CASCADE")
    end

    ActiveRecord::Base.connection.execute("SET session_replication_role = 'origin';") if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
  end

  def without_fixtures
    # Temporarily disable fixtures for this test
    old_fixture_table_names = self.class.fixture_table_names
    self.class.fixture_table_names = []
    yield
  ensure
    self.class.fixture_table_names = old_fixture_table_names
  end
end
