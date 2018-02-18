require 'colorize'
require 'io/console'

require_relative '../api/Api'
require_relative '../settings'
require_relative 'base'

class Login < CommandBase
    
    def run (options)
        print "Username: "
        userName = gets.chomp
        print "Password (You won't see any typing):"
        password = STDIN.noecho(&:gets).chomp
        puts ""
        begin
            resp = @api.login(userName, password)
            @info['token'] = resp["token"]
            puts "Login successful!".green
        rescue ShuttlNotFound
            $stderr.puts "username or password is incorrect".red
        end
    end

end