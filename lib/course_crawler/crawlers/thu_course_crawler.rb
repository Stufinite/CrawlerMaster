# 東海大學
# 課程查詢網址：http://course.thu.edu.tw/

module CourseCrawler::Crawlers
class ThuCourseCrawler < CourseCrawler::Base

  DAYS = {
    '一' => 1,
    '二' => 2,
    '三' => 3,
    '四' => 4,
    '五' => 5,
    '六' => 6,
    '日' => 7
  }

  PERIODS = {
    "0"   => 1,
    "1"   => 2,
    "2"   => 3,
    "3"   => 4,
    "4"   => 5,
    "4.5" => 6,
    "5"   => 7,
    "6"   => 8,
    "7"   => 9,
    "8"   => 10,
    "9"   => 11,
    "10"  => 12,
    "11"  => 13,
    "12"  => 14,
    "13"  => 15,
    "14"  => 16,
  }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year                 = year || current_year
    @term                 = term || current_term
    @update_progress_proc = update_progress
    @after_each_proc      = after_each

    @url = "http://course.thu.edu.tw/view-dept/#{@year-1911}/#{term}/everything"

    @ic = Iconv.new('utf-8//translit//IGNORE', 'utf-8') #
  end


  def courses
    @courses = []
    r = RestClient.get @url
    doc = Nokogiri::HTML(r)
    # doc.css('table tr td[data-title="系所名稱"] a')[0][:href]
    dep_urls = doc.css('table tr td[data-title="系所名稱"] a').map { |a| URI.join(@url, a[:href]).to_s }

    dep_urls.each_with_index do |url, url_index|
      set_progress "#{url_index+1} / #{dep_urls.count}\n"

      r = RestClient.get url
      doc = Nokogiri::HTML(r)
      doc.css('table.aqua_table')[-1].css('tr')[1..-1].each do |row|
        datas = row.css('td')

        course_days = []
        course_periods = []
        course_locations = []
        time_loc_regex = /(?<day>[#{DAYS.keys.join}])\/(?<period>(\d{1,2}\,?)+)(\[(?<loc>.+)\])?/

        # datas[3].text.strip.match(time_loc_regex) do |m|
        # DAYS[m[:day]]
        # end

        datas[3].text.strip.scan(time_loc_regex).each do |array|
          array[1].split(',').each do |period|
            course_days << DAYS[array[0]]
            course_periods << PERIODS[period.strip]
            course_locations << array[2]
          end
        end

        code = datas[0].text.strip.match(/\d+/)[0].to_s
        course = {
          name:         "#{datas[1].text.strip}",
          year:         @year,
          term:         @term,
          code:         "#{@year}-#{@term}-#{code}",
          general_code: code,
          credits:      "#{datas[2].text[0]}",
          lecturer:     "#{datas[4].text.strip}",
          day_1:        course_days[0],
          day_2:        course_days[1],
          day_3:        course_days[2],
          day_4:        course_days[3],
          day_5:        course_days[4],
          day_6:        course_days[5],
          day_7:        course_days[6],
          day_8:        course_days[7],
          day_9:        course_days[8],
          period_1:     course_periods[0],
          period_2:     course_periods[1],
          period_3:     course_periods[2],
          period_4:     course_periods[3],
          period_5:     course_periods[4],
          period_6:     course_periods[5],
          period_7:     course_periods[6],
          period_8:     course_periods[7],
          period_9:     course_periods[8],
          location_1:   course_locations[0],
          location_2:   course_locations[1],
          location_3:   course_locations[2],
          location_4:   course_locations[3],
          location_5:   course_locations[4],
          location_6:   course_locations[5],
          location_7:   course_locations[6],
          location_8:   course_locations[7],
          location_9:   course_locations[8],
        }

        @after_each_proc.call(course: course) if @after_each_proc
        @courses << course
      end
    end

    @courses

  end

end
end
