# encoding: UTF-8

require 'open-uri'
require 'CGI'
require 'csv'

host = "http://www.equip.ru"

CSV.open("equip_dump.txt", "wb", {:force_quotes => true}) do |csv|
#contents = contents.encode("UTF-8")
#items_path = https://gist.githubusercontent.com/allaud/c21e20b2c7576b75743f/raw/db30b2b78969e8d899b15bf6ab2bb1a06bf3ce21/gistfile1.txt
items = (open("gistfile1.txt").read).scan(/Searching for (.+?)...found 0/).each do |item|
#items = [["Книга Линчевский Э. ПСИХОЛОГИЧЕСКИЙ КЛИМАТ ТУРИСТСКОЙ ГРУППЫ"]].each do |item|

	search_result = (open(host+'/search?search='+URI.encode(item[0].to_s)).read).scan(/li><a href="(.+?)"><strong>.+?<\/strong><\/a><\/li>/)
	
	search_result.each do |search_result|
		unless (search_result.empty? or search_result[0]["shop"] == nil)
			item_page = open(host+CGI.unescapeHTML(search_result[0])).read	
	
			path = item_page.scan(/<a\shref="\/shop\?mode=search&_folder_id=.+?">(.+?)<\/a><span>\s?&minus;&gt;\s?<\/span>/)
		
			properties = item_page.scan(/<h1>(.+?)<\/h1>[\s\S]*
				<span>(.+?)<\/span><span\sclass="currency_type">i<\/span>[\s\S]*
				<div\sclass="parameters"><div\sclass="brand"><p>.+?<span>(.+?)<\/span><\/p><\/div>[\s\S]*
				<div\sid="product_body"\sclass="product_body">\s+
				([\s\S]*?)\s+
				<div\sclass="product_clear"><\/div>\s+<\/div>\s+<\/div>\s+<div\sclass="product_table">/x)

			images = item_page.scan(/<div\sclass="item">\s+<a\shref="(.+?)"\sonclick="return\sprev_image
				\(this,\s'.+?',\s'#img_wrap',\s'#img_cont',\s\d*\);">/x)
				if images.empty?
					images = item_page.scan(/<a\sid="img_wrap"\sclass="highslide"\shref="(.+?)"\sonclick/x)
				end
			#puts item[0]
			#p properties
			#p path
			#p images
			#puts ""
			temp = {}
			temp[:SKU] = "EQ"+search_result[0].scan(/id=(.+)/)[0][0]
			temp[:Name] = properties[0][0]
			temp[:Description] = CGI.unescapeHTML(properties[0][3])
			temp[:Available_On] = (Time.now - (24*60*60)).to_s.split[0]
			temp[:price] = properties[0][1].gsub(/\s/, "").to_i
			temp[:CostPrice] = (temp[:price]*0.8).round
			temp[:product_properties] = ""
			if path.empty?
				temp[:Taxons] = "Каталог|Бренд>"+properties[0][2]
			else
				temp[:Taxons] = path[0][0]
					for i in 1..path.length-1
						temp[:Taxons] += ">"+path[i][0]	
					end
				temp[:Taxons] += "|Бренд>"+properties[0][2]
			end	
			temp[:OptionTypes] = ""
			temp[:Variants] = ""
			temp[:count_on_hand] = "999"
			if images.empty?
				temp[:Images] = ""
			else	
				temp[:Images] = host+images[0][0]
					for i in 1..images.length-1
						temp[:Images] += "|"+host+images[i][0]
					end
			end
			csv << temp.values
		end# unless search_result end
	end#search_result end
end#items end
end#CSV block end