class PriceGetter

  def initialize ticker
    url = format_url(ticker)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    if response.code == "200"
      puts "200 response"
      @result = JSON.parse(response.body, :allow_nan => true)
    else
      puts "Error"
    end
  end

  def get_dividends
    #TODO: Check if dividend data is adjusted for stock splits
    dividends_hash = Hash.new
    dividends = @result["DividendData"]
    dividends.each do |dividend|
      puts dividend["Type"]
      if dividend["Type"] == "Dividend"
        dividend_string = dividend["Desc"][10..-4]
        key_date = convert_yyyymmdd_to_ruby_date(dividend["Date"])
        dividends_hash[key_date] = [dividend_string.to_f, dividend["x"]]
      else
        #TODO: Create get_stock_splits
      end
    end
    return dividends_hash
  end

  def get_close_prices
    close_prices = Array.new
    prices = @result["PriceDataList"][0]["Datapoints"]
    prices.each { |datapoint| close_prices << datapoint.first }
    return close_prices
  end

  def get_dates
    dates = @result["PriceDataList"][0]["DateIndexs"]
  end


  def create_time_series_data
    time_series_array = Array.new
    dates = Array.new
    dates += get_dates
    close_prices = get_close_prices
    dividends = get_dividends
    dates.each do |date|
      date_to_add = convert_excel_date_to_ruby_date(date)
      if dividends.key?(date_to_add)
        dividend = dividends[date_to_add][0]
      else
        dividend = 0
      end
      time_series_array << [date_to_add, close_prices[dates.index(date)], dividend]
    end
    return time_series_array
  end

  def format_url (ticker)
    url1 = "http://globalquote.morningstar.com/globalcomponent/RealtimeHistoricalStockData.ashx?ticker="
    url2 = "&showVol=false&dtype=his&f=d&curry=USD&range="
    url3 = "|"
    url4 = "&isD=true&isS=true&hasF=true&ProdCode=DIRECT"
    start_date = "1900-1-1"
    todays_date = Date.today
    end_date = todays_date.strftime("%Y-%m-%d")
    url = (url1 + ticker + url2 + start_date + url3 + end_date + url4)
  end

  def convert_excel_date_to_ruby_date (excel_date)
    date = Date.new(1900, 01, 01) + excel_date.days
  end

  def convert_yyyymmdd_to_ruby_date (old_date)
    #Converts date from yyyy-mm-dd to ruby date object
    date = Date.strptime(old_date, '%Y-%m-%d')
  end
end
