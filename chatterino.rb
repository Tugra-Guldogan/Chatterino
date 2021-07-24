require 'em-websocket'
require 'json'

class Chat
  def initialize
    # When querying a channel that doesn't exist, create a new one
    @channels = Hash.new { |hash, key| hash[key] = EM::Channel.new }
    # Do the same for online users
    @online = Hash.new { |hash, key| hash[key] = [] }
    @admins = Hash.new { |hash,key| hash[key] = [] }
  end

  def method_missing(_m, *_args)
    puts 'Invalid method called'
  end

  # Sends back a list of channels as a JSON list
  def get_chans(ws)
    ws.send(@channels.keys.to_json)
  end

  # Sends back a list of online users in a channel
  def get_online(ws, cname)
    ws.send(@online[cname].to_json)
  end

  # Creates a new channel `cname` and subscribes `user` to it
  def new_chan(ws, cname, user)
    @channels[cname] ||= EM::Channel.new
    @online[cname] ||= []
    subscribe(ws, cname, user)
  end

  # Subscribes `user` to `cname`
  def subscribe(ws, cname, user)
    sid = @channels[cname].subscribe { |m| ws.send(m) }
    @online[cname] << {user: user, sid: sid}
    jsonify(cname, cname, "#{user} joined the chat")
  end

  # Sends a list of words to `cname` with `user` as author
  def send_msg(ws, cname, user, *words)
    unless @channels[cname]
      ws.send({author: 'server', msg: 'Invalid channel'}.to_json)
      return
    end
    # Do not send messages if the user does not belong to this channel
    return unless find_user(cname, user).empty?
    str = ''
    words.map { |w| str += "#{w} " }
    jsonify(cname, user, str)
  end

  # Unsubscribes `user` from `cname` and sends back a warm goodbye
  def unsubscribe(ws, cname, user)
    return unless @channels[cname]
    users = find_user(cname, user)
    users.each {|elem| @channels[cname].unsubscribe elem[:sid] }
    @online[cname].delete_if { |elem| elem[:user] == user }
    ws.send({author: 'server', msg: 'Goodbye'}.to_json)
    jsonify(cname, cname, "#{user} left the chat")
  end

  def add_admin(ws, cname, user)
    @admins[cname] << user
  end

  def kick(ws, cname, admin, user)
    if @admins[cname].include? admin
      # Just unsubscribe the user to "kick" it
      unsubscribe(ws, cname, user)
      # And shame it in front of everybody
      jsonify(cname, cname, "#{admin} kicked #{user}")
      return
    end
    ws.send({ author: 'server', msg: 'Not enough permissions' }.to_json)
  end

  def jsonify(cname, author, message)
    msg = {author: author, msg: message}.to_json
    @channels[cname].push msg
  end

  def find_user(cname, user)
    @online[cname].select{ |elem| elem[:user] == user }
  end

  private :jsonify, :find_user
end

@chat = Chat.new

EventMachine.run do
  EventMachine::WebSocket.start(host: '0.0.0.0', port: 8081) do |ws|
    ws.onopen { |handshake| puts "#{handshake} connected" }
    ws.onmessage do |msg|
      tokens = msg.split
      @chat.send(tokens.shift, ws, *tokens)
    end
  end
end
