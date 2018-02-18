class APIError < StandardError
    attr_accessor :response
    def initialize (resp)
        @response = resp
    end
end

class NotFound < APIError
end
