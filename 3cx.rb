require 'mechanize'
require 'faye/websocket'
require 'eventmachine'
require 'permessage_deflate'
require 'json'
require 'httparty'
require 'websocket/extensions'

config_file = ARGV[0]
settings = YAML.load_file(config_file)
wallboard_url = settings["3cx_wallboard_host"]+":"+settings["3cx_wallboard_port"]
wallboard_ws = settings["3cx_wallboard_host"]+":"+settings["3cx_websocket_port"]
queue = {"key" => "QueueID", "value" => settings["queue"]}

agent = Mechanize.new
agent.user_agent_alias = 'Mac Safari'
agent.get("http://#{wallboard_url}/Wallboard/Account/Login.aspx") do | home_page |
  login_form = home_page.form_with(:id => "LoginForm")
  @params = Hash.new
  login_form.fields.each { |f| @params[f.name] = f.value }
  @params["ctl00$MainContent$LoginUser$UserName"]    = settings["username"]
  @params["ctl00$MainContent$LoginUser$Password"]    = settings["password"]
  @params["ctl00$MainContent$LoginUser$LoginButton"] = settings["loginbutton"]
  @params["ctl00$MainContent$LoginUser$Queue"]       = settings["queue"]
end
  agent.post "http://#{wallboard_url}/Wallboard/Account/Login.aspx", @params, 'Content-Type' => 'application/x-www-form-urlencoded'
  cookies = agent.cookie_jar.store.map {|i| i}
EM.run {
  url="ws://#{wallboard_ws}/Wallboard"
  ws = Faye::WebSocket::Client.new(url, [], :headers => { 'Cookie' => cookies.join(';')})
  ws.onopen do |event|
    ws.send queue.to_json
  end
  ws.on :message do |event|
    p [event.data]
    if JSON.parse(event.data)["key"] != "KeepAlive"
      settings["widgets"].each do |widget|
        puts JSON.parse(JSON.parse(event.data)["value"])["#{widget['wallboard']}"]["Value"]
        HTTParty.post("http://#{settings['dashing_url']}/widgets/#{widget['name']}",
          :body => { auth_token: "#{settings['auth_token']}", value: JSON.parse(JSON.parse(event.data)["value"])["#{widget['wallboard']}"]["Value"]}.to_json)
      end
    end
  end
}
