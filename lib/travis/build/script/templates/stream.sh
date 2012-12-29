echo <%= Shellwords.escape(template('stream.rb')) %> > ~/travis_stream
chmod +x ~/travis_stream

~/travis_stream <%= LOGS[:build] %> <%= config.urls[:logs]  %> &
~/travis_stream <%= LOGS[:state] %> <%= config.urls[:state] %> &

