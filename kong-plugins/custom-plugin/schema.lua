return {
  name = "custom-plugin",
  fields = {
    { config = {
        type = "record",
        fields = {
          { token_name = { type = "string", default = "X-Auth-Token" }},
          { password = { type = "string", required = true } }
        }
      },
    }
  }
}
