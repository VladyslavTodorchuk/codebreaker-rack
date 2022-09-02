# frozen_string_literal: true

require_relative './app/middlewares/routes'
require 'delegate'
require 'rack/session/cookie'

use Rack::Reloader, 0
use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           expire_after: 36_000,
                           secret: 'fj1'
use Rack::Static, urls: ['/assets'], root: 'templates'
run Middlewares::Routes
