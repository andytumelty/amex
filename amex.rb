require 'watir'
require 'highline/import'
require 'yaml'
require 'date'
require 'ap'

def credential_load
  config = File.expand_path("~/.amex.yaml")

  if File.exists?(config)
    if File.world_readable?(config) or not File.owned?(config)
      mode = File.stat(config).mode.to_s(8)
      $stderr.puts "#{config}: Insecure permissions: #{mode}"
    end
  end

  credentials = YAML.load(File.read(config)) rescue {}

  ['username', 'password'].each do |credential|
    key = credential.tr(' ','_').downcase.to_sym
    next if credentials.key?(key)
    unless $stdin.tty? and $stdout.tty?
      $stderr.puts "Can't prompt for credentials; STDIN or STDOUT is not a TTY"
      exit(1)
    end
    credentials[key] = ask("Please enter your #{credential}:") do |q|
      q.echo = "*"
    end
  end

  return credentials
end

class Amex
  def initialize
    @ua = Watir::Browser.start("https://www.americanexpress.com/uk")
  end

  def close
    @ua.close
  end
  
  def login(credentials)
    @ua.text_field(name: "UserID").set(credentials[:username])
    @ua.text_field(name: "Password").set(credentials[:password])
    @ua.form(id: 'ssoform').submit
  end

  def transactions(start_date, end_date, account)
    @ua.link(text: "Your Statement").click
    @ua.link(id: "date-layer-link").click
    @ua.link(text: "Date range").click
    #puts "from: #{start_date}"
    @ua.div(id: "from-datepicker").select_list(class: "ui-datepicker-year").select(Date.parse(start_date).strftime("%Y"))
    @ua.div(id: "from-datepicker").select_list(class: "ui-datepicker-month").select_value(Date.parse(start_date).strftime("%-m").to_i - 1)
    @ua.div(id: "from-datepicker").link(text: Date.parse(start_date).strftime("%-d")).click
    #puts "to: #{end_date}"
    @ua.div(id: "to-datepicker").select_list(class: "ui-datepicker-year").select(Date.parse(end_date).strftime("%Y"))
    @ua.div(id: "to-datepicker").select_list(class: "ui-datepicker-month").select_value(Date.parse(end_date).strftime("%-m").to_i - 1)
    @ua.div(id: "to-datepicker").link(text: Date.parse(end_date).strftime("%-d")).click

    @ua.link(id: "date-go-button").click

    cp = @ua.div(id: "statement-data-table_info").text
    prev_cp = ''
    text = []

    until prev_cp == cp
      text += @ua.table(id: "statement-data-table").tbody.text.split(/\n/)
      #ap @ua.link(id: "statement-data-table_next").methods
      if @ua.link(id: "statement-data-table_next").visible?
        @ua.link(id: "statement-data-table_next").click
      end
      prev_cp = cp
      cp = @ua.div(id: "statement-data-table_info").text
    end

    i = 0
    transactions = []
    while i*3 < text.size do
      transaction = {}
      transaction[:date] = Date.parse(text[i*3])
      transaction[:description] = text[i*3 + 1]
      # TODO parse different currencies
      transaction[:amount] = text[i*3 + 2].split(/ /).last.tr('£','').to_f
      transactions << transaction
      i = i + 1
    end

    return transactions
  end
end


credentials = credential_load

Amex.new.tap do |am| 
  begin
    am.login(credentials)
    # TODO make account selection actually do something
    # TODO quick summary
    # TODO document and usage
    transactions = am.transactions(ARGV[0], ARGV[1], ARGV[2])
    ap transactions
    ap transactions.count
  ensure
    am.close
  end
end
