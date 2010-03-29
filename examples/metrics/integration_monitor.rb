# Namespacing: should be namespaceable via Monitor() like everything else;
# should show up as $namespace/story("story title")
# steps show up as $namespace/story("story title")/step("step title") <= assuming there's value in breaking down steps
Story("Signup for the Opscode Platform") do |s|
	# step should be aliased as #given, #when and #then
  s.step("I complete the signup form") do
    # In here, we're in the same context as in a Monitor() block.
    # the #browser behavior below can be implemented as a Metric()
    # if we switch Metric to using class eval...
    
    # browser should be a wrapper around mechanize.
    # browser should take an options hash in the constructor
    # for various things like content accept headers and the like.
    browser do |b|
      b.visit("http://cookbooks.opscode.com/signup").expect(:status => 200)
      b.fill_in(:user_name => "valid-user", :password => "password", :password_confirmation => "password")
      b.fill_in(:email_address => "testuser+slug@gmail.com")
      b.submit("signup")
    end
  end
  s.step("I click confirmation link in the verification email") do
    email_client do |e|
      e.retrieve_mail(:from => "signup@opscode.com", :to => "testuser+slug@gmail.com", :timeout => {10 => :minutes}) do |mail|
        #process the email
        #...
        # story_data is a hash available throughout the story steps
        story_data[:verification_url] = "" # extract from the email in real life
      end
    end
    browser do |b|
      b.visit story_data[:verification_url]
    end
  end
  s.step("")
end
