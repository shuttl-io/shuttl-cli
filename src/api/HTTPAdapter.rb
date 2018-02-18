require 'net/http'
require 'json'

require_relative "./Exceptions"

class HTTPAdapter
    def initialize (url, headers=Hash[])
        @url = URI(url)
        @headers = headers
        @http = Net::HTTP.new(@url.host, @url.port)
    end

    def get(url, params=nil, headers=Hash[])
        headers = @headers.merge headers
        url = URI("#{@url}#{url}")
        if !params.nil?
            url.query = URI.encode_www_form(params)
        end
        res = Net::HTTP::Get.new(url.request_uri)
        headers.map do |headerName, headerValue|
            res[headerName] = headerValue
        end
        res = @http.request(res)
        throw res if !res.is_a?(Net::HTTPSuccess)
        JSON.parse(res.body)
    end

    def post(url, body=Hash[], headers=Hash[])
        headers = @headers.merge headers
        url = URI("#{@url}#{url}")
        res = Net::HTTP::Post.new(url.request_uri, 'Content-Type' => 'application/json')
        res.body = body.to_json
        headers.map do |headerName, headerValue|
            res[headerName] = headerValue
        end
        res = @http.request(res)
        raise NotFound.new(res) if res.is_a?(Net::HTTPNotFound)
        JSON.parse(res.body)
    end
end