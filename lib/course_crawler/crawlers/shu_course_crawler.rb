##
# 世新課程爬蟲
# https://ap2.shu.edu.tw/STU1/Loginguest.aspx
#

module CourseCrawler::Crawlers
class ShuCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7,
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'https://ap2.shu.edu.tw/STU1/Loginguest.aspx'
    @result_url = 'https://ap2.shu.edu.tw/STU1/STU1/SC0102.aspx'
    @ic = Iconv.new('utf-8//translit//IGNORE', 'utf-8')
  end

  def courses
    @courses = {}

    r = RestClient.get(@query_url)
    cookie = "ASP.NET_SessionId=#{r.cookies["ASP.NET_SessionId"]}"
    doc = Nokogiri::HTML(@ic.iconv(r))
    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = %x(curl -s '#{@query_url}' -H 'Cookie: #{cookie}' --data '__VIEWSTATE=#{URI.escape(hidden["__VIEWSTATE"], "=+/")}&LoginGuest_Guest.x=20&LoginGuest_Guest.y=20' --compressed)

    r = RestClient.get(@result_url, {"Cookie" => cookie })
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = %x(curl -s '#{@result_url}' -H 'Cookie: #{cookie}' --data '__EVENTTARGET=SRH_setyear_SRH&__EVENTARGUMENT=&__VIEWSTATE=#{URI.escape(hidden["__VIEWSTATE"], "=+/")}&SRH_setyear_SRH=#{@year - 1911}' --compressed)
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = %x(curl -s '#{@result_url}' -H 'Cookie: #{cookie}' --data '__EVENTTARGET=SRH_setterm_SRH&__EVENTARGUMENT=&__VIEWSTATE=#{URI.escape(hidden["__VIEWSTATE"], "=+/")}&SRH_setyear_SRH=#{@year - 1911}&SRH_setterm_SRH=#{@term}&SRH_teach_code_SRH=&SRH_teach_name=&SRH_majr_no=&SRH_grade=&SRH_class_no=&SRH_disp_cr_code=&SRH_full_name=&SRH_day_of_wk_SRH=' --compressed)
    doc = Nokogiri::HTML(r)

    hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    r = %x(curl -s '#{@result_url}' -H 'Cookie: #{cookie}' --data '__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=#{URI.escape(hidden["__VIEWSTATE"], "=+/")}&SRH_setyear_SRH=#{@year - 1911}&SRH_setterm_SRH=#{@term}&SRH_teach_code_SRH=&SRH_teach_name=&SRH_majr_no=&SRH_grade=&SRH_class_no=&SRH_disp_cr_code=&SRH_full_name=&SRH_day_of_wk_SRH=&SRH_search_button=%E6%90%9C%E5%B0%8B' --compressed)

    @result_url = "https://ap2.shu.edu.tw/STU1/STU1/SC0102.aspx?setyear_SRH=#{@year - 1911}&teach_code_SRH=&majr_no=&disp_cr_code=&day_of_wk_SRH=&setterm_SRH=#{@term}&teach_name=&grade=&full_name=&class_no=&"
    r = RestClient.get(@result_url, {"Cookie" => cookie })
    doc = Nokogiri::HTML(r)

    course_temp(doc)

    for page in 1..doc.css('span[id="GRD_ASPager_lblPageTotal"]').text.split(' ')[-1][0..-2].to_i - 1

      hidden = Hash[doc.css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

      r = %x(curl -s '#{@result_url}' -H 'Cookie: #{cookie}' --data '__EVENTTARGET=GRD_ASPager%3AlnkNext&__EVENTARGUMENT=&__VIEWSTATE=#{URI.escape(hidden["__VIEWSTATE"], "=+/")}&SRH_setyear_SRH=#{@year - 1911}&SRH_setterm_SRH=#{@term}&SRH_teach_code_SRH=&SRH_teach_name=&SRH_majr_no=&SRH_grade=&SRH_class_no=&SRH_disp_cr_code=&SRH_full_name=&SRH_day_of_wk_SRH=&GRD_ASPager%3AtxtPage=#{page}' --compressed)
      doc = Nokogiri::HTML(r)

      course_temp(doc)
    # binding.pry if page == 10
    end

    @courses.map{|k, course|
      course.merge({
        :day_1      => course[:course_days][0],
        :day_2      => course[:course_days][1],
        :day_3      => course[:course_days][2],
        :day_4      => course[:course_days][3],
        :day_5      => course[:course_days][4],
        :day_6      => course[:course_days][5],
        :day_7      => course[:course_days][6],
        :day_8      => course[:course_days][7],
        :day_9      => course[:course_days][8],
        :period_1   => course[:course_periods][0],
        :period_2   => course[:course_periods][1],
        :period_3   => course[:course_periods][2],
        :period_4   => course[:course_periods][3],
        :period_5   => course[:course_periods][4],
        :period_6   => course[:course_periods][5],
        :period_7   => course[:course_periods][6],
        :period_8   => course[:course_periods][7],
        :period_9   => course[:course_periods][8],
        :location_1 => course[:course_locations][0],
        :location_2 => course[:course_locations][1],
        :location_3 => course[:course_locations][2],
        :location_4 => course[:course_locations][3],
        :location_5 => course[:course_locations][4],
        :location_6 => course[:course_locations][5],
        :location_7 => course[:course_locations][6],
        :location_8 => course[:course_locations][7],
        :location_9 => course[:course_locations][8],
      })
    }
  end

  def course_temp(doc)
    doc.css('table[id="GRD_DataGrid"] tr:nth-child(n+2)').map{|tr| tr}.each do |tr|
      data = tr.css('td').map{|td| td.text}
      syllabus_url = "https://ap2.shu.edu.tw/STU1/STU1/" + tr.css('td:nth-child(3) a').map{|a| a[:href]}[0] if tr.css('td:nth-child(3) a').map{|a| a[:href]}[0] != nil

      course_days, course_periods, course_locations = [], [], []
      (data[8].scan(/\w+/)[0]..data[8].scan(/\w+/)[1]).each do |p|
        course_days << DAYS[data[7].scan(/[一二三四五六日]/)[0]]
        course_periods << p.to_i
        course_locations << data[9].scan(/\S+/)[0]
      end

      general_code = data[1].scan(/\S+/)[0]
      lecturer = data[6].scan(/(?<name>(\S+\s?)+)/)[0][0].strip

      hash_key = "#{general_code}-#{lecturer}"

      @courses[hash_key] ||= {}

      @courses[hash_key][:year]           = @year    # 西元年
      @courses[hash_key][:term]           = @term    # 學期 (第一學期 = 1，第二學期 = 2)
      @courses[hash_key][:name]           = data[2].scan(/(?<name>(\S+\s?)+)/)[0][0].strip    # 課程名稱
      @courses[hash_key][:lecturer]       = lecturer        # 授課教師
      @courses[hash_key][:credits]        = data[4].to_i         # 學分數
      @courses[hash_key][:code]           = "#{@year}-#{@term}-#{general_code}"
      @courses[hash_key][:general_code]   = general_code
      # @courses[hash_key][:general_code] = data[1]    # 選課代碼
      @courses[hash_key][:url]            = syllabus_url    # 課程大綱之類的連結(如果有的話)
      @courses[hash_key][:required]       = data[5].include?('必')      # 必修或選修
      @courses[hash_key][:department]     = data[0].scan(/\S+/)[0]      # 開課系級

        # department_code: data[0].scan(/\w+/)[0]
        # note: data[11]          # 備註說明
        # term_type: data[3]       # 年別
      @courses[hash_key][:week_type]      = data[10].strip      # 週別!!!有分單雙周!!!

      @courses[hash_key][:course_days]      ||= []
      @courses[hash_key][:course_periods]   ||= []
      @courses[hash_key][:course_locations] ||= []

      @courses[hash_key][:course_days].concat(course_days)
      @courses[hash_key][:course_periods].concat(course_periods)
      @courses[hash_key][:course_locations].concat(course_locations)

      binding.pry
    end
  end
end
end
