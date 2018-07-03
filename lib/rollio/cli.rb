require 'thor'
require 'rollio'
module Rollio
  class CLI < Thor
    option(
      :source,
      aliases: '-s',
      required: true,
      default: File.join(ENV['HOME'], '.rollio'),
      desc: "The <source> directory for tables to load into rollio"
    )
    def initialize(*args)
      super
      register!
    end

    desc "list", "List the registered tables"
    long_desc <<-LONGDESC
      `rollio list` will print out a list of all registered tables
    LONGDESC
    option(
      :delimiter,
      aliases: '-d',
      desc: "The <delimiter> used to separate the table entries"
    )
    option(:help, aliases: '-h')
    def list
      help(__method__) and return if options[:help]
      $stdout.puts @registry.table_names.join(options.fetch(:delimiter, "\n"))
    end

    desc "audit", "Audit the tables in <source> to ensure validity"
    option(:help, aliases: '-h')
    def audit
    end

    desc "roll <table>", "Roll on the given table"
    option(:help, aliases: '-h')
    def roll(table)
      help(__method__) and return if options[:help]
      $stdout.puts @registry.roll_on(table)
    end

    desc "render", "Render the stored tables"
    option(:help, aliases: '-h')
    def render
      help(__method__) and return if options[:help]
      $stdout.puts @registry.render
    end

    private

    def register!
      @registry = Rollio.load
      Dir.glob("#{options[:source]}/**/*.json").each do |filename|
        tables = JSON.parse(File.read(filename))
        tables = [tables] unless tables.is_a?(Array)
        tables.each do |table|
          data = Hanami::Utils::Hash.deep_symbolize(table)
          Rollio.load_a_table(registry: @registry, data: data)
        end
      end
    end
  end
end
