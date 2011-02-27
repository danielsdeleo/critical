# require 'mechanize'
# require 'webrat'

Metric(:browser) do
  
  def after_initialize
    @mechanize = ::Mechanize.new
  end

  def visit(url)
    @base_url = url
  end
end

__END__

# Namespacing: should be namespaceable via Monitor() like everything else;
# should show up as $namespace/story("story title")
# steps show up as $namespace/story("story title")/step("step title") <= assuming there's value in breaking down steps
Story("Signup for my website") do |s|
	# step should be aliased as #given, #when and #then
  s.step("I complete the signup form") do
    # In here, we're in the same context as in a Monitor() block.

    # browser should be a wrapper around mechanize.
    # browser should take an options hash in the constructor
    # for various things like content accept, base url, etc.
    # browser can be implemented by defining methods on a
    # browser Metric()
    browser do |user|
      user.visits("http://my-web20-site.example.com/signup")
      user.fills_in(:user_name => "valid-user", :password => "password", :password_confirmation => "password")
      user.fills_in(:email_address => "testuser+slug@gmail.com")
      user.submits("signup")
      # should also allow for expecting errors (404, 403, whatevr) like this (?)
      user.expect(:status => 404).visit('/blackhole')
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
