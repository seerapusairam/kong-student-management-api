local CustomHandler = {
  PRIORITY = 1000,
  VERSION = "1.0.0",
}

function CustomHandler:header_filter()
  kong.response.set_header("X-Custom-Header", "This is custom variable")
end

return CustomHandler