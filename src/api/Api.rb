require 'net/http'
require 'json'
require_relative 'HTTPAdapter'

class ShuttlAPI < HTTPAdapter
    def login(username, password)
        post('/api/login', {"username": username, "password": password})
    end
end