# 國立成功大學
# 選課網址: http://course-query.acad.ncku.edu.tw/qry/

module CourseCrawler::Crawlers
class NckuCourseCrawler < CourseCrawler::Base
  include CrawlerRocks::DSL

  PERIODS = {
    "0" => 1,
    "1" => 2,
    "2" => 3,
    "3" => 4,
    "4" => 5,
    "N" => 6,
    "5" => 7,
    "6" => 8,
    "7" => 9,
    "8" => 10,
    "9" => 11,
    "A" => 12,
    "B" => 13,
    "C" => 14,
    "D" => 15,
  }

  def initialize year: current_year, term: current_term, update_progress: nil, after_each: nil, params: nil

    @query_url = "http://course-query.acad.ncku.edu.tw/qry/qry001.php"

    @year = year || current_year
    @term = term || current_term

    @update_progress_proc = update_progress
    @after_each_proc = after_each
  end

  def courses
    @courses = []
    @threads = []

    visit "http://course-query.acad.ncku.edu.tw/qry/index.php"
    deps_h = Hash[(@doc.css('.dept a') | @doc.css('.institute a')).map do |d|
      m = d.text.gsub(/\s+/, ' ').match(/\ \(\ (?<dep_c>.{2})\ \）(?<dep>.+)\ /)
      [m[:dep], m[:dep_c]]
    end]

    done_departments_count = 0

    deps_h.each do |dep_n, dep_c|
      sleep(1) until (
        @threads.delete_if { |t| !t.status };  # remove dead (ended) threads
        @threads.count < (ENV['MAX_THREADS'] || 20)
      )

      # @threads << Thread.new do
        # begin
          # print "(#{dep_c}) #{dep_n}\n"


          # r = nil;

          # 3.times do
          #   begin
              r = RestClient.get "#{@query_url}?dept_no=#{URI.encode(dep_c)}&syear=#{(@year-1911).to_s.rjust(4, '0')}&sem=#{@term}".gsub(/\s+/, '')
          #     break
          #   rescue Exception => e
          #     sleep 3;
          #   end
          # end

          doc = Nokogiri::HTML r.to_s


          doc.css('[class^=course_y]').each do |row|
            datas = row.css('td')

            next if datas[0].text == "系所名稱"

            serial_no = datas[2] && datas[2].text
            code = datas[3] && datas[3].text
            group_code = datas[4] && datas[4].text.strip
            gs = datas[5] && datas[5].text.split(/\s+/)
            # grade = gs[0]
            # group = gs[1]

            course_days = []
            course_periods = []
            course_locations = []

            loc = datas[17] && datas[17].text.squeeze
            datas[16].search('br').each {|br| br.replace("\n") }
            datas[16].text.strip.split("\n").each do |pss|
              pss.match(/\[(?<d>\d)\](?<ps>.+)/) do |m|
                _start = PERIODS[m[:ps].split('~').first]
                _end = PERIODS[m[:ps].split('~').last]
                (_start.._end).each do |period|
                  course_days << m[:d].to_i
                  course_periods << period
                  course_locations << loc
                end
              end
            end

            course = {
              year: @year,
              term: @term,
              department: dep_n.strip,
              department_code: dep_c.strip,
              # code: "#{@year}-#{@term}-#{serial_no}-#{code}-#{group_code}",
              code: "#{@year}-#{@term}-#{code}-#{group_code}",
              general_code: code,
              group: gs.join,
              grade: datas[6] && datas[6].text.to_i,
              name: datas[10] && datas[10].text.strip,
              url: datas[10] && !datas[10].css('a').empty? && datas[10].css('a')[0][:href],
              required: datas[11] && datas[11].text.include?('必'),
              credits: datas[12] && datas[12].text.to_i,
              lecturer: datas[13] && datas[13].text.strip,
              day_1: course_days[0],
              day_2: course_days[1],
              day_3: course_days[2],
              day_4: course_days[3],
              day_5: course_days[4],
              day_6: course_days[5],
              day_7: course_days[6],
              day_8: course_days[7],
              day_9: course_days[8],
              period_1: course_periods[0],
              period_2: course_periods[1],
              period_3: course_periods[2],
              period_4: course_periods[3],
              period_5: course_periods[4],
              period_6: course_periods[5],
              period_7: course_periods[6],
              period_8: course_periods[7],
              period_9: course_periods[8],
              location_1: course_locations[0],
              location_2: course_locations[1],
              location_3: course_locations[2],
              location_4: course_locations[3],
              location_5: course_locations[4],
              location_6: course_locations[5],
              location_7: course_locations[6],
              location_8: course_locations[7],
              location_9: course_locations[8],
            }
            @after_each_proc.call(:course => course) if @after_each_proc
            @courses << course
          end # doc.css each row

          done_departments_count += 1
          set_progress "#{done_departments_count} / #{deps_h.keys.count}"

        # rescue Exception => e
        #   sleep 3
        #   redo
        # end
      # end # end thread do
    end # deps_h.each do
    ThreadsWait.all_waits(*@threads)

    @courses
  end

  def current_year
    (Time.now.month.between?(1, 7) ? Time.now.year - 1 : Time.now.year)
  end

  def current_term
    (Time.now.month.between?(2, 7) ? 2 : 1)
  end
end
end
