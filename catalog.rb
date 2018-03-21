
require 'unirest'
require 'csv'
require 'json'
require 'highline/import'

domain = ask("What is your Canvas subdomain? (the bit that goes before .instructure.com)  ")
env = "" #ask("Which environment do you want to use? (beta, test) just leave BLANK and press enter for production  ")
course_id = ask("What is the COURSE_ID you need to report on?  ")
access_token = ask("Please input your admin token  ")
report_file = 'report.csv'

fileheaders = ["User_id", "user_name", "user_email", "user_login", "address", "country", "uscourse", "TsandCs"]
   CSV.open("#{report_file}", "w") do |csv| #open new file for write
      csv << fileheaders
   end


env != '' ? env << '.' : env
base_url = "https://#{domain}.#{env}instructure.com/api/v1"


Unirest.default_header("Authorization", "Bearer #{access_token}")


#CSV.foreach(csv_file, {:headers => true}) do |row|

  users_get = "https://#{domain}.#{env}instructure.com/api/v1/courses/#{course_id}/users"

  user_data = Unirest.get(users_get, parameters: { "per_page" => 100, "include[]" => ["email", "bio", "custom_links"], "enrollment_type[]" => "student"})

  #capture all loop
  links = user_data.headers[:link] 
  all_links = links.split(",")  
  next_link = all_links[1].split(";")[0].gsub(/\<|\>/, "") 
  last_link = all_links[3].split(";")[0].gsub(/\<|\>/, "") 


  user_response = user_data.body
  
  user_response.each do |user|
    user_id = user['id']
    user_name = user['name']
    user_email = user['email']
    user_login = user['login_id']

    user_custom_data = "https://#{domain}.#{env}instructure.com/api/v1/users/#{user_id}/custom_data?ns=com.instructure.gallery"

    

    custom_data_call = Unirest.get(user_custom_data)
    if custom_data_call.code == 200

    custom_data = custom_data_call.body
    custom_data_first = custom_data['data']['registration'].first#['Address']
    custom_address = custom_data_first[1]['Address']
    custom_country = custom_data_first[1]['Country']
    custom_uscourse = custom_data_first[1]['UScourse']
    custom_tsandcs = custom_data_first[1]['TandCs']

   
    puts "Adding #{user_name}'s information to the spreadsheet"

       data = [ user_id, user_name, user_email, user_login, custom_address, custom_country, custom_uscourse, custom_tsandcs]
         CSV.open("#{report_file}", "a") do |csv| #open same file for write
           csv << data #write value to file
         end
    else 

       puts "#{user_name} has no custom data"

    end
        
  end



  while links.include? 'rel="next"'

    user_data = Unirest.get(next_link, parameters: { "per_page" => 100, "include[]" => ["email", "bio", "custom_links"], "enrollment_type[]" => "student" })
    
    links = user_data.headers[:link]
    all_links = links.split(",")  
    next_link = all_links[1].split(";")[0].gsub(/\<|\>/, "")  
    #last = all_links[2].split(";")[0].gsub(/\<|\>/, "") 

    user_response = user_data.body

  
      user_response.each do |user|
        user_id = user['id']
        user_name = user['name']
        user_email = user['email']
        user_login = user['login_id']

        user_custom_data = "https://#{domain}.#{env}instructure.com/api/v1/users/#{user_id}/custom_data?ns=com.instructure.gallery"

        custom_data_call = Unirest.get(user_custom_data)
        
        if custom_data_call.code == 200
      
          custom_data = custom_data_call.body
          custom_data_first = custom_data['data']['registration'].first#['Address']
          custom_address = custom_data_first[1]['Address']
          custom_country = custom_data_first[1]['Country']
          custom_uscourse = custom_data_first[1]['UScourse']
          custom_tsandcs = custom_data_first[1]['TandCs']

         
          puts "Adding #{user_name}'s information to the spreadsheet"

             data = [ user_id, user_name, user_email, user_login, custom_address, custom_country, custom_uscourse, custom_tsandcs]
               CSV.open("#{report_file}", "a") do |csv| #open same file for write
                 csv << data #write value to file
               end

      else 
      puts "#{user_name} has no custom data"
    end
  end
end

puts "Finished! Have yourself and awesome day!"
