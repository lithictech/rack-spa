[![Gem Version](https://badge.fury.io/rb/rack-spa.svg)](https://badge.fury.io/rb/rack-spa)
[![Status](https://github.com/lithictech/rack-spa/actions/workflows/pr-checks.yml/badge.svg)](https://github.com/lithictech/rack-spa/actions/workflows/pr-checks.yml)

# rack-spa

Rack middlewares to make building and serving a Single Page App from a Ruby Rack app easy.

Usually used for serving something like an admin app
from the same server as an API, simplifying infrastructure by removing unnecessary static app hosting.

Build your SPA JS app into a folder like `/ui-dist`:

```
cd ui
# Need dev deps to build
npm install --production=false
export NODE_ENV=production
npm run build
mv dist ../ui-dist
```

In `config.ru`, map your frontend path to the Rack app serving the content:

```rb
# This can move to some place else, like an apps.rb, to organize mounting multiple apps.
ui = Rack::Builder.new do
  dw = Rack::DynamicConfigWriter.new(
    "ui-dist/index.html",
  )
  env = {
    "VITE_API_HOST" => '/',
    "VITE_RELEASE" => "ui@1.0.0",
    "NODE_ENV" => 'production',
  }.merge(Rack::DynamicConfigWriter.pick_env("VITE_"))
  dw.emplace(env)
  # self.use Rack::Csp, policy: "default-src 'self'; img-src 'self' data:"
  Rack::SpaApp.run_spa_app(self, "ui-dist", enforce_ssl: ENV['RACK_ENV'] != 'development')
end

map "/ui" do
  run ui.to_app
end
```

See `demo` for a working example (run it from `demo` folder with `rackup demo` or `make demo` from this folder).
