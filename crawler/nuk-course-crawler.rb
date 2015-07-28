require 'crawler_rocks'
require 'json'
require 'iconv'
require 'pry'

class NationalUniversityOfKaohsiungCrawler

	def initialize year: nil, term: nil, update_progress: nil, after_each: nil

		@year = year-1911
		@term = term
		@update_progress_proc = update_progress
		@after_each_proc = after_each

		@ic = Iconv.new('utf-8//IGNORE//translit', 'big5')
	end

	def courses
		@courses = []

		@Pclass = ''		# 初始預設爲空
		query_url = %x(curl -s 'http://course.nuk.edu.tw/QueryCourse/QueryCourse.asp' --data 'Condition=&OpenYear=#{@year}&Helf=#{@term}&Pclass=#{@Pclass}' --compressed)
		doc = Nokogiri::HTML(@ic.iconv(query_url))

		facs_h = Hash[doc.css('select[name="Pclass"] option:not(:first-child)').map{|opt| [opt[:value], opt.text]}]

		facs_h.each do |fac_c, fac_n|

			@Pclass = fac_c

			query_url = %x(curl -s 'http://course.nuk.edu.tw/QueryCourse/QueryCourse.asp' --data 'Condition=&OpenYear=#{@year}&Helf=#{@term}&Pclass=#{@Pclass}' --compressed)
			doc = Nokogiri::HTML(@ic.iconv(query_url))

			deps_h = Hash[doc.css('select[name="Sclass"] option:not(:first-child)').map{|opt| [opt[:value], opt.text]}]
			deps_h.each do |dep_c, dep_n|

				@Sclass = dep_c

				result_url = %x(curl -s 'http://course.nuk.edu.tw/QueryCourse/QueryResult.asp' --data 'Condition=%3Ctr%3E%3Ctd+width%3D%22%2233%25%22%22%3E%B6%7D%BD%D2%BE%C7%A6%7E%A1G104%A1%40%A1%40%B6%7D%BD%D2%BE%C7%B4%C1%A1G%B2%C41%BE%C7%B4%C1%3C%2Ftd%3E%3Ctd+width%3D%22%2233%25%22%22%3E%B6%7D%BD%D2%B3%A1%A7O%A1G%A4j%BE%C7%B3%A1%A4G%A6%7E%A8%EE%A6b%C2%BE%B1M%AFZ%3C%2Ftd%3E%3Ctd+width%3D%22%2234%25%22%22%3E%B6%7D%BD%D2%A8t%A9%D2%A1G%B9B%B0%CA%B0%B7%B1d%BBP%A5%F0%B6%A2%BE%C7%A8t%3C%2Ftd%3E%3C%2Ftr%3E%3Ctr%3E%3Ctd+width%3D%22%2233%25%22%22%3E%B6%7D%BD%D2%AFZ%AF%C5%A1G%B9B%B0%CA%B0%B7%B1d%BBP%A5%F0%B6%A2%BE%C7%A8t1%A6%7E%AF%C5%28F10412%29%3C%2Ftd%3E%3Ctd+width%3D%22%2233%25%22%22%3E%B1%C2%BD%D2%B1%D0%AEv%A1G%B5L%3C%2Ftd%3E%3Ctd+width%3D%22%2234%25%22%22%3E%A4W%BD%D2%AE%C9%B6%A1%A1G%B5L%3C%2Ftd%3E%3C%2Ftr%3E&OpenYear=#{@year}&Helf=#{@term}&Pclass=#{@Pclass}&Sclass=#{@Sclass}' --compressed)
				doc = Nokogiri::HTML(@ic.iconv(result_url))

				for i in 0..doc.css('tr[align = "center"]').count - 1
					data = []

					for j in 0..doc.css('tr[align = "center"]')[i].css('td').count - 1

						data[j] = doc.css('tr[align = "center"]')[i].css('td')[j].text

					end

					course = {
						year: @year,
						term: @term,
						faculty: fac_n,		# 開課部別
						department: dep_n,		# 開課系所
						department_code: data[0],		# 系所代碼
						general_code: data[1],		# 課號
						grade: data[2],		# 年級
						calss: data[3],		# 班別
						name: data[4],		# 課程名稱
						credits: data[5],		# 學分
						required: data[6],		# 修別
						limit_people: data[7],		# 限修人數
						people: data[8],		# 選課確定
						people_online: data[9],		# 線上人數
						people_last: data[10],		# 餘額
						lecturer: data[11],		# 授課教師
						location: data[12],		# 上課教室
						day_1: data[13],		# 一~日的上課時間(節次)
						day_2: data[14],
						day_3: data[15],
						day_4: data[16],
						day_5: data[17],
						day_6: data[18],
						day_7: data[19],
						pre_limit: data[20],		# 先修限修學程
						notes: data[21],		# 備註
					}

					@after_each_proc.call(course: course) if @after_each_proc

					@courses << course
				end
			end
		end

		# binding.pry
		@courses
	end

end

# crawler = NationalUniversityOfKaohsiungCrawler.new(year: 2015, term: 1)
# File.write('courses.json', JSON.pretty_generate(crawler.courses()))
