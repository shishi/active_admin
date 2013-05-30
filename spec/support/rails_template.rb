# Rails template to build the sample app for specs

# Create a cucumber database and environment
copy_file File.expand_path('../templates/cucumber.rb', __FILE__),                "config/environments/cucumber.rb"
copy_file File.expand_path('../templates/cucumber_with_reloading.rb', __FILE__), "config/environments/cucumber_with_reloading.rb"

gsub_file 'config/database.yml', /^test:.*\n/, "test: &test\n"
gsub_file 'config/database.yml', /\z/, "\ncucumber:\n  <<: *test\n  database: db/cucumber.sqlite3"
gsub_file 'config/database.yml', /\z/, "\ncucumber_with_reloading:\n  <<: *test\n  database: db/cucumber.sqlite3"

generate :model, "post title:string body:text published_at:datetime author_id:integer category_id:integer starred:boolean"
inject_into_file 'app/models/post.rb', %q{
  belongs_to :category
  belongs_to :author, :class_name => 'User'
  accepts_nested_attributes_for :author
  attr_accessible :author if Rails::VERSION::STRING >= '3.2'
}, :after => 'class Post < ActiveRecord::Base'
copy_file File.expand_path('../templates/post_decorator.rb', __FILE__), "app/models/post_decorator.rb"

generate :model, "user type:string first_name:string last_name:string username:string age:integer"
inject_into_file 'app/models/user.rb', %q{
  has_many :posts, :foreign_key => 'author_id'
  def display_name
    "#{first_name} #{last_name}"
  end
}, :after => 'class User < ActiveRecord::Base'

generate :model, 'publisher --migration=false --parent=User'
generate :model, 'category name:string description:text'
inject_into_file 'app/models/category.rb', %q{
  has_many :posts
  accepts_nested_attributes_for :posts
}, :after => 'class Category < ActiveRecord::Base'
generate :model, 'store name:string'

# Generate a model with string ids
generate :model, "tag name:string"
gsub_file(Dir['db/migrate/*_create_tags.rb'][0], /\:tags\sdo\s.*/, ":tags, :id => false, :primary_key => :id do |t|\n\t\t\tt.string :id\n")
inject_into_file 'app/models/tag.rb', %q{
  self.primary_key = :id
  before_create :set_id

  private
  def set_id
    self.id = 8.times.inject("") { |s,e| s << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
  end
}, :after => 'class Tag < ActiveRecord::Base'

if Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR == 1 #Rails 3.1 Gotcha
  gsub_file 'app/models/tag.rb', /self\.primary_key.*$/, "define_attr_method :primary_key, :id"
end

# Configure default_url_options in test environment
inject_into_file "config/environments/test.rb", "  config.action_mailer.default_url_options = { :host => 'example.com' }\n", :after => "config.cache_classes = true\n"

# Add our local Active Admin to the load path
inject_into_file "config/environment.rb", "\n$LOAD_PATH.unshift('#{File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))}')\nrequire \"active_admin\"\n", :after => "require File.expand_path('../application', __FILE__)"

# Add some translations
append_file "config/locales/en.yml", File.read(File.expand_path('../templates/en.yml', __FILE__))

# Add predefined admin resources
directory File.expand_path('../templates/admin', __FILE__), "app/admin"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# we need this routing path, named "logout_path", for testing
route %q{
  devise_scope :user do
    match '/admin/logout' => 'active_admin/devise/sessions#destroy', :as => :logout
  end
}

generate :'active_admin:install'

# Setup a root path for devise
route "root :to => 'admin/dashboard#index'"

rake "db:migrate"
rake "db:test:prepare"
run "/usr/bin/env RAILS_ENV=cucumber rake db:migrate"
