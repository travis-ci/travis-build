<% [:build, :state].each do |type| %>
  <% if data.urls[type] %>
    echo <%= Shellwords.escape(template("report_#{type}.rb")) %> > ~/travis_report_<%= type %>.rb
    ruby ~/travis_report_<%= type %>.rb <%= logs[type] %> <%= data.urls[type]  %> &
  <% end %>
<% end %>

