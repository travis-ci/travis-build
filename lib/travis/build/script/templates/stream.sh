echo <%= Shellwords.escape(template('stream.rb')) %> > ~/travis_stream
chmod +x ~/travis_stream

<% if data.urls[:logs] %>
  ~/travis_stream <%= LOGS[:build] %> <%= data.urls[:logs]  %> &
<% end %>
<% if data.urls[:state] %>
  ~/travis_stream <%= LOGS[:state] %> <%= data.urls[:state] %> &
<% end %>

