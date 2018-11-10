require_relative 'db_connection'
require 'active_support/inflector'
# require_relative "02_searchable"
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.
require "byebug"


class SQLObject

  # include Searchable

  def self.columns
    # ...
    unless @columns
      data = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      SQL

      @columns = []
      data.first.each { |col| @columns << col.to_sym }
    end
    
    @columns

  end

  def self.finalize!

    columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end
      define_method("#{col}=") do |val|
        self.attributes[col] = val
      end
    end

  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name ||= "#{self}".tableize
    

  end

  def self.all
    result = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
    parse_all(result)
  end

  def self.parse_all(results)
    # ...
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      id = #{id}
    SQL
    return nil if result.empty?
    self.new(result.first)
  end

  def initialize(params = {})
    self.class.finalize!
    params.each do |col, val|
      col = col.to_sym
      raise "unknown attribute '#{col}'" unless self.class.columns.include?(col)
      send("#{col}=", val)
    end
  end

  def attributes
    # ...
    @attributes ||= {}


  end

  def attribute_values
    self.class.columns.map { |attr| send(attr) }
  end

  def insert
    num_of_questionmarks = (["?"] * self.class.columns.length).join(",")

    attrs = attribute_values
    
    DBConnection.execute(<<-SQL, *attrs)
    INSERT INTO
      #{self.class.table_name} (#{self.class.columns.join(",")})
    VALUES
      (#{num_of_questionmarks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.columns.map { |col| "#{col} = ?" }
    set_line = set_line.join(", ")

    attrs = attribute_values

    DBConnection.execute(<<-SQL, *attrs)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      id = #{self.id}
    SQL
  end

  def save
    if self.id == nil
      self.insert
    else
      self.update
    end

  end
end
