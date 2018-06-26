require 'shopify_api'

#---------------------------------------------------------------------------------+
# Copy SmartCollections from TEST to PROD.	
#---------------------------------------------------------------------------------+
# This ruby will connect to PROD site, get a list of all Smart Collections, and
# for each: 1. delete like-named collection on TEST, 2. copy collection from PROD to 
# TEST, and when all collections have been processed, # 3. disconnect from TEST.  
# All API calls are wrapped in timeout traps.
#---------------------------------------------------------------------------------+
# Notes: 	(1) The static .55 sleep throttles API calls.
#      			See Shopify "API LIMITS" for an adaptive method.
#---------------------------------------------------------------------------------+
# Issues:  	(1) JSON parsing is slow. 	
#---------------------------------------------------------------------------------+
# 06/2016 pb
#---------------------------------------------------------------------------------+

# Define PROD authentication parameters
SHOPIFY_SHOP_PROD='example1'
SHOPIFY_API_KEY_PROD='1ad21fb5e1df48d57a6ad412b106846d'
SHOPIFY_PASSWORD_PROD='6ae33fd841969aafb17649f1b61c642c'

# Define TEST authentication parameters
SHOPIFY_SHOP_TEST='example2'
SHOPIFY_API_KEY_TEST='641dc00ea34c560542072d545ea84kd09bb800acd35b'
SHOPIFY_PASSWORD_TEST='b713cb33ed0afb44907b946fe8c916464abb0fcd37'

# Clear any previous session
puts 'Clear any residual session'
ShopifyAPI::Base.clear_session

# Open the PROD site
puts 'Connect to PROD site'
sleep(0.55)
begin
	ShopifyAPI::Base.site = "https://#{SHOPIFY_API_KEY_PROD}:#{SHOPIFY_PASSWORD_PROD}@#{SHOPIFY_SHOP_PROD}.myshopify.com/admin"
rescue ActiveResource::TimeoutError 
    puts 'Connect timeout PROD'
    exit(12)
end

# Fetch Smart Collections from PROD. 
puts 'Fetch all SmartCollections from PROD site'
sleep(0.55)
begin
	@sc = ShopifyAPI::SmartCollection.find(:all)
rescue ActiveResource::TimeoutError 
   	puts 'FIND timeout PROD'
   	exit (12)
end

# Close the PROD shop and open TEST to build the new objects.
puts 'Disconnect from PROD site'
sleep(0.55)
ShopifyAPI::Base.clear_session

puts 'Connect to TEST site'
sleep(0.55)
begin
ShopifyAPI::Base.site = "https://#{SHOPIFY_API_KEY_TEST}:#{SHOPIFY_PASSWORD_TEST}@#{SHOPIFY_SHOP_TEST}.myshopify.com/admin"
rescue ActiveResource::TimeoutError 
    puts "Connect timeout TEST"
    exit(12)
end

@sc.each do |c|		# Copy each Collection from PROD to TEST

	# ----- Can filter what is copied as needed -------------------------------- #
	#if c.handle != "men" then next end

	# First, remove like-named TEST collections
	# Could make one find call then parse json <<<
	puts 'Remove any like-named TEST collections'
	sleep(0.55)
	begin
		@tc=ShopifyAPI::SmartCollection.find(:all,:params=>{:handle=>c.handle})
	rescue ActiveResource::TimeoutError 
    	puts 'TEST FIND timeout: handle ' + c.handle
#    	puts c.to_json
    	next
    end

	@tc.each do |ct|
		puts 'Remove obsolete TEST collection... ' + ct.handle
		ct.destroy
		puts 'Done: ' + ct.handle + ' removed'
	end

	puts 'Instantiate new TEST collection: ' + c.handle + '...'
	nc = ShopifyAPI::SmartCollection.new	# New Smart Collection
	nc.title=c.title
	nc.handle=c.handle
	nc.body_html=c.body_html
	nc.disjunctive=c.disjunctive
	(c.to_json.include? '"image":') ? (nc.image=c.image) : 0  	# <<< 
	(c.to_json.include? '"rules":') ? (nc.rules=c.rules) : 0 	# <<<
	nc.sort_order=c.sort_order
	nc.template_suffix=c.template_suffix
	puts 'Create TEST collection: ' + nc.handle + '...'
	nc.save
	puts 'Done: ' + nc.handle  + ' created'
end

puts 'Disconnect from TEST site'
sleep(0.55)
ShopifyAPI::Base.clear_session	# Cleanup session

puts 'Exiting with code 0'
exit(0)
