Rack::Attack.throttle("booking_pages/ip", limit: 30, period: 60) do |req|
  req.ip if req.path.start_with?("/book/") && req.get?
end

Rack::Attack.throttle("booking_create/ip", limit: 5, period: 60) do |req|
  req.ip if req.path.start_with?("/book/") && req.post?
end

Rack::Attack.throttled_responder = lambda do |_request|
  [ 429, { "Content-Type" => "text/html; charset=utf-8" }, [ File.read(Rails.root.join("public/429.html")) ] ]
end
