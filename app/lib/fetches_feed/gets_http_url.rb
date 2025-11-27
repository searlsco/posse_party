class FetchesFeed
  class GetsHttpUrl
    Response = Struct.new(:code, :headers, :body)

    def get(url, headers: {})
      response = HTTParty.get(url, headers:)

      Response.new(response.code, response.headers, response.body)
    end
  end
end
