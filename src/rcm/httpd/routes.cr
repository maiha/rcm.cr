require "./dsl"

route "/" , Rcm::Httpd::Actions::Home.index
route "/*", Rcm::Httpd::Actions::Redis.execute
