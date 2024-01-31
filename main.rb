require 'rack'

class VerbConnectApp
  def call(env)
    [
      200,
      {
        'rack.hijack' => (
          if env['rack.hijack?'] && env['REQUEST_METHOD'] == 'CONNECT'
            proc { |_h_io| tunnel(env) }
          end
        ),
      }.compact,
      [], # Ignored when the response is hijacked.
    ]
  end

  def tunnel(env)
    client_socket = env['rack.hijack'].call

    host, port = env['HTTP_HOST'].split(':')
    dst_socket = TCPSocket.new(host, port)

    peers = {client_socket => dst_socket, dst_socket => client_socket}
    readers = peers.keys
    loop do
      rs, _ = IO.select(readers)
      break if :terminating == rs.each do |r_io|
        peers[r_io].syswrite(r_io.sysread(2**15))
      rescue EOFError => e
        break :terminating
      rescue Errno::ECONNRESET => e
        # Tried to read from an abortively closed TCPSocket.
        break :terminating
      rescue Errno::EPIPE => e
        # Tried to write on a closed socket.
        break :terminating
      rescue => e
        # Abort on errors.
        break :terminating
      end
    end

    begin
      dst_socket.close
    rescue
      nil
    end
  ensure
    client_socket.close
  end
end

run VerbConnectApp.new