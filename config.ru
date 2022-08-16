
require_relative './app/middlewares/routes'
require "delegate"
require "rack/session/cookie"

use Rack::Session::Cookie, :key => 'rack.session',
    :path => '/',
    :expire_after => 2592000
use Rack::Static, urls: ['/assets'], root: 'templates'
run Middlewares::Routes