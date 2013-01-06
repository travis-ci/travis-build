<% [:logs, :state].each do |type| %>
  <% if data.urls[type] %>
    echo <%= Shellwords.escape(template("report_#{type}.rb")) %> > ~/travis_report_<%= type %>
    chmod +x ~/travis_report_<%= type %>
    ~/travis_report_<%= type %> <%= LOGS[type] %> <%= data.urls[type]  %> &
  <% end %>
<% end %>

