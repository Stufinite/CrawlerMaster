##
# 虎科大課程爬蟲
# http://osa.nfu.edu.tw/query/class.php
#

module CourseCrawler::Crawlers
class NfuCourseCrawler < CourseCrawler::Base

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil
    @year                 = year || current_year
    @term                 = term || current_term
    @post_url             = "http://osa.nfu.edu.tw/query/class_ajax.php"
    @post_url_class       = "http://osa.nfu.edu.tw/query/classlist.php"
    @update_progress_proc = update_progress
    @after_each_proc      = after_each
	end

	def courses
		@courses = []
		dep = []
		year = (@year-1911).to_s
		term = @term.to_s
		all_yt = year + term

		# search dep
		r = RestClient.post( @post_url_class , { pselclss: '12011' })
		doc = Nokogiri::HTML(r)

		doc.css('select[id="selclss"] option')[1..-1].each do |department|
			dep << department.text[0..4]
		end

		#do search datas
		dep.each do |dep_no|
			set_progress "#{dep.index(dep_no)+1} / #{dep.size.to_s}"

			r = RestClient.post( @post_url , {
					pselyr: all_yt,
					pselclss: dep_no,
				})

			doc = Nokogiri::HTML(r)

			talbe_un = doc.css('div[id="copyall"]')
			if (talbe_un.text.size > 0)
				index = doc.css('div[id="copyall"]').css('table tr')
				index[3..-1].each do |row|
					datas = row.css('td')

					course_days = []
					course_periods = []
					course_locations = []

					datas[6..12].each do |day_class|
						if(day_class.text != "&nbsp")
							day_have_class = (datas.index(day_class).to_i - 5)
							day_have_periods = day_class.text.split(',')
							day_have_periods.each do |_periods|
								course_days << day_have_class
								course_periods << _periods
								course_locations << datas[13].text.strip
							end
						end
					end

					next if datas[1].text.strip.empty?

					course = {
            name:         "#{datas[1].text.strip}",
            year:         @year,
            term:         @term,
            code:         "#{@year}-#{@term}-#{datas[0].text.strip}",
            general_code: datas[0].text.strip,
            dep_code:     dep_no,
            credits:      "#{datas[3].text.strip}",
            lecturer:     "#{datas[5].text.strip}",
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
		end
		@courses
	end
end
end
