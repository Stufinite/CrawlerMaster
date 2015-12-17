module CourseCrawler
  def crawler_list
    Crawlers.constants.reject { |c| !c.to_s.include? "Crawler" }
  end

  def get_crawler sym
    Crawlers.const_get sym
  end

  module_function :crawler_list, :get_crawler
end
