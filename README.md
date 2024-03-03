[![Gem Version](https://badge.fury.io/rb/rack-spa.svg)](https://badge.fury.io/rb/rack-spa)
[![Status](https://github.com/lithictech/rack-spa/actions/workflows/pr-checks.yml/badge.svg)](https://github.com/lithictech/rack-spa/actions/workflows/pr-checks.yml)

# rack-spa

Rack middlewares to make building and serving a Single Page App from a Ruby Rack app easy.

Usually used for serving something like an admin app
from the same server as an API, simplifying infrastructure by removing unnecessary static app hosting.

Build your SPA JS app into a folder like `/build-admin`:

```
cd admin
# Need dev deps to build
npm install --production=false
export NODE_ENV=production
npm run build
```

In `config.ru`, map your frontend path to the Rack app serving the content:

```rb
require "apps"

map "/admin" do
  run Apps::Admin.to_app
end
```

In `apps.rb'`, set up the content serving:

```rb
require 'rack/spa_app'

module Apps
  Admin = Rack::Builder.new do
    dw = Rack::DynamicConfigWriter.new(
      "build-admin/index.html",
    )
    env = {
      "VITE_API_HOST" => '/',
      "VITE_RELEASE" => "admin@1.0.0",
      "NODE_ENV" => 'production',
    }.merge(Rack::DynamicConfigWriter.pick_env("VITE_"))
    dw.emplace(env)
    # self.use Rack::Csp, policy: "default-src 'self'; img-src 'self' data:"
    Rack::SpaApp.run_spa_app(self, "build-admin", enforce_ssl: ENV['RACK_ENV'] != 'development')
  end
end
```
