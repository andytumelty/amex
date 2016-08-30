require 'watir'
require 'date'
require 'headless'

class Amex
  def initialize
    @headless = Headless.new
    @headless.start
    @ua = Watir::Browser.new()
    @ua.goto("https://www.americanexpress.com/uk")
  end

  def close
    @ua.close
    @headless.destroy
  end

  def login(credentials)
    if @ua.button(id: "sprite-ContinueButton_EN").exists?
      if @ua.button(id: "sprite-ContinueButton_EN").visible?
        @ua.button(id: "sprite-ContinueButton_EN").click
      end
    end
    @ua.text_field(name: "UserID").set(credentials[:username])
    @ua.text_field(name: "Password").set(credentials[:password])
    @ua.form(id: 'ssoform').submit
  end

  def transactions(start_date, end_date, account)
    @ua.link(text: "Your Statement").click

    # TODO: more reliable way of doing this?
    sleep 2

    if @ua.span(class: "interstitial-message").visible?
      @ua.link(class: "close-interstitial").click
    end

    @ua.div(id: "daterange").click
    @ua.div(title: "Select start and end dates").click

    [start_date, end_date].each do |date|
      @ua.th(class: "months").button().click
      while @ua.strong(class: "uib").text.to_i > Date.parse(date).year
        # max clicks?
        @ua.button(class: "pull-left").click
      end
      @ua.button(title: Date.parse(date).strftime("%B")).click
      @ua.span(text: Date.parse(date).strftime("%d")).click
    end

    @ua.button(class: "action_button").click

    if @ua.button(title: "Show more transactions").exists?
      while @ua.button(title: "Show more transactions").visible?
        @ua.button(title: "Show more transactions").click
      end
    end

    n = 0
    while (! @ua.table(id: "transaction-table").exists? ) && n < 3
      sleep 1
      n += 1
    end

    text = @ua.table(id: "transaction-table").tbody.text.split(/\n/)

    i = 0
    transactions = []
    while i*3 < text.size do
      #puts text[i*3]
      transaction = {}
      transaction[:date] = Date.parse(text[i*3])
      transaction[:description] = text[i*3 + 1]
      # TODO parse different currencies
      transaction[:amount] = text[i*3 + 2].split(/ /).last.gsub(/[£,]/,'').to_f
      transactions << transaction
      i = i + 1
    end

    return transactions
  end
end
