local CustomHandler = {
  PRIORITY = 1000,
  VERSION = "1.0.0",
}

function CustomHandler:access(conf)
  local token = kong.request.get_header(conf.token_name)

  if not token then
    return kong.response.exit(400, { message = "X-Auth-Token header is missing" })
  end

  -- This is a mock validation. In a real scenario, you would
  -- validate the token against a database or an auth service.
  if token ~= conf.password then
    return kong.response.exit(401, { message = "Unauthorized" })
  end

  -- If the token is valid, you can add custom headers to the
  -- upstream request or to the response.
  kong.response.set_header("X-Custom-Header", "This is a custom variable")
end

return CustomHandler