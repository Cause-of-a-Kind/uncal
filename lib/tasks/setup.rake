namespace :setup do
  desc "Create the first admin user"
  task admin: :environment do
    name     = ENV.fetch("NAME")     { prompt("Name: ") }
    email    = ENV.fetch("EMAIL")    { prompt("Email: ") }
    password = ENV.fetch("PASSWORD") { prompt("Password: ") }

    user = User.find_or_initialize_by(email_address: email)
    user.name = name
    user.password = password
    user.owner = true
    user.timezone = "Etc/UTC" if user.new_record?

    if user.save
      status = user.previously_new_record? ? "Created" : "Updated"
      puts "#{status} admin user: #{user.email_address}"
    else
      puts "Error: #{user.errors.full_messages.join(', ')}"
      exit 1
    end
  end
end

def prompt(message)
  print message
  $stdin.gets.chomp
end
