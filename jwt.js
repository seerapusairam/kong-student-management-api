const jwt = require('jsonwebtoken');

const token = jwt.sign(
  { iss: "AUT2wMh0lfZpv0vaXBdMZMDHjE3Vql3b" }, // use JWT credential 'key'
  "Ovsczn0ZzmOxYouHYfzgWTYM0NPweB5w",        // secret
  { algorithm: "HS256", expiresIn: "1h" }
);

console.log(token);
